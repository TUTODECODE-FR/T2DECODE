// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
//
// Entraînement « Droits Linux » : conversions rwx <-> octal, lecture de ls -l,
// commandes chmod, umask, bits spéciaux (SUID, SGID, sticky).
//
// La logique (génération, vérification, simulation de chmod) est pure et testable
// sans interface. La simulation de chmod suit le comportement de GNU coreutils
// (gnulib modechange.c), y compris la conservation des bits SUID/SGID d'un dossier
// avec un mode numérique de quatre chiffres ou moins.
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/training/training_kit.dart';

// ---------------------------------------------------------------------------
// Bits (Dart n'a pas de littéral octal : valeurs en hexadécimal, octal en commentaire)
// ---------------------------------------------------------------------------

/// 04000 : set-user-ID.
const int kSuid = 0x800;

/// 02000 : set-group-ID.
const int kSgid = 0x400;

/// 01000 : sticky bit.
const int kSticky = 0x200;

/// 0777 : les neuf bits rwx.
const int kPermBits = 0x1FF;

/// 07777 : tous les bits modifiables par chmod.
const int kModeBits = 0xFFF;

/// 0111 : les trois bits x.
const int kAllX = 0x49;

/// 0444 / 0222 : les trois bits r, les trois bits w.
const int kAllR = 0x124;
const int kAllW = 0x92;

/// Lit un nombre écrit en octal (pour la lisibilité des tables).
int octal(String s) => int.parse(s, radix: 8);

/// Écrit un mode en octal sur [digits] chiffres au moins.
String toOctal(int mode, [int digits = 3]) =>
    mode.toRadixString(8).padLeft(digits, '0');

/// Écriture octale « naturelle » : 3 chiffres sans bit spécial, 4 sinon.
String naturalOctal(int mode) =>
    toOctal(mode, (mode & (kSuid | kSgid | kSticky)) != 0 ? 4 : 3);

/// Les trois classes, dans l'ordre d'affichage de ls -l.
enum PermClass { owner, group, other }

const _classShift = {
  PermClass.owner: 6,
  PermClass.group: 3,
  PermClass.other: 0
};
const _classSpecial = {
  PermClass.owner: kSuid,
  PermClass.group: kSgid,
  PermClass.other: kSticky,
};
const _classLetter = {
  PermClass.owner: 'u',
  PermClass.group: 'g',
  PermClass.other: 'o',
};
const _className = {
  PermClass.owner: 'propriétaire',
  PermClass.group: 'groupe',
  PermClass.other: 'autres',
};

/// Triplet (0 à 7) d'une classe.
int tripletOf(int mode, PermClass c) => (mode >> _classShift[c]!) & 7;

/// Les 9 caractères de ls -l (sans le type), avec s/S/t/T.
String permString(int mode) {
  final b = StringBuffer();
  for (final c in PermClass.values) {
    final t = tripletOf(mode, c);
    b.write((t & 4) != 0 ? 'r' : '-');
    b.write((t & 2) != 0 ? 'w' : '-');
    final x = (t & 1) != 0;
    final special = (mode & _classSpecial[c]!) != 0;
    final letter = c == PermClass.other ? 't' : 's';
    b.write(special ? (x ? letter : letter.toUpperCase()) : (x ? 'x' : '-'));
  }
  return b.toString();
}

/// Les 10 caractères de ls -l : type (d ou -) puis droits.
String lsMode(int mode, {required bool dir}) =>
    '${dir ? 'd' : '-'}${permString(mode)}';

/// Lit 9 caractères de droits (r/w/x/s/S/t/T/-) ; null si invalide.
int? parsePermString(String s) {
  if (s.length != 9) return null;
  var mode = 0;
  for (final c in PermClass.values) {
    final i = c.index * 3;
    final shift = _classShift[c]!;
    final r = s[i], w = s[i + 1], x = s[i + 2];
    if (r == 'r') {
      mode |= 4 << shift;
    } else if (r != '-') {
      return null;
    }
    if (w == 'w') {
      mode |= 2 << shift;
    } else if (w != '-') {
      return null;
    }
    final letter = c == PermClass.other ? 't' : 's';
    if (x == 'x') {
      mode |= 1 << shift;
    } else if (x == letter) {
      mode |= (1 << shift) | _classSpecial[c]!;
    } else if (x == letter.toUpperCase()) {
      mode |= _classSpecial[c]!;
    } else if (x != '-') {
      return null;
    }
  }
  return mode;
}

/// Lit une réponse de droits : octal (« 755 », « 0755 », « 4755 », « 0o755 ») ou
/// symbolique (9 caractères, ou 10 avec le type). Renvoie le mode, ou null.
int? parsePermAnswer(String raw) {
  final s = raw.replaceAll(RegExp(r'\s+'), '');
  final o = parseOctalAnswer(s);
  if (o != null) return o;
  if (s.length == 10 && (s[0] == '-' || s[0].toLowerCase() == 'd')) {
    return parsePermString(s.substring(1));
  }
  return parsePermString(s);
}

/// Lit un nombre octal de 1 à 5 chiffres (préfixe 0o toléré), au plus 07777.
int? parseOctalAnswer(String raw) {
  var s = raw.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  if (s.startsWith('0o')) s = s.substring(2);
  if (!RegExp(r'^[0-7]{1,5}$').hasMatch(s)) return null;
  final v = int.parse(s, radix: 8);
  return v > kModeBits ? null : v;
}

// ---------------------------------------------------------------------------
// Simulation de chmod (GNU coreutils / gnulib modechange.c)
// ---------------------------------------------------------------------------

enum _Flag { ordinary, copyExisting, xIfAnyX }

/// Valeur d'une suite de chiffres octaux, ou null au-delà de 07777. Calcul chiffre
/// par chiffre (comme gnulib) : int.parse lèverait une exception sur une très
/// longue saisie.
int? _octalDigits(String digits) {
  var v = 0;
  for (var k = 0; k < digits.length; k++) {
    v = v * 8 + digits.codeUnitAt(k) - 0x30;
    if (v > kModeBits) return null;
  }
  return v;
}

class _Change {
  _Change(this.op, this.flag, this.affected, this.value, this.mentioned);
  final String op;
  final _Flag flag;
  final int affected;
  final int value;
  final int mentioned;
}

/// Résultat d'une compilation de mode chmod : liste de changements ou erreur.
class ChmodMode {
  ChmodMode._(this._changes, this.error);

  final List<_Change> _changes;

  /// Message d'erreur en français si le mode est invalide.
  final String? error;
  bool get valid => error == null;

  /// Applique le mode à [oldMode] (fichier ou dossier) avec le umask donné.
  int apply(int oldMode, {required bool dir, int umask = 0x12}) {
    var newmode = oldMode & kModeBits;
    for (final c in _changes) {
      final omit = dir ? (kSuid | kSgid) & ~c.mentioned : 0;
      var value = c.value;
      switch (c.flag) {
        case _Flag.ordinary:
          break;
        case _Flag.copyExisting:
          value &= newmode;
          value |= ((value & kAllR) != 0 ? kAllR : 0) |
              ((value & kAllW) != 0 ? kAllW : 0) |
              ((value & kAllX) != 0 ? kAllX : 0);
          break;
        case _Flag.xIfAnyX:
          if ((newmode & kAllX) != 0 || dir) value |= kAllX;
          break;
      }
      value &= (c.affected != 0 ? c.affected : ~umask) & ~omit;
      switch (c.op) {
        case '=':
          final preserved = (c.affected != 0 ? ~c.affected : 0) | omit;
          newmode = (newmode & preserved) | value;
          break;
        case '+':
          newmode |= value;
          break;
        default:
          newmode &= ~value;
      }
    }
    return newmode & kModeBits;
  }

