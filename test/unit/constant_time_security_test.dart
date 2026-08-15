import 'package:flutter_test/flutter_test.dart';
import 'package:t2decode/core/security/constant_time_security.dart';

void main() {
  group('ConstantTimeSecurity Shield', () {
    test('compareStrings timing safety', () {
      expect(ConstantTimeSecurity.compareStrings('secret123', 'secret123'), isTrue);
      expect(ConstantTimeSecurity.compareStrings('secret123', 'wrong1234'), isFalse);
    });

    test('zeroize memory wiping', () {
      final buffer = [1, 2, 3, 4, 5];
      ConstantTimeSecurity.zeroize(buffer);
      expect(buffer, equals([0, 0, 0, 0, 0]));
    });

    test('computeMerkleRoot hash calculation', () {
      final root = ConstantTimeSecurity.computeMerkleRoot(['asset1', 'asset2']);
      expect(root, isNotEmpty);
      expect(root.length, equals(64));
    });
  });
}
