// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>

import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/core/parser/tdc_parser.dart';
import 'package:tutodecode/core/services/tdc_category_registry.dart';
import 'package:tutodecode/core/services/tdc_icon_registry.dart';
import 'package:tutodecode/core/services/tdc_signature_service.dart';
import 'package:tutodecode/core/services/tdc_community_service.dart';

void main() {
  group('Phase A — Catégories Personnalisées', () {
    test('Valide un cours avec category custom auto-contenue', () {
      const source = '''category custom "devops" {
  label: "DevOps & CI/CD"
  color: mint
  icon: Rocket
}

course "cours-devops" {
  title: "Introduction à DevOps"
  category: devops
  level: beginner
  duration: 1h
  icon: Rocket
}''';
      final errors = TDCParser.validateSyntax(source);
      expect(errors, isEmpty, reason: 'La catégorie custom déclarée dans le fichier doit être valide');

      final parsed = TDCParser.parseCourse(source);
      expect(parsed['category'], equals('devops'));
      expect((parsed['custom_categories'] as List).length, equals(1));
    });

    test('Refuse une catégorie custom non déclarée', () {
      const source = '''course "cours-orphelin" {
  title: "Test Invalide"
  category: categorie_inconnue_123
}''';
      final errors = TDCParser.validateSyntax(source);
      expect(errors, isNotEmpty);
      expect(errors.first.message, contains('non déclarée'));
    });

    test('Refuse une collision avec une catégorie intégrée', () {
      const source = '''category custom "linux" {
  label: "Faux Linux"
  color: mint
}

course "cours-test" {
  title: "Test"
  category: linux
}''';
      final errors = TDCParser.validateSyntax(source);
      expect(errors, isNotEmpty);
      expect(errors.first.message, contains('collision avec une catégorie intégrée'));
    });
  });

  group('Phase B — Icônes Étendues & Recherche Bilingue', () {
    test('Recherche bilingue FR et EN non vide', () {
      final resSecu = TDCIconRegistry.search('securite');
      final resShield = TDCIconRegistry.search('shield');
      final resTerm = TDCIconRegistry.search('terminal');
      final resCloud = TDCIconRegistry.search('cloud');

      expect(resSecu, isNotEmpty);
      expect(resShield, isNotEmpty);
      expect(resTerm, isNotEmpty);
      expect(resCloud, isNotEmpty);
    });

    test('Validation token icône et repli fallback', () {
      expect(TDCIconRegistry.isValidToken('Terminal'), isTrue);
      expect(TDCIconRegistry.isValidToken('Rocket'), isTrue);
      expect(TDCIconRegistry.isValidToken('IconeInconnue999'), isFalse);
    });
  });

  group('Phase C — Tokens de Couleurs & Accents', () {
    test('Validation de la palette stricte sans code hex', () {
      expect(TDCColorTokens.isValidToken('mint'), isTrue);
      expect(TDCColorTokens.isValidToken('lavande'), isTrue);
      expect(TDCColorTokens.isValidToken('sky'), isTrue);
      expect(TDCColorTokens.isValidToken('invalid_hex_color'), isFalse);
    });
  });

  group('Phase D — Signature Cryptographique & Canonisation', () {
    test('Canonisation déterministe excluant la signature', () {
      const source = '''course "demo" {
  title: "Demo"
  author: "Alice"
  signature: "MEQCID..."
}''';
      final canonical = TDCSignatureService.canonicalizeSource(source);
      expect(canonical.contains('signature:'), isFalse);
      expect(canonical.contains('author: "Alice"'), isTrue);
    });
  });

  group('Phase E — Explorateur Communauté & Checksum', () {
    test('Vérification intégrité SHA256', () {
      const text = 'TUTODECODE SOUVERAIN';
      expect(TDCCommunityService.verifyChecksum(text, ''), isTrue);
    });
  });
}