  /// Compile un argument de mode comme le fait chmod (numérique ou symbolique).
  static ChmodMode parse(String s) {
    ChmodMode err(String m) => ChmodMode._(const [], m);
    if (s.isEmpty) return err('Mode vide.');
    if (RegExp(r'^[0-7]+$').hasMatch(s)) {
      final v = _octalDigits(s);
      if (v == null) {
        return err('Mode numérique trop grand (maximum 7777).');
      }
      final mentioned = s.length < 5
          ? (v & (kSuid | kSgid)) | kSticky | kPermBits
          : kModeBits;
      return ChmodMode._(
          [_Change('=', _Flag.ordinary, kModeBits, v, mentioned)], null);
    }
    final changes = <_Change>[];
    var i = 0;
    while (true) {
      var affected = 0;
      while (i < s.length && 'ugoa'.contains(s[i])) {
        switch (s[i]) {
          case 'u':
            affected |= kSuid | 0x1C0;
            break;
          case 'g':
            affected |= kSgid | 0x38;
            break;
          case 'o':
            affected |= kSticky | 0x7;
            break;
          default:
            affected |= kModeBits;
        }
        i++;
      }
      if (i >= s.length || !'=+-'.contains(s[i])) {
        return err(i < s.length
            ? 'Caractère inattendu « ${s[i]} » : une clause s\'écrit qui (u, g, o, a) '
                'puis opérateur (+, - ou =) puis droits (r, w, x, X, s, t).'
            : 'Clause incomplète : il manque l\'opérateur (+, - ou =).');
      }
      do {
        final op = s[i++];
        if (i < s.length && RegExp('[0-7]').hasMatch(s[i])) {
          if (affected != 0) {
            return err(
                'Un nombre octal après l\'opérateur n\'est permis que sans '
                'u, g, o ou a (exemple : =755).');
          }
          final start = i;
          while (i < s.length && RegExp('[0-7]').hasMatch(s[i])) {
            i++;
          }
          if (i < s.length && s[i] != ',') {
            return err('Le nombre octal doit terminer la clause.');
          }
          final v = _octalDigits(s.substring(start, i));
          if (v == null) return err('Mode numérique trop grand.');
          changes.add(_Change(op, _Flag.ordinary, kModeBits, v, kModeBits));
          break;
        }
        if (i < s.length && 'ugo'.contains(s[i])) {
          final v = s[i] == 'u' ? 0x1C0 : (s[i] == 'g' ? 0x38 : 0x7);
          i++;
          changes.add(_Change(op, _Flag.copyExisting, affected, v,
              affected != 0 ? affected & v : v));
          continue;
        }
        var value = 0;
        var flag = _Flag.ordinary;
        while (i < s.length && 'rwxXst'.contains(s[i])) {
          switch (s[i]) {
            case 'r':
              value |= kAllR;
              break;
            case 'w':
              value |= kAllW;
              break;
            case 'x':
              value |= kAllX;
              break;
            case 'X':
              flag = _Flag.xIfAnyX;
              break;
            case 's':
              value |= kSuid | kSgid;
              break;
            default:
              value |= kSticky;
          }
          i++;
        }
        changes.add(_Change(op, flag, affected, value,
            affected != 0 ? affected & value : value));
      } while (i < s.length && '=+-'.contains(s[i]));
      if (i >= s.length) break;
      if (s[i] != ',') {
        return err('Caractère inattendu « ${s[i]} » dans le mode. Les droits '
            'possibles sont r, w, x, X, s, t (en minuscules sauf X).');
      }
      i++;
    }
    return ChmodMode._(changes, null);
  }
}

/// Raccourci : applique [mode] (argument de chmod) ; null si le mode est invalide.
int? applyChmod(int oldMode, String mode,
    {required bool dir, int umask = 0x12}) {
  final m = ChmodMode.parse(mode);
  return m.valid ? m.apply(oldMode, dir: dir, umask: umask) : null;
}

/// Ce qu'un chmod complet saisi par l'élève donne, ou pourquoi il est refusé.
class ChmodAnswer {
  const ChmodAnswer({this.result, this.error, this.mode, this.umaskNote});
  final int? result;
  final String? error;
  final String? mode;

  /// Renseigné si le mode n'a pas de u/g/o/a et que le résultat dépend du umask.
  final String? umaskNote;
}

/// Analyse « chmod MODE fichier » (ou seulement MODE) et calcule le résultat.
ChmodAnswer evaluateChmodCommand(String raw, int oldMode, {required bool dir}) {
  final cleaned = raw.trim().replaceAll(RegExp(r'\s*,\s*'), ',');
  final tokens =
      cleaned.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (tokens.isNotEmpty && tokens.first == 'sudo') tokens.removeAt(0);
  if (tokens.isNotEmpty && tokens.first == 'chmod') tokens.removeAt(0);
  const options = {
    '-R', '-v', '-c', '-f', '--recursive', '--verbose', '--changes', //
    '--silent', '--quiet', '--',
  };
  tokens.removeWhere(options.contains);
  if (tokens.isEmpty) {
    return const ChmodAnswer(error: 'Aucun mode trouvé dans ta réponse.');
  }
  if (tokens.length > 2) {
    return ChmodAnswer(
        error: 'chmod ne prend qu\'un seul argument de mode : « ${tokens[1]} » '
            'serait pris pour un nom de fichier. Sépare les clauses par des '
            'virgules, sans espace (exemple : u+x,g-w).');
  }
  final modeStr = tokens.first;
  final m = ChmodMode.parse(modeStr);
  if (!m.valid) return ChmodAnswer(error: m.error, mode: modeStr);
  final results = <int>{
    for (var u = 0; u <= kPermBits; u++) m.apply(oldMode, dir: dir, umask: u)
  };
  final with022 = m.apply(oldMode, dir: dir, umask: 0x12);
  if (results.length > 1) {
    return ChmodAnswer(
      mode: modeStr,
      result: null,
      umaskNote: 'Sans u, g, o ou a devant l\'opérateur, chmod n\'applique pas '
          'les bits bloqués par le umask : le résultat dépend du umask de la '
          'session (avec le umask 022 courant, tu obtiendrais '
          '${lsMode(with022, dir: dir)}). Écris a+…, u+…, etc. pour être sûr.',
    );
  }
  return ChmodAnswer(mode: modeStr, result: with022);
}

// ---------------------------------------------------------------------------
// Explications réutilisables
// ---------------------------------------------------------------------------

const String kMemoDirX = 'Sur un dossier, les lettres changent de sens :\n'
    '- r : lire la liste des noms qu\'il contient (ls).\n'
    '- w : créer, supprimer, renommer des entrées. Sans x, w ne sert à rien.\n'
    '- x : traverser. Entrer dedans (cd), ouvrir un fichier par son chemin, lire '
    'ses métadonnées (ls -l). Il faut x sur CHAQUE dossier du chemin.\n'
    'r sans x : tu vois les noms, mais ls -l affiche des « ? » et tu ne peux rien '
    'ouvrir. x sans r : tu peux ouvrir un fichier dont tu connais le nom, sans '
    'pouvoir lister le dossier.';

const String kMemoRoot =
    'root (uid 0) n\'est pas soumis aux bits r et w : grâce à la capacité '
    'CAP_DAC_OVERRIDE, il lit, écrit, liste et traverse tout. Une seule limite '
    'sur les droits classiques : pour exécuter un fichier ordinaire, il faut '
    'qu\'au moins un des trois x soit présent (propriétaire, groupe ou autres). '
    '(Les attributs comme chattr +i, SELinux ou un montage en lecture seule '
    'peuvent quand même l\'arrêter.)';

const String kMemoClass =
    'Le noyau choisit UNE seule classe, dans cet ordre : propriétaire, sinon membre '
    'du groupe du fichier, sinon autres. Il ne regarde que ce triplet : si tu es '
    'propriétaire avec ---, tu es refusé même si les autres ont rwx.';

const String kMemoSpecial =
    'Bits spéciaux (chiffre placé devant les trois autres) :\n'
    '- 4000 SUID (s à la place du x du propriétaire) : un programme s\'exécute avec '
    'l\'identité de son propriétaire (exemple : /usr/bin/passwd, 4755 root).\n'
    '- 2000 SGID (s à la place du x du groupe) : sur un programme, groupe effectif '
    'du fichier ; sur un dossier, les nouveaux fichiers héritent du groupe du '
    'dossier (dossier partagé, 2775).\n'
    '- 1000 sticky (t à la place du x des autres) : dans ce dossier, seuls le '
    'propriétaire du fichier, le propriétaire du dossier et root peuvent '
    'supprimer ou renommer un fichier (/tmp, 1777).\n'
    'Minuscule (s, t) : bit spécial ET x. Majuscule (S, T) : bit spécial SANS x, '
    'souvent une erreur de configuration.';

const String kMemoUmask =
    'umask : à la création, la plupart des programmes demandent 666 (rw-rw-rw-) '
    'pour un fichier et 777 pour un dossier ; le noyau retire les bits du umask. '
    'Résultat = base ET NON umask, bit par bit. Ce n\'est pas une soustraction : '
    'avec le umask 033, un fichier donne 644 (et non 633).';

String _rwxParts(int t) {
  final parts = <String>[
    if ((t & 4) != 0) '4',
    if ((t & 2) != 0) '2',
    if ((t & 1) != 0) '1',
  ];
  return parts.isEmpty ? '0' : parts.join(' + ');
}

