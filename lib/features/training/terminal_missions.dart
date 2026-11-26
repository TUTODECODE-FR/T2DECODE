// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
//
// Entraînement « Terminal Linux : missions » : un terminal virtuel et des missions
// à accomplir (se déplacer, créer, copier, chercher, filtrer, changer les droits).
// La vérification lit l'état réel du système de fichiers virtuel (existence, type,
// contenu, droits) et explique pas à pas ce qui manque.
//
// La logique (génération à partir d'un TrainingRandom, vérification) est pure et
// testable sans interface ; le widget TerminalMissions n'en est que l'affichage.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/lab/services/virtual_shell.dart';
import 'package:tutodecode/features/training/training_kit.dart';

/// Dossier personnel de l'utilisateur du terminal virtuel (~).
const String kMissionHome = '/home/admin';

// ---------------------------------------------------------------------------
// Modèle
// ---------------------------------------------------------------------------

enum MissionLevel { bases, fichiers, recherche, droits }

const Map<MissionLevel, String> kMissionLevelLabels = {
  MissionLevel.bases: 'Se repérer',
  MissionLevel.fichiers: 'Créer et organiser',
  MissionLevel.recherche: 'Chercher et filtrer',
  MissionLevel.droits: 'Droits',
};

/// Un point de contrôle de la vérification.
class MissionStep {
  const MissionStep(this.label, this.ok, [this.detail = '']);
  final String label;
  final bool ok;

  /// Ce qui manque ou ce qui a été constaté (vide si rien à dire).
  final String detail;
}

/// Une mission générée : consigne, préparation du système de fichiers,
/// critères de réussite, indice et solution.
class TerminalMission {
  TerminalMission({
    required this.kind,
    required this.level,
    required this.title,
    required this.instruction,
    required this.hint,
    required this.solution,
    required this.method,
    required void Function(VirtualShell shell) setup,
    required List<MissionStep> Function(VirtualShell shell) criteria,
  })  : _setup = setup,
        _criteria = criteria;

  /// Numéro du modèle de mission (0 .. kMissionKinds - 1).
  final int kind;
  final MissionLevel level;
  final String title;
  final String instruction;
  final String hint;

  /// Une suite de commandes qui accomplit la mission.
  final List<String> solution;

  /// La méthode générale, rappelée dans la correction.
  final String method;

  final void Function(VirtualShell shell) _setup;
  final List<MissionStep> Function(VirtualShell shell) _criteria;

  /// Nouveau terminal (système de fichiers neuf) préparé pour la mission.
  VirtualShell createShell() {
    final shell = VirtualShell();
    _setup(shell);
    return shell;
  }

  /// Points de contrôle évalués sur l'état actuel du terminal.
  List<MissionStep> evaluate(VirtualShell shell) => _criteria(shell);

  /// Vérifie la mission et explique, point par point, ce qui est fait ou manque.
  TrainingCheck check(VirtualShell shell) {
    final steps = evaluate(shell);
    final ok = steps.every((s) => s.ok);
    final b = StringBuffer(ok
        ? 'Mission accomplie. Vérification pas à pas :\n'
        : 'La mission n\'est pas encore accomplie. Vérification pas à pas :\n');
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      b.write('${i + 1}. ${s.label} : ${s.ok ? 'OK' : 'manque'}');
      if (s.detail.isNotEmpty) b.write('. ${s.detail}');
      b.write('\n');
    }
    b.write('\nMéthode : $method');
    return TrainingCheck(ok, b.toString());
  }
}

// ---------------------------------------------------------------------------
// Outils de vérification
// ---------------------------------------------------------------------------

/// Chemin absolu sous le dossier personnel.
String _h(String rel) => '$kMissionHome/$rel';

/// Lignes d'un contenu (un contenu vide n'a aucune ligne ; saut final ignoré).
List<String> missionLines(String? content) {
  if (content == null || content.isEmpty) return [];
  final l = content.split('\n');
  if (content.endsWith('\n')) l.removeLast();
  return l;
}

/// Droits au format « 640 (rw-r-----) ».
String describeMode(int mode) {
  final octal = (mode & 0xFFF).toRadixString(8);
  return '${octal.padLeft(3, '0')} '
      '(${VirtualFileSystem.modeString(mode).substring(1)})';
}

MissionStep _fileExists(VirtualFileSystem fs, String path, {String? label}) {
  final shown = _tilde(path);
  if (fs.isFile(path))
    return MissionStep(label ?? 'Le fichier $shown existe', true);
  if (fs.isDir(path)) {
    return MissionStep(label ?? 'Le fichier $shown existe', false,
        '$shown est un dossier, pas un fichier');
  }
  return MissionStep(label ?? 'Le fichier $shown existe', false,
      'Aucun fichier à cet emplacement');
}

MissionStep _dirExists(VirtualFileSystem fs, String path) {
  final shown = _tilde(path);
  if (fs.isDir(path)) return MissionStep('Le dossier $shown existe', true);
  if (fs.isFile(path)) {
    return MissionStep('Le dossier $shown existe', false,
        '$shown est un fichier ordinaire, pas un dossier');
  }
  return MissionStep('Le dossier $shown existe', false, 'Introuvable');
}

MissionStep _absent(VirtualFileSystem fs, String path, String what) {
  final shown = _tilde(path);
  return fs.exists(path)
      ? MissionStep('$what $shown n\'existe plus', false, 'Il est toujours là')
      : MissionStep('$what $shown n\'existe plus', true);
}

MissionStep _sameContent(
    VirtualFileSystem fs, String path, String expected, String label) {
  final content = fs.isFile(path) ? fs.readFile(path) : null;
  if (content == null) return MissionStep(label, false, 'Fichier absent');
  return content == expected
      ? MissionStep(label, true)
      : MissionStep(label, false, 'Le contenu a changé');
}

/// Compare des lignes obtenues aux lignes attendues et décrit l'écart.
MissionStep _linesEqual(
    VirtualFileSystem fs, String path, List<String> expected, String label) {
  if (!fs.isFile(path)) return MissionStep(label, false, 'Fichier absent');
  final got = missionLines(fs.readFile(path));
  if (got.length == expected.length) {
    for (var i = 0; i < got.length; i++) {
      if (got[i] != expected[i]) {
        return MissionStep(label, false,
            'Ligne ${i + 1} : « ${got[i]} » au lieu de « ${expected[i]} »');
      }
    }
    return MissionStep(label, true, '${expected.length} ligne(s) exactes');
  }
  final missing = expected.where((l) => !got.contains(l)).length;
  final extra = got.where((l) => !expected.contains(l)).length;
  final parts = <String>[
    '${got.length} ligne(s) au lieu de ${expected.length}',
    if (missing > 0) '$missing ligne(s) attendue(s) absente(s)',
    if (extra > 0) '$extra ligne(s) en trop',
    if (missing == 0 && extra == 0) 'des lignes sont répétées',
  ];
  return MissionStep(label, false, parts.join(', '));
}

