import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FOSS & Air-Gapped Compliance Automated Audit', () {
    test('pubspec.yaml must not contain any telemetry or proprietary SDKs', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      
      final bannedPackages = [
        'firebase',
        'google_mobile_ads',
        'google_sign_in',
        'play_services',
        'in_app_purchase',
        'in_app_review',
        'amplitude',
        'mixpanel',
        'sentry',
        'facebook',
        'appsflyer',
        'adjust',
        'datadog',
        'newrelic',
        'crashlytics',
        'onesignal',
        'intercom',
        'telemetry',
      ];

      for (final pkg in bannedPackages) {
        final matches = RegExp('^\\s*$pkg', multiLine: true).hasMatch(pubspec);
        expect(
          matches,
          isFalse,
          reason: 'Banned proprietary package "$pkg" found in pubspec.yaml!',
        );
      }
    });

    test('Android F-Droid ProGuard rules and Gradle exclusions must be present', () {
      final proguardFile = File('android/app/proguard-rules.pro');
      expect(proguardFile.existsSync(), isTrue, reason: 'proguard-rules.pro missing!');

      final proguardContent = proguardFile.readAsStringSync();
      expect(proguardContent.contains('com.google.android.play'), isTrue);

      final appGradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(appGradle.contains('exclude(group = "com.google.android.play")'), isTrue);

      final rootGradle = File('android/build.gradle.kts').readAsStringSync();
      expect(rootGradle.contains('exclude(group = "com.google.android.play")'), isTrue);
    });

    test('AndroidManifest.xml must not declare intrusive surveillance permissions', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      
      final bannedPermissions = [
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.ACCESS_COARSE_LOCATION',
        'android.permission.READ_CONTACTS',
        'android.permission.WRITE_CONTACTS',
        'android.permission.RECORD_AUDIO',
        'android.permission.CAMERA',
        'android.permission.READ_SMS',
      ];

      for (final perm in bannedPermissions) {
        expect(
          manifest.contains(perm),
          isFalse,
          reason: 'Intrusive permission "$perm" declared in AndroidManifest.xml!',
        );
      }
    });

    test('Assets integrity checksums file must be present and valid JSON', () {
      final checksumsFile = File('assets/asset_checksums.json');
      expect(checksumsFile.existsSync(), isTrue);
      expect(checksumsFile.lengthSync(), greaterThan(10));
    });
  });
}