/// Explication pas à pas de la conversion d'un mode (symbolique <-> octal).
String explainPermConversion(int mode, {required bool dir}) {
  final sym = permString(mode);
  final b = StringBuffer()
    ..writeln('Méthode : découpe les 9 caractères en trois triplets '
        '(propriétaire, groupe, autres). Dans chaque triplet, r vaut 4, w vaut 2, '
        'x vaut 1 ; additionne.')
    ..writeln('Le premier caractère « ${dir ? 'd' : '-'} » est le type '
        '(${dir ? 'dossier' : 'fichier ordinaire'}) : il ne fait pas partie du nombre.');
  for (final c in PermClass.values) {
    final i = c.index * 3;
    final tri = sym.substring(i, i + 3);
    final t = tripletOf(mode, c);
    var line = '- ${_className[c]} : $tri -> ${_rwxParts(t)} = $t';
    final ch = tri[2];
    if (ch == 's' || ch == 't') {
      line += ' (« $ch » minuscule : x présent + bit spécial)';
    } else if (ch == 'S' || ch == 'T') {
      line += ' (« $ch » majuscule : bit spécial sans x, donc 0 pour x)';
    }
    b.writeln(line);
  }
  final special = (mode >> 9) & 7;
  if (special != 0) {
    final parts = <String>[
      if ((mode & kSuid) != 0) 'SUID 4',
      if ((mode & kSgid) != 0) 'SGID 2',
      if ((mode & kSticky) != 0) 'sticky 1',
    ];
    b.writeln(
        '- bits spéciaux : ${parts.join(' + ')} = $special, placé devant.');
  } else {
    b.writeln('- aucun s, S, t ou T : pas de chiffre spécial (on peut écrire '
        '${toOctal(mode)} ou ${toOctal(mode, 4)}).');
  }
  b.write('Résultat : ${lsMode(mode, dir: dir)} = ${naturalOctal(mode)}.');
  return b.toString();
}

// ---------------------------------------------------------------------------
// Exercices
// ---------------------------------------------------------------------------

enum PermExerciseMode { conversion, lecture, chmod, umask }

enum PermLevel { debutant, avance }

const permModeLabels = {
  PermExerciseMode.conversion: 'rwx et octal',
  PermExerciseMode.lecture: 'Lire ls -l',
  PermExerciseMode.chmod: 'Commande chmod',
  PermExerciseMode.umask: 'umask',
};

/// Un exercice généré : consigne, bloc à lire, champs de réponse et vérification.
abstract class PermExercise {
  String get instruction;

  /// Bloc à chasse fixe (sortie de terminal) ; null s'il n'y en a pas.
  String? get code;

  /// Étiquettes des champs de saisie (un ou deux).
  List<String> get labels;
  List<String> get hints;

  /// Si non nul, la réponse se choisit parmi ces valeurs (boutons).
  List<String>? get choices => null;

  /// Une bonne réponse par champ (affichée en correction, utilisée par les tests).
  List<String> get expected;

  TrainingCheck check(List<String> answers);
}

/// Génère un exercice du mode et du niveau demandés.
PermExercise generatePermExercise(
    TrainingRandom r, PermExerciseMode mode, PermLevel level) {
  switch (mode) {
    case PermExerciseMode.conversion:
      return PermConversionExercise.generate(r, level);
    case PermExerciseMode.lecture:
      return AccessExercise.generate(r, level);
    case PermExerciseMode.chmod:
      return ChmodExercise.generate(r, level);
    case PermExerciseMode.umask:
      return UmaskExercise.generate(r, level);
  }
}

const _commonModes = [
  '644', '755', '600', '700', '640', '750', '664', '775', '444', '555', //
  '400', '711', '666', '777', '660', '770', '604', '751', '440', '500',
];

int _randomPerms(TrainingRandom r) =>
    r.nextInt(3) == 0 ? r.nextInt(kPermBits + 1) : octal(r.pick(_commonModes));

/// Modes réalistes avec bits spéciaux : « f » fichier ou « d » dossier, puis le mode.
const _specialSamples = [
  'f4755', 'f4711', 'f4750', 'f2755', 'f6755', 'f4644', 'd2775', 'd2770', //
  'd1777', 'd1770', 'd3770', 'd1776', 'd2750', 'f2664', 'd1755', 'd3777',
];

// --- (1) Conversions ---------------------------------------------------------

class PermConversionExercise extends PermExercise {
  PermConversionExercise(this.mode,
      {required this.dir, required this.toOctalForm});

  final int mode;
  final bool dir;

  /// true : on donne rwx, on demande l'octal ; false : l'inverse.
  final bool toOctalForm;

  factory PermConversionExercise.generate(TrainingRandom r, PermLevel level) {
    int mode;
    bool dir;
    if (level == PermLevel.avance && r.nextInt(4) != 0) {
      if (r.nextBool()) {
        final s = r.pick(_specialSamples);
        mode = octal(s.substring(1));
        dir = s[0] == 'd';
      } else {
        mode = r.nextInt(kPermBits + 1) | ((1 + r.nextInt(7)) << 9);
        dir = r.nextBool();
      }
    } else {
      mode = _randomPerms(r);
      dir = r.nextInt(3) == 0;
    }
    return PermConversionExercise(mode, dir: dir, toOctalForm: r.nextBool());
  }

  String get _what => dir ? 'Un dossier' : 'Un fichier ordinaire';

  @override
  String get instruction => toOctalForm
      ? 'Voici les droits affichés par ls -l. Donne le mode octal correspondant '
          '(bits spéciaux compris).'
      : '$_what a le mode octal ci-dessous. Écris ce qu\'affiche ls -l : les 10 '
          'caractères, type compris (d ou -).';

  @override
  String? get code => toOctalForm
      ? lsMode(mode, dir: dir)
      : 'Mode ${naturalOctal(mode)}, ${dir ? 'dossier' : 'fichier ordinaire'}';

  @override
  List<String> get labels =>
      [toOctalForm ? 'Mode octal' : 'Droits (10 caractères)'];

  @override
  List<String> get hints => [toOctalForm ? 'ex. 750' : 'ex. -rw-r--r--'];

  @override
  List<String> get expected =>
      [toOctalForm ? naturalOctal(mode) : lsMode(mode, dir: dir)];

  @override
  TrainingCheck check(List<String> answers) {
    final raw = answers.isEmpty ? '' : answers.first;
    final explain = explainPermConversion(mode, dir: dir);
    if (toOctalForm) {
      final v = parseOctalAnswer(raw);
      if (v == null) {
        return TrainingCheck(false,
            'Réponse attendue : un nombre octal (chiffres 0 à 7).\n\n$explain');
      }
      if (v == mode) return TrainingCheck(true, explain);
      var hint = 'Tu as donné ${naturalOctal(v)} (${permString(v)}).';
      if ((v & kPermBits) == (mode & kPermBits) && v != mode) {
        hint += ' Les neuf bits rwx sont justes, mais le chiffre des bits '
            'spéciaux ne l\'est pas.';
      }
      return TrainingCheck(false, '$hint\n\n$explain');
    }
    final s = raw.replaceAll(RegExp(r'\s+'), '');
    final expectedStr = lsMode(mode, dir: dir);
    if (s.length == 9) {
      return TrainingCheck(
          false,
          'Il manque le premier caractère, le type : « ${dir ? 'd' : '-'} » pour '
          '${dir ? 'un dossier' : 'un fichier ordinaire'}.\n\n$explain');
    }
    final norm = s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);
    if (norm == expectedStr) return TrainingCheck(true, explain);
    final b = StringBuffer('Attendu : $expectedStr.');
    if (norm.length == 10 && norm[0] != expectedStr[0]) {
      b.write(
          ' Le type est faux : « d » = dossier, « - » = fichier ordinaire.');
    }
    if (norm.length == 10 &&
        norm.substring(1).toLowerCase() ==
            expectedStr.substring(1).toLowerCase() &&
        norm.substring(1) != expectedStr.substring(1)) {
      b.write(' Attention à la casse : s/t minuscule = bit spécial avec x, '
          'S/T majuscule = bit spécial sans x.');
    }
    return TrainingCheck(false, '$b\n\n$explain');
  }
}

// --- (2) Lecture de ls -l ----------------------------------------------------

/// Un compte : nom, uid, groupe principal, groupes secondaires.
class UnixAccount {
  const UnixAccount(this.name, this.uid, this.primary, this.supplementary);
  final String name;
  final int uid;
  final String primary;
  final List<String> supplementary;

