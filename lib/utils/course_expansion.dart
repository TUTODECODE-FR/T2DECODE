// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import '../features/courses/data/course_repository.dart';

/// CourseExpansion : formatte le contenu pédagogique de façon propre et professionnelle
/// en s'appuyant sur le contenu JSON brut.
class CourseExpansion {
  // ─── Utilitaires markdown ────────────────────────────────────────────────
  static String stripMarkdownSyntax(String value) {
    return value
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
        .replaceAll(RegExp(r'`([^`]+)`'), r'\1')
        .replaceAll(RegExp(r'#+\s?'), '')
        .replaceAll(RegExp(r'[>*_]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String clipText(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength - 1).trimRight()}…';
  }

  // ─── Analyse intelligente des lignes de code ────────────────────────────
  static final Map<String, String> _commandHints = {
    // Shell / Linux
    'pwd': 'affiche le répertoire courant',
    'ls': 'liste le contenu du dossier',
    'cd': 'change de répertoire',
    'mkdir': 'crée un dossier',
    'touch': 'crée un fichier vide',
    'cp': 'copie un fichier ou dossier',
    'mv': 'déplace ou renomme',
    'rm': 'supprime un fichier ou dossier',
    'cat': 'affiche le contenu complet d\'un fichier',
    'less': 'affiche page par page',
    'grep': 'cherche un motif dans du texte',
    'find': 'recherche récursive de fichiers',
    'chmod': 'modifie les permissions',
    'chown': 'change le propriétaire',
    'wget': 'télécharge un fichier via URL',
    'curl': 'effectue une requête HTTP',
    'ssh': 'connexion sécurisée à un serveur distant',
    'scp': 'copie sécurisée vers un serveur',
    'tar': 'archive et compresse',
    'ps': 'liste les processus actifs',
    'kill': 'envoie un signal à un processus',
    'top': 'monitore les ressources en temps réel',
    'htop': 'monitore interactivement',
    'sudo': 'exécute en tant que super-utilisateur',
    'apt': 'gestionnaire de paquets Debian/Ubuntu',
    'systemctl': 'contrôle les services systemd',
    'journalctl': 'consulte les logs systemd',
    'ping': 'teste la connectivité réseau',
    'ip': 'gère interfaces et routage IP',
    'ss': 'liste les sockets réseau',
    'nmap': 'scanne les ports et services',
    'dig': 'interroge le DNS',
    'uname': 'affiche les informations système',

    // Docker
    'docker': 'pilote Docker',

    // Kubernetes
    'kubectl': 'pilote Kubernetes',

    // Package managers
    'npm': 'gère les dépendances Node.js',
    'yarn': 'alternative à npm',
    'pip': 'installe des packages Python',
    'cargo': 'compile et gère les dépendances Rust',
    'rustc': 'compile directement un fichier Rust',
    'go': 'build et exécute du Go',

    // Git
    'git': 'gère le versioning',

    // SQL
    'SELECT': 'lit les données',
    'INSERT': 'ajoute des enregistrements',
    'UPDATE': 'modifie des données',
    'DELETE': 'supprime des lignes',
    'CREATE': 'crée un objet en base',
    'ALTER': 'modifie la structure',
    'DROP': 'supprime définitivement',
    'BEGIN': 'démarre une transaction',
    'COMMIT': 'valide la transaction',
    'ROLLBACK': 'annule la transaction',
  };

  static String _explainCodeLines(String code) {
    final lines = code
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#') && !l.startsWith('//') && !l.startsWith('--'))
        .take(8)
        .toList();

    final List<String> explained = [];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final firstTokenRaw = line.split(RegExp(r'\s+')).first;
      final firstToken = firstTokenRaw.replaceAll(RegExp(r'[^a-zA-Z]'), '');
      final sqlToken = firstTokenRaw.toUpperCase();
      final hint = _commandHints[firstToken] ?? _commandHints[sqlToken];

      if (hint != null) {
        explained.add('- **`$line`** : $hint');
      } else if (RegExp(r'^(fn|function|def|func)\s+', caseSensitive: false).hasMatch(line)) {
        explained.add('- **`$line`** : définit une fonction');
      } else if (RegExp(r'^(let|const|var|val|mut)\s+', caseSensitive: false).hasMatch(line)) {
        explained.add('- **`$line`** : déclare une variable');
      } else if (RegExp(r'^if\s*[\({]|^if\s+', caseSensitive: false).hasMatch(line)) {
        explained.add('- **`$line`** : condition');
      } else if (RegExp(r'^(for|while|loop)\s*', caseSensitive: false).hasMatch(line)) {
        explained.add('- **`$line`** : boucle');
      } else if (RegExp(r'^(return|yield)\s+', caseSensitive: false).hasMatch(line)) {
        explained.add('- **`$line`** : retourne un résultat');
      } else if (RegExp(r'^(import|use|require|from)\s+', caseSensitive: false).hasMatch(line)) {
        explained.add('- **`$line`** : importe une dépendance');
      } else if (RegExp(r'^(class|struct|enum|interface|type)\s+', caseSensitive: false).hasMatch(line)) {
        explained.add('- **`$line`** : définit une structure de données');
      }
    }
    
    if (explained.isEmpty) return '';
    return explained.join('\n');
  }

  // ─── Génération de cheat sheet ───────────────────────────────────────────
  static String _generateCheatSheet(String title, String codeLanguage, String code) {
    if (code.isEmpty) return '';

    final commands = code
        .split('\n')
        .where((l) => l.trim().isNotEmpty && !l.trim().startsWith('#') && !l.trim().startsWith('//'))
        .take(6)
        .map((l) => '- `${l.trim()}`')
        .join('\n');

    if (commands.isEmpty) return '';
    
    return '''### Commandes clés
$commands''';
  }

  // ─── Point d'entrée principal ────────────────────────────────────────────
  static String expandChapterContent(Course course, CourseChapter chapter, int index) {
    final title = chapter.title;
    final duration = chapter.duration.trim().isNotEmpty ? chapter.duration.trim() : 'durée libre';
    final rawContent = chapter.content.trim();
    final total = course.chapters.length;

    // Extraction du premier bloc de code
    String code = '';
    String codeLanguage = 'bash';
    if (chapter.codeBlocks?.isNotEmpty == true) {
      code = chapter.codeBlocks![0]['code']?.toString().trim() ?? '';
      codeLanguage = chapter.codeBlocks![0]['language']?.toString() ?? 'bash';
    }

    // Contenu brut
    final courseContent = rawContent;

    // Analyse du code
    final explainedCode = _explainCodeLines(code);
    final codeSection = explainedCode.isNotEmpty
        ? '''### Analyse du Code\n$explainedCode'''
        : '';

    // Cheat sheet
    final cheatSheet = _generateCheatSheet(title, codeLanguage, code);

    // Assemblage final, propre et professionnel
    return [
      '# $title',
      '**Durée estimée :** $duration | **Chapitre ${index + 1} / $total**',
      '',
      courseContent,
      if (codeSection.isNotEmpty) ...[
        '',
        '---',
        '',
        codeSection,
      ],
      if (cheatSheet.isNotEmpty) ...[
        '',
        '---',
        '',
        cheatSheet,
      ],
    ].join('\n');
  }
}