/// Le fichier contient un nombre (premier mot) égal à [expected].
/// Accepte « 7 » comme la sortie de « wc -l fichier » (« 7 fichier »).
MissionStep _numberIn(VirtualFileSystem fs, String path, int expected) {
  final label = 'Le nombre écrit dans ${_tilde(path)} est le bon';
  if (!fs.isFile(path)) return MissionStep(label, false, 'Fichier absent');
  final words = (fs.readFile(path) ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return MissionStep(label, false, 'Le fichier est vide');
  final n = int.tryParse(words.first);
  if (n == null) {
    return MissionStep(label, false,
        'Le fichier doit commencer par un nombre (trouvé : « ${words.first} »)');
  }
  return n == expected
      ? MissionStep(label, true)
      : MissionStep(label, false, 'Trouvé $n');
}

String _tilde(String path) => path == kMissionHome
    ? '~'
    : (path.startsWith('$kMissionHome/')
        ? '~${path.substring(kMissionHome.length)}'
        : path);

/// Lignes [lines] jointes (contenu d'un fichier préparé).
String _join(List<String> lines) => lines.join('\n');

List<T> _pickN<T>(TrainingRandom r, List<T> items, int n) =>
    r.shuffled(items).take(n).toList();

// Réserves de valeurs (minuscules ASCII : le tri est le même dans toutes les locales).
const _words = [
  'alpha',
  'bravo',
  'charlie',
  'delta',
  'echo',
  'foxtrot',
  'golf',
  'hotel',
  'india',
  'juliet',
  'kilo',
  'lima',
  'mike',
  'oscar',
  'papa',
  'romeo',
  'sierra',
  'tango',
  'victor',
  'zulu',
];
const _names = [
  'alice',
  'bruno',
  'chloe',
  'david',
  'emma',
  'farid',
  'gaelle',
  'hugo',
  'ines',
  'jules',
  'karim',
  'lea',
  'malik',
  'nora',
  'oscar',
  'paul',
  'sarah',
  'thomas',
  'yanis',
  'zoe',
];
const _projects = [
  'atelier',
  'robot',
  'meteo',
  'jardin',
  'station',
  'agenda',
  'boutique',
  'radio',
  'biblio',
  'quiz',
];
const _phrases = [
  'Sauvegarde terminée',
  'Bonjour depuis le terminal',
  'Le serveur est prêt',
  'Ne pas effacer ce fichier',
  'Version 2 en cours de test',
  'Projet créé en atelier',
  'Réunion lundi à 14 h',
  'Tout fonctionne correctement',
];
const _services = [
  'paiement',
  'connexion',
  'cache',
  'disque',
  'courriel',
  'sauvegarde',
  'annuaire',
  'impression',
];
const _messages = [
  'demande traitée',
  'délai dépassé',
  'échec de la requête',
  'reprise automatique',
  'espace faible',
  'redémarrage',
  'utilisateur inconnu',
  'réponse lente',
];

/// Journal d'application : « 2026-11-03 08:12:45 ERROR cache: délai dépassé ».
List<String> _logLines(
    TrainingRandom r, List<String> services, List<String> levels) {
  var minute = r.range(0, 20);
  return [
    for (var i = 0; i < services.length; i++)
      () {
        minute += r.range(1, 3);
        final hh = (8 + minute ~/ 60).toString().padLeft(2, '0');
        final mm = (minute % 60).toString().padLeft(2, '0');
        final ss = r.range(0, 59).toString().padLeft(2, '0');
        return '2026-11-03 $hh:$mm:$ss ${levels[i]} ${services[i]}: '
            '${r.pick(_messages)}';
      }()
  ];
}

// ---------------------------------------------------------------------------
// Génération des missions
// ---------------------------------------------------------------------------

/// Nombre de modèles de mission.
const int kMissionKinds = 29;

/// Niveau d'un modèle de mission.
MissionLevel missionLevelOf(int kind) {
  if (kind <= 4) return MissionLevel.bases;
  if (kind <= 15) return MissionLevel.fichiers;
  if (kind <= 24) return MissionLevel.recherche;
  return MissionLevel.droits;
}

/// Modèles de mission d'un niveau (tous si [level] est null).
List<int> missionKindsOf(MissionLevel? level) => [
      for (var k = 0; k < kMissionKinds; k++)
        if (level == null || missionLevelOf(k) == level) k
    ];

/// Mission tirée au hasard (dans un niveau ou parmi toutes).
TerminalMission randomMission(TrainingRandom r, {MissionLevel? level}) =>
    buildMission(r.pick(missionKindsOf(level)), r);

/// Construit la mission [kind] avec des valeurs tirées de [r].
TerminalMission buildMission(int kind, TrainingRandom r) {
  switch (kind) {
    case 0:
      return _mCd(r);
    case 1:
      return _mCdUp(r);
    case 2:
      return _mHidden(r);
    case 3:
      return _mCount(r);
    case 4:
      return _mTail(r);
    case 5:
      return _mTree(r);
    case 6:
      return _mEcho(r);
    case 7:
      return _mAppend(r);
    case 8:
      return _mTouch(r);
    case 9:
      return _mCp(r);
    case 10:
      return _mCpR(r);
    case 11:
      return _mMv(r);
    case 12:
      return _mRename(r);
    case 13:
      return _mRm(r);
    case 14:
      return _mRmR(r);
    case 15:
      return _mRmGlob(r);
    case 16:
      return _mFind(r);
    case 17:
      return _mFindCount(r);
    case 18:
      return _mGrep(r);
    case 19:
      return _mGrepCount(r);
    case 20:
      return _mWc(r);
    case 21:
      return _mSortUniq(r);
    case 22:
      return _mHead(r);
    case 23:
      return _mGrepV(r);
    case 24:
      return _mVotes(r);
    case 25:
      return _mChmodX(r);
    case 26:
      return _mChmodExact(r);
    case 27:
      return _mChmodDir(r);
    case 28:
      return _mChmodR(r);
    default:
      throw RangeError.range(kind, 0, kMissionKinds - 1, 'kind');
  }
}

// --- Niveau 1 : se repérer ---------------------------------------------------

TerminalMission _mCd(TrainingRandom r) {
  final year = r.range(2019, 2025);
  final month = r.pick(['mars', 'avril', 'mai', 'juin', 'juillet']);
  final target = _h('archives/$year/$month');
  return TerminalMission(
    kind: 0,
    level: MissionLevel.bases,
    title: 'Se déplacer',
    instruction: 'Place-toi dans le dossier ~/archives/$year/$month.',
    hint: 'cd change le dossier courant ; pwd affiche où tu es. '
        'Le caractère ~ désigne ton dossier personnel ($kMissionHome).',
    solution: ['cd ~/archives/$year/$month', 'pwd'],
    method: 'cd suivi d\'un chemin absolu (qui commence par / ou ~) ou relatif '
        '(depuis le dossier courant). pwd confirme l\'emplacement.',
    setup: (sh) {
      sh.fs.mkdirp(target);
      for (final m in ['janvier', 'fevrier']) {
        sh.fs.mkdirp(_h('archives/$year/$m'));
      }
    },
    criteria: (sh) => [
      MissionStep(
          'Le dossier courant est ~/archives/$year/$month',
          sh.cwd == target,
          sh.cwd == target ? '' : 'Tu es dans ${_tilde(sh.cwd)}'),
    ],
  );
}

TerminalMission _mCdUp(TrainingRandom r) {
  final names = _pickN(r, _words, 3);
  final top = _h(names[0]);
  final deep = '$top/${names[1]}/${names[2]}';
  return TerminalMission(
    kind: 1,
    level: MissionLevel.bases,
    title: 'Remonter dans l\'arborescence',
    instruction:
        'Tu es dans ~/${names[0]}/${names[1]}/${names[2]}. Remonte de deux '
        'niveaux pour te placer dans ~/${names[0]}, avec un chemin relatif.',
    hint: '.. désigne le dossier parent. On peut les enchaîner : ../.. remonte '
        'de deux niveaux.',
    solution: ['cd ../..', 'pwd'],
    method: 'Chaque .. remonte d\'un niveau : depuis ~/${names[0]}/${names[1]}/'
        '${names[2]}, ../.. mène à ~/${names[0]}.',
    setup: (sh) {
      sh.fs.mkdirp(deep);
      sh.execute('cd $deep');
    },
    criteria: (sh) => [
      MissionStep('Le dossier courant est ~/${names[0]}', sh.cwd == top,
          sh.cwd == top ? '' : 'Tu es dans ${_tilde(sh.cwd)}'),
    ],
  );
}

TerminalMission _mHidden(TrainingRandom r) {
  final word = r.pick(_words);
  final code = '${r.range(1000, 9999)}';
  final hidden = '.code_$word';
  return TerminalMission(
    kind: 2,
    level: MissionLevel.bases,
    title: 'Fichier caché',
    instruction:
        'Le dossier ~/coffre contient un fichier caché (son nom commence '
        'par un point). Lis-le, puis écris le code qu\'il contient, seul, dans '
        'le fichier ~/code.txt.',
    hint:
        'ls n\'affiche pas les fichiers cachés : ls -a les montre. cat affiche '
        'un fichier ; echo texte > fichier écrit dans un fichier.',
    solution: [
      'ls -a ~/coffre',
      'cat ~/coffre/$hidden',
      'echo $code > ~/code.txt'
    ],
    method:
        'ls -a liste aussi les noms qui commencent par un point ; cat lit le '
        'fichier ; la redirection > envoie la sortie d\'echo dans un fichier '
        '(créé ou écrasé).',
    setup: (sh) {
      sh.fs.mkdirp(_h('coffre'));
      sh.fs.write(_h('coffre/lisez-moi.txt'), 'Le code est bien caché ici.');
      sh.fs.write(_h('coffre/inventaire.txt'), 'trois clés\nune boussole');
      sh.fs.write(_h('coffre/$hidden'), code);
    },
    criteria: (sh) {
      final path = _h('code.txt');
      final f = _fileExists(sh.fs, path);
      if (!f.ok) return [f];
      final got = (sh.fs.readFile(path) ?? '').trim();
      return [
        f,
        MissionStep('~/code.txt contient le code $code', got == code,
            got == code ? '' : 'Trouvé « $got »'),
      ];
    },
  );
}

TerminalMission _mCount(TrainingRandom r) {
  final n = r.range(3, 9);
  final nums = _pickN(r, [for (var i = 100; i < 1000; i++) i], n);
  return TerminalMission(
    kind: 3,
    level: MissionLevel.bases,
    title: 'Compter des fichiers',
    instruction: 'Combien de fichiers contient le dossier ~/photos ? Écris ce '
        'nombre dans ~/nombre.txt.',
    hint:
        'ls ~/photos les affiche. Dans un tube (|), ls écrit un nom par ligne : '
        'wc -l compte alors les lignes.',
    solution: ['ls ~/photos | wc -l > ~/nombre.txt', 'cat ~/nombre.txt'],
    method:
        'ls ~/photos | wc -l : la sortie de ls (un nom par ligne quand elle '
        'part dans un tube) est comptée par wc -l ; > l\'écrit dans le fichier. '
        'Ici, $n fichiers.',
    setup: (sh) {
      sh.fs.mkdirp(_h('photos'));
      for (final k in nums) {
        sh.fs.write(_h('photos/img_$k.jpg'), 'JPEG $k');
      }
    },
    criteria: (sh) {
      final f = _fileExists(sh.fs, _h('nombre.txt'));
      return f.ok ? [f, _numberIn(sh.fs, _h('nombre.txt'), n)] : [f];
    },
  );
}

TerminalMission _mTail(TrainingRandom r) {
  final count = r.range(6, 10);
  final services = [for (var i = 0; i < count; i++) r.pick(_services)];
  final levels = [
    for (var i = 0; i < count; i++) r.pick(['INFO', 'WARN', 'ERROR'])
  ];
  final lines = _logLines(r, services, levels);
  return TerminalMission(
    kind: 4,
    level: MissionLevel.bases,
    title: 'Dernière ligne d\'un journal',
    instruction:
        'Écris la dernière ligne du journal ~/serveur.log (et seulement '
        'elle) dans ~/derniere.txt.',
    hint:
        'tail affiche la fin d\'un fichier ; l\'option -n choisit le nombre de '
        'lignes.',
    solution: [
      'tail -n 1 ~/serveur.log > ~/derniere.txt',
      'cat ~/derniere.txt'
    ],
    method: 'tail -n 1 garde la dernière ligne ; > écrit le résultat dans le '
        'fichier au lieu de l\'afficher.',
    setup: (sh) => sh.fs.write(_h('serveur.log'), _join(lines)),
    criteria: (sh) => [
      _linesEqual(
          sh.fs,
          _h('derniere.txt'),
          [lines.last],
          '~/derniere.txt '
          'contient exactement la dernière ligne')
    ],
  );
}

// --- Niveau 2 : créer et organiser -------------------------------------------

TerminalMission _mTree(TrainingRandom r) {
  final p = r.pick(_projects);
  final subs = r.nextBool() ? ['src', 'docs'] : ['src', 'docs', 'tests'];
  final brace = '{${subs.join(',')}}';
  return TerminalMission(
    kind: 5,
    level: MissionLevel.fichiers,
    title: 'Créer une arborescence',
    instruction: 'Crée le dossier ~/$p avec les sous-dossiers '
        '${subs.join(', ')} (des dossiers, pas des fichiers).',
    hint: 'mkdir -p crée aussi les dossiers parents manquants ; les accolades '
        'de bash développent une liste : a/{x,y} donne a/x a/y.',
    solution: ['mkdir -p ~/$p/$brace', 'ls ~/$p'],
    method: 'mkdir -p ~/$p/$brace : bash développe les accolades en '
        '${subs.map((s) => '~/$p/$s').join(' ')}, et -p crée ~/$p au passage '
        '(sans erreur s\'il existe déjà).',
    setup: (sh) {},
    criteria: (sh) => [
      _dirExists(sh.fs, _h(p)),
      for (final s in subs) _dirExists(sh.fs, _h('$p/$s')),
    ],
  );
}

TerminalMission _mEcho(TrainingRandom r) {
  final p = r.pick(_projects);
  final phrase = r.pick(_phrases);
  final path = _h('$p/LISEZMOI.txt');
  return TerminalMission(
    kind: 6,
    level: MissionLevel.fichiers,
    title: 'Écrire dans un fichier',
    instruction: 'Crée le fichier ~/$p/LISEZMOI.txt contenant exactement la '
        'ligne : $phrase',
    hint: 'echo "texte" affiche le texte ; > fichier envoie cette sortie dans '
        'le fichier. Les guillemets gardent les espaces tels quels.',
    solution: ['echo "$phrase" > ~/$p/LISEZMOI.txt', 'cat ~/$p/LISEZMOI.txt'],
    method: 'echo "..." > fichier crée le fichier (ou l\'écrase) avec la ligne '
        'donnée. Pour ajouter sans écraser, on utilise >>.',
    setup: (sh) => sh.fs.mkdirp(_h(p)),
    criteria: (sh) {
      final f = _fileExists(sh.fs, path);
      if (!f.ok) return [f];
      final got = missionLines(sh.fs.readFile(path));
      final exact = got.length == 1 && got.first == phrase;
      var detail = '';
      if (!exact) {
        if (got.isEmpty) {
          detail = 'Le fichier est vide';
        } else if (got.length > 1) {
          detail = '${got.length} lignes au lieu d\'une';
        } else if (normalizeAnswer(got.first) == normalizeAnswer(phrase)) {
          detail = 'Presque : la casse ou les espaces diffèrent '
              '(« ${got.first} »)';
        } else {
          detail = 'Trouvé « ${got.first} »';
        }
      }
      return [
        f,
        MissionStep('Le contenu est exactement « $phrase »', exact, detail)
      ];
    },
  );
}

TerminalMission _mAppend(TrainingRandom r) {
  final day = r.range(2, 27);
  final first = ['Jour 1 : installation du poste', 'Jour 2 : mise à jour'];
  final line = 'Jour 3 : ${r.pick([
        'sauvegarde vérifiée',
        'réseau configuré',
        'droits corrigés',
        'journaux relus'
      ])} le $day';
  final path = _h('journal_de_bord.txt');
  return TerminalMission(
    kind: 7,
    level: MissionLevel.fichiers,
    title: 'Ajouter sans écraser',
    instruction: 'Ajoute à la fin de ~/journal_de_bord.txt la ligne :\n$line\n'
        'Les deux lignes déjà présentes doivent rester.',
    hint: '> écrase le fichier ; >> ajoute à la fin.',
    solution: [
      'echo "$line" >> ~/journal_de_bord.txt',
      'cat ~/journal_de_bord.txt'
    ],
    method: 'echo "..." >> fichier ajoute une ligne à la fin sans toucher au '
        'reste. Avec un seul >, les deux premières lignes auraient été perdues.',
    setup: (sh) => sh.fs.write(path, _join(first)),
    criteria: (sh) {
      final f = _fileExists(sh.fs, path);
      if (!f.ok) return [f];
      final got = missionLines(sh.fs.readFile(path));
      final kept = got.length >= 2 && got[0] == first[0] && got[1] == first[1];
      return [
        f,
        MissionStep('Les deux lignes d\'origine sont toujours là', kept,
            kept ? '' : 'Elles ont été modifiées ou effacées (attention à >)'),
        _linesEqual(sh.fs, path, [...first, line],
            'Le fichier se termine par la nouvelle ligne'),
      ];
    },
  );
}