  bool get isRoot => uid == 0;
  bool inGroup(String g) => primary == g || supplementary.contains(g);
  List<String> get allGroups => [primary, ...supplementary];
}

const _userNames = [
  'alice', 'bob', 'chloe', 'david', 'emma', 'farid', 'gael', 'ines', //
  'julien', 'lea',
];
const _sharedGroups = {
  'dev': 2001, 'compta': 2002, 'web': 2003, 'admins': 2004, 'projet': 2005, //
  'profs': 2006,
};

int _uidOf(String name) => name == 'root' ? 0 : 1001 + _userNames.indexOf(name);

int _gidOf(String group) =>
    _sharedGroups[group] ?? (group == 'root' ? 0 : _uidOf(group));

/// Sortie de « id nom » (locale C).
String idLine(UnixAccount a) {
  final groups = a.allGroups.map((g) => '${_gidOf(g)}($g)').join(',');
  return 'uid=${a.uid}(${a.name}) gid=${_gidOf(a.primary)}(${a.primary}) '
      'groups=$groups';
}

/// Une entrée de ls -l.
class LsEntry {
  const LsEntry(this.name, this.mode, this.owner, this.group,
      {required this.dir, this.size = 4096, this.date = 'Nov 26 09:15'});
  final String name;
  final int mode;
  final String owner;
  final String group;
  final bool dir;
  final int size;
  final String date;

  String get line =>
      '${lsMode(mode, dir: dir)} ${dir ? 2 : 1} ${owner.padRight(6)} '
      '${group.padRight(6)} ${size.toString().padLeft(5)} $date $name';
}

/// Classe retenue par le noyau pour [user] face à un fichier (root à part).
PermClass classFor(UnixAccount user, String owner, String group) {
  if (user.name == owner) return PermClass.owner;
  if (user.inGroup(group)) return PermClass.group;
  return PermClass.other;
}

enum AccessKind {
  read,
  write,
  exec,
  list,
  enter,
  create,
  deleteIn,
  readThrough,
  suidUser
}

const _questionText = {
  AccessKind.read: 'lire le contenu de ce fichier (cat)',
  AccessKind.write: 'modifier le contenu de ce fichier',
  AccessKind.exec: 'exécuter ce programme (binaire compilé)',
  AccessKind.list: 'lister les noms contenus dans ce dossier (ls)',
  AccessKind.enter: 'entrer dans ce dossier (cd)',
  AccessKind.create: 'créer un nouveau fichier dans ce dossier',
};

/// Bonne réponse d'une question de lecture, avec son explication pas à pas.
class AccessSolution {
  const AccessSolution(this.answer, this.explanation);
  final String answer;
  final String explanation;
}

class AccessExercise extends PermExercise {
  AccessExercise({
    required this.kind,
    required this.user,
    required this.target,
    this.parent,
  });

  final AccessKind kind;
  final UnixAccount user;

  /// Fichier ou dossier visé.
  final LsEntry target;

  /// Dossier qui contient [target] (questions deleteIn et readThrough).
  final LsEntry? parent;

  static const _root = UnixAccount('root', 0, 'root', []);

  static UnixAccount _account(TrainingRandom r, String name,
      {String? mustHave, Set<String> exclude = const {}}) {
    final candidates =
        _sharedGroups.keys.where((g) => !exclude.contains(g)).toList();
    final supp = <String>{};
    for (var i = r.nextInt(3); i > 0; i--) {
      supp.add(r.pick(candidates));
    }
    var primary = name;
    if (mustHave != null) {
      if (r.nextInt(4) == 0) {
        primary = mustHave; // groupe principal (gid)
      } else {
        supp.add(mustHave);
      }
    }
    supp.remove(primary);
    return UnixAccount(name, _uidOf(name), primary, supp.toList()..sort());
  }

  /// Tire l'utilisateur testé selon sa relation avec (owner, group).
  static UnixAccount _pickUser(TrainingRandom r, String owner, String group) {
    final roll = r.nextInt(100);
    final shared = _sharedGroups.containsKey(group);
    if (roll < 10) return _root;
    if (roll < 40 && owner != 'root') {
      // Le propriétaire, parfois aussi membre du groupe (piège classique).
      return _account(r, owner,
          mustHave: shared && r.nextBool() ? group : null,
          exclude: shared ? {} : {group});
    }
    final others = _userNames.where((n) => n != owner).toList();
    final name = r.pick(others);
    if (roll < 72 && shared) return _account(r, name, mustHave: group);
    return _account(r, name, exclude: {group});
  }

  static String _date(TrainingRandom r) {
    const months = ['Sep', 'Oct', 'Nov'];
    return '${r.pick(months)} ${r.range(1, 28).toString().padLeft(2)} '
        '${r.range(7, 22).toString().padLeft(2, '0')}:'
        '${r.range(0, 59).toString().padLeft(2, '0')}';
  }

  /// [propriétaire, groupe].
  static List<String> _ownerGroup(TrainingRandom r) {
    final owner = r.nextInt(8) == 0 ? 'root' : r.pick(_userNames);
    final group =
        r.nextInt(3) == 0 ? owner : r.pick(_sharedGroups.keys.toList());
    return [owner, group];
  }

  static int _withSpecial(TrainingRandom r, int perms, PermLevel level,
      {required bool dir}) {
    if (level != PermLevel.avance || r.nextInt(5) >= 2) return perms;
    return perms | (dir ? r.pick([kSgid, kSticky]) : r.pick([kSuid, kSgid]));
  }

  factory AccessExercise.generate(TrainingRandom r, PermLevel level) {
    final kinds = [
      AccessKind.read, AccessKind.write, AccessKind.exec, //
      AccessKind.list, AccessKind.enter, AccessKind.create,
      if (level == PermLevel.avance) ...[
        AccessKind.deleteIn, AccessKind.deleteIn, AccessKind.readThrough, //
        AccessKind.suidUser, AccessKind.suidUser,
      ],
    ];
    final kind = r.pick(kinds);
    final date = _date(r);
    switch (kind) {
      case AccessKind.read:
      case AccessKind.write:
      case AccessKind.exec:
      case AccessKind.list:
      case AccessKind.enter:
      case AccessKind.create:
        {
          final dir = kind.index >= AccessKind.list.index;
          final og = _ownerGroup(r);
          final owner = og[0], group = og[1];
          final user = _pickUser(r, owner, group);
          final perms =
              _withSpecial(r, r.nextInt(kPermBits + 1), level, dir: dir);
          final name = dir
              ? r.pick(['projets', 'partage', 'archives', 'notes', 'site'])
              : kind == AccessKind.exec
                  ? r.pick(['sauvegarde', 'outil', 'deploy', 'calcul', 'scan'])
                  : r.pick(
                      ['rapport.txt', 'notes.md', 'budget.ods', 'config.ini']);
          return AccessExercise(
            kind: kind,
            user: user,
            target: LsEntry(name, perms, owner, group,
                dir: dir, size: dir ? 4096 : r.range(80, 90000), date: date),
          );
        }
      case AccessKind.suidUser:
        {
          final og = _ownerGroup(r);
          final owner = og[0], group = og[1];
          final user = _pickUser(r, owner, group);
          var perms = r.nextInt(kPermBits + 1);
          // L'utilisateur doit pouvoir exécuter le programme.
          if (user.isRoot) {
            if ((perms & kAllX) == 0) perms |= 1 << (3 * r.nextInt(3));
          } else {
            perms |= 1 << _classShift[classFor(user, owner, group)]!;
          }
          final special =
              r.nextInt(4) == 0 ? 0 : r.pick([kSuid, kSuid, kSuid | kSgid]);
          return AccessExercise(
            kind: kind,
            user: user,
            target: LsEntry(r.pick(['outil', 'sauvegarde', 'scan', 'monitor']),
                perms | special, owner, group,
                dir: false, size: r.range(9000, 90000), date: date),
          );
        }
      case AccessKind.deleteIn:
      case AccessKind.readThrough:
        {
          final LsEntry parent;
          if (kind == AccessKind.deleteIn && r.nextInt(5) < 2) {
            parent = LsEntry('partage', octal('1777'), 'root', 'root',
                dir: true, date: date);
          } else {
            final og = _ownerGroup(r);
            final dOwner = og[0], dGroup = og[1];
            var dPerms = r.nextInt(kPermBits + 1);
            if (kind == AccessKind.deleteIn && r.nextBool()) dPerms |= kSticky;
            parent = LsEntry(r.pick(['commun', 'equipe', 'depot', 'docs']),
                dPerms, dOwner, dGroup,
                dir: true, date: date);
          }
          final user = _pickUser(r, parent.owner, parent.group);
          final fOwner =
              r.nextInt(5) < 2 && !user.isRoot ? user.name : r.pick(_userNames);
          final fGroup =
              r.nextBool() ? fOwner : r.pick(_sharedGroups.keys.toList());
          final file = LsEntry(r.pick(['notes.txt', 'plan.pdf', 'liste.csv']),
              r.nextInt(kPermBits + 1), fOwner, fGroup,
              dir: false, size: r.range(80, 90000), date: _date(r));
          return AccessExercise(
              kind: kind, user: user, target: file, parent: parent);
        }
    }
  }

