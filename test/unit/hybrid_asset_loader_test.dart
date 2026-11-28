import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
// Transitive test-only dependencies, as in tdc_module_import_test.dart.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tutodecode/core/localization/hybrid_asset_loader.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  FakePathProviderPlatform(this.path);

  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const loader = HybridAssetLoader();

  test('charge le fichier groupé en.json pour la locale anglaise', () async {
    final result = await loader.load('assets/translations', const Locale('en'));

    expect(result['home']['sections']['tools_services'], 'Tools & Services');
  });

  test('renvoie le français pour la locale fr (comportement inchangé)',
      () async {
    final result = await loader.load('assets/translations', const Locale('fr'));

    expect(result['home']['sections']['tools_services'], 'Outils & Services');
  });

  group('fallback and override', () {
    late Directory tempDir;
    late PathProviderPlatform originalPlatform;

    setUp(() async {
      originalPlatform = PathProviderPlatform.instance;
      tempDir = await Directory.systemTemp.createTemp('tdc_loader_test');
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    });

    tearDown(() async {
      PathProviderPlatform.instance = originalPlatform;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<void> writeOverride(String code, String content) async {
      final file = File(
        p.join(tempDir.path, 'T2DECODE', 'translations', '$code.json'),
      );
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    }

    test('falls back to French for a locale without a bundled file', () async {
      final result =
          await loader.load('assets/translations', const Locale('it'));

      expect(result['home']['sections']['tools_services'], 'Outils & Services');
      expect(result['home']['title'], 'Accueil');
    });

    test('fills keys missing from a partial bundle with French values',
        () async {
      final result =
          await loader.load('assets/translations', const Locale('es'));

      // es.json has no `home` object: it comes from fr.json.
      expect(result['home']['title'], 'Accueil');
      // es.json defines `menu.home`: it stays Spanish.
      expect(result['menu']['home'], 'Inicio');
    });

    test('Documents override wins and is deep-merged with the bundle',
        () async {
      await writeOverride(
        'en',
        '{"home": {"sections": {"tools_services": "Custom Tools"}}}',
      );

      final result =
          await loader.load('assets/translations', const Locale('en'));

      expect(result['home']['sections']['tools_services'], 'Custom Tools');
      // Sibling key in the same nested map keeps the bundled English value.
      expect(result['home']['sections']['courses'], 'IT Pathways');
    });

    test('malformed override is ignored without throwing', () async {
      await writeOverride('en', '{not json');

      final result =
          await loader.load('assets/translations', const Locale('en'));

      expect(result['home']['sections']['tools_services'], 'Tools & Services');
    });

    test('top-level array override is ignored without throwing', () async {
      await writeOverride('en', '[1,2]');

      final result =
          await loader.load('assets/translations', const Locale('en'));

      expect(result['home']['sections']['tools_services'], 'Tools & Services');
    });
  });
}
