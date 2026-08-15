import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/core/parser/tdc_parser.dart';

void main() {
  test('Detects invalid syntax lines', () {
    const invalidCode1 = '''course "nouveau-cours" {
  title: "Nouveau Cours"
  description: ""
  category: linux
  level: beginner
  duration: 1h
  icon: BookOpen
  nvbjksf;,nhi(a"o'mzqioa
  a QMLSPJMSHWI<
  bqvfsjkhj'oazmq <
}''';

    final errors1 = TDCParser.validateSyntax(invalidCode1);
    expect(errors1.isNotEmpty, true);
    print('Errors found in test 1:');
    for (final e in errors1) {
      print('  - $e');
    }
  });

  test('Detects misspelling of course keyword', () {
    const invalidCode2 = '''corse "nouveau-cours" {
  title: "Nouveau Cours"
}''';

    final errors2 = TDCParser.validateSyntax(invalidCode2);
    expect(errors2.isNotEmpty, true);
    print('Errors found in test 2:');
    for (final e in errors2) {
      print('  - $e');
    }
  });
}