  String get _path =>
      parent == null ? target.name : '${parent!.name}/${target.name}';

  @override
  String get instruction {
    final who = user.name;
    switch (kind) {
      case AccessKind.suidUser:
        return '$who lance ./${target.name}. Sous quel utilisateur effectif (euid) '
            'le processus tourne-t-il ? Réponds par un nom d\'utilisateur.';
      case AccessKind.deleteIn:
        return '$who peut-il supprimer $_path (rm $_path) ?';
      case AccessKind.readThrough:
        return '$who peut-il lire le contenu de $_path (cat $_path), en '
            'connaissant son nom ?';
      default:
        return '$who peut-il ${_questionText[kind]} ?';
    }
  }

  @override
  String? get code {
    final b = StringBuffer();
    if (parent != null) {
      b
        ..writeln('\$ ls -ld ${parent!.name}')
        ..writeln(parent!.line)
        ..writeln('\$ ls -l $_path')
        ..writeln(LsEntry(_path, target.mode, target.owner, target.group,
                dir: false, size: target.size, date: target.date)
            .line);
    } else {
      b
        ..writeln('\$ ls -l${target.dir ? 'd' : ''} ${target.name}')
        ..writeln(target.line);
    }
    b
      ..writeln('\$ id ${user.name}')
      ..write(idLine(user));
    return b.toString();
  }

  @override
  List<String> get labels =>
      [kind == AccessKind.suidUser ? 'Utilisateur effectif' : 'Réponse'];

  @override
  List<String> get hints =>
      [kind == AccessKind.suidUser ? 'ex. alice' : 'oui ou non'];

  @override
  List<String>? get choices =>
      kind == AccessKind.suidUser ? null : const ['oui', 'non'];

  /// Bonne réponse et explication pas à pas.
  AccessSolution solve() {
    final b = StringBuffer();
    b.writeln('1. Qui est ${user.name} ? ${idLine(user)}');
    if (kind == AccessKind.suidUser) return _solveSuid(b);
    if (kind == AccessKind.deleteIn) return _solveDelete(b);
    if (kind == AccessKind.readThrough) return _solveThrough(b);

    final t = target;
    final sym = permString(t.mode);
    if (user.isRoot) {
      final bool ok;
      if (kind == AccessKind.exec) {
        ok = (t.mode & kAllX) != 0;
        b.writeln(
            '2. root ne regarde pas les bits r et w, mais pour exécuter un '
            'fichier ordinaire il faut au moins un x quelque part.');
        b.writeln(
            '3. Droits $sym : ${ok ? 'au moins un x présent' : 'aucun x (S ou T '
                'majuscule ne comptent pas)'} -> ${ok ? 'oui' : 'non'}.');
      } else {
        ok = true;
        b.writeln(
            '2. root (uid 0) contourne les contrôles de lecture, d\'écriture '
            'et de traversée (CAP_DAC_OVERRIDE) : les bits ne comptent pas ici.');
        b.writeln('3. Donc oui.');
      }
      b.write('\n$kMemoRoot');
      return AccessSolution(ok ? 'oui' : 'non', b.toString());
    }

    final cls = classFor(user, t.owner, t.group);
    _writeClass(b, cls, t, step: 2);
    final tri = tripletOf(t.mode, cls);
    final triStr = sym.substring(cls.index * 3, cls.index * 3 + 3);
    final r = (tri & 4) != 0, w = (tri & 2) != 0, x = (tri & 1) != 0;
    final bool ok;
    switch (kind) {
      case AccessKind.read:
        ok = r;
        b.writeln('3. Lire un fichier demande r. Triplet $triStr : '
            '${r ? 'r présent' : 'pas de r'}.');
        break;
      case AccessKind.write:
        ok = w;
        b.writeln('3. Modifier un fichier demande w. Triplet $triStr : '
            '${w ? 'w présent' : 'pas de w'}.');
        b.writeln('   (Supprimer le fichier, en revanche, dépend des droits du '
            'dossier parent, pas de ceux du fichier.)');
        break;
      case AccessKind.exec:
        ok = x;
        b.writeln('3. Exécuter un binaire demande x. Triplet $triStr : '
            '${x ? 'x présent (x, s ou t minuscule)' : 'pas de x (-, S ou T majuscule)'}.');
        b.writeln(
            '   (Pour un script, il faudrait aussi r : l\'interpréteur doit '
            'le lire.)');
        break;
      case AccessKind.list:
        ok = r;
        b.writeln('3. Lister les noms d\'un dossier demande r sur le dossier. '
            'Triplet $triStr : ${r ? 'r présent' : 'pas de r'}.');
        if (r && !x) {
          b.writeln('   Sans x, ls affichera les noms mais pas leurs détails.');
        }
        break;
      case AccessKind.enter:
        ok = x;
        b.writeln('3. Entrer dans un dossier (cd) demande x, le droit de '
            'traverser. r ne suffit pas. Triplet $triStr : '
            '${x ? 'x présent' : 'pas de x'}.');
        break;
      default:
        ok = w && x;
        b.writeln(
            '3. Créer une entrée modifie le dossier : il faut w ET x sur le '
            'dossier. Triplet $triStr : w ${w ? 'présent' : 'absent'}, x '
            '${x ? 'présent' : 'absent'}.');
    }
    b.write('4. Donc ${ok ? 'oui' : 'non'}.');
    if (t.dir) b.write('\n\n$kMemoDirX');
    return AccessSolution(ok ? 'oui' : 'non', b.toString());
  }

  void _writeClass(StringBuffer b, PermClass cls, LsEntry e,
      {required int step}) {
    final sym = permString(e.mode);
    final tri = sym.substring(cls.index * 3, cls.index * 3 + 3);
    final String why;
    if (cls == PermClass.owner) {
      why = '${user.name} est le propriétaire (${e.owner})'
          '${user.inGroup(e.group) ? ', et aussi membre de ${e.group}, mais le '
              'propriétaire passe en premier : le triplet du groupe est ignoré' : ''}';
    } else if (cls == PermClass.group) {
      why = '${user.name} n\'est pas le propriétaire (${e.owner}) '
          'mais appartient au groupe ${e.group}'
          '${user.primary == e.group ? ' (c\'est son groupe principal, gid)' : ''}';
    } else {
      why = '${user.name} n\'est ni le propriétaire (${e.owner}) ni '
          'membre du groupe ${e.group}';
    }
    b.writeln('$step. Classe retenue pour ${e.name} : $why -> classe '
        '« ${_className[cls]} », triplet $tri (seul celui-ci compte).');
  }

  AccessSolution _solveSuid(StringBuffer b) {
    final t = target;
    final suid = (t.mode & kSuid) != 0;
    b.writeln('2. Droits ${lsMode(t.mode, dir: false)} : '
        '${suid ? 'un « s » ou « S » à la place du x du propriétaire = SUID.' : 'pas de s dans le triplet du propriétaire : pas de SUID.'}');
    if (suid) {
      b.writeln(
          '3. Avec SUID, execve() donne au processus l\'identité effective du '
          'PROPRIÉTAIRE du fichier (${t.owner}), quel que soit celui qui le lance'
          '${user.isRoot ? ', même root' : ''}. L\'uid réel reste ${user.name}.');
    } else {
      b.writeln('3. Sans SUID, le processus garde l\'identité de celui qui le '
          'lance : ${user.name}.');
    }
    if ((t.mode & kSgid) != 0) {
      b.writeln(
          '   SGID est aussi présent : le groupe effectif sera ${t.group}.');
    }
    b.write(
        'Note : Linux ignore SUID sur les scripts (#!) et sur un système de '
        'fichiers monté avec nosuid.');
    return AccessSolution(suid ? t.owner : user.name, b.toString());
  }