TerminalMission _mTouch(TrainingRandom r) {
  final files = [for (final w in _pickN(r, _words, 3)) '$w.txt'];
  return TerminalMission(
    kind: 8,
    level: MissionLevel.fichiers,
    title: 'Créer des fichiers vides',
    instruction: 'Crée dans ~/brouillons trois fichiers vides : '
        '${files.join(', ')}.',
    hint:
        'touch crée un fichier vide s\'il n\'existe pas ; il accepte plusieurs '
        'noms à la suite.',
    solution: ['cd ~/brouillons', 'touch ${files.join(' ')}', 'ls'],
    method: 'touch nom1 nom2 nom3 crée les fichiers manquants (vides) en une '
        'seule commande.',
    setup: (sh) => sh.fs.mkdirp(_h('brouillons')),
    criteria: (sh) => [
      for (final f in files) ...[
        _fileExists(sh.fs, _h('brouillons/$f')),
        if (sh.fs.isFile(_h('brouillons/$f')))
          () {
            final empty = (sh.fs.readFile(_h('brouillons/$f')) ?? '').isEmpty;
            return MissionStep('~/brouillons/$f est vide', empty,
                empty ? '' : 'Il contient du texte');
          }(),
      ],
    ],
  );
}

TerminalMission _mCp(TrainingRandom r) {
  final name = '${r.pick(_words)}_${r.range(10, 99)}.txt';
  final content = 'Rapport ${r.pick(_projects)}\n${r.pick(_phrases)}';
  final src = _h('Documents/$name');
  final dst = _h('sauvegarde/$name');
  return TerminalMission(
    kind: 9,
    level: MissionLevel.fichiers,
    title: 'Copier un fichier',
    instruction: 'Copie ~/Documents/$name dans le dossier ~/sauvegarde (le '
        'fichier d\'origine doit rester en place).',
    hint: 'cp source destination. Si la destination est un dossier, la copie y '
        'garde le même nom.',
    solution: ['cp ~/Documents/$name ~/sauvegarde/', 'ls ~/sauvegarde'],
    method: 'cp copie ; mv déplacerait (l\'original disparaîtrait). Quand la '
        'destination est un dossier existant, la copie y prend le même nom.',
    setup: (sh) {
      sh.fs.write(src, content);
      sh.fs.mkdirp(_h('sauvegarde'));
    },
    criteria: (sh) => [
      _sameContent(
          sh.fs, src, content, 'L\'original ~/Documents/$name est intact'),
      _fileExists(sh.fs, dst),
      if (sh.fs.isFile(dst))
        _sameContent(sh.fs, dst, content, 'La copie a le même contenu'),
    ],
  );
}

