import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/core/security/anti_tampering.dart';
import 'package:tutodecode/core/security/build_verification.dart';
import 'package:tutodecode/core/security/identity_verification.dart';
import 'package:tutodecode/core/security/source_authentication.dart';

void main() {
  group('Security Constants and Classes Smoke Test', () {
    test('AntiTampering constants', () {
      expect(RiskLevel.low.name, 'low');
    });

    test('BuildVerification constants', () {
      expect(BuildVerification.APP_VERSION, isNotNull);
    });

    test('IdentityVerification constants', () {
      expect(IdentityVerification.ASSOCIATION_NAME, 'Association TUTODECODE');
      expect(IdentityVerification.VERIFICATION_VERSION, '1.0.0');
    });

    test('SourceAuthentication constants', () {
      expect(SourceAuthentication.OFFICIAL_DEVELOPER['name'], 'Association TUTODECODE');
    });
  });
}
