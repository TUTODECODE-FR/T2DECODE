import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/features/lab/simulators/network_simulator.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/providers/search_provider.dart';
import 'package:tutodecode/features/courses/providers/courses_provider.dart';

void main() {
  testWidgets('NetworkSimulator smoke test', (WidgetTester tester) async {
    // Définir une taille de surface fixe pour éviter les erreurs de contraintes
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider(create: (_) => CoursesProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: NetworkSimulator(),
          ),
        ),
      ),
    );

    // Attendre que les animations initiales se terminent (flutter_animate)
    // On utilise pump(duration) pour avancer le temps si pumpAndSettle échoue sur des animations infinies
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(NetworkSimulator), findsOneWidget);
  });
}