TerminalMission _mCpR(TrainingRandom r) {
  final suffix = r.pick(['sauvegarde', 'copie', 'v2', 'old', 'test']);
  final files = {
    'index.html': '<h1>${r.pick(_projects)}</h1>',
    'css/style.css': 'body { color: #222; }',
    'img/logo.svg': '<svg></svg>',
  };
  final copy = 'site_$suffix';
  return TerminalMission(
    kind: 10,
    level: MissionLevel.fichiers,
    title: 'Copier un dossier entier',
    instruction: 'Fais une copie complète du dossier ~/site (avec ses '
        'sous-dossiers) nommée ~/$copy.',
    hint:
        'Sans option, cp refuse de copier un dossier : il faut -r (récursif).',
    solution: ['cp -r ~/site ~/$copy', 'find ~/$copy'],
    method: 'cp -r copie un dossier et tout ce qu\'il contient. Comme ~/$copy '
        'n\'existe pas encore, il devient la copie de ~/site (s\'il existait, '
        'la copie irait dedans, en ~/$copy/site).',
    setup: (sh) {
      files.forEach((rel, c) => sh.fs.write(_h('site/$rel'), c));
    },
    criteria: (sh) => [
      _dirExists(sh.fs, _h(copy)),
      for (final e in files.entries)
        _sameContent(sh.fs, _h('$copy/${e.key}'), e.value,
            '~/$copy/${e.key} est présent avec le bon contenu'),
      _sameContent(sh.fs, _h('site/index.html'), files['index.html']!,
          'L\'original ~/site est intact'),
    ],
  );
}

TerminalMission _mMv(TrainingRandom r) {
  final name = 'facture_${r.range(1000, 9999)}.pdf';
  final content = 'PDF facture ${r.range(10, 999)} euros';
  return TerminalMission(
    kind: 11,
    level: MissionLevel.fichiers,
    title: 'Déplacer un fichier',
    instruction: 'Déplace ~/Downloads/$name dans le dossier ~/Documents.',
    hint: 'mv source destination déplace ; si la destination est un dossier, '
        'le fichier y garde son nom.',
    solution: ['mv ~/Downloads/$name ~/Documents/', 'ls ~/Documents'],
    method: 'mv déplace (ou renomme) : le fichier quitte ~/Downloads et arrive '
        'dans ~/Documents avec le même nom et le même contenu.',
    setup: (sh) => sh.fs.write(_h('Downloads/$name'), content),
    criteria: (sh) => [
      _absent(sh.fs, _h('Downloads/$name'), 'Le fichier'),
      _fileExists(sh.fs, _h('Documents/$name')),
      if (sh.fs.isFile(_h('Documents/$name')))
        _sameContent(
            sh.fs, _h('Documents/$name'), content, 'Son contenu est inchangé'),
    ],
  );
}

TerminalMission _mRename(TrainingRandom r) {
  final w = _pickN(r, _words, 2);
  final oldName = 'brouillon_${w[0]}.txt';
  final newName = 'final_${w[1]}.txt';
  final content = r.pick(_phrases);
  return TerminalMission(
    kind: 12,
    level: MissionLevel.fichiers,
    title: 'Renommer',
    instruction: 'Renomme ~/$oldName en ~/$newName.',
    hint: 'Il n\'y a pas de commande « rename » de base : renommer, c\'est '
        'déplacer vers un nouveau nom avec mv.',
    solution: ['mv ~/$oldName ~/$newName', 'ls'],
    method: 'mv ancien nouveau : quand la destination n\'est pas un dossier '
        'existant, mv renomme.',
    setup: (sh) => sh.fs.write(_h(oldName), content),
    criteria: (sh) => [
      _absent(sh.fs, _h(oldName), 'Le fichier'),
      _fileExists(sh.fs, _h(newName)),
      if (sh.fs.isFile(_h(newName)))
        _sameContent(sh.fs, _h(newName), content, 'Son contenu est inchangé'),
    ],
  );
}

TerminalMission _mRm(TrainingRandom r) {
  final names = [for (final w in _pickN(r, _words, 4)) '$w.log'];
  final target = r.pick(names);
  final keep = names.where((n) => n != target).toList();
  return TerminalMission(
    kind: 13,
    level: MissionLevel.fichiers,
    title: 'Supprimer un fichier',
    instruction: 'Supprime ~/nettoyage/$target, et uniquement lui.',
    hint: 'rm fichier supprime un fichier. Il n\'y a pas de corbeille : '
        'vérifie le nom avant de valider.',
    solution: ['rm ~/nettoyage/$target', 'ls ~/nettoyage'],
    method: 'rm supprime définitivement le fichier nommé ; les autres fichiers '
        'du dossier ne sont pas touchés.',
    setup: (sh) {
      for (final n in names) {
        sh.fs.write(_h('nettoyage/$n'), 'journal $n');
      }
    },
    criteria: (sh) => [
      _absent(sh.fs, _h('nettoyage/$target'), 'Le fichier'),
      for (final n in keep)
        _fileExists(sh.fs, _h('nettoyage/$n'),
            label: '~/nettoyage/$n est toujours là'),
    ],
  );
}

TerminalMission _mRmR(TrainingRandom r) {
  final old = 'ancien_${r.pick(_projects)}';
  return TerminalMission(
    kind: 14,
    level: MissionLevel.fichiers,
    title: 'Supprimer un dossier',
    instruction: 'Supprime le dossier ~/$old et tout son contenu. Le dossier '
        '~/a_garder doit rester.',
    hint: 'rm seul refuse un dossier (« Is a directory ») ; rmdir n\'accepte '
        'qu\'un dossier vide ; rm -r supprime récursivement.',
    solution: ['rm -r ~/$old', 'ls'],
    method: 'rm -r supprime le dossier et tout ce qu\'il contient, sans retour '
        'possible. À utiliser en relisant le chemin.',
    setup: (sh) {
      sh.fs.write(_h('$old/notes.txt'), 'à jeter');
      sh.fs.write(_h('$old/src/main.c'), 'int main(void) { return 0; }');
      sh.fs.write(_h('a_garder/important.txt'), 'ne pas supprimer');
    },
    criteria: (sh) => [
      _absent(sh.fs, _h(old), 'Le dossier'),
      _dirExists(sh.fs, _h('a_garder')),
      _fileExists(sh.fs, _h('a_garder/important.txt'),
          label: '~/a_garder/important.txt est toujours là'),
    ],
  );
}

