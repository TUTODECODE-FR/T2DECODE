// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
//
// Ghost Link TCP: packet framing and dispatch, exercised through real loopback
// sockets against GhostLinkService (singleton, fixed TCP port 54322). Keep all
// TCP tests in this single file so `flutter test` never binds the port twice.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutodecode/features/ghost_link/service/ghost_link_service.dart';

const _password = 'framing-test-password';
const _timeout = Duration(seconds: 10);

// Same derivation as GhostLinkService._getKey (PBKDF2-HMAC-SHA256, 100k).
final _salt = [...utf8.encode('TUTODECODE_GHOSTLINK_V2_SALT'), 0, 0, 0, 0];

// Derived once: the derivation is slow and every test needs the key.
final Future<SecretKey> _keyFuture = Pbkdf2(
  macAlgorithm: Hmac.sha256(),
  iterations: 100000,
  bits: 256,
).deriveKey(secretKey: SecretKey(utf8.encode(_password)), nonce: _salt);

Future<SecretKey> _key() => _keyFuture;

Future<String> _encrypt(Map<String, dynamic> inner) async {
  final box = await AesGcm.with256bits().encrypt(
    utf8.encode(jsonEncode(inner)),
    secretKey: await _key(),
  );
  return jsonEncode({
    'iv': base64Encode(box.nonce),
    'mac': base64Encode(box.mac.bytes),
    'ct': base64Encode(box.cipherText),
  });
}

Future<Map<String, dynamic>> _decrypt(String raw) async {
  final d = jsonDecode(raw) as Map<String, dynamic>;
  final box = SecretBox(
    base64Decode(d['ct'] as String),
    nonce: base64Decode(d['iv'] as String),
    mac: Mac(base64Decode(d['mac'] as String)),
  );
  final clear = await AesGcm.with256bits().decrypt(
    box,
    secretKey: await _key(),
  );
  return jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
}

/// A raw TCP client that reads newline-terminated JSON packets.
class _Client {
  _Client(this.socket) {
    // Consume the socket eagerly: closing with unread data would reset the
    // connection and make the service's pending writes fail with EPIPE.
    final lines = StreamController<String>();
    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      lines.add,
      onDone: () {
        _closed.complete();
        lines.close();
      },
      onError: (_) {},
      cancelOnError: false,
    );
    _lines = StreamIterator(lines.stream);
  }

  final Socket socket;
  final _closed = Completer<void>();

  /// Completes when the service (or the network) closes the connection.
  Future<void> get closed => _closed.future;
  late final StreamIterator<String> _lines;

  static Future<_Client> connect() async =>
      _Client(await Socket.connect('127.0.0.1', 54322));

  /// Next packet of [type]; throws TimeoutException if none arrives, which is
  /// what happens when the peer never sends a real newline.
  Future<Map<String, dynamic>> next(String type,
      {Duration timeout = _timeout}) async {
    while (await _lines.moveNext().timeout(timeout)) {
      final p = jsonDecode(_lines.current) as Map<String, dynamic>;
      if (p['type'] == type) return p;
    }
    throw StateError('connection closed before a "$type" packet');
  }

  void send(Map<String, dynamic> packet) =>
      socket.write('${jsonEncode(packet)}\n');

  Future<void> sendSecure(Map<String, dynamic> inner) async =>
      send({'type': 'secure_msg', 'data': await _encrypt(inner)});

  Future<void> close() async {
    await socket.close();
    socket.destroy();
  }
}

