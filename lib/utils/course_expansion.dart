import '../features/courses/data/course_repository.dart';

/// CourseExpansion : génère un contenu pédagogique ultra-riche et structuré
/// pour chaque chapitre en s'appuyant sur le contenu JSON brut.
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
    'pwd':    'affiche le répertoire courant — indispensable pour savoir **où vous êtes** avant d\'agir',
    'ls':     'liste le contenu du dossier — vérifiez **avant** de créer ou supprimer quoi que ce soit',
    'cd':     'change de répertoire — naviguez toujours avec précision pour éviter les erreurs de chemin',
    'mkdir':  'crée un dossier — utilisez `-p` pour créer des arborescences complètes en une commande',
    'touch':  'crée un fichier vide ou met à jour son horodatage — pratique pour initialiser des configs',
    'cp':     'copie un fichier en conservant l\'original — parfait pour tester sans risque',
    'mv':     'déplace ou renomme — une seule commande pour réorganiser votre arborescence',
    'rm':     '⚠️ supprime définitivement — pas de corbeille Linux, vérifiez deux fois avant d\'exécuter',
    'cat':    'affiche le contenu complet d\'un fichier — rapide pour auditer une config ou un log',
    'less':   'affiche page par page — utilisez `/` pour rechercher dans un fichier volumineux',
    'grep':   'cherche un motif dans du texte — l\'outil de diagnostic #1 pour logs et configs',
    'find':   'recherche récursive de fichiers — combinable avec `-exec` pour des actions en lot',
    'chmod':  'modifie les permissions — mémorisez `755` (exécutable) et `600` (privé SSH)',
    'chown':  'change le propriétaire — crucial en production pour la sécurité des fichiers',
    'wget':   'télécharge un fichier via URL — utile pour récupérer des scripts d\'installation',
    'curl':   'effectue une requête HTTP — le couteau suisse du debug API',
    'ssh':    'connexion sécurisée à un serveur distant — la porte d\'entrée de tout admin système',
    'scp':    'copie sécurisée vers un serveur — alternative chiffrée à FTP',
    'tar':    'archive et compresse — `tar -czf` pour créer, `tar -xzf` pour extraire',
    'ps':     'liste les processus actifs — combinez avec `grep` pour trouver un service spécifique',
    'kill':   'envoie un signal à un processus — `-9` en dernier recours (force brute)',
    'top':    'monitore les ressources en temps réel — appuyez sur `q` pour quitter',
    'htop':   'monitore interactivement — bien plus lisible que `top` avec couleurs et tri',
    'sudo':   'exécute en tant que super-utilisateur — à utiliser avec discernement',
    'apt':    'gestionnaire de paquets Debian/Ubuntu — `apt update` avant chaque `apt install`',
    'systemctl': 'contrôle les services systemd — `status`, `start`, `stop`, `enable`, `restart`',
    'journalctl': 'consulte les logs systemd — `journalctl -f` pour suivre en temps réel',
    'ping':   'teste la connectivité réseau — simple mais efficace pour diagnostiquer',
    'ip':     'gère interfaces et routage IP — remplace `ifconfig` dans les systèmes modernes',
    'ss':     'liste les sockets réseau — remplace `netstat` pour auditer les ports ouverts',
    'nmap':   'scanne les ports et services — l\'outil de référence du diagnostic réseau',
    'dig':    'interroge le DNS — plus complet que `nslookup` pour diagnostiquer la résolution',
    'uname':  'affiche les informations système — `-r` pour le noyau, `-a` pour tout',

    // Docker
    'docker': 'pilote Docker — `run`, `build`, `ps`, `logs`, `exec` sont les commandes du quotidien',

    // Kubernetes
    'kubectl': 'pilote Kubernetes — commandez vos pods, deployments et services',

    // Package managers
    'npm':    'gère les dépendances Node.js — `npm install` pour démarrer, `npm audit` pour la sécurité',
    'yarn':   'alternative à npm — généralement plus rapide pour les projets volumineux',
    'pip':    'installe des packages Python — ajoutez `--user` pour éviter les conflits systèmes',
    'cargo':  'compile et gère les dépendances Rust — `cargo build --release` pour la production',
    'rustc':  'compile directement un fichier Rust — préférez `cargo` pour les projets réels',
    'go':     'build et exécute du Go — `go build`, `go test`, `go run` sont vos alliés',

    // Git
    'git':    'gère le versioning — chaque action laisse une trace dans l\'historique',

    // SQL
    'SELECT': 'lit les données — précisez toujours les colonnes plutôt que `SELECT *` en production',
    'INSERT': 'ajoute des enregistrements — vérifiez les contraintes NOT NULL et UNIQUE',
    'UPDATE': 'modifie des données — **toujours** ajouter un WHERE pour ne pas tout modifier',
    'DELETE': '⚠️ supprime des lignes — à encapsuler dans une transaction et tester avec SELECT d\'abord',
    'CREATE': 'crée un objet en base (table, index, vue) — définissez bien les types dès le départ',
    'ALTER':  'modifie la structure d\'une table existante — prudence en production avec les locks',
    'DROP':   '⚠️ supprime définitivement — impossible à annuler hors transaction',
    'BEGIN':  'démarre une transaction — groupez plusieurs opérations atomiques',
    'COMMIT': 'valide la transaction — les données sont persistées une fois ici',
    'ROLLBACK': 'annule la transaction — votre filet de sécurité contre les erreurs',
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
        explained.add('> 🔹 **`$line`** — $hint');
      } else if (RegExp(r'^(fn|function|def|func)\s+', caseSensitive: false).hasMatch(line)) {
        explained.add('> 🔹 **`$line`** — définit une fonction réutilisable qui encapsule la logique');
      } else if (RegExp(r'^(let|const|var|val|mut)\s+', caseSensitive: false).hasMatch(line)) {
        explained.add('> 🔹 **`$line`** — déclare et initialise une donnée de travail');
      } else if (RegExp(r'^if\s*[\({]|^if\s+', caseSensitive: false).hasMatch(line)) {
        explained.add('> 🔹 **`$line`** — branche conditionnelle qui protège le flux d\'exécution');
      } else if (RegExp(r'^(for|while|loop)\s*', caseSensitive: false).hasMatch(line)) {
        explained.add('> 🔹 **`$line`** — boucle qui automatise une tâche répétitive');
      } else if (RegExp(r'^(return|yield)\s+', caseSensitive: false).hasMatch(line)) {
        explained.add('> 🔹 **`$line`** — renvoie un résultat à l\'appelant');
      } else if (RegExp(r'^(import|use|require|from)\s+', caseSensitive: false).hasMatch(line)) {
        explained.add('> 🔹 **`$line`** — importe une dépendance ou un module externe');
      } else if (RegExp(r'^(class|struct|enum|interface|type)\s+', caseSensitive: false).hasMatch(line)) {
        explained.add('> 🔹 **`$line`** — définit une abstraction de données ou un contrat');
      } else {
        explained.add('> 🔹 **`$line`** — instruction technique à comprendre dans son contexte');
      }
    }
    return explained.join('\n');
  }

  // ─── Génération de quiz adaptatifs ──────────────────────────────────────
  static String _generateQuiz(String title, List<String> keywords) {
    final k1 = keywords.isNotEmpty ? keywords[0] : 'ce concept';
    final k2 = keywords.length > 1 ? keywords[1] : 'la pratique';
    return '''### 🧠 Quiz de validation (testez-vous !)

**Q1 — Compréhension**
Expliquez à quelqu'un qui découvre **$k1** ce que fait ce chapitre sur "$title" en 2 phrases maximum.

**Q2 — Application**
Dans quel scénario réel utiliseriez-vous les techniques de ce chapitre ?
Citez un exemple précis issu de votre contexte (projet perso, travail, étude).

**Q3 — Diagnostic**
Qu'est-ce qui pourrait mal tourner si vous appliquez **$k2** sans respecter les bonnes pratiques ?
Décrivez le symptôme et la cause racine probable.

**Q4 — Optimisation**
Comment amélioreriez-vous ce que vous venez d'apprendre pour le rendre plus robuste en production ?''';
  }

  // ─── Génération de pitfalls spécifiques ─────────────────────────────────
  static String _generatePitfalls(String title, String category) {
    final Map<String, List<String>> pitfallsByCategory = {
      'linux': [
        '⚠️ **`rm -rf` sans vérification** — Toujours faire un `ls` sur le chemin avant de supprimer récursivement.',
        '⚠️ **Confondre chemins absolus et relatifs** — Un `cd /` accidentel change tout le contexte.',
        '⚠️ **Modifier `/etc` sans backup** — Sauvegardez `cp /etc/fichier /etc/fichier.bak` avant toute édition.',
        '⚠️ **Permissions trop larges (chmod 777)** — Exposé à tous les utilisateurs, dangereux en multi-user.',
        '⚠️ **Ignorer les messages d\'erreur stderr** — La plupart des bugs se révèlent dans le canal d\'erreur.',
      ],
      'devops': [
        '⚠️ **Image Docker sans tag précis** — `image: redis` peut casser lors d\'une mise à jour. Préférez `redis:7.2-alpine`.',
        '⚠️ **Secrets en clair dans le Dockerfile** — Toujours utiliser des variables d\'environnement ou un vault.',
        '⚠️ **Pas de healthcheck** — Docker ne sait pas que votre service a crashé sans `HEALTHCHECK`.',
        '⚠️ **Root dans le conteneur** — Tournez toujours avec un user non-root pour la sécurité.',
        '⚠️ **Volumes non persistants** — Les données dans un conteneur disparaissent à l\'arrêt sans volume monté.',
      ],
      'sql': [
        '⚠️ **`UPDATE` ou `DELETE` sans `WHERE`** — Teste toujours avec `SELECT` avant de modifier.',
        '⚠️ **`SELECT *` en production** — Sélectionnez uniquement les colonnes nécessaires pour les performances.',
        '⚠️ **Manque d\'index sur les colonnes de jointure** — Une jointure sans index = un scan complet de table.',
        '⚠️ **Transactions ouvertes trop longues** — Bloquent les autres utilisateurs, timeout possible.',
        '⚠️ **Stocker les mots de passe en clair** — Utilisez toujours `bcrypt` ou `argon2` pour le hachage.',
      ],
      'javascript': [
        '⚠️ **Oublier `await`** — La promesse reste en attente, la donnée est `undefined` au lieu du résultat.',
        '⚠️ **Mutater directement le state (React)** — Passez toujours par le setter pour déclencher le re-render.',
        '⚠️ **Callback hell** — Préférez `async/await` ou les chaînes `.then()` structurées.',
        '⚠️ **`==` au lieu de `===`** — L\'égalité stricte évite les conversions implicites dangereuses.',
        '⚠️ **Fuite mémoire avec les event listeners** — Pensez à `removeEventListener` dans le cleanup.',
      ],
      'python': [
        '⚠️ **Mutable comme valeur par défaut** — `def f(lst=[])` partage la liste entre tous les appels !',
        '⚠️ **Indentation mixte (tabs/espaces)** — Python n\'accepte qu\'un seul type. Configurez votre éditeur.',
        '⚠️ **Import circulaire** — Restructurez vos modules pour briser le cycle.',
        '⚠️ **Ignorer les exceptions trop largement** — `except Exception: pass` cache des bugs critiques.',
        '⚠️ **f-strings avec des guillemets mal imbriqués** — Utilisez des guillemets alternés ou des backslashes.',
      ],
      'securite': [
        '⚠️ **Faire confiance aux données utilisateur** — Tout input externe est potentiellement malveillant.',
        '⚠️ **Désactiver HTTPS en dev** — Les mauvaises habitudes persistent en production.',
        '⚠️ **Secrets dans le code source** — Utilisez des variables d\'environnement ou un vault (HashiCorp, AWS SSM).',
        '⚠️ **JWT sans expiration** — Un token volé est valable indéfiniment sans `exp`.',
        '⚠️ **CORS trop permissif (`*`)** — Limitez aux origines connues en production.',
      ],
      'reseau': [
        '⚠️ **Confondre IP privée et publique** — Les IPs `192.168.x.x` ne sont pas routables sur Internet.',
        '⚠️ **Firewall désactivé par défaut** — Activez `ufw` ou `iptables` dès l\'installation du serveur.',
        '⚠️ **DNS hardcodé** — Configurez plusieurs serveurs DNS pour la résilience.',
        '⚠️ **Oublier IPv6** — De plus en plus d\'hébergeurs assignent des IPv6 en primaire.',
        '⚠️ **Pas de monitoring réseau** — Sans alertes, vous découvrez les pannes via vos utilisateurs.',
      ],
      'web': [
        '⚠️ **Images non optimisées** — Une image de 5MB ralentit votre site. Convertissez en WebP avec compression.',
        '⚠️ **CSS bloquant** — Chargez les CSS critiques en `<head>` et les autres de façon asynchrone.',
        '⚠️ **Accessibilité négligée** — Ajoutez `alt` sur les images et `aria-label` sur les boutons icon-only.',
        '⚠️ **Styles inline trop utilisés** — Difficiles à maintenir et ils surchargent le HTML.',
        '⚠️ **Pas de meta viewport** — Sans `<meta name="viewport">`, le site ne s\'adapte pas au mobile.',
      ],
    };

    final pittfalls = pitfallsByCategory[category] ?? [
      '⚠️ **Ne pas lire la documentation officielle** — La doc primaire est toujours la source la plus fiable.',
      '⚠️ **Manque de tests** — Validez votre implémentation avant de la considérer terminée.',
      '⚠️ **Pas de logging** — Impossible de déboguer sans traces. Implémentez des logs dès le départ.',
      '⚠️ **Négliger la gestion des erreurs** — Anticipez les cas d\'échec et traitez-les explicitement.',
      '⚠️ **Travailler sans version control** — Commitez après chaque étape stable.',
    ];

    return '''### ⚠️ Erreurs classiques à éviter absolument

${pittfalls.join('\n')}''';
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

    return '''### 📋 Mémo rapide — À garder sous la main

Les commandes-clés de ce chapitre (copiez-les dans vos notes !) :

$commands

> 💡 **Conseil pro :** Créez un fichier `~/.notes/$title.md` et collez-y vos commandes les plus utilisées. Votre futur vous vous remerciera.''';
  }

  // ─── Générateur de contexte métier ──────────────────────────────────────
  static String _generateContext(String courseTitle, String title, String category, int index, int total) {
    final posLabel = index == 0
        ? '🚀 **Point de départ** du cours'
        : index == total - 1
            ? '🏁 **Chapitre final** — consolidez tout ce que vous avez appris'
            : '📍 **Étape ${index + 1} / $total** dans votre progression';

    final categoryContext = {
      'linux':       'administrer des serveurs Linux en production',
      'devops':      'déployer et opérer des applications dans le cloud',
      'sql':         'concevoir et interroger des bases de données professionnelles',
      'javascript':  'développer des applications web modernes côté client et serveur',
      'python':      'automatiser, analyser et développer avec Python en contexte réel',
      'securite':    'sécuriser des applications et infrastructures contre les cyberattaques',
      'reseau':      'concevoir et dépanner des infrastructures réseau',
      'web':         'créer des interfaces web accessibles, rapides et esthétiques',
    };

    final ctx = categoryContext[category] ?? 'maîtriser une compétence technique recherchée';

    return '''## $posLabel dans **$courseTitle**

**Pourquoi ce chapitre existe :**
Ce bloc "$title" est fondamental pour **$ctx**. Dans les équipes tech professionnelles, maîtriser ce sujet vous distingue d\'un utilisateur occasionnel d\'un vrai praticien.

**Ce que vous gagnerez concrètement :**
- ✅ Compréhension profonde du mécanisme sous-jacent
- ✅ Capacité à diagnostiquer et résoudre des problèmes réels
- ✅ Vocabulaire technique pour communiquer avec vos pairs
- ✅ Réflexes opérationnels applicables immédiatement''';
  }

  // ─── Générateur de ressources complémentaires ────────────────────────────
  static String _generateResources(String category, List<String> keywords) {
    final Map<String, String> docLinks = {
      'linux':       'man.he.net (man pages en ligne) · tldr.sh (exemples concis) · explainshell.com',
      'devops':      'docs.docker.com · kubernetes.io/docs · hub.docker.com (images officielles)',
      'sql':         'postgresql.org/docs · sqlbolt.com (exercices interactifs) · use-the-index-luke.com',
      'javascript':  'developer.mozilla.org/fr · javascript.info · tc39.es (spec ES)',
      'python':      'docs.python.org/fr · realpython.com · peps.python.org',
      'securite':    'owasp.org · portswigger.net/web-security · haveibeenpwned.com',
      'reseau':      'ietf.org/rfc (specs RFC) · networklessons.com · wireshark.org',
      'web':         'developer.mozilla.org/fr · web.dev (Google) · caniuse.com',
    };

    final resources = docLinks[category] ?? 'Documentation officielle du projet · GitHub Issues · Stack Overflow';

    return '''### 📚 Pour aller plus loin

**Ressources recommandées :**
$resources

**Pratiquez maintenant :**
> Ouvrez un terminal, un éditeur ou un playground et **refaites** les exemples de ce chapitre de mémoire. La répétition espacée est la meilleure méthode d\'apprentissage.''';
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
    String codeTitle = '';
    if (chapter.codeBlocks?.isNotEmpty == true) {
      code = chapter.codeBlocks![0]['code']?.toString().trim() ?? '';
      codeLanguage = chapter.codeBlocks![0]['language']?.toString() ?? 'bash';
      codeTitle = chapter.codeBlocks![0]['title']?.toString() ?? '';
    }

    final k1 = course.keywords.isNotEmpty ? course.keywords[0] : course.category;
    final k2 = course.keywords.length > 1 ? course.keywords[1] : title;

    // ── Section 1 : contexte et objectifs ───────────────────────────────
    final contextSection = _generateContext(course.title, title, course.category, index, total);

    // ── Section 2 : Mise en situation ───────────────────────────────────
    final miseEnSituation = '''### 🎬 Mise en situation réelle

Imaginez : vous rejoignez une équipe de développement. La première semaine, votre tech lead vous demande de prendre en main les responsabilités liées à **$title** sur un projet en production.

Vous ouvrez votre terminal (ou votre IDE). L'équipe observe. Voici exactement ce que ce chapitre vous permet de faire avec confiance :

- Comprendre **pourquoi** on fait ça (pas juste copier-coller)
- Savoir **quand** appliquer cette technique dans un projet réel
- Être capable d\'**expliquer** votre démarche à un collègue
- **Déboguer** quand quelque chose ne fonctionne pas comme prévu

> 💼 **Profil ciblé :** Ce chapitre s\'adresse à quelqu\'un qui veut passer de "je regarde des tutoriels" à "je produis des solutions autonomes".''';

    // ── Section 3 : Contenu technique du cours ──────────────────────────
    final courseContent = '''### 📖 Le cours — Contenu technique complet

$rawContent''';

    // ── Section 4 : Analyse du code ─────────────────────────────────────
    final codeSection = code.isNotEmpty
        ? '''### 🔍 Analyse ligne par ligne — $codeTitle

Décryptage de l\'exemple de code fourni :

${_explainCodeLines(code)}

> 🛠️ **Exercice immédiat :** Modifiez **une seule ligne** de ce code et observez l\'impact. C\'est la meilleure façon de comprendre le rôle de chaque instruction.'''
        : '''### 🔍 Mise en pratique guidée

Ce chapitre est théorique mais demande une mise en pratique immédiate.

**Démarche recommandée :**
1. Lisez le cours attentivement une première fois
2. Résumez les 3 points clés dans vos propres mots
3. Cherchez un exemple concret dans un projet personnel ou professionnel
4. Testez dans un environnement de test/bac à sable''';

    // ── Section 5 : Plan d'action ────────────────────────────────────────
    final actionPlan = '''### 🗺️ Plan d'action pas à pas

**Phase 1 — Comprendre (5 minutes)**
1. Identifier l\'objectif principal de "$title"
2. Lister les prérequis nécessaires (qu\'est-ce que vous devez savoir avant ?)
3. Noter les 3 concepts clés à retenir

**Phase 2 — Expérimenter (15-20 minutes)**
1. Reproduire l\'exemple du cours dans votre environnement
2. Tester avec des valeurs différentes pour comprendre les limites
3. Provoquer intentionnellement une erreur pour apprendre à la corriger

**Phase 3 — Solidifier (5-10 minutes)**
1. Refaire l\'exercice de mémoire (sans regarder)
2. Expliquer le concept à voix haute, comme si vous formatiez quelqu\'un
3. Documenter dans vos notes personnelles''';

    // ── Section 6 : Cas concret professionnel ───────────────────────────
    final realWorld = '''### 💼 Cas terrain professionnel

**Scénario :** Vous intervenez en urgence sur un projet **${course.title}** en production.

**Le problème :** Une anomalie liée à **$title** bloque une partie des utilisateurs.

**Les étapes que vous suivriez :**
1. 🔍 **Diagnostic** — Identifier le symptôme exact (logs, erreurs, comportement inattendu)
2. 🧠 **Hypothèse** — Formuler 2-3 causes probables basées sur votre connaissance de $k1
3. 🧪 **Test** — Valider ou invalider chaque hypothèse méthodiquement
4. 🔧 **Correction** — Implémenter le fix minimal, sûr et réversible
5. ✅ **Validation** — Confirmer la résolution avec des métriques claires
6. 📝 **Post-mortem** — Documenter pour éviter la récidive

> 🎯 **Leçon clé :** En production, la méthode compte autant que le résultat. Une correction bien documentée vaut 10 fois plus qu\'un hack rapide.''';

    // ── Section 7 : Avant / Après ────────────────────────────────────────
    final beforeAfter = '''### ⚡ Transformation : Avant vs Après ce chapitre

| Avant | Après |
|-------|-------|
| Vous cherchez sur Google à chaque fois | Vous exécutez de mémoire avec confiance |
| Vous copiez-collez sans comprendre | Vous adaptez le code à votre contexte |
| Un bug bloque plusieurs heures | Vous diagnostiquez en moins de 15 minutes |
| Vous évitez les sujets liés à $k2 | Vous prenez l\'initiative sur ces sujets |
| Vous ne savez pas expliquer votre démarche | Vous pouvez former quelqu\'un d\'autre |''';

    // ── Section 8 : Pitfalls ─────────────────────────────────────────────
    final pitfalls = _generatePitfalls(title, course.category);

    // ── Section 9 : Quiz ─────────────────────────────────────────────────
    final quiz = _generateQuiz(title, course.keywords);

    // ── Section 10 : Cheat sheet ─────────────────────────────────────────
    final cheatSheet = _generateCheatSheet(title, codeLanguage, code);

    // ── Section 11 : Mission élite ───────────────────────────────────────
    final eliteMission = '''### 🏆 Mission Élite — Pour ceux qui veulent tout maîtriser

**Niveau 1 — Bronze :** Reproduisez l\'exemple du cours en moins de 5 minutes sans aide.

**Niveau 2 — Argent :** Adaptez l\'exemple à un cas personnalisé (votre propre projet, vos propres données).

**Niveau 3 — Or :** Trouvez une limitation ou un edge case dans les exemples fournis et proposez une amélioration.

**Niveau 4 — Platine :** Expliquez le chapitre entier à quelqu\'un qui ne connaît pas $k1, avec vos propres exemples.''';

    // ── Section 12 : Ressources ──────────────────────────────────────────
    final resources = _generateResources(course.category, course.keywords);

    // ── Assemblage final ─────────────────────────────────────────────────
    return [
      '# 📚 $title',
      '**⏱️ Durée estimée :** $duration  |  **📍 Chapitre ${index + 1} / $total**',
      '',
      contextSection,
      '',
      '---',
      '',
      miseEnSituation,
      '',
      '---',
      '',
      courseContent,
      '',
      '---',
      '',
      codeSection,
      '',
      '---',
      '',
      actionPlan,
      '',
      '---',
      '',
      realWorld,
      '',
      '---',
      '',
      beforeAfter,
      '',
      '---',
      '',
      pitfalls,
      '',
      '---',
      '',
      quiz,
      '',
      if (cheatSheet.isNotEmpty) ...[
        '---',
        '',
        cheatSheet,
        '',
      ],
      '---',
      '',
      eliteMission,
      '',
      '---',
      '',
      resources,
    ].join('\n');
  }
}