TerminalMission _mRmGlob(TrainingRandom r) {
  final words = _pickN(r, _words, 7);
  final n = r.range(2, 4);
  final tmp = [for (final w in words.take(n)) '$w.tmp'];
  final keep = [
    for (final w in words.skip(n).take(2)) '$w.txt',
    'notes.md',
    'tmp.txt',
    'liste.tmp.bak',
  ];
  return TerminalMission(
    kind: 15,
    level: MissionLevel.fichiers,
    title: 'Supprimer avec un joker',
    instruction: 'Supprime tous les fichiers de ~/chantier dont le nom se '
        'termine par .tmp, sans toucher aux autres.',
    hint: 'Le joker * remplace n\'importe quelle suite de caractères : *.tmp '
        'désigne les noms qui finissent par .tmp. Vérifie d\'abord avec ls.',
    solution: ['ls ~/chantier/*.tmp', 'rm ~/chantier/*.tmp', 'ls ~/chantier'],
    method: 'bash remplace ~/chantier/*.tmp par la liste des fichiers qui '
        'correspondent (${tmp.join(', ')}) avant de lancer rm. tmp.txt et '
        'liste.tmp.bak ne finissent pas par .tmp : ils restent.',
    setup: (sh) {
      for (final f in [...tmp, ...keep]) {
        sh.fs.write(_h('chantier/$f'), 'contenu de $f');
      }
    },
    criteria: (sh) => [
      for (final f in tmp) _absent(sh.fs, _h('chantier/$f'), 'Le fichier'),
      for (final f in keep)
        _fileExists(sh.fs, _h('chantier/$f'),
            label: '~/chantier/$f est toujours là'),
    ],
  );
}

// --- Niveau 3 : chercher et filtrer ------------------------------------------

TerminalMission _mFind(TrainingRandom r) {
  final name = 'secret_${r.pick(_words)}.txt';
  final years = ['2022', '2023', '2024'];
  final subs = ['clients', 'factures', 'photos'];
  final dirs = [
    for (final y in years)
      for (final s in subs) 'archives/$y/$s'
  ];
  final where = r.pick(dirs);
  final target = _h('$where/$name');
  return TerminalMission(
    kind: 16,
    level: MissionLevel.recherche,
    title: 'Trouver un fichier',
    instruction: 'Le fichier $name est rangé quelque part sous ~/archives. '
        'Écris son chemin absolu dans ~/chemin.txt.',
    hint: 'find point_de_départ -name "nom" parcourt tous les sous-dossiers. '
        'Mets le motif entre guillemets.',
    solution: [
      'find ~/archives -name "$name"',
      'find ~/archives -name "$name" > ~/chemin.txt',
      'cat ~/chemin.txt',
    ],
    method: 'find ~/archives -name "$name" affiche le chemin complet '
        '(~ est remplacé par $kMissionHome) ; > l\'écrit dans le fichier. '
        'Réponse : $target.',
    setup: (sh) {
      for (final d in dirs) {
        sh.fs.mkdirp(_h(d));
        sh.fs.write(_h('$d/index.txt'), 'index $d');
      }
      sh.fs.write(target, 'trouvé');
      sh.fs.write(_h('archives/$name.bak'), 'ancienne version');
    },
    criteria: (sh) {
      final f = _fileExists(sh.fs, _h('chemin.txt'));
      if (!f.ok) return [f];
      final got = (sh.fs.readFile(_h('chemin.txt')) ?? '').trim();
      final normalized =
          got.startsWith('~/') ? '$kMissionHome${got.substring(1)}' : got;
      final ok = normalized == target;
      var detail = '';
      if (!ok) {
        detail = got.isEmpty
            ? 'Le fichier est vide'
            : (got.startsWith('/') || got.startsWith('~')
                ? 'Trouvé « $got »'
                : 'Trouvé « $got » : un chemin absolu commence par /');
      }
      return [
        f,
        MissionStep('Le chemin écrit est celui du fichier', ok, detail)
      ];
    },
  );
}

TerminalMission _mFindCount(TrainingRandom r) {
  final dirs = _pickN(r, ['reseau', 'web', 'base', 'mail', 'ssh'], 3);
  final n = r.range(3, 7);
  final confs = <String>[];
  final names = r.shuffled(_words);
  for (var i = 0; i < n; i++) {
    final where = i == 0 ? '' : '${r.pick(dirs)}/';
    confs.add('config/$where${names[i]}.conf');
  }
  final withDirDecoy = r.nextBool();
  return TerminalMission(
    kind: 17,
    level: MissionLevel.recherche,
    title: 'Compter avec find',
    instruction:
        'Combien de fichiers dont le nom finit par .conf y a-t-il dans '
        '~/config, sous-dossiers compris ? Écris ce nombre dans ~/nb_conf.txt.',
    hint: 'find ~/config -type f -name "*.conf" liste les fichiers (et pas les '
        'dossiers) ; wc -l compte les lignes.',
    solution: [
      'find ~/config -type f -name "*.conf"',
      'find ~/config -type f -name "*.conf" | wc -l > ~/nb_conf.txt',
    ],
    method: 'find descend dans tous les sous-dossiers ; -type f écarte les '
        'dossiers${withDirDecoy ? ' (ici ~/config/modules.conf est un dossier)' : ''} ; '
        '-name "*.conf" ne retient que les noms qui finissent par .conf '
        '(pas reseau.conf.bak). wc -l compte : $n.',
    setup: (sh) {
      for (final c in confs) {
        sh.fs.write(_h(c), 'option=1');
      }
      sh.fs.write(_h('config/${dirs.first}/reseau.conf.bak'), 'ancien');
      sh.fs.write(_h('config/notes.txt'), 'à lire');
      if (withDirDecoy) sh.fs.write(_h('config/modules.conf/a.load'), 'charge');
    },
    criteria: (sh) {
      final f = _fileExists(sh.fs, _h('nb_conf.txt'));
      return f.ok ? [f, _numberIn(sh.fs, _h('nb_conf.txt'), n)] : [f];
    },
  );
}

/// Journal avec [target] présent 2 à 4 fois.
List<String> _serviceLog(TrainingRandom r, String target) {
  final total = r.range(10, 14);
  final k = r.range(2, 4);
  final others = _services.where((s) => s != target).toList();
  final services = r.shuffled([
    for (var i = 0; i < k; i++) target,
    for (var i = k; i < total; i++) r.pick(others),
  ]);
  final levels = [
    for (var i = 0; i < total; i++) r.pick(['INFO', 'WARN', 'ERROR'])
  ];
  return _logLines(r, services, levels);
}

TerminalMission _mGrep(TrainingRandom r) {
  final word = r.pick(_services);
  final lines = _serviceLog(r, word);
  final expected = lines.where((l) => l.contains(word)).toList();
  return TerminalMission(
    kind: 18,
    level: MissionLevel.recherche,
    title: 'Extraire des lignes avec grep',
    instruction: 'Écris dans ~/$word.txt toutes les lignes de ~/app.log qui '
        'contiennent le mot « $word », dans leur ordre d\'origine, et seulement '
        'elles.',
    hint: 'grep motif fichier affiche les lignes qui contiennent le motif ; '
        '> fichier enregistre le résultat.',
    solution: ['grep $word ~/app.log', 'grep $word ~/app.log > ~/$word.txt'],
    method: 'grep garde les lignes qui contiennent « $word » sans changer leur '
        'ordre (${expected.length} ligne(s) ici) ; la redirection les écrit dans '
        '~/$word.txt.',
    setup: (sh) => sh.fs.write(_h('app.log'), _join(lines)),
    criteria: (sh) => [
      _fileExists(sh.fs, _h('$word.txt')),
      if (sh.fs.isFile(_h('$word.txt')))
        _linesEqual(sh.fs, _h('$word.txt'), expected,
            'Le fichier contient exactement les lignes avec « $word »'),
    ],
  );
}