Future<void> _until(bool Function() cond) async {
  final end = DateTime.now().add(_timeout);
  while (!cond()) {
    if (DateTime.now().isAfter(end)) fail('condition not met in time');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  // The service binds 0.0.0.0:54322 (and UDP 54321); neither is configurable.
  // Discovery announces stay off (stealth mode is the default), so nothing is
  // broadcast, but the tests fail if the app itself is running on this host.
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = GhostLinkService();
  late _Client client;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    expect(
      await service.start(name: 'Receiver'),
      isTrue,
      reason: service.lastStartError,
    );
    await service.setRoomPassword(_password);
  });

  tearDownAll(() async => service.stop());

  setUp(() async => client = await _Client.connect());
  tearDown(() async {
    // Let the service finish writing before the peer disappears, otherwise a
    // late write fails with EPIPE inside the service and leaks into the next test.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await client.close();
  });

  const peerIp = '127.0.0.1';
  final fromMe = {'fromId': 'ghost_peer', 'fromName': 'Peer'};

  test('handshake is terminated by a real newline', () async {
    final hs = await client.next('handshake');
    expect(hs['v'], 2);
    expect(hs['name'], 'Receiver');
  });

  test(
    'receiver registers a peer from a newline-terminated handshake',
    () async {
      client.send({'type': 'handshake', 'id': 'ghost_peer_a', 'name': 'Alice'});
      await _until(() => service.peers.any((p) => p.id == 'ghost_peer_a'));
    },
  );

  test(
    'encrypted text message is stored and ACKed with a real newline',
    () async {
      await client.sendSecure({
        ...fromMe,
        'id': 'm-text-1',
        'text': 'hello',
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
      await _until(
        () => service.getConversation(peerIp).any((m) => m.id == 'm-text-1'),
      );
      final ack = await client.next('ack');
      expect(ack['id'], 'm-text-1');
    },
  );

  test('sendMessage writes a newline-terminated secure_msg', () async {
    await client.next('handshake'); // registers the connection as active
    final ok = await service.sendMessage(
      GhostPeer(
        id: 'ghost_peer',
        name: 'Peer',
        ip: peerIp,
        lastSeen: DateTime.now(),
      ),
      'from the service',
    );
    expect(ok, isTrue);
    final packet = await client.next('secure_msg');
    final inner = await _decrypt(packet['data'] as String);
    expect(inner['text'], 'from the service');
  });

  test('encrypted file_meta + file_chunk reach the file handlers', () async {
    const id = 'f-1';
    final bytes = utf8.encode('0123456789abcdef!');
    await client.sendSecure({
      ...fromMe,
      'type': 'file_meta',
      'id': id,
      'name': 'a.txt',
      'size': 17,
    });
    await _until(() => service.getConversation(peerIp).any((m) => m.id == id));
    await client.sendSecure({
      'type': 'file_chunk',
      'id': id,
      'data': base64Encode(bytes),
      'done': true,
    });
    await _until(
      () => service
          .getConversation(peerIp)
          .any((m) => m.id == id && m.fileData != null),
    );
    final msg = service.getConversation(peerIp).firstWhere((m) => m.id == id);
    expect(msg.fileName, 'a.txt');
    expect(msg.fileData, bytes);
  });

  test('file packets outside secure_msg are ignored', () async {
    client.send({
      ...fromMe,
      'type': 'file_meta',
      'id': 'f-clear',
      'name': 'clear.txt',
      'size': 4,
    });
    client.send({
      'type': 'file_chunk',
      'id': 'f-clear',
      'data': base64Encode([1, 2, 3, 4]),
      'done': true,
    });
    // An ACK for a later packet proves the earlier ones were processed.
    await client.sendSecure({
      ...fromMe,
      'id': 'm-after-clear',
      'text': 'after',
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    expect((await client.next('ack'))['id'], 'm-after-clear');
    expect(
        service.getConversation(peerIp).any((m) => m.id == 'f-clear'), isFalse);
  });

  test(
    'multi-byte UTF-8 character split across TCP reads is not corrupted',
    () async {
      final line = utf8.encode(
        '${jsonEncode({
              'type': 'handshake',
              'id': 'ghost_peer_u',
              'name': 'Jérôme'
            })}\n',
      );
      final cut = line.indexOf(0xC3) + 1; // between the two bytes of "é"
      client.socket.add(line.sublist(0, cut));
      await client.socket.flush();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      client.socket.add(line.sublist(cut));
      await client.socket.flush();
      await _until(
        () => service.peers.any(
          (p) => p.id == 'ghost_peer_u' && p.name == 'Jérôme',
        ),
      );
    },
  );

  test('back-to-back packets during key derivation are handled once', () async {
    // Reset the cached key so the first secure_msg runs the slow derivation.
    await service.setRoomPassword(_password);
    final ts = DateTime.now().millisecondsSinceEpoch;
    await client
        .sendSecure({...fromMe, 'id': 'm-seq-1', 'text': 'one', 'ts': ts});
    // Let the service start deriving, then send the next packet at once.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await client
        .sendSecure({...fromMe, 'id': 'm-seq-2', 'text': 'two', 'ts': ts});
    expect((await client.next('ack'))['id'], 'm-seq-1');
    expect((await client.next('ack'))['id'], 'm-seq-2');
    // No duplicate ACK (a packet handled twice) and nothing lost.
    await expectLater(
      client.next('ack', timeout: const Duration(seconds: 1)),
      throwsA(isA<TimeoutException>()),
    );
    final ids = service.getConversation(peerIp).map((m) => m.id);
    expect(ids.where((i) => i == 'm-seq-1'), hasLength(1));
    expect(ids.where((i) => i == 'm-seq-2'), hasLength(1));
  });

  test('connection is closed when a line exceeds the length cap', () async {
    final chunk = List<int>.filled(64 * 1024, 0x61);
    try {
      for (var i = 0; i < 20; i++) {
        // 20 x 64 KiB = 1.25 MiB without a newline.
        client.socket.add(chunk);
        await client.socket.flush();
      }
    } on SocketException {
      // The service already dropped us: expected.
    }
    await client.closed.timeout(_timeout);
  });

  test('invalid UTF-8 closes the connection', () async {
    client.socket.add([0xFF, 0xFE, 0x0A]);
    await client.socket.flush();
    await client.closed.timeout(_timeout);
  });
}
