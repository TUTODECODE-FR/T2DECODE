// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:tutodecode/core/security/anti_tampering.dart';
import 'package:tutodecode/core/security/build_verification.dart';
import 'package:tutodecode/core/security/identity_verification.dart';
import 'package:tutodecode/core/security/source_authentication.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mocking the method channel for flutter_secure_storage
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return null; // Simulate empty storage
  });

  group('Security Methods Coverage Test', () {
    test('AntiTamperingSystem coverage', () async {
      final checksums = await AntiTamperingSystem.computeCurrentChecksums();
      expect(checksums, isNotNull);
      
      final isModified = await AntiTamperingSystem.isApplicationModified();
      expect(isModified, isNotNull);

      final report = await AntiTamperingSystem.generateIntegrityReport();
      expect(report, isNotNull);

      final quick = await AntiTamperingService.quickIntegrityCheck();
      expect(quick, isNotNull);
      
      final check = await AntiTamperingService.checkIntegrity();
      expect(check, isNotNull);
      
      AntiTamperingService.clearCache();
    });

    test('BuildVerification coverage', () async {
      final verification = await BuildVerification.verifyCurrentBuild();
      expect(verification, isNotNull);

      final cert = await BuildVerification.generateBuildCertificate();
      expect(cert, isNotNull);

      final quick = await BuildVerificationService.quickBuildCheck();
      expect(quick, isNotNull);

      final report = await BuildVerificationService.generateBuildReport();
      expect(report, isNotNull);
      
      final check = await BuildVerificationService.verifyBuild();
      expect(check, isNotNull);
      
      BuildVerificationService.clearCache();
    });

    test('IdentityVerification coverage', () async {
      final verification = await IdentityVerification.verifyApplicationIdentity();
      expect(verification, isNotNull);

      final cert = await IdentityVerification.generateAuthenticityCertificate();
      expect(cert, isNotNull);

      final metadata = IdentityVerification.getApplicationMetadata();
      expect(metadata, isNotNull);

      final seal = IdentityVerification.createAssociationSeal();
      expect(seal, isNotNull);
      
      final isValidSeal = IdentityVerification.verifyDigitalSeal(seal);
      expect(isValidSeal, isTrue);

      final quick = await IdentityVerificationService.verifyIdentity();
      expect(quick, isNotNull);

      final report = await IdentityVerificationService.generateVerificationReport();
      expect(report, isNotNull);
      
      IdentityVerificationService.clearCache();
    });

    test('SourceAuthentication coverage', () async {
      final verification = await SourceAuthentication.verifySourceAuthenticity();
      expect(verification, isNotNull);

      final sig = await SourceAuthentication.generateCodeSignature();
      expect(sig, isNotNull);

      final quick = await SourceAuthService.quickSourceCheck();
      expect(quick, isNotNull);

      final report = await SourceAuthService.generateSourceReport();
      expect(report, isNotNull);
      
      final check = await SourceAuthService.verifySource();
      expect(check, isNotNull);
      
      SourceAuthService.clearCache();
    });
  });
}