TerminalMission _mGrepCount(TrainingRandom r) {
  final level = r.pick(['ERROR', 'WARN']);
  final total = r.range(10, 15);
  final levels = [
    for (var i = 0; i < total; i++) r.pick(['INFO', 'WARN', 'ERROR'])
  ];
  // Au moins une ligne du niveau cherché et au moins une autre.
  final forced = r.nextInt(total);
  levels[forced] = level;
  if (levels.every((l) => l == level)) levels[(forced + 1) % total] = 'INFO';
  final services = [for (var i = 0; i < total; i++) r.pick(_services)];
  final lines = _logLines(r, services, levels);
  final n = lines.where((l) => l.contains(level)).length;
  return TerminalMission(
    kind: 19,
    level: MissionLevel.recherche,
    title: 'Compter des lignes avec grep',
    instruction:
        'Combien de lignes de ~/app.log contiennent « $level » ? Écris '
        'ce nombre dans ~/nb_$level.txt.',
    hint:
        'grep -c compte les lignes qui correspondent au lieu de les afficher. '
        'grep ... | wc -l donne le même nombre.',
    solution: [
      'grep -c $level ~/app.log > ~/nb_$level.txt',
      'cat ~/nb_$level.txt'
    ],
    method: 'grep -c $level ~/app.log affiche directement le nombre de lignes '
        'qui contiennent $level : $n.',
    setup: (sh) => sh.fs.write(_h('app.log'), _join(lines)),
    criteria: (sh) {
      final f = _fileExists(sh.fs, _h('nb_$level.txt'));
      return f.ok ? [f, _numberIn(sh.fs, _h('nb_$level.txt'), n)] : [f];
    },
  );
}

TerminalMission _mWc(TrainingRandom r) {
  final name = '${r.pick(['eleves', 'clients', 'stock', 'mesures'])}.csv';
  final rows = r.range(5, 15);
  final lines = [
    'id,nom,ville',
    for (var i = 1; i <= rows; i++)
      '$i,${r.pick(_names)},${r.pick([
            'Lyon',
            'Lille',
            'Nantes',
            'Brest',
            'Nice'
          ])}'
  ];
  return TerminalMission(
    kind: 20,
    level: MissionLevel.recherche,
    title: 'Compter les lignes avec wc',
    instruction:
        'Combien de lignes contient ~/$name (ligne d\'en-tête comprise) ? '
        'Écris ce nombre dans ~/lignes.txt.',
    hint: 'wc -l compte les lignes. « wc -l fichier » affiche aussi le nom du '
        'fichier ; « wc -l < fichier » n\'affiche que le nombre.',
    solution: ['wc -l < ~/$name > ~/lignes.txt', 'cat ~/lignes.txt'],
    method: 'wc -l < ~/$name lit le fichier par l\'entrée standard et affiche '
        'seulement le nombre (${lines.length}). « wc -l ~/$name » écrit aussi le '
        'nom du fichier après le nombre : accepté aussi, le nombre vient en '
        'premier.',
    setup: (sh) => sh.fs.write(_h(name), _join(lines)),
    criteria: (sh) {
      final f = _fileExists(sh.fs, _h('lignes.txt'));
      return f.ok ? [f, _numberIn(sh.fs, _h('lignes.txt'), lines.length)] : [f];
    },
  );
}

TerminalMission _mSortUniq(TrainingRandom r) {
  final people = _pickN(r, _names, r.range(5, 7));
  final list = r.shuffled([
    for (final p in people)
      for (var i = r.range(1, 3); i > 0; i--) p
  ]);
  if (list.length == people.length) list.add(people.first);
  final shuffled = r.shuffled(list);
  final expected = people.toList()..sort();
  return TerminalMission(
    kind: 21,
    level: MissionLevel.recherche,
    title: 'Trier et dédoublonner',
    instruction:
        '~/inscrits.txt contient des prénoms, certains en double, dans '
        'le désordre. Écris dans ~/liste_propre.txt la liste triée par ordre '
        'alphabétique, chaque prénom une seule fois.',
    hint: 'uniq ne supprime que les doublons qui se suivent : il faut donc '
        'trier d\'abord (sort), puis enchaîner avec un tube (|).',
    solution: [
      'sort ~/inscrits.txt | uniq > ~/liste_propre.txt',
      'cat ~/liste_propre.txt'
    ],
    method: 'sort regroupe les lignes identiques, uniq en garde une par groupe '
        '(sort -u fait les deux à la fois). Résultat : ${expected.join(', ')}.',
    setup: (sh) => sh.fs.write(_h('inscrits.txt'), _join(shuffled)),
    criteria: (sh) => [
      _fileExists(sh.fs, _h('liste_propre.txt')),
      if (sh.fs.isFile(_h('liste_propre.txt')))
        _linesEqual(sh.fs, _h('liste_propre.txt'), expected,
            'La liste est triée et sans doublon'),
    ],
  );
}

TerminalMission _mHead(TrainingRandom r) {
  final n = r.range(3, 5);
  final people = _pickN(r, _names, 8);
  var score = r.range(90, 99);
  final lines = [
    for (var i = 0; i < people.length; i++)
      '${i + 1} ${people[i]} ${score -= r.range(1, 6)}'
  ];
  return TerminalMission(
    kind: 22,
    level: MissionLevel.recherche,
    title: 'Garder le début d\'un fichier',
    instruction: 'Écris les $n premières lignes de ~/classement.txt dans '
        '~/podium.txt.',
    hint:
        'head affiche le début d\'un fichier ; -n choisit le nombre de lignes '
        '(10 par défaut).',
    solution: [
      'head -n $n ~/classement.txt > ~/podium.txt',
      'cat ~/podium.txt'
    ],
    method: 'head -n $n garde les $n premières lignes ; tail -n ferait la même '
        'chose avec la fin.',
    setup: (sh) => sh.fs.write(_h('classement.txt'), _join(lines)),
    criteria: (sh) => [
      _fileExists(sh.fs, _h('podium.txt')),
      if (sh.fs.isFile(_h('podium.txt')))
        _linesEqual(sh.fs, _h('podium.txt'), lines.take(n).toList(),
            'Le fichier contient les $n premières lignes'),
    ],
  );
}

TerminalMission _mGrepV(TrainingRandom r) {
  final settings = r
      .shuffled([
        'port=${r.range(1024, 9999)}',
        'langue=${r.pick(['fr', 'en', 'de'])}',
        'journal=/var/log/app.log',
        'max_clients=${r.range(10, 200)}',
        'mode=${r.pick(['production', 'test'])}',
      ])
      .take(r.range(3, 5))
      .toList();
  final comments = r
      .shuffled([
        '# Fichier de configuration',
        '# Ne pas modifier sans sauvegarde',
        '# Port d\'écoute du service',
        '#mode=debug',
      ])
      .take(r.range(2, 3))
      .toList();
  final all = <String>[comments.first];
  final rest = r.shuffled([...settings, ...comments.skip(1)]);
  // Garde l'ordre relatif des réglages : on les replace dans l'ordre d'origine.
  var si = 0;
  for (final l in rest) {
    all.add(l.startsWith('#') ? l : settings[si++]);
  }
  final expected = all.where((l) => !l.startsWith('#')).toList();
  return TerminalMission(
    kind: 23,
    level: MissionLevel.recherche,
    title: 'Retirer les commentaires',
    instruction: '~/reglages.conf mélange réglages et commentaires (lignes qui '
        'commencent par #). Écris dans ~/reglages_actifs.conf toutes les lignes '
        'qui ne sont pas des commentaires, dans le même ordre.',
    hint: 'grep -v inverse la sélection (lignes qui NE correspondent PAS). '
        'Dans une expression régulière, ^ désigne le début de ligne.',
    solution: [
      "grep -v '^#' ~/reglages.conf > ~/reglages_actifs.conf",
      'cat ~/reglages_actifs.conf'
    ],
    method: "grep -v '^#' garde les lignes qui ne commencent pas par # (les "
        'guillemets simples empêchent bash d\'interpréter le motif) ; > écrit '
        'le résultat.',
    setup: (sh) => sh.fs.write(_h('reglages.conf'), _join(all)),
    criteria: (sh) => [
      _fileExists(sh.fs, _h('reglages_actifs.conf')),
      if (sh.fs.isFile(_h('reglages_actifs.conf')))
        _linesEqual(sh.fs, _h('reglages_actifs.conf'), expected,
            'Le fichier contient les réglages, sans commentaire'),
    ],
  );
}

