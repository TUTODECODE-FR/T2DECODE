// ============================================================
// GhostLink — Découverte LAN + messagerie chiffrée pair-à-pair
// Découverte : broadcast UDP port 54321
// Messages   : TCP socket     port 54322
// Chiffrement : AES-256-GCM, clé dérivée via PBKDF2-HMAC-SHA256
// ============================================================
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as pkg_crypto;
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';

const int _discoveryPort = 54321;
const int _tcpPort = 54322;
const String _broadcastAddr = '255.255.255.255';
const Duration _announceInterval = Duration(seconds: 3);
const Duration _peerTimeout = Duration(seconds: 10);

// Rate-limiting UDP discovery : max paquets par IP sur 10 s.
const int _maxUdpPacketsPerWindow = 15;
const Duration _udpRateLimitWindow = Duration(seconds: 10);

/// Génère un ID hexadécimal de 32 chars cryptographiquement aléatoire.
String _generateSecureId(String prefix) {
  final rand = Random.secure();
  final bytes = Uint8List.fromList(List.generate(16, (_) => rand.nextInt(256)));
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${prefix}_$hex';
}

// ─── Modèles ─────────────────────────────────────────────────
class GhostPeer {
  final String id;
  final String name;
  final String ip;
  final bool isManual;
  DateTime lastSeen;
  bool get isOnline => isManual
      ? _isManualOnline
      : DateTime.now().difference(lastSeen) < _peerTimeout;
  bool _isManualOnline = false;
  final bool isPinned;
  final int protocolVersion;

  GhostPeer({
    required this.id,
    required this.name,
    required this.ip,
    required this.lastSeen,
    this.isManual = false,
    this.isPinned = false,
    this.protocolVersion = 1,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'ip': ip,
        'isManual': isManual,
        'isPinned': isPinned,
        'v': protocolVersion,
      };

  factory GhostPeer.fromMap(Map<String, dynamic> map) => GhostPeer(
        id: map['id'],
        name: map['name'],
        ip: map['ip'],
        lastSeen: DateTime.now(),
        isManual: map['isManual'] ?? false,
        isPinned: map['isPinned'] ?? false,
        protocolVersion: map['v'] ?? 1,
      );
}

class GhostMessage {
  final String id;
  final String fromId;
  final String fromName;
  final String peerIp; // IP de l'autre côté (pour grouper par pair)
  final String text;
  final DateTime timestamp;
  final bool isOwn;

  GhostMessage({
    required this.id,
    required this.fromId,
    required this.fromName,
    required this.peerIp,
    required this.text,
    required this.timestamp,
    required this.isOwn,
    this.expiry,
    this.fileData,
    this.fileName,
  });

  final DateTime? expiry;
  final String? fileName;
  final Uint8List? fileData;

  bool get isExpired => expiry != null && DateTime.now().isAfter(expiry!);
}

// ─── Service ─────────────────────────────────────────────────
class GhostLinkService extends ChangeNotifier {
  static final GhostLinkService _instance = GhostLinkService._();
  factory GhostLinkService() => _instance;
  GhostLinkService._();

  // State
  bool _running = false;
  bool get isRunning => _running;
  String? _lastStartError;
  String? get lastStartError => _lastStartError;

  bool _stealthMode = true;
  bool get stealthMode => _stealthMode;

  String _localIp = '';
  String _localId = '';
  String _localName = 'Ghost';
  String get localIp => _localIp;
  String get localName => _localName;

  void setStealthMode(bool val) {
    _stealthMode = val;
    notifyListeners();
  }