  AccessSolution _solveDelete(StringBuffer b) {
    final d = parent!;
    final sticky = (d.mode & kSticky) != 0;
    b.writeln('2. Supprimer une entrée modifie le DOSSIER ${d.name}, pas le '
        'fichier : les droits de ${target.name} ne comptent pas (rm demande '
        'seulement une confirmation s\'il est protégé en écriture).');
    if (user.isRoot) {
      b.write('3. root contourne les droits du dossier et le sticky bit '
          '(CAP_DAC_OVERRIDE, CAP_FOWNER) : oui.');
      return AccessSolution('oui', b.toString());
    }
    final cls = classFor(user, d.owner, d.group);
    _writeClass(b, cls, d, step: 3);
    final tri = tripletOf(d.mode, cls);
    final w = (tri & 2) != 0, x = (tri & 1) != 0;
    b.writeln(
        '4. Il faut w ET x sur le dossier : w ${w ? 'présent' : 'absent'}, '
        'x ${x ? 'présent' : 'absent'}.');
    var ok = w && x;
    if (sticky) {
      final mine = user.name == target.owner || user.name == d.owner;
      b.writeln(
          '5. Le dossier a le sticky bit (t ou T en dernière position) : il '
          'faut en plus être propriétaire du fichier (${target.owner}) ou du '
          'dossier (${d.owner}). ${user.name} : ${mine ? 'oui' : 'non'}.');
      ok = ok && mine;
    } else {
      b.writeln('5. Pas de sticky bit : quiconque a w et x sur le dossier peut '
          'supprimer n\'importe quel fichier dedans, même celui d\'un autre.');
    }
    b.write('Donc ${ok ? 'oui' : 'non'}.');
    return AccessSolution(ok ? 'oui' : 'non', b.toString());
  }

  AccessSolution _solveThrough(StringBuffer b) {
    final d = parent!;
    if (user.isRoot) {
      b.write('2. root contourne la traversée et la lecture : oui.');
      return AccessSolution('oui', b.toString());
    }
    final dc = classFor(user, d.owner, d.group);
    _writeClass(b, dc, d, step: 2);
    final dx = (tripletOf(d.mode, dc) & 1) != 0;
    b.writeln(
        '3. Atteindre ${target.name} par son chemin demande x (traverser) '
        'sur ${d.name} ; r sur le dossier n\'est pas nécessaire quand on connaît '
        'le nom. x ${dx ? 'présent' : 'absent'}.');
    final fc = classFor(user, target.owner, target.group);
    _writeClass(b, fc, target, step: 4);
    final fr = (tripletOf(target.mode, fc) & 4) != 0;
    b.writeln('5. Lire le fichier demande r sur le fichier : '
        '${fr ? 'présent' : 'absent'}.');
    final ok = dx && fr;
    b.write('Donc ${ok ? 'oui' : 'non'}.\n\n$kMemoDirX');
    return AccessSolution(ok ? 'oui' : 'non', b.toString());
  }

  @override
  List<String> get expected => [solve().answer];

  @override
  TrainingCheck check(List<String> answers) {
    final sol = solve();
    final good = sol.answer;
    final explanation = sol.explanation;
    final a = normalizeAnswer(answers.isEmpty ? '' : answers.first);
    if (kind == AccessKind.suidUser) {
      final ok = a == good ||
          (good == 'root' && a == '0') ||
          a == '${_uidOf(good)}' ||
          a == '${_uidOf(good)}($good)';
      return TrainingCheck(
          ok, '${ok ? '' : 'Réponse : $good.\n\n'}$explanation');
    }
    final bool? yes = const {'oui', 'o', 'yes', 'y'}.contains(a)
        ? true
        : (const {'non', 'n', 'no'}.contains(a) ? false : null);
    if (yes == null) {
      return TrainingCheck(false, 'Réponds par oui ou non.\n\n$explanation');
    }
    final ok = (yes ? 'oui' : 'non') == good;
    return TrainingCheck(ok, '${ok ? '' : 'Réponse : $good.\n\n'}$explanation');
  }
}

// --- (3) chmod de A vers B ---------------------------------------------------

class ChmodExercise extends PermExercise {
  ChmodExercise(this.from, this.to, {required this.dir, required this.name});

  final int from;
  final int to;
  final bool dir;
  final String name;

  factory ChmodExercise.generate(TrainingRandom r, PermLevel level) {
    final dir = r.nextInt(3) == 0;
    var from = _randomPerms(r);
    if (level == PermLevel.avance && r.nextBool()) {
      from |= dir
          ? r.pick([kSgid, kSticky, kSgid | kSticky])
          : r.pick([kSuid, kSgid]);
    }
    var to = from;
    while (to == from) {
      to = from;
      for (var n = r.range(1, 3); n > 0; n--) {
        to ^= 1 << r.nextInt(9);
      }
      if (level == PermLevel.avance && r.nextInt(3) > 0) {
        to ^= dir ? r.pick([kSgid, kSticky]) : r.pick([kSuid, kSgid]);
      }
    }
    final name = dir
        ? r.pick(['partage', 'depot', 'site', 'equipe'])
        : r.pick(['script.sh', 'rapport.txt', 'outil', 'cles.pem']);
    return ChmodExercise(from, to, dir: dir, name: name);
  }

  @override
  String get instruction => 'Donne une commande chmod qui fait passer '
      '${dir ? 'ce dossier' : 'ce fichier'} de ${lsMode(from, dir: dir)} à '
      '${lsMode(to, dir: dir)}. Octal ou symbolique : les deux sont acceptés si le '
      'résultat est identique (comportement de GNU chmod sous Linux).';

  @override
  String? get code => '\$ ls -l${dir ? 'd' : ''} $name\n'
      '${LsEntry(name, from, 'alice', 'dev', dir: dir, size: dir ? 4096 : 1532).line}\n'
      'Objectif : ${lsMode(to, dir: dir)}';

  @override
  List<String> get labels => ['Commande'];

  @override
  List<String> get hints => ['ex. chmod u+x,g-w $name'];

  /// Mode octal qui donne exactement [to] (5 chiffres si GNU garderait SUID/SGID).
  String get octalAnswer {
    final lost = dir && (from & (kSuid | kSgid) & ~to) != 0;
    return lost ? toOctal(to, 5) : naturalOctal(to);
  }

  /// Mode symbolique minimal : ajouts et retraits classe par classe.
  String get symbolicAnswer {
    final clauses = <String>[];
    for (final c in PermClass.values) {
      String letters(int bits) {
        final t = (bits >> _classShift[c]!) & 7;
        return '${(t & 4) != 0 ? 'r' : ''}${(t & 2) != 0 ? 'w' : ''}'
            '${(t & 1) != 0 ? 'x' : ''}'
            '${(bits & _classSpecial[c]!) != 0 ? (c == PermClass.other ? 't' : 's') : ''}';
      }

      final mask = (7 << _classShift[c]!) | _classSpecial[c]!;
      final add = letters(to & ~from & mask);
      final rem = letters(from & ~to & mask);
      if (add.isEmpty && rem.isEmpty) continue;
      clauses.add('${_classLetter[c]}${add.isEmpty ? '' : '+$add'}'
          '${rem.isEmpty ? '' : '-$rem'}');
    }
    return clauses.join(',');
  }

  @override
  List<String> get expected => ['chmod $octalAnswer $name'];

  @override
  TrainingCheck check(List<String> answers) {
    final raw = answers.isEmpty ? '' : answers.first;
    final res = evaluateChmodCommand(raw, from, dir: dir);
    final method = _methodText();
    if (res.error != null) {
      return TrainingCheck(false, '${res.error}\n\n$method');
    }
    if (res.result == null) {
      return TrainingCheck(false, '${res.umaskNote}\n\n$method');
    }
    final got = res.result!;
    if (got == to) {
      return TrainingCheck(true,
          'chmod ${res.mode} donne bien ${lsMode(got, dir: dir)}.\n\n$method');
    }
    return TrainingCheck(
        false,
        'chmod ${res.mode} donne ${lsMode(got, dir: dir)} '
        '(${naturalOctal(got)}), et non ${lsMode(to, dir: dir)} '
        '(${naturalOctal(to)}).\n\n$method');
  }