TerminalMission _mVotes(TrainingRandom r) {
  final candidates = _pickN(r, _names, r.range(3, 4));
  final counts = [for (var i = 1; i < candidates.length; i++) r.range(1, 4)];
  final winnerCount = counts.reduce((a, b) => a > b ? a : b) + r.range(1, 2);
  final winner = candidates.first;
  final votes = r.shuffled([
    for (var i = 0; i < winnerCount; i++) winner,
    for (var c = 1; c < candidates.length; c++)
      for (var i = 0; i < counts[c - 1]; i++) candidates[c],
  ]);
  return TerminalMission(
    kind: 24,
    level: MissionLevel.recherche,
    title: 'Le plus fréquent',
    instruction: '~/votes.txt contient un prénom par vote. Quel prénom a reçu '
        'le plus de voix ? Écris-le dans ~/gagnant.txt.',
    hint: 'sort regroupe les lignes identiques, uniq -c les compte, sort -n '
        'trie selon ce nombre.',
    solution: [
      'sort ~/votes.txt | uniq -c | sort -n',
      'echo $winner > ~/gagnant.txt',
    ],
    method:
        'sort ~/votes.txt | uniq -c | sort -n affiche chaque prénom précédé '
        'de son nombre de voix, du plus petit au plus grand : la dernière ligne '
        'donne $winner ($winnerCount voix).',
    setup: (sh) => sh.fs.write(_h('votes.txt'), _join(votes)),
    criteria: (sh) {
      final f = _fileExists(sh.fs, _h('gagnant.txt'));
      if (!f.ok) return [f];
      final words = (sh.fs.readFile(_h('gagnant.txt')) ?? '')
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      // Accepte « nora » ou la ligne de uniq -c « 5 nora ».
      final ok = words.isNotEmpty &&
          words.last.toLowerCase() == winner &&
          (words.length == 1 ||
              (words.length == 2 && words.first == '$winnerCount'));
      return [
        f,
        MissionStep('Le prénom écrit est celui du gagnant', ok,
            ok ? '' : 'Trouvé « ${words.join(' ')} »'),
      ];
    },
  );
}

// --- Niveau 4 : droits --------------------------------------------------------

TerminalMission _mChmodX(TrainingRandom r) {
  final name = '${r.pick([
        'deployer',
        'nettoyer',
        'sauver',
        'installer',
        'verifier'
      ])}.sh';
  final path = _h(name);
  return TerminalMission(
    kind: 25,
    level: MissionLevel.droits,
    title: 'Rendre un script exécutable',
    instruction: 'Rends le script ~/$name exécutable par son propriétaire. Le '
        'groupe et les autres ne doivent pas obtenir le droit d\'écriture.',
    hint: 'ls -l montre les droits (rw-r--r-- : pas de x). chmod u+x ajoute '
        'l\'exécution pour le propriétaire (u = user).',
    solution: ['ls -l ~/$name', 'chmod u+x ~/$name', 'ls -l ~/$name'],
    method: 'chmod u+x ajoute x pour le propriétaire : 644 (rw-r--r--) devient '
        '744 (rwxr--r--). chmod +x (sans u/g/o/a) ajoute x pour tous, dans la '
        'limite du umask (022) : 755, accepté aussi. chmod 777 donnerait '
        'l\'écriture à tout le monde : à éviter.',
    setup: (sh) => sh.fs
        .write(path, '#!/bin/bash\necho "Script ${name.split('.').first}"'),
    criteria: (sh) {
      final f = _fileExists(sh.fs, path);
      if (!f.ok) return [f];
      final mode = sh.fs.permissions(path)!;
      return [
        f,
        MissionStep('Le propriétaire a le droit x', mode & 0x40 != 0,
            'Droits actuels : ${describeMode(mode)}'),
        MissionStep('Le groupe et les autres n\'ont pas le droit w',
            mode & 0x12 == 0, 'Droits actuels : ${describeMode(mode)}'),
        MissionStep('Le propriétaire peut toujours lire et modifier',
            mode & 0x180 == 0x180, 'Droits actuels : ${describeMode(mode)}'),
      ];
    },
  );
}

const _exactModes = [
  0x180,
  0x1A0,
  0x1A4,
  0x1C0,
  0x1E8,
  0x1ED,
  0x100,
  0x124,
  0x1B0
];

TerminalMission _mChmodExact(TrainingRandom r) {
  final target = r.pick(_exactModes);
  var initial = r.pick(_exactModes);
  while (initial == target) {
    initial = r.pick(_exactModes);
  }
  final name = '${r.pick(_words)}.${r.pick(['txt', 'csv', 'conf'])}';
  final path = _h('donnees/$name');
  final value = r.range(1, 99);
  final sym = VirtualFileSystem.modeString(target).substring(1);
  final octal = target.toRadixString(8);
  String digit(int k) {
    final v = (target >> (6 - 3 * k)) & 7;
    final part = sym.substring(3 * k, 3 * k + 3);
    final terms = <String>[
      if (v & 4 != 0) 'r=4',
      if (v & 2 != 0) 'w=2',
      if (v & 1 != 0) 'x=1',
    ];
    return '$part = ${terms.isEmpty ? '0' : '${terms.join(' + ')} = $v'}';
  }

  return TerminalMission(
    kind: 26,
    level: MissionLevel.droits,
    title: 'Droits exacts',
    instruction: 'Donne au fichier ~/donnees/$name exactement les droits $sym '
        '(propriétaire, groupe, autres).',
    hint: 'En octal, chaque groupe de trois lettres vaut r=4, w=2, x=1 '
        'additionnés : rw- = 6, r-- = 4, --- = 0.',
    solution: ['chmod $octal ~/donnees/$name', 'ls -l ~/donnees'],
    method: 'Conversion : ${digit(0)} ; ${digit(1)} ; ${digit(2)}. '
        'D\'où chmod $octal. En symbolique : chmod '
        'u=${sym.substring(0, 3).replaceAll('-', '')},'
        'g=${sym.substring(3, 6).replaceAll('-', '')},'
        'o=${sym.substring(6, 9).replaceAll('-', '')}.',
    setup: (sh) {
      sh.fs.write(path, 'valeur=$value');
      sh.fs.setPermissions(path, initial);
    },
    criteria: (sh) {
      final f = _fileExists(sh.fs, path);
      if (!f.ok) return [f];
      final mode = sh.fs.permissions(path)! & 0xFFF;
      return [
        f,
        MissionStep('Les droits sont $sym ($octal)', mode == target,
            mode == target ? '' : 'Droits actuels : ${describeMode(mode)}'),
      ];
    },
  );
}

TerminalMission _mChmodDir(TrainingRandom r) {
  final name = 'prive_${r.pick(_words)}';
  final path = _h(name);
  final initial = r.pick([0x1ED, 0x1FF, 0x1E8]);
  return TerminalMission(
    kind: 27,
    level: MissionLevel.droits,
    title: 'Dossier privé',
    instruction: 'Le dossier ~/$name doit être utilisable par toi seul : tu '
        'gardes lecture, écriture et traversée ; le groupe et les autres ne '
        'doivent ni lister son contenu, ni y entrer, ni y écrire.',
    hint: 'Sur un dossier, r permet de lister, w de créer ou supprimer des '
        'entrées, x d\'y entrer (traverser). Tout pour toi, rien pour les '
        'autres : rwx------.',
    solution: ['chmod 700 ~/$name', 'ls -ld ~/$name'],
    method: 'rwx------ = 7 (4+2+1) pour le propriétaire, 0 pour le groupe et '
        'les autres : chmod 700, ou chmod go= (ou go-rwx) qui retire tout au '
        'groupe et aux autres.',
    setup: (sh) {
      sh.fs.write(_h('$name/journal_intime.txt'), 'personnel');
      sh.fs.setPermissions(path, initial);
    },
    criteria: (sh) {
      final d = _dirExists(sh.fs, path);
      if (!d.ok) return [d];
      final mode = sh.fs.permissions(path)! & 0x1FF;
      return [
        d,
        MissionStep('Le propriétaire a rwx', mode & 0x1C0 == 0x1C0,
            'Droits actuels : ${describeMode(mode)}'),
        MissionStep('Le groupe et les autres n\'ont aucun droit',
            mode & 0x3F == 0, 'Droits actuels : ${describeMode(mode)}'),
      ];
    },
  );
}

