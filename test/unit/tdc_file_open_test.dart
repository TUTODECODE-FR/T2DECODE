// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutodecode/core/services/module_service.dart';
import 'package:tutodecode/core/services/tdc_file_open.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.docsPath);

  final String docsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => docsPath;
}

const _bashDsl = '''
course "bash-scripting" {
  title: "Bash Scripting"
  description: "Ecrire des scripts Bash hors ligne"
  category: linux
  level: beginner
  duration: 1h

  module "intro" {
    title: "Le shebang"
    duration: 10min
    content """
# Bash

echo "hello"
    """
  }
}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tdc_open_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(TdcFileImporter.channelName),
      null,
    );
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Info.plist exports org.t2decode.tdc for the .tdc extension', () {
    final plist = File('macos/Runner/Info.plist').readAsStringSync();
    final documentTypes = plist
        .split('<key>CFBundleDocumentTypes</key>')
        .last
        .split('<key>UTExportedTypeDeclarations</key>')
        .first;
    expect(documentTypes, contains('<string>org.t2decode.tdc</string>'));
    expect(documentTypes, contains('<string>tdc</string>'));
    expect(documentTypes, contains('<string>Owner</string>'));
    expect(documentTypes, isNot(contains('public.data')));
    expect(documentTypes, isNot(contains('public.plain-text')));

    final exported = plist.split('<key>UTExportedTypeDeclarations</key>').last;
    expect(exported, contains('<string>org.t2decode.tdc</string>'));
    expect(exported, contains('<string>tdc</string>'));
    expect(exported, contains('<string>public.plain-text</string>'));
    expect(exported, contains('<string>public.data</string>'));

    final swift = File('macos/Runner/AppDelegate.swift').readAsStringSync();
    expect(swift, contains('org.t2decode.app/open_files'));
    expect(swift, contains('getPendingFiles'));
    expect(
        swift,
        contains(
            'func application(_ application: NSApplication, open urls: [URL])'));
    expect(
      File('macos/Runner/MainFlutterWindow.swift').readAsStringSync(),
      contains('TdcOpenFileCenter.register'),
    );
  });

  test('accepts a .tdc path and rejects other names', () {
    expect(
      TdcFileImporter.acceptsPath('/Users/me/Desktop/bash-scripting.tdc'),
      isTrue,
    );
    expect(TdcFileImporter.acceptsPath(r'C:\cours\Bash Scripting.TDC'), isTrue);
    expect(
      TdcFileImporter.acceptsPath('file:///Users/me/bash-scripting.tdc'),
      isTrue,
    );
    expect(TdcFileImporter.acceptsPath('/Users/me/notes.txt'), isFalse);
    expect(TdcFileImporter.acceptsPath('/Users/me/course.tdc.bak'), isFalse);
    expect(TdcFileImporter.acceptsPath('/Users/me/course.tdc.json'), isFalse);
    expect(
      TdcFileImporter.filterPaths(const [
        '/tmp/bash-scripting.tdc',
        '/tmp/readme.txt',
        '/tmp/bash-scripting.tdc',
      ]),
      ['/tmp/bash-scripting.tdc'],
    );
  });

  test('parses bash-scripting.tdc and stores the course', () async {
    final file = File('${tempDir.path}/bash-scripting.tdc');
    await file.writeAsString(_bashDsl);

    final result = await const TdcFileImporter().importPath(file.path);
    expect(result.isImported, isTrue);
    expect(result.course!.id, 'bash-scripting');
    expect(result.course!.title, 'Bash Scripting');
    expect(result.course!.chapters, isNotEmpty);
    expect(result.course!.chapters.first.content, contains('echo "hello"'));

    final loaded = await ModuleService().loadExternalModules();
    expect(loaded.map((course) => course.id), contains('bash-scripting'));
    expect(
      loaded.firstWhere((course) => course.id == 'bash-scripting').title,
      'Bash Scripting',
    );
  });

  test('accepts a minimal TDC Studio document and stores the course', () async {
    const studio = '''
tdc-version: 2
type: course

course "mini" {
  title: "Mini"
  description: "Document TDC Studio minimal"
  category: linux
  level: beginner
  duration: 15min

  module "intro" {
    title: "Introduction"
    duration: 5min
    content """
    Bonjour
    """
  }
}
''';
    final file = File('${tempDir.path}/mini.tdc');
    await file.writeAsString(studio);

    final result = await const TdcFileImporter().importPath(file.path);
    expect(result.isImported, isTrue);
    expect(result.course!.id, 'mini');
    expect(result.course!.title, 'Mini');
    expect(result.course!.chapters.single.content, contains('Bonjour'));

    final loaded = await ModuleService().loadExternalModules();
    expect(loaded.map((course) => course.id), contains('mini'));
  });

  test('rejects a file whose only TDC trait is the .tdc extension', () async {
    final file = File('${tempDir.path}/notes.tdc');
    await file.writeAsString('Notes personnelles renommees en .tdc\n');

    final result = await const TdcFileImporter().importPath(file.path);
    expect(result.isImported, isFalse);
    expect(result.course, isNull);
    expect(result.error, contains("n'est pas un document TDC Studio"));
    expect(result.error, contains('.tdc'));
    expect(
        Directory('${tempDir.path}/TUTODECODE_Modules').existsSync(), isFalse);
  });

  test('does not import an encrypted .tdc backup as a course', () async {
    final file = File('${tempDir.path}/backup.tdc');
    await file.writeAsString(
      '{"header":{"magic":"TDCB"},"payload":"secret"}',
    );

    final result = await const TdcFileImporter().importPath(file.path);
    expect(result.course, isNull);
    expect(result.error, contains('Paramètres'));
    expect(
        Directory('${tempDir.path}/TUTODECODE_Modules').existsSync(), isFalse);
  });

  test('macOS channel delivers a .tdc path and the file is parsed', () async {
    final file = File('${tempDir.path}/bash-scripting.tdc');
    await file.writeAsString(_bashDsl);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var pulls = 0;
    messenger.setMockMethodCallHandler(
      const MethodChannel(TdcFileImporter.channelName),
      (call) async {
        if (call.method == 'getPendingFiles') {
          pulls += 1;
          if (pulls == 1) {
            return <String>[file.path, '${tempDir.path}/readme.txt'];
          }
          return <String>[];
        }
        return null;
      },
    );

    final titles = <String>[];
    final bridge = TdcOpenBridge();
    await bridge.start(onPaths: (paths) async {
      expect(paths, [file.path]);
      for (final path in paths) {
        final result = await const TdcFileImporter().importPath(path);
        titles.add(result.course!.title);
      }
    });

    expect(titles, ['Bash Scripting']);
    bridge.stop();
  });
}
