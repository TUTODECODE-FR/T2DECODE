import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/core/localization/hybrid_asset_loader.dart';

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
}