  final Map<String, GhostPeer> _peers = {};
  List<GhostPeer> get peers =>
      _peers.values.toList()..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));

  // Messages groupés par IP du pair
  final Map<String, List<GhostMessage>> _conversations = {};
  List<GhostMessage> getConversation(String peerIp) =>
      _conversations[peerIp] ?? [];

  // Sockets
  RawDatagramSocket? _udpSocket;
  ServerSocket? _tcpServer;
  final Map<String, Socket> _activeSockets = {};
  Timer? _announceTimer;
  Timer? _cleanupTimer;

  // Rate-limiting UDP par IP source
  final Map<String, List<DateTime>> _udpPacketLog = {};

  // ─── Démarrage ──────────────────────────────────────────────
  Future<bool> start({String? name}) async {
    if (_running) return true;
    _lastStartError = null;
    try {
      _localIp = await _resolveLocalIp();
      _localName = await _resolveLocalName(name);

      // Charger état persistant
      final prefs = await SharedPreferences.getInstance();
      // ID cryptographiquement aléatoire — généré une fois, persisté ensuite.
      if (!prefs.containsKey('ghost_link_local_id')) {
        final newId = _generateSecureId('ghost');
        await prefs.setString('ghost_link_local_id', newId);
      }
      _localId = prefs.getString('ghost_link_local_id')!;
      await _loadPeers();

      // Charger le mot de passe de salle depuis le stockage sécurisé.
      // Si aucun mot de passe n'a jamais été défini, générer un mot de passe
      // aléatoire unique par appareil et le persister (évite le mot de passe
      // partagé entre tous les appareils).
      var savedPassword = await _readRoomPassword();
      if (savedPassword == null || savedPassword.isEmpty) {
        savedPassword = _generateSecureId('room');
        await _persistRoomPassword(savedPassword);
      }
      _roomPassword = savedPassword;
      _roomHash = _computeRoomHash(_roomPassword);

      // Socket UDP pour discovery (optionnel selon OS/politiques réseau).
      try {
        _udpSocket = await _bindDiscoverySocket();
        _udpSocket!.broadcastEnabled = true;
        _udpSocket!.listen(_onUdpData);
      } catch (e) {
        _udpSocket = null;
        _lastStartError =
            'Découverte LAN limitée sur cet OS. Ajoutez des pairs via IP manuelle.';
        if (kDebugMode) debugPrint('[GhostLink] UDP discovery disabled: $e');
      }

      // Serveur TCP pour recevoir les messages
      _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, _tcpPort);
      _tcpServer!.listen(_onNewTcpConnection);

      _running = true;
      notifyListeners();

      // Annoncer périodiquement
      _announce();
      _announceTimer = Timer.periodic(_announceInterval, (_) => _announce());
      _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _cleanupPeers();
        _cleanupMessages();
      });

      if (kDebugMode)
        debugPrint('[GhostLink] Started. IP=$_localIp Name=$_localName');
      return true;
    } catch (e) {
      await stop();
      _lastStartError = _formatStartupError(e);
      if (kDebugMode) debugPrint('[GhostLink] Start failed: $_lastStartError');
      notifyListeners();
      return false;
    }
  }

  Future<void> stop() async {
    _announceTimer?.cancel();
    _cleanupTimer?.cancel();
    _udpSocket?.close();
    await _tcpServer?.close();
    for (final s in _activeSockets.values) {
      await s.close();
    }
    _activeSockets.clear();
    _peers.removeWhere((key, value) => !value.isPinned); // Keep pinned peers
    _running = false;
    notifyListeners();
  }

  // ─── Persistence ──────────────────────────────────────────────
  static const String _prefKey = 'ghost_link_pinned_peers';

  Future<void> _savePeers() async {
    final prefs = await SharedPreferences.getInstance();
    final pinned = _peers.values
        .where((p) => p.isPinned == true)
        .map((p) => jsonEncode(p.toMap()))
        .toList();
    await prefs.setStringList(_prefKey, pinned);
  }

  Future<void> _loadPeers() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefKey) ?? [];
    for (final it in list) {
      try {
        final peer = GhostPeer.fromMap(jsonDecode(it));
        _peers[peer.id] = peer;
      } catch (_) {}
    }
    notifyListeners();
  }

  // ─── Security ───────────────────────────────────────────────
  // La clé AES-256 est dérivée du mot de passe de la salle via PBKDF2-HMAC-SHA256.
  // Par défaut : salle publique TUTODECODE (toutes les instances communiquent).
  // L'utilisateur peut rejoindre une salle privée avec un mot de passe personnalisé.
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _kRoomPasswordKey = 'ghost_link_room_password_v1';
  static const String _kRoomPasswordFallbackPrefKey =
      'ghost_link_room_password_fallback_v1';

  final _cipher = AesGcm.with256bits();

  // Salt fixe et connu — pas un secret, la sécurité vient du mot de passe.
  // Encodé en UTF-8 de 'TUTODECODE_GHOSTLINK_V2_SALT'
  static const List<int> _kRoomKeySalt = [
    0x54,
    0x55,
    0x54,
    0x4F,
    0x44,
    0x45,
    0x43,
    0x4F,
    0x44,
    0x45,
    0x5F,
    0x47,
    0x48,
    0x4F,
    0x53,
    0x54,
    0x4C,
    0x49,
    0x4E,
    0x4B,
    0x5F,
    0x56,
    0x32,
    0x5F,
    0x53,
    0x41,
    0x4C,
    0x54,
    0x00,
    0x00,
    0x00,
    0x00,
  ];

  String _roomPassword =
      ''; // Initialisé dans start() depuis le stockage sécurisé
  String _roomHash = ''; // Identifiant de salle (SHA-256 tronqué, non-secret)
  SecretKey? _derivedKey; // Cache de la clé dérivée

  String get roomPassword => _roomPassword;
  String get roomHash => _roomHash;

  /// Dérive la clé AES-256 depuis le mot de passe de la salle (PBKDF2-HMAC-SHA256).
  /// 100k itérations — équilibre sécurité / latence pour un chat temps-réel.
  Future<SecretKey> _getKey() async {
    if (_derivedKey != null) return _derivedKey!;
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    _derivedKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(_roomPassword)),
      nonce: _kRoomKeySalt,
    );
    return _derivedKey!;
  }

  /// Calcule un identifiant de salle 8 hex-chars (non-secret, utilisé pour filtrer les peers).
  String _computeRoomHash(String password) {
    final bytes = utf8.encode('GHOSTLINK_ROOM:$password');
    final digest = pkg_crypto.sha256.convert(bytes);
    return digest.toString().substring(0, 8);
  }

  /// Change le mot de passe de la salle et re-dérive la clé.
  /// Si le champ est laissé vide, un nouveau mot de passe aléatoire est généré.
  Future<void> setRoomPassword(String password) async {
    final p =
        password.trim().isEmpty ? _generateSecureId('room') : password.trim();
    _roomPassword = p;
    _derivedKey = null; // Invalider le cache
    _roomHash = _computeRoomHash(p);
    await _persistRoomPassword(p);
    notifyListeners();
  }

  Future<String> _resolveLocalIp() async {
    try {
      final info = NetworkInfo();
      final wifiIp = await info.getWifiIP();
      if (wifiIp != null && wifiIp.isNotEmpty) return wifiIp;
    } catch (_) {
      // Fallback via interfaces réseau natives si plugin indisponible.
    }

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback &&
              !addr.address.startsWith('169.254.') &&
              addr.address.isNotEmpty) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  Future<String> _resolveLocalName(String? preferredName) async {
    if (preferredName != null && preferredName.trim().isNotEmpty) {
      return preferredName.trim();
    }
    try {
      final di = DeviceInfoPlugin();
      if (Platform.isMacOS) return (await di.macOsInfo).computerName;
      if (Platform.isWindows) return (await di.windowsInfo).computerName;
      if (Platform.isIOS) return (await di.iosInfo).name;
      if (Platform.isAndroid) return (await di.androidInfo).model;
    } catch (_) {
      // Fallback si plugin non disponible sur la cible.
    }
    return Platform.localHostname;
  }

  Future<String?> _readRoomPassword() async {
    try {
      final value = await _secureStorage.read(key: _kRoomPasswordKey);
      if (value != null && value.isNotEmpty) return value;
    } catch (_) {
      // Linux/Windows peuvent ne pas avoir de keychain configurée.
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRoomPasswordFallbackPrefKey);
  }

  Future<void> _persistRoomPassword(String value) async {
    try {
      await _secureStorage.write(key: _kRoomPasswordKey, value: value);
      return;
    } catch (_) {
      // Fallback persistant hors secure storage.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRoomPasswordFallbackPrefKey, value);
  }

  Future<RawDatagramSocket> _bindDiscoverySocket() async {
    Object? lastError;
    final attempts = <Map<String, bool>>[
      {'reuseAddress': true, 'reusePort': true},
      {'reuseAddress': true, 'reusePort': false},
      {'reuseAddress': false, 'reusePort': false},
    ];

    for (final options in attempts) {
      try {
        return await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          _discoveryPort,
          reuseAddress: options['reuseAddress']!,
          reusePort: options['reusePort']!,
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('Impossible de créer le socket UDP');
  }

  String _formatStartupError(Object error) {
    if (error is SocketException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('address already in use')) {
        return 'Port Ghost Link déjà utilisé (UDP $_discoveryPort / TCP $_tcpPort).';
      }
      if (msg.contains('operation not permitted') ||
          msg.contains('permission denied')) {
        return 'Permission réseau refusée par le système.';
      }
      return 'Erreur socket: ${error.message}';
    }
    return error.toString();
  }

  Future<String> _encrypt(String text) async {
    final key = await _getKey();
    final nonce = _cipher.newNonce();
    final secretBox = await _cipher.encrypt(
      utf8.encode(text),
      secretKey: key,
      nonce: nonce,
    );
    return jsonEncode({
      'iv': base64Encode(secretBox.nonce),
      'mac': base64Encode(secretBox.mac.bytes),
      'ct': base64Encode(secretBox.cipherText),
    });
  }

  /// Retourne le texte déchiffré, ou null si le déchiffrement échoue.
  /// Un retour null indique une tentative de falsification ou une clé incorrecte.
  Future<String?> _decrypt(String raw) async {
    try {
      final key = await _getKey();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      // Validation stricte des champs requis avant de construire le SecretBox.
      final ctB64 = data['ct'] as String?;
      final ivB64 = data['iv'] as String?;
      final macB64 = data['mac'] as String?;
      if (ctB64 == null || ivB64 == null || macB64 == null) return null;

      final secretBox = SecretBox(
        base64Decode(ctB64),
        nonce: base64Decode(ivB64),
        mac: Mac(base64Decode(macB64)),
      );
      final decrypted = await _cipher.decrypt(secretBox, secretKey: key);
      return utf8.decode(decrypted);
    } catch (_) {
      // Échec silencieux : peut indiquer un message de mauvaise salle ou falsifié.
      return null;
    }
  }

  // ─── Discovery UDP ───────────────────────────────────────────
  void _announce() {
    if (_udpSocket == null || _stealthMode) return;
    // Inclure le hash de salle dans l'annonce pour que seuls les pairs
    // de la même salle apparaissent dans la liste.
    final msg = jsonEncode({
      'type': 'announce',
      'id': _localId,
      'name': _localName,
      'ip': _localIp,
      'room': _roomHash,
    });
    final bytes = utf8.encode(msg);
    _udpSocket!.send(bytes, InternetAddress(_broadcastAddr), _discoveryPort);
  }

  /// Vérifie si l'IP source dépasse la limite de paquets UDP par fenêtre de temps.
  bool _isUdpRateLimited(String sourceIp) {
    final now = DateTime.now();
    final log = _udpPacketLog.putIfAbsent(sourceIp, () => []);
    // Purger les entrées hors fenêtre
    log.removeWhere((t) => now.difference(t) > _udpRateLimitWindow);
    if (log.length >= _maxUdpPacketsPerWindow) return true;
    log.add(now);
    return false;
  }

  void _onUdpData(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final dg = _udpSocket?.receive();
    if (dg == null) return;
    // Limite de taille : un paquet de découverte ne dépasse pas 512 octets.
    if (dg.data.length > 512) return;

    final sourceIp = dg.address.address;
    // Rate-limiting : ignorer les IPs qui envoient trop de paquets.
    if (_isUdpRateLimited(sourceIp)) return;

    try {
      final raw = utf8.decode(dg.data);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['type'] != 'announce') return;
      // Filtrer les pairs qui ne sont pas dans la même salle.
      final peerRoom = data['room'] as String?;
      if (peerRoom != null && peerRoom != _roomHash) return;
      final id = data['id'] as String?;
      final name = data['name'] as String?;
      final ip = data['ip'] as String?;
      if (id == null || id.isEmpty || ip == null || ip.isEmpty) return;
      if (id == _localId) return; // Ignorer soi-même
      if (_peers.containsKey(id)) {
        _peers[id]!.lastSeen = DateTime.now();
      } else {
        _peers[id] = GhostPeer(
            id: id, name: name ?? 'Inconnu', ip: ip, lastSeen: DateTime.now());
      }
      notifyListeners();
    } catch (_) {}
  }

  // ─── Manual Peers ───────────────────────────────────────────
  Future<void> addManualPeer(String ip, String name) async {
    final id = 'manual_$ip';
    final peer = GhostPeer(
      id: id,
      name: name.isEmpty ? 'Peer ($ip)' : name,
      ip: ip,
      lastSeen: DateTime.now(),
      isManual: true,
      isPinned: true, // Auto-pin manual IPs for stability
    );
    _peers[id] = peer;
    await _savePeers();
    notifyListeners();
    await verifyPeerConnection(ip);
  }

  Future<void> togglePin(String peerId) async {
    if (_peers.containsKey(peerId)) {
      final p = _peers[peerId]!;
      _peers[peerId] = GhostPeer(
        id: p.id,
        name: p.name,
        ip: p.ip,
        lastSeen: p.lastSeen,
        isManual: p.isManual,
        isPinned: !p.isPinned,
      );
      await _savePeers();
      notifyListeners();
    }
  }

  Future<bool> verifyPeerConnection(String ip) async {
    final id = 'manual_$ip';
    if (!_peers.containsKey(id)) return false;

    try {
      final socket = await Socket.connect(ip, _tcpPort,
          timeout: const Duration(seconds: 2));
      await socket.close();
      _peers[id]!._isManualOnline = true;
      _peers[id]!.lastSeen = DateTime.now();
      notifyListeners();
      return true;
    } catch (_) {
      _peers[id]!._isManualOnline = false;
      notifyListeners();
      return false;
    }
  }

  void _cleanupPeers() {
    final before = _peers.length;
    _peers.removeWhere((_, peer) => !peer.isManual && !peer.isOnline);
    // For manual peers, we just update status periodically
    for (final p in _peers.values.where((p) => p.isManual)) {
      verifyPeerConnection(p.ip);
    }
    if (_peers.length != before) notifyListeners();
  }

  void _cleanupMessages() {
    bool changed = false;
    for (final ip in _conversations.keys) {
      final list = _conversations[ip]!;
      final count = list.length;
      list.removeWhere((m) => m.isExpired);
      if (list.length != count) changed = true;
    }
    if (changed) notifyListeners();
  }

  // ─── Messaging TCP ───────────────────────────────────────────
  void _onNewTcpConnection(Socket socket) {
    final remoteIp = socket.remoteAddress.address;
    _setupSocket(socket, remoteIp);
    // Send our handshake first
    _sendHandshake(socket);
  }

  void _setupSocket(Socket socket, String remoteIp) {
    _activeSockets[remoteIp] = socket;
    final buffer = StringBuffer();
    socket.listen(
      (bytes) async {
        buffer.write(utf8.decode(bytes));
        final raw = buffer.toString();
        if (raw.contains('\n')) {
          final lines = raw.split('\n');
          for (var i = 0; i < lines.length - 1; i++) {
            await _handleIncomingPacket(lines[i], remoteIp, socket);
          }
          buffer.clear();
          if (lines.last.isNotEmpty) buffer.write(lines.last);
        }
      },
      onDone: () {
        _activeSockets.remove(remoteIp);
      },
      onError: (_) {
        _activeSockets.remove(remoteIp);
      },
      cancelOnError: false,
    );
  }

  Future<void> _sendHandshake(Socket socket) async {
    final packet = {
      'type': 'handshake',
      'id': _localId,
      'name': _localName,
      'v': 2, // Protocol version 2 (Hardened)
    };
    socket.write('${jsonEncode(packet)}\n');
  }

  Future<void> _handleIncomingPacket(
      String raw, String senderIp, Socket socket) async {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final type = data['type'] as String;

      switch (type) {
        case 'handshake':
          final id = data['id'] as String;
          final name = data['name'] as String;
          final version = data['v'] as int? ?? 1;
          if (id != _localId) {
            _peers[id] = GhostPeer(
                id: id,
                name: name,
                ip: senderIp,
                lastSeen: DateTime.now(),
                protocolVersion: version);
            notifyListeners();
          }
          break;
        case 'secure_msg':
          final encrypted = data['data'] as String?;
          if (encrypted == null || encrypted.isEmpty) break;
          final decrypted = await _decrypt(encrypted);
          if (decrypted != null && decrypted.isNotEmpty) {
            _handleDecryptedMessage(decrypted, senderIp);
            // Send ACK
            final msgId = (jsonDecode(decrypted) as Map<String, dynamic>)['id'];
            if (msgId != null) {
              _sendPacket(socket, {'type': 'ack', 'id': msgId}, encrypt: false);
            }
          }
          break;
        case 'ack':
          if (kDebugMode)
            debugPrint('[GhostLink] ACK received for msg ${data['id']}');
          break;
        case 'req_info':
          _sendSystemInfo(socket);
          break;
        case 'info_res':
          _handleSystemInfoResponse(data['data'], senderIp);
          break;
        case 'file_meta':
          _handleFileMeta(data, senderIp);
          break;
        case 'file_chunk':
          _handleFileChunk(data, senderIp);
          break;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[GhostLink] Packet error: $e');
    }
  }

  void _sendSystemInfo(Socket socket) {
    final info = {
      'os': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'cpuCount': Platform.numberOfProcessors,
      'mem': 'Local device stats', // Placeholder for more advanced metrics
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    _sendPacket(socket, {'type': 'info_res', 'data': info});
  }

  void _handleSystemInfoResponse(dynamic data, String senderIp) {
    // Notify UI with system info
    if (kDebugMode) debugPrint('[GhostLink] System info from $senderIp: $data');
  }

  void _handleFileMeta(Map<String, dynamic> data, String senderIp) {
    _conversations.putIfAbsent(senderIp, () => []).add(GhostMessage(
          id: data['id'],
          fromId: data['fromId'],
          fromName: data['fromName'],
          peerIp: senderIp,
          text: 'Fichier entrant : ${data['name']} (${data['size']} octets)',
          timestamp: DateTime.now(),
          isOwn: false,
          fileName: data['name'],
        ));
    notifyListeners();
  }

  void _handleFileChunk(Map<String, dynamic> data, String senderIp) {
    // In a real implementation, we'd append to a file or buffer.
    // For now, we just log it to verify the protocol.
    if (kDebugMode) debugPrint('[GhostLink] Chunk received from $senderIp');
  }

  void _handleDecryptedMessage(String decrypted, String senderIp) {
    try {
      final data = jsonDecode(decrypted) as Map<String, dynamic>;
      final msg = GhostMessage(
        id: data['id'] as String,
        fromId: data['fromId'] as String,
        fromName: data['fromName'] as String,
        peerIp: senderIp,
        text: data['text'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(data['ts'] as int),
        isOwn: false,
        expiry: data.containsKey('expiry')
            ? DateTime.fromMillisecondsSinceEpoch(data['expiry'] as int)
            : null,
        fileName: data['fileName'] as String?,
      );
      // Éviter les doublons
      final conv = _conversations.putIfAbsent(senderIp, () => []);
      if (!conv.any((m) => m.id == msg.id)) {
        conv.add(msg);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _sendPacket(Socket socket, Map<String, dynamic> packet,
      {bool encrypt = true}) async {
    if (encrypt) {
      final raw = jsonEncode(packet);
      final encrypted = await _encrypt(raw);
      socket
          .write('${jsonEncode({'type': 'secure_msg', 'data': encrypted})}\n');
    } else {
      socket.write('${jsonEncode(packet)}\n');
    }
  }

  Future<bool> sendMessage(GhostPeer peer, String text,
      {Duration? expiry}) async {
    try {
      Socket? socket = _activeSockets[peer.ip];
      if (socket == null) {
        socket = await Socket.connect(peer.ip, _tcpPort,
            timeout: const Duration(seconds: 4));
        _setupSocket(socket, peer.ip);
        await _sendHandshake(socket);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // ID cryptographiquement aléatoire — évite l'énumération et les replays.
      final rand = Random.secure();
      final msgId = List.generate(16, (_) => rand.nextInt(256))
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final packet = {
        'id': msgId,
        'fromId': _localId,
        'fromName': _localName,
        'text': text,
        'ts': DateTime.now().millisecondsSinceEpoch,
        if (expiry != null)
          'expiry': DateTime.now().add(expiry).millisecondsSinceEpoch,
      };

      await _sendPacket(socket, packet);

      final msg = GhostMessage(
        id: msgId,
        fromId: _localId,
        fromName: _localName,
        peerIp: peer.ip,
        text: text,
        timestamp: DateTime.now(),
        isOwn: true,
        expiry: expiry != null ? DateTime.now().add(expiry) : null,
      );
      _conversations.putIfAbsent(peer.ip, () => []).add(msg);
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[GhostLink] Send failed: $e');
      return false;
    }
  }

  Future<void> requestRemoteInfo(GhostPeer peer) async {
    final socket = _activeSockets[peer.ip];
    if (socket != null) {
      await _sendPacket(socket, {'type': 'req_info'});
    }
  }

  Future<void> sendFile(GhostPeer peer) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final socket = _activeSockets[peer.ip];
    if (socket == null) return;

    final rand2 = Random.secure();
    final msgId = List.generate(16, (_) => rand2.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    // 1. Send metadata
    await _sendPacket(socket, {
      'type': 'file_meta',
      'id': msgId,
      'name': file.name,
      'size': file.size,
      'fromId': _localId,
      'fromName': _localName,
    });

    // 2. Send in chunks (simulated for now with the first few bytes)
    if (file.bytes != null) {
      final chunk = file.bytes!.sublist(0, min(1024, file.size));
      await _sendPacket(socket, {
        'type': 'file_chunk',
        'id': msgId,
        'data': base64Encode(chunk),
      });
    }

    _conversations.putIfAbsent(peer.ip, () => []).add(GhostMessage(
          id: msgId,
          fromId: _localId,
          fromName: _localName,
          peerIp: peer.ip,
          text: 'Fichier envoyé : ${file.name}',
          timestamp: DateTime.now(),
          isOwn: true,
          fileName: file.name,
        ));
    notifyListeners();
  }
}
