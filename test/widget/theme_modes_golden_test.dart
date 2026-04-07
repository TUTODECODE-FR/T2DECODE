import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(TdcSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aperçu UI',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: TdcSpacing.md),
            Text(
              'Texte principal et secondaire pour vérifier les contrastes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: TdcSpacing.lg),
            Wrap(
              spacing: TdcSpacing.sm,
              runSpacing: TdcSpacing.sm,
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Action')),
                OutlinedButton(onPressed: () {}, child: const Text('Secondaire')),
                TextButton(onPressed: () {}, child: const Text('Lien')),
              ],
            ),
            const SizedBox(height: TdcSpacing.lg),
            const TextField(
              decoration: InputDecoration(labelText: 'Champ texte'),
            ),
            const SizedBox(height: TdcSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(TdcSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Carte'),
                    SizedBox(height: TdcSpacing.sm),
                    Text('Contenu de test pour les surfaces.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  const surfaceSize = Size(1280, 800);

  Future<void> _pumpPreview(
    WidgetTester tester, {
    required ThemeData theme,
    required String title,
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: ThemePreview(title: title),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('Light theme golden', (WidgetTester tester) async {
    await _pumpPreview(
      tester,
      theme: buildAppLightTheme(),
      title: 'Mode clair',
    );

    await expectLater(
      find.byType(ThemePreview),
      matchesGoldenFile('goldens/theme_light.png'),
    );
  });

  testWidgets('Dark theme golden', (WidgetTester tester) async {
    await _pumpPreview(
      tester,
      theme: buildAppTheme(),
      title: 'Mode sombre',
    );

    await expectLater(
      find.byType(ThemePreview),
      matchesGoldenFile('goldens/theme_dark.png'),
    );
  });
}