  String _methodText() {
    final sym = permString(to);
    final symFrom = permString(from);
    final b = StringBuffer()
      ..writeln(
          'Méthode octale : un nombre fixe TOUS les droits, quel que soit '
          'l\'état de départ. Convertis la cible :');
    for (final c in PermClass.values) {
      final tri = sym.substring(c.index * 3, c.index * 3 + 3);
      final t = tripletOf(to, c);
      b.writeln('- ${_className[c]} $tri = ${_rwxParts(t)} = $t');
    }
    final sp = (to >> 9) & 7;
    if (sp != 0) b.writeln('- bits spéciaux = $sp, placé devant');
    b.writeln('-> chmod $octalAnswer $name');
    if (octalAnswer.length == 5) {
      b.writeln(
          'Piège GNU : sur un dossier, chmod ${naturalOctal(to)} GARDE les '
          'bits SUID/SGID déjà présents (choix de coreutils pour les dossiers '
          'partagés). Pour les retirer en octal, il faut 5 chiffres '
          '(${toOctal(to, 5)}) ou =${naturalOctal(to)} ; en symbolique, g-s ou u-s.');
    }
    b
      ..writeln()
      ..writeln(
          'Méthode symbolique : compare classe par classe ce qui change.');
    for (final c in PermClass.values) {
      final i = c.index * 3;
      final a = symFrom.substring(i, i + 3), z = sym.substring(i, i + 3);
      b.writeln('- ${_className[c]} (${_classLetter[c]}) : $a -> $z'
          '${a == z ? ', inchangé' : ''}');
    }
    b.write('-> chmod $symbolicAnswer $name\n'
        'Rappel : u = propriétaire, g = groupe, o = autres, a = tous ; '
        '+ ajoute, - retire, = remplace ; s sur u = SUID, s sur g = SGID, '
        't sur o = sticky.');
    return b.toString();
  }
}

// --- (4) umask ---------------------------------------------------------------

class UmaskExercise extends PermExercise {
  UmaskExercise(this.umask, {required this.reverse});

  /// umask sur 9 bits.
  final int umask;

  /// true : on donne les droits obtenus, on demande le umask.
  final bool reverse;

  static const _common = [
    '022',
    '002',
    '077',
    '027',
    '007',
    '037',
    '026',
    '033',
    '011',
    '066',
  ];

  factory UmaskExercise.generate(TrainingRandom r, PermLevel level) {
    if (level == PermLevel.debutant) {
      return UmaskExercise(octal(r.pick(_common)), reverse: false);
    }
    final u = r.nextBool() ? octal(r.pick(_common)) : r.nextInt(kPermBits + 1);
    return UmaskExercise(u, reverse: r.nextBool());
  }

  int get fileMode => 0x1B6 & ~umask; // 0666
  int get dirMode => kPermBits & ~umask; // 0777

  @override
  String get instruction => reverse
      ? 'Après avoir réglé le umask, un nouveau fichier (touch) et un nouveau '
          'dossier (mkdir) ont les droits ci-dessous. Quel est le umask ?'
      : 'Avec ce umask, quels droits auront un nouveau fichier (touch) et un '
          'nouveau dossier (mkdir) ? Octal ou symbolique.';

  @override
  String? get code => reverse
      ? '\$ touch f && mkdir d && ls -ld f d\n'
          '${LsEntry('d', dirMode, 'alice', 'alice', dir: true).line}\n'
          '${LsEntry('f', fileMode, 'alice', 'alice', dir: false, size: 0).line}'
      : '\$ umask ${toOctal(umask, 4)}';

  @override
  List<String> get labels =>
      reverse ? ['umask'] : ['Nouveau fichier', 'Nouveau dossier'];

  @override
  List<String> get hints => reverse
      ? ['ex. 022 ou u=rwx,g=rx,o=rx']
      : ['ex. 644 ou rw-r--r--', 'ex. 755 ou rwxr-xr-x'];

  @override
  List<String> get expected =>
      reverse ? [toOctal(umask, 4)] : [toOctal(fileMode), toOctal(dirMode)];

  String _digitLine(String what, int base, int result) {
    final b =
        StringBuffer('$what : base ${toOctal(base)} (${permString(base)}), '
            'umask ${toOctal(umask)} (${permString(umask)})\n');
    for (final c in PermClass.values) {
      final bt = tripletOf(base, c),
          ut = tripletOf(umask, c),
          rt = tripletOf(result, c);
      b.writeln('  - ${_className[c]} : $bt ET NON $ut = $rt '
          '(${permString(bt << 6).substring(0, 3)} moins les bits de '
          '${permString(ut << 6).substring(0, 3)} = ${permString(rt << 6).substring(0, 3)})');
    }
    b.write('  -> ${toOctal(result)} (${permString(result)})');
    return b.toString();
  }

  String _explanation() {
    final b = StringBuffer();
    if (reverse) {
      b
        ..writeln(
            'Méthode : un dossier part de 777 (tous les bits). Chaque bit '
            'absent du dossier créé a donc été retiré par le umask : umask = '
            'complément des droits du dossier, soit 7 moins chaque chiffre.')
        ..writeln(
            '- dossier ${permString(dirMode)} = ${toOctal(dirMode)} -> umask '
            '${[
          for (final c in PermClass.values) '7-${tripletOf(dirMode, c)}'
        ].join(', ')} '
            '= ${toOctal(umask)}')
        ..writeln('Vérification sur le fichier (base 666) :')
        ..writeln(_digitLine('fichier', 0x1B6, fileMode))
        ..writeln(
            'Le fichier seul ne suffirait pas : il ne dit rien des bits x du '
            'umask, puisque 666 n\'a jamais de x.')
        ..write('En symbolique : umask -S affiche ce qui est GARDÉ : '
            '${_umaskSymbolic(umask)}.');
    } else {
      b
        ..writeln(
            'Méthode : base 666 pour un fichier (jamais de x à la création), '
            '777 pour un dossier ; on retire les bits du umask (ET NON), triplet '
            'par triplet.')
        ..writeln(_digitLine('Fichier', 0x1B6, fileMode))
        ..writeln(_digitLine('Dossier', kPermBits, dirMode));
      if (fileMode != (0x1B6 - umask)) {
        b.writeln('Attention : 666 - ${toOctal(umask)} = '
            '${(0x1B6 - umask) >= 0 ? toOctal(0x1B6 - umask) : 'négatif'} serait '
            'faux ; un bit déjà absent de la base ne peut pas être retiré une '
            'seconde fois.');
      }
      b.write(
          'Le x n\'apparaît jamais sur un fichier créé : il faut un chmod +x '
          'ensuite. Certains programmes demandent moins que 666 (ssh-keygen, mktemp '
          'créent en 600) : le umask ne fait que retirer, jamais ajouter.');
    }
    return b.toString();
  }

  static String _umaskSymbolic(int u) {
    final kept = kPermBits & ~u;
    return PermClass.values.map((c) {
      final t = tripletOf(kept, c);
      return '${_classLetter[c]}=${(t & 4) != 0 ? 'r' : ''}${(t & 2) != 0 ? 'w' : ''}'
          '${(t & 1) != 0 ? 'x' : ''}';
    }).join(',');
  }

  /// Lit un umask : octal (« 027 », « 0027 », « umask 027 ») ou symbolique
  /// complet (« u=rwx,g=rx,o= ») comme l'affiche umask -S.
  static int? parseUmask(String raw) {
    final tokens =
        raw.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isNotEmpty && tokens.first == 'umask') tokens.removeAt(0);
    if (tokens.isNotEmpty && tokens.first == '-S') tokens.removeAt(0);
    final s = tokens.join();
    if (RegExp(r'^[0-7]{1,4}$').hasMatch(s)) {
      final v = int.parse(s, radix: 8);
      return v > kPermBits ? null : v;
    }
    var kept = 0;
    var seen = 0;
    for (final clause in s.split(',')) {
      final m = RegExp(r'^([ugoa]+)=([rwx]*)$').firstMatch(clause);
      if (m == null) return null;
      var who = 0;
      for (final ch in m.group(1)!.split('')) {
        who |= const {'u': 0x1C0, 'g': 0x38, 'o': 0x7, 'a': kPermBits}[ch]!;
      }
      var bits = 0;
      for (final ch in m.group(2)!.split('')) {
        bits |= const {'r': kAllR, 'w': kAllW, 'x': kAllX}[ch]!;
      }
      kept = (kept & ~who) | (bits & who);
      seen |= who;
    }
    if (seen != kPermBits) return null;
    return kPermBits & ~kept;
  }

  @override
  TrainingCheck check(List<String> answers) {
    final explain = _explanation();
    if (reverse) {
      final v = parseUmask(answers.isEmpty ? '' : answers.first);
      if (v == null) {
        return TrainingCheck(
            false,
            'Réponse attendue : un umask en octal (ex. 027) ou au format de '
            'umask -S (ex. u=rwx,g=rx,o=).\n\n$explain');
      }
      final ok = v == umask;
      return TrainingCheck(
          ok,
          ok
              ? explain
              : 'Le umask ${toOctal(v)} donnerait un fichier '
                  '${permString(0x1B6 & ~v)} et un dossier '
                  '${permString(kPermBits & ~v)}. Attendu : ${toOctal(umask)}.\n\n$explain');
    }
    final f = answers.isNotEmpty ? parsePermAnswer(answers[0]) : null;
    final d = answers.length > 1 ? parsePermAnswer(answers[1]) : null;
    final fileOk = f == fileMode;
    final dirOk = d == dirMode;
    if (fileOk && dirOk) return TrainingCheck(true, explain);
    final b = StringBuffer();
    if (!fileOk) {
      b.writeln(
          'Fichier : attendu ${toOctal(fileMode)} (${permString(fileMode)})'
          '${f == null ? ', réponse illisible' : ', tu as donné ${naturalOctal(f)}'}.');
    }
    if (!dirOk) {
      b.writeln('Dossier : attendu ${toOctal(dirMode)} (${permString(dirMode)})'
          '${d == null ? ', réponse illisible' : ', tu as donné ${naturalOctal(d)}'}.');
    }
    return TrainingCheck(false, '$b\n$explain');
  }
}

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

