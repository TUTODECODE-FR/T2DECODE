import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/widgets/app_shell.dart';
import 'package:tutodecode/core/providers/search_provider.dart';
import 'package:tutodecode/features/courses/providers/courses_provider.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/providers/settings_provider.dart';

void main() {
  testWidgets('AppShell smoke test', (WidgetTester tester) async {
    // Set a fixed surface size
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider(create: (_) => CoursesProvider()),
          ChangeNotifierProvider(create: (_) => ShellProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: AppShell(child: Container()),
        ),
      ),
    );

    await tester.pump();
    
    expect(find.byType(AppShell), findsOneWidget);
  });
}
