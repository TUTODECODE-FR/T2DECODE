// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>

class MarkdownSanitizer {
  /// Sanitize markdown content before rendering to prevent XSS vulnerabilities.
  static String sanitize(String input) {
    if (input.isEmpty) return input;

    var sanitized = input;
    
    // 1. Purger systématiquement toutes les balises <script>
    sanitized = sanitized.replaceAll(
      RegExp(r'<script\b[^>]*>[\s\S]*?</script>', caseSensitive: false), 
      ''
    );
    
    // 2. Supprimer tous les attributs d'événements DOM (onClick, onLoad, etc.)
    sanitized = sanitized.replaceAll(
      RegExp(r"""\bon[A-Za-z]+\s*=\s*(?:(["'])(?:(?!\1).)*\1|[^\s>]+)""", caseSensitive: false), 
      ''
    );
    
    // 3. Neutraliser les URI javascript: dans les liens hypertextes
    sanitized = sanitized.replaceAll(
      RegExp(r"""javascript:[^\s"'<>]*""", caseSensitive: false), 
      '#'
    );

    return sanitized;
  }
}