/// Entraînement « Droits Linux (chmod, umask) ».
class PermissionsTrainer extends StatefulWidget {
  const PermissionsTrainer({super.key});

  @override
  State<PermissionsTrainer> createState() => _PermissionsTrainerState();
}

class _PermissionsTrainerState extends State<PermissionsTrainer> {
  final _random = TrainingRandom();
  final _controllers = [TextEditingController(), TextEditingController()];
  PermExerciseMode _mode = PermExerciseMode.conversion;
  PermLevel _level = PermLevel.debutant;
  late PermExercise _exercise;
  TrainingCheck? _result;
  String? _choice;
  int _score = 0;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _exercise = generatePermExercise(_random, _mode, _level);
    // Le bouton Vérifier s'active dès qu'une réponse est saisie.
    for (final c in _controllers) {
      c.addListener(_onTyped);
    }
  }

  void _onTyped() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    for (final c in _controllers) {
      c.clear();
    }
    setState(() {
      _exercise = generatePermExercise(_random, _mode, _level);
      _result = null;
      _choice = null;
    });
  }

  List<String> get _answers => _exercise.choices != null
      ? [_choice ?? '']
      : [
          for (var i = 0; i < _exercise.labels.length; i++) _controllers[i].text
        ];

  bool get _canCheck =>
      _result == null && _answers.any((a) => a.trim().isNotEmpty);

  void _check() {
    if (!_canCheck) return;
    final res = _exercise.check(_answers);
    setState(() {
      _result = res;
      _attempts++;
      if (res.correct) _score++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ex = _exercise;
    return TrainingFrame(
      title: 'Droits Linux',
      subtitle: 'chmod, umask, ls -l, SUID, SGID, sticky bit',
      icon: Icons.lock_outline,
      instruction: ex.instruction,
      score: _score,
      attempts: _attempts,
      result: _result,
      onNext: _next,
      onCheck: _canCheck ? _check : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _selectors(),
          const SizedBox(height: 16),
          if (ex.code != null) ...[
            TrainingCode(ex.code!),
            const SizedBox(height: 16),
          ],
          if (ex.choices != null)
            Wrap(
              spacing: 10,
              children: [
                for (final c in ex.choices!)
                  ChoiceChip(
                    label: Text(c == 'oui' ? 'Oui' : 'Non'),
                    selected: _choice == c,
                    onSelected: _result != null
                        ? null
                        : (_) => setState(() => _choice = c),
                    selectedColor: TdcColors.accentDim,
                    labelStyle: const TextStyle(color: TdcColors.textPrimary),
                    side: const BorderSide(color: TdcColors.border),
                  ),
              ],
            )
          else
            for (var i = 0; i < ex.labels.length; i++)
              TrainingField(
                label: ex.labels[i],
                hint: ex.hints[i],
                controller: _controllers[i],
                onSubmitted: (_) => _check(),
                state: _result?.correct,
              ),
          if (_result != null && !_result!.correct) ...[
            const SizedBox(height: 8),
            Text('Une bonne réponse : ${ex.expected.join('  /  ')}',
                style: const TextStyle(
                    color: TdcColors.textSecondary, fontFamily: 'monospace')),
          ],
          const SizedBox(height: 12),
          const _Memo(),
          const SizedBox(height: 8),
          const PermissionCalculator(),
        ],
      ),
    );
  }

  Widget _selectors() {
    Widget chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: TdcColors.accentDim,
          labelStyle: TextStyle(
              color: selected ? TdcColors.accent : TdcColors.textSecondary),
          side: const BorderSide(color: TdcColors.border),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in PermExerciseMode.values)
            chip(permModeLabels[m]!, _mode == m, () {
              _mode = m;
              _next();
            }),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          chip('Débutant', _level == PermLevel.debutant, () {
            _level = PermLevel.debutant;
            _next();
          }),
          chip('Avancé (SUID, SGID, sticky)', _level == PermLevel.avance, () {
            _level = PermLevel.avance;
            _next();
          }),
        ]),
      ],
    );
  }
}

/// Aide-mémoire repliable.
class _Memo extends StatelessWidget {
  const _Memo();

  @override
  Widget build(BuildContext context) {
    Widget section(String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: TdcColors.accent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              SelectableText(body,
                  style: const TextStyle(
                      color: TdcColors.textPrimary, height: 1.5, fontSize: 13)),
            ],
          ),
        );
    return Material(
      color: TdcColors.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: TdcColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: const Text('Aide-mémoire',
            style: TextStyle(color: TdcColors.textPrimary, fontSize: 14)),
        iconColor: TdcColors.accent,
        collapsedIconColor: TdcColors.textSecondary,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          section('Quelle classe ?', kMemoClass),
          section('Le x sur un dossier', kMemoDirX),
          section('root', kMemoRoot),
          section('Bits spéciaux', kMemoSpecial),
          section('umask', kMemoUmask),
        ],
      ),
    );
  }
}

/// Calculatrice libre : cocher les bits, ou saisir un mode, et voir les deux écritures.
class PermissionCalculator extends StatefulWidget {
  const PermissionCalculator({super.key});

  @override
  State<PermissionCalculator> createState() => _PermissionCalculatorState();
}

class _PermissionCalculatorState extends State<PermissionCalculator> {
  int _mode = 0x1ED; // 0755
  bool _dir = false;
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _load(String s) {
    final v = parsePermAnswer(s);
    if (v != null) setState(() => _mode = v);
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: TdcColors.textSecondary, fontSize: 12);
    Widget bit(int mask, String label) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: (_mode & mask) != 0,
              onChanged: (v) =>
                  setState(() => _mode = v! ? _mode | mask : _mode & ~mask),
              activeColor: TdcColors.accent,
              checkColor: TdcColors.bg,
              side: const BorderSide(color: TdcColors.textMuted),
            ),
            Text(label, style: style),
          ],
        );
    final row = <Widget>[];
    for (final c in PermClass.values) {
      final s = _classShift[c]!;
      row.add(Container(
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            border: Border.all(color: TdcColors.border),
            borderRadius: BorderRadius.circular(6)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_className[c]!, style: style),
          Row(mainAxisSize: MainAxisSize.min, children: [
            bit(4 << s, 'r'),
            bit(2 << s, 'w'),
            bit(1 << s, 'x'),
            bit(
                _classSpecial[c]!,
                c == PermClass.owner
                    ? 'SUID'
                    : c == PermClass.group
                        ? 'SGID'
                        : 'sticky'),
          ]),
        ]),
      ));
    }
    return Material(
      color: TdcColors.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: TdcColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: const Text('Calculatrice de droits',
            style: TextStyle(color: TdcColors.textPrimary, fontSize: 14)),
        iconColor: TdcColors.accent,
        collapsedIconColor: TdcColors.textSecondary,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(children: row),
          Row(children: [
            Checkbox(
              value: _dir,
              onChanged: (v) => setState(() => _dir = v!),
              activeColor: TdcColors.accent,
              checkColor: TdcColors.bg,
              side: const BorderSide(color: TdcColors.textMuted),
            ),
            const Text('Dossier', style: style),
          ]),
          TrainingField(
            label: 'Saisir un mode (octal ou rwx)',
            hint: 'ex. 2775 ou rwxr-sr-x',
            controller: _input,
            onSubmitted: _load,
          ),
          TrainingCode(
              '${lsMode(_mode, dir: _dir)}   =   ${naturalOctal(_mode)}\n'
              'chmod ${naturalOctal(_mode)} ${_dir ? 'dossier' : 'fichier'}'),
        ],
      ),
    );
  }
}