TerminalMission _mChmodR(TrainingRandom r) {
  final files = [for (final w in _pickN(r, _words, 3)) '$w.txt'];
  final sub = r.pick(['photos', 'textes', 'rapports']);
  final paths = <String>[
    'partage',
    'partage/$sub',
    'partage/${files[0]}',
    'partage/$sub/${files[1]}',
    'partage/$sub/${files[2]}',
  ];
  return TerminalMission(
    kind: 28,
    level: MissionLevel.droits,
    title: 'Droits récursifs',
    instruction: 'Retire le droit d\'écriture au groupe et aux autres sur '
        '~/partage et sur tout son contenu, sans changer les autres droits.',
    hint: 'chmod -R applique le changement à tout ce que contient le dossier. '
        'g = groupe, o = autres, - retire.',
    solution: ['chmod -R go-w ~/partage', 'ls -l ~/partage'],
    method:
        'chmod -R go-w retire seulement w au groupe et aux autres, partout : '
        'les dossiers passent de 777 (rwxrwxrwx) à 755 (rwxr-xr-x), les fichiers '
        'de 666 (rw-rw-rw-) à 644 (rw-r--r--). Un mode octal (chmod -R 755) '
        'rendrait les fichiers exécutables : c\'est pour cela qu\'on préfère la '
        'forme symbolique ici.',
    setup: (sh) {
      for (final p in paths.skip(2)) {
        sh.fs.write(_h(p), 'partagé');
        sh.fs.setPermissions(_h(p), 0x1B6);
      }
      sh.fs.setPermissions(_h('partage'), 0x1FF);
      sh.fs.setPermissions(_h('partage/$sub'), 0x1FF);
    },
    criteria: (sh) => [
      for (var i = 0; i < paths.length; i++)
        () {
          final p = paths[i];
          final path = _h(p);
          // Les deux premiers chemins sont des dossiers, les autres des fichiers.
          final isDir = i < 2;
          final label =
              '~/$p : ${isDir ? '755 (rwxr-xr-x)' : '644 (rw-r--r--)'}';
          if (!sh.fs.exists(path))
            return MissionStep(label, false, 'Introuvable');
          if (sh.fs.isDir(path) != isDir) {
            return MissionStep(
                label,
                false,
                isDir
                    ? 'Ce n\'est plus un dossier'
                    : 'Ce n\'est plus un fichier');
          }
          final want = isDir ? 0x1ED : 0x1A4;
          final mode = sh.fs.permissions(path)! & 0xFFF;
          return MissionStep(label, mode == want,
              mode == want ? '' : 'Droits actuels : ${describeMode(mode)}');
        }(),
    ],
  );
}

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

class TerminalMissions extends StatefulWidget {
  const TerminalMissions({super.key, this.seed});

  /// Graine facultative : même suite de missions à chaque fois (tests).
  final int? seed;

  @override
  State<TerminalMissions> createState() => _TerminalMissionsState();
}

class _TermLine {
  const _TermLine(this.text, this.isPrompt);
  final String text;
  final bool isPrompt;
}

class _TerminalMissionsState extends State<TerminalMissions> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();
  late final TrainingRandom _random = TrainingRandom(widget.seed);

  MissionLevel? _level;
  late TerminalMission _mission;
  late VirtualShell _shell;
  final List<_TermLine> _lines = [];
  final List<String> _history = [];
  int _historyIndex = 0;

  TrainingCheck? _result;
  bool _showHint = false;
  bool _showSolution = false;
  bool _failedOnce = false;
  bool _counted = false;
  bool _solved = false;
  int _score = 0;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _newMission();
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _newMission({int? kind}) {
    _mission = kind == null
        ? randomMission(_random, level: _level)
        : buildMission(kind, _random);
    _counted = false;
    _solved = false;
    _failedOnce = false;
    _restart();
  }

  /// Remet le système de fichiers dans l'état de départ de la mission.
  void _restart() {
    _shell = _mission.createShell();
    _lines
      ..clear()
      ..add(const _TermLine(
          'Terminal virtuel. Tape help pour la liste des commandes.', false));
    _result = null;
    _showHint = false;
    _showSolution = false;
  }

  void _run(String raw) {
    final cmd = raw.trim();
    setState(() {
      _lines.add(_TermLine('${_shell.prompt}$cmd', true));
      if (cmd.isNotEmpty) {
        _history.add(cmd);
        for (final l in _shell.execute(cmd)) {
          if (l == '__CLEAR__') {
            _lines.clear();
          } else {
            _lines.add(_TermLine(l, false));
          }
        }
        if (_lines.length > 500) _lines.removeRange(0, _lines.length - 500);
      }
      _historyIndex = _history.length;
    });
    _input.clear();
    _inputFocus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _recallHistory(int delta) {
    if (_history.isEmpty) return;
    final i = (_historyIndex + delta).clamp(0, _history.length);
    _historyIndex = i;
    _input.text = i < _history.length ? _history[i] : '';
    _input.selection = TextSelection.collapsed(offset: _input.text.length);
  }

  void _check() {
    final res = _mission.check(_shell);
    setState(() {
      _result = res;
      if (!_counted) {
        _counted = true;
        _attempts++;
      }
      if (res.correct && !_solved) {
        _solved = true;
        _score++;
      }
      if (!res.correct) _failedOnce = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kinds = missionKindsOf(_level);
    return TrainingFrame(
      title: 'Terminal Linux : missions',
      subtitle: 'Un vrai terminal virtuel : accomplis la mission, puis fais-la '
          'vérifier',
      icon: Icons.terminal,
      instruction: '${_mission.title} (${kMissionLevelLabels[_mission.level]})'
          '\n\n${_mission.instruction}',
      checkLabel: 'Vérifier la mission',
      onCheck: _check,
      onNext: () => setState(_newMission),
      result: _result,
      score: _score,
      attempts: _attempts,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final l in <MissionLevel?>[null, ...MissionLevel.values])
                ChoiceChip(
                  label: Text(
                      l == null ? 'Tous niveaux' : kMissionLevelLabels[l]!),
                  selected: _level == l,
                  onSelected: (_) => setState(() {
                    _level = l;
                    _newMission();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButton<int>(
            value: kinds.contains(_mission.kind) ? _mission.kind : null,
            isExpanded: true,
            dropdownColor: TdcColors.surfaceAlt,
            hint: const Text('Choisir une mission',
                style: TextStyle(color: TdcColors.textSecondary)),
            style: const TextStyle(color: TdcColors.textPrimary),
            items: [
              for (final k in kinds)
                DropdownMenuItem(
                  value: k,
                  child: Text('Mission ${k + 1} : ${_titleOf(k)}'),
                ),
            ],
            onChanged: (k) {
              if (k != null) setState(() => _newMission(kind: k));
            },
          ),
          const SizedBox(height: 8),
          _terminal(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _showHint = !_showHint),
                icon: const Icon(Icons.lightbulb_outline, size: 18),
                label: Text(_showHint ? 'Masquer l\'indice' : 'Indice'),
              ),
              OutlinedButton.icon(
                onPressed: _failedOnce
                    ? () => setState(() => _showSolution = !_showSolution)
                    : null,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: Text(
                    _showSolution ? 'Masquer la solution' : 'Voir la solution'),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(_restart),
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Recommencer la mission'),
              ),
            ],
          ),
          if (!_failedOnce)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                  'La solution devient disponible après une première vérification '
                  'manquée.',
                  style: TextStyle(color: TdcColors.textMuted, fontSize: 12)),
            ),
          if (_showHint) ...[
            const SizedBox(height: 12),
            Text('Indice : ${_mission.hint}',
                style: const TextStyle(
                    color: TdcColors.textSecondary, height: 1.5)),
          ],
          if (_showSolution) ...[
            const SizedBox(height: 12),
            const Text('Une solution possible :',
                style: TextStyle(color: TdcColors.textSecondary)),
            const SizedBox(height: 6),
            TrainingCode(_mission.solution.join('\n')),
          ],
        ],
      ),
    );
  }

  /// Titres des modèles de mission (le titre ne dépend pas des valeurs tirées).
  static final List<String> _titles = [
    for (var k = 0; k < kMissionKinds; k++)
      buildMission(k, TrainingRandom(0)).title
  ];
  static String _titleOf(int kind) => _titles[kind];

  Widget _terminal() {
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.4);
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TdcColors.border),
      ),
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () => _inputFocus.requestFocus(),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                itemCount: _lines.length,
                itemBuilder: (context, i) => SelectableText(
                  _lines[i].text,
                  style: mono.copyWith(
                      color: _lines[i].isPrompt
                          ? TdcColors.accent
                          : TdcColors.textPrimary),
                ),
              ),
            ),
            Row(
              children: [
                Text(_shell.prompt,
                    style: mono.copyWith(
                        color: TdcColors.accent, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent) return KeyEventResult.ignored;
                      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        _recallHistory(-1);
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        _recallHistory(1);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: _input,
                      focusNode: _inputFocus,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: mono.copyWith(color: TdcColors.textPrimary),
                      cursorColor: TdcColors.accent,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                      onSubmitted: _run,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
