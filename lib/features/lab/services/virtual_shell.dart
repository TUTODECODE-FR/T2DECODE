// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'dart:convert';
import 'dart:math';

import 'package:tutodecode/features/training/permissions_trainer.dart';

const String _pts0 = 'pts/0';

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}

class VirtualFileSystem {
  late _FSNode _root;

  VirtualFileSystem() {
    _init();
  }

  void resetToDefaultState() {
    _init();
  }

  void _init() {
    _root = _FSNode.directory('');
    _mkdirp('/bin');
    _mkdirp('/etc');
    _mkdirp('/home');
    _mkdirp('/home/admin');
    _mkdirp('/home/admin/Desktop');
    _mkdirp('/home/admin/Documents');
    _mkdirp('/home/admin/Downloads');
    _mkdirp('/home/admin/.ssh');
    _mkdirp('/root');
    _mkdirp('/tmp');
    _mkdirp('/var');
    _mkdirp('/var/log');
    _mkdirp('/usr');
    _mkdirp('/usr/bin');
    _mkdirp('/usr/local');
    _mkdirp('/usr/local/bin');
    _mkdirp('/dev');
    _mkdirp('/proc');
    _mkdirp('/sys');
    _mkdirp('/opt');

    _writeFile('/etc/hostname', 't2decode');
    _writeFile(
        '/etc/passwd',
        'root:x:0:0:root:/root:/bin/bash\n'
            'admin:x:1000:1000:admin:/home/admin:/bin/bash\n'
            'nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin');
    _writeFile('/etc/shadow',
        'root:!:19000:0:99999:7:::\nadmin:\$6\$rounds=...:19000:0:99999:7:::');
    _writeFile('/etc/group', 'root:x:0:\nadmin:x:1000:admin\nsudo:x:27:admin');
    _writeFile('/etc/os-release',
        'NAME="T2DECODE Linux"\nVERSION="1.0"\nID=t2decode\nPRETTY_NAME="T2DECODE Linux 1.0"');
    _writeFile('/etc/resolv.conf', 'nameserver 8.8.8.8\nnameserver 1.1.1.1');
    _writeFile('/etc/hosts',
        '127.0.0.1\tlocalhost\n127.0.1.1\tt2decode\n::1\tlocalhost');
    _writeFile('/etc/fstab',
        '/dev/sda1  /     ext4  defaults  0 1\n/dev/sda2  /home ext4  defaults  0 2');
    _writeFile('/etc/crontab',
        '# m h dom mon dow user command\n*/5 * * * * root /usr/bin/apt-get update');
    _writeFile('/home/admin/.bashrc',
        '# ~/.bashrc\nexport PATH="/usr/local/bin:/usr/bin:/bin"\nexport EDITOR=nano\nalias ll="ls -la"');
    _writeFile('/home/admin/.ssh/authorized_keys', '# Aucune clé configurée');
    _writeFile('/home/admin/Documents/notes.txt',
        'Bienvenue dans T2DECODE.\nCe fichier est un exemple.');
    _writeFile('/home/admin/Documents/readme.md',
        '# T2DECODE\nPlateforme pédagogique offline.');
    _writeFile(
        '/var/log/syslog',
        'Jun 12 08:00:01 t2decode CRON[1234]: (root) CMD (apt-get update)\n'
            'Jun 12 08:01:12 t2decode sshd[5678]: Accepted publickey for admin\n'
            'Jun 12 08:05:33 t2decode kernel: [UFW BLOCK] IN=eth0 OUT= SRC=10.0.0.5 DST=192.168.1.10');
    _writeFile(
        '/var/log/auth.log',
        'Jun 12 07:55:00 t2decode sshd[4321]: Failed password for root from 10.0.0.99\n'
            'Jun 12 08:01:12 t2decode sshd[5678]: Accepted publickey for admin from 192.168.1.5');
    _writeFile('/proc/cpuinfo',
        'processor\t: 0\nmodel name\t: T2C vCPU @ 2.4GHz\ncpu cores\t: 4');
    _writeFile('/proc/meminfo',
        'MemTotal:       8192000 kB\nMemFree:        4096000 kB\nMemAvailable:   5120000 kB');
    _writeFile('/proc/version',
        'Linux version 6.1.0-t2c (gcc 12.2) #1 SMP PREEMPT_DYNAMIC');

    for (final cmd in [
      'bash',
      'ls',
      'cat',
      'cp',
      'mv',
      'rm',
      'grep',
      'find',
      'chmod',
      'chown',
      'mkdir',
      'touch',
      'echo',
      'ps',
      'kill',
      'ping',
      'ip',
      'ss',
      'curl',
      'wget',
      'ssh',
      'scp',
      'tar',
      'gzip',
      'nano',
      'vim',
      'head',
      'tail',
      'wc',
      'sort',
      'uniq',
      'cut',
      'awk',
      'sed'
    ]) {
      _writeFile('/usr/bin/$cmd', 'ELF binary');
    }
  }

  _FSNode? _getNode(String path) {
    if (path == '/' || path.isEmpty) return _root;
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    _FSNode current = _root;
    for (final part in parts) {
      if (!current.isDirectory) return null;
      if (!current.children!.containsKey(part)) return null;
      current = current.children![part]!;
    }
    return current;
  }

  void _mkdirp(String path) {
    if (path == '/' || path.isEmpty) return;
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    _FSNode current = _root;
    for (final part in parts) {
      if (!current.children!.containsKey(part)) {
        final node = _FSNode.directory(part)..parent = current;
        current.children![part] = node;
      }
      current = current.children![part]!;
    }
  }

  void _writeFile(String path, String content) {
    if (path == '/' || path.isEmpty) return;
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    final name = parts.removeLast();
    _FSNode current = _root;
    for (final part in parts) {
      if (!current.children!.containsKey(part)) {
        current.children![part] = _FSNode.directory(part)..parent = current;
      }
      current = current.children![part]!;
    }
    final existing = current.children![name];
    if (existing != null && existing.isFile) {
      // Réécrire un fichier existant garde ses droits (comme sous Linux).
      existing.content = content;
      return;
    }
    current.children![name] = _FSNode.file(name, content)..parent = current;
  }

  /// Droits (mode octal, ex. 0644 = 420) d'un fichier ou dossier, null s'il n'existe pas.
  int? permissions(String path) => _getNode(path)?.permissions;

  /// Change les droits d'un fichier ou dossier existant (bits 07777).
  void setPermissions(String path, int mode) {
    final node = _getNode(path);
    if (node != null) node.permissions = mode & 0xFFF;
  }

  /// Copie récursive de [from] vers [to] (les dossiers parents de [to] doivent exister).
  /// Renvoie false si la source ou le dossier parent de la destination est introuvable.
  bool copy(String from, String to) {
    final src = _getNode(from);
    if (src == null || src == _root) return false;
    final toParts = to.split('/').where((p) => p.isNotEmpty).toList();
    if (toParts.isEmpty) return false;
    final toName = toParts.removeLast();
    final parent = _getNode('/${toParts.join('/')}');
    if (parent == null || !parent.isDirectory) return false;
    final existing = parent.children![toName];
    if (existing != null && existing.isFile && src.isFile) {
      existing.content = src.content;
      return true;
    }
    parent.children![toName] = src.clone(toName)..parent = parent;
    return true;
  }

  /// Crée [path] et ses dossiers parents (mkdir -p). Faux si un élément est un fichier.
  bool mkdirp(String path) {
    _FSNode current = _root;
    for (final part in path.split('/').where((p) => p.isNotEmpty)) {
      final child = current.children![part];
      if (child == null) {
        final node = _FSNode.directory(part)..parent = current;
        current.children![part] = node;
        current = node;
      } else if (child.isFile) {
        return false;
      } else {
        current = child;
      }
    }
    return true;
  }

  /// Représentation façon « ls -l » : -rw-r--r--, drwxr-x---, -rwsr-xr-x…
  static String modeString(int mode, {bool isDir = false}) {
    final b = StringBuffer(isDir ? 'd' : '-');
    const letters = 'rwx';
    const special = [0x800, 0x400, 0x200];
    for (var k = 0; k < 3; k++) {
      final shift = 6 - 3 * k;
      for (var j = 0; j < 3; j++) {
        final set = mode & (1 << (shift + 2 - j)) != 0;
        if (j == 2 && mode & special[k] != 0) {
          final c = k == 2 ? 't' : 's';
          b.write(set ? c : c.toUpperCase());
        } else {
          b.write(set ? letters[j] : '-');
        }
      }
    }
    return b.toString();
  }

  /// Applique un mode chmod à [current] : octal ou symbolique, avec la même
  /// simulation que l'entraînement « Droits Linux » (GNU coreutils / gnulib).
  /// Renvoie null si le mode est invalide.
  static int? applyMode(String spec, int current,
          {required bool isDir, int umask = 0x12}) =>
      applyChmod(current, spec, dir: isDir, umask: umask);

  bool exists(String path) => _getNode(path) != null;
  bool isDir(String path) => _getNode(path)?.isDirectory ?? false;
  bool isFile(String path) => _getNode(path)?.isFile ?? false;

  String? readFile(String path) => _getNode(path)?.content;

  void write(String path, String content) {
    _writeFile(path, content);
  }

  void mkdir(String path) {
    if (path == '/' || path.isEmpty) return;
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    final name = parts.removeLast();
    final parentPath = parts.isEmpty ? '/' : '/${parts.join('/')}';
    final parent = _getNode(parentPath);
    if (parent != null && parent.isDirectory) {
      parent.children![name] = _FSNode.directory(name)..parent = parent;
    }
  }

  void delete(String path) {
    if (path == '/' || path.isEmpty) return;
    final node = _getNode(path);
    if (node != null && node.parent != null) {
      node.parent!.children!.remove(node.name);
    }
  }

  void rename(String from, String to) {
    if (from == '/' || from.isEmpty || to == '/' || to.isEmpty) return;
    final fromNode = _getNode(from);
    if (fromNode == null || fromNode == _root) return;

    final fromParent = fromNode.parent!;

    final toParts = to.split('/').where((p) => p.isNotEmpty).toList();
    final toName = toParts.removeLast();

    _FSNode toParent = _root;
    for (final part in toParts) {
      if (!toParent.children!.containsKey(part)) {
        toParent.children![part] = _FSNode.directory(part)..parent = toParent;
      }
      toParent = toParent.children![part]!;
    }

    fromParent.children!.remove(fromNode.name);
    fromNode.name = toName;
    fromNode.parent = toParent;
    toParent.children![toName] = fromNode;
  }

  List<String> listDir(String path) {
    final node = _getNode(path);
    if (node == null || !node.isDirectory) return [];
    return node.children!.keys.toList()..sort();
  }

  void _addFindResultIfMatches(_FSNode node, String? name, List<String> results,
      String? type, bool ignoreCase) {
    if (node == _root && name != null) return;
    if (type == 'f' && !node.isFile) return;
    if (type == 'd' && !node.isDirectory) return;
    if (name == null || globMatch(name, node.name, ignoreCase: ignoreCase)) {
      results.add(node.fullPath);
    }
  }

  void _traverseFind(_FSNode node, String? name, List<String> results,
      String? type, bool ignoreCase) {
    _addFindResultIfMatches(node, name, results, type, ignoreCase);
    if (node.isDirectory) {
      for (final child in node.children!.values) {
        _traverseFind(child, name, results, type, ignoreCase);
      }
    }
  }

  /// [type] : 'f' (fichiers) ou 'd' (dossiers) ; null = tout.
  List<String> find(String startPath,
      {String? name, String? type, bool ignoreCase = false}) {
    final results = <String>[];
    final startNode = _getNode(startPath);
    if (startNode == null) return results;

    _traverseFind(startNode, name, results, type, ignoreCase);
    return results..sort();
  }

  /// Motif du shell (* ? [abc]) appliqué à un nom complet.
  static bool globMatch(String pattern, String text,
      {bool ignoreCase = false}) {
    final b = StringBuffer('^');
    for (var i = 0; i < pattern.length; i++) {
      final c = pattern[i];
      if (c == '*') {
        b.write('.*');
      } else if (c == '?') {
        b.write('.');
      } else if (c == '[') {
        final end = i + 2 <= pattern.length ? pattern.indexOf(']', i + 2) : -1;
        if (end < 0) {
          b.write(r'\[');
        } else {
          var set = pattern.substring(i + 1, end);
          if (set.startsWith('!')) set = '^${set.substring(1)}';
          b.write('[${set.replaceAll(r'\', r'\\')}]');
          i = end;
        }
      } else {
        b.write(RegExp.escape(c));
      }
    }
    b.write(r'$');
    try {
      return RegExp(b.toString(), caseSensitive: !ignoreCase).hasMatch(text);
    } on FormatException {
      return false;
    }
  }

  void _collectGrepTargets(
      _FSNode node, bool recursive, List<_FSNode> targets) {
    if (node.isFile) {
      targets.add(node);
    } else if (node.isDirectory && recursive) {
      for (final child in node.children!.values) {
        _collectGrepTargets(child, recursive, targets);
      }
    }
  }

  void _searchInTargets(List<_FSNode> targets, RegExp regex, bool recursive,
      List<String> results) {
    for (final t in targets) {
      final content = t.content ?? '';
      final lines = content.split('\n');
      for (int i = 0; i < lines.length; i++) {
        if (regex.hasMatch(lines[i])) {
          results.add(recursive
              ? '${t.fullPath}:${i + 1}:${lines[i]}'
              : '${i + 1}:${lines[i]}');
        }
      }
    }
  }

  List<String> grep(String pattern, String path, {bool recursive = false}) {
    final results = <String>[];
    final startNode = _getNode(path);
    if (startNode == null) return results;

    final targets = <_FSNode>[];
    _collectGrepTargets(startNode, recursive, targets);

    final RegExp regex;
    try {
      regex = RegExp(pattern, caseSensitive: true);
    } on FormatException catch (e) {
      throw FormatException('grep: invalid regular expression: ${e.message}');
    }

    _searchInTargets(targets, regex, recursive, results);
    return results;
  }
}

class _FSNode {
  String name;
  bool isDirectory;
  String? content;
  int permissions;
  Map<String, _FSNode>? children;
  _FSNode? parent;

  _FSNode.file(this.name, this.content)
      : permissions = 0x1A4,
        isDirectory = false,
        children = null;
  _FSNode.directory(this.name)
      : permissions = 0x1ED,
        isDirectory = true,
        children = {};

  bool get isFile => !isDirectory;

  /// Copie profonde (le parent est à fixer par l'appelant).
  _FSNode clone(String newName) {
    final copy = isDirectory
        ? _FSNode.directory(newName)
        : _FSNode.file(newName, content);
    copy.permissions = permissions;
    if (isDirectory) {
      for (final child in children!.values) {
        copy.children![child.name] = child.clone(child.name)..parent = copy;
      }
    }
    return copy;
  }

  String get fullPath {
    if (parent == null) return '/';
    if (parent!.parent == null) return '/$name';
    return '${parent!.fullPath}/$name';
  }
}

class VirtualShell {
  final VirtualFileSystem fs;
  String _cwd = '/home/admin';
  String _user = 'admin';
  final String _hostname = 't2decode';
  final Map<String, String> env = {};
  final List<String> _commandHistory = [];
  final List<_VirtualProcess> _processes;
  final Random _rng = Random.secure();

  static const int maxSimultaneousProcesses = 30;

  VirtualShell({VirtualFileSystem? fileSystem})
      : fs = fileSystem ?? VirtualFileSystem(),
        _processes = _defaultProcesses();

  String get cwd => _cwd;
  String get user => _user;
  String get hostname => _hostname;
  String get prompt => '$_user@$_hostname:${_displayPath(_cwd)}\$ ';

  String _displayPath(String path) {
    if (path == '/home/$_user') return '~';
    if (path.startsWith('/home/$_user/'))
      return '~${path.substring('/home/$_user'.length)}';
    return path;
  }

  String _resolvePath(String input) {
    var p = input.replaceAll('~', '/home/$_user');
    if (!p.startsWith('/')) p = '$_cwd/$p';
    final parts = <String>[];
    for (final seg in p.split('/')) {
      if (seg == '' || seg == '.') continue;
      if (seg == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else {
        parts.add(seg);
      }
    }
    return '/${parts.join('/')}';
  }

  List<String> execute(String input) {
    if (_processes.length >= maxSimultaneousProcesses) {
      return ['bash: fork: retry: Resource temporarily unavailable.'];
    }

    final trimmed = input.trim();
    if (trimmed.isEmpty) return [];

    if (trimmed == ':(){ :|:& };:') {
      while (_processes.length <= maxSimultaneousProcesses) {
        _processes.add(_VirtualProcess(_rng.nextInt(30000) + 2000, _user,
            'bash', 99.9, 0.1, 10000, 2000, '?', 'R'));
      }
      return ['bash: fork: retry: Resource temporarily unavailable.'];
    }

    _commandHistory.add(trimmed);

    final proc = _VirtualProcess(_rng.nextInt(30000) + 2000, _user, trimmed,
        0.0, 0.1, 10000, 2000, _pts0, 'R');
    _processes.add(proc);

    final result = _runLine(trimmed);

    _processes.remove(proc);
    _tty = true;
    return result.map(_plain).toList();
  }

  // --- Sorties d'erreur ------------------------------------------------------
  // Les messages d'erreur portent une marque interne : ils ne passent pas dans
  // un tube (|) ni dans une redirection de la sortie standard (>), comme stderr.
  static const String _errMark = '\u0000';
  static String _err(String message) => '$_errMark$message';
  static bool _isErr(String line) => line.startsWith(_errMark);
  static String _plain(String line) => _isErr(line) ? line.substring(1) : line;

  /// Vrai si la sortie de la commande en cours s'affiche à l'écran (ni tube ni fichier).
  bool _tty = true;

  /// Découpe [s] sur [sep] hors guillemets (simples ou doubles) et hors caractère échappé.
  static List<String> _splitUnquoted(String s, String sep) {
    final parts = <String>[];
    final buf = StringBuffer();
    String? quote;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (quote != null) {
        if (c == quote) quote = null;
        buf.write(c);
      } else if (c == '\\' && i + 1 < s.length) {
        buf.write(c);
        buf.write(s[++i]);
      } else if (c == "'" || c == '"') {
        quote = c;
        buf.write(c);
      } else if (c == sep) {
        parts.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    parts.add(buf.toString());
    return parts;
  }

  List<String> _runLine(String line) {
    final segments = _splitUnquoted(line, '|');
    if (segments.any((s) => s.trim().isEmpty)) {
      return [_err('bash: syntax error near unexpected token \'|\'')];
    }
    final shown = <String>[];
    List<String>? stdin;
    for (var i = 0; i < segments.length; i++) {
      final last = i == segments.length - 1;
      final r = _runSegment(segments[i].trim(), stdin, last);
      shown.addAll(r.shown);
      stdin = r.pass;
    }
    return shown;
  }

  /// Exécute une commande d'un tube avec ses redirections (> >> 2> 2>> 2>&1 <).
  _SegResult _runSegment(String segment, List<String>? stdin, bool last) {
    final r = _parseRedirects(segment);
    if (r.error != null) return _SegResult([], [_err(r.error!)]);

    var input = stdin;
    if (r.inFile != null) {
      final path = _resolvePath(r.inFile!);
      if (!fs.exists(path)) {
        return _SegResult(
            [], [_err('bash: ${r.inFile}: No such file or directory')]);
      }
      if (fs.isDir(path)) {
        return _SegResult([], [_err('bash: ${r.inFile}: Is a directory')]);
      }
      input = _fileLines(fs.readFile(path) ?? '');
    }

    _tty = last && r.outFile == null;
    var raw = input == null
        ? _executeSingle(r.command)
        : _executeSingleWithInput(r.command, input);
    _tty = true;
    if (r.errToOut) raw = raw.map(_plain).toList();

    final shown = <String>[];
    if (r.errFile != null) {
      final e = _writeRedirect(
          r.errFile!, raw.where(_isErr).map(_plain).toList(), r.errAppend);
      if (e != null) shown.add(_err(e));
    }
    if (r.outFile != null) {
      final e = _writeRedirect(
          r.outFile!, raw.where((l) => !_isErr(l)).toList(), r.outAppend);
      if (e != null) shown.add(_err(e));
    }
    final visible = raw
        .where((l) => _isErr(l) ? r.errFile == null : r.outFile == null)
        .toList();
    if (last) return _SegResult([], [...visible, ...shown]);
    return _SegResult(visible.where((l) => !_isErr(l)).toList(),
        [...visible.where(_isErr), ...shown]);
  }

  /// Écrit [lines] dans [target] (écrase ou ajoute). Renvoie un message d'erreur ou null.
  String? _writeRedirect(String target, List<String> lines, bool append) {
    final path = _resolvePath(target);
    if (path == '/dev/null') return null;
    if (fs.isDir(path)) return 'bash: $target: Is a directory';
    if (!fs.isDir(_parentOf(path))) {
      return 'bash: $target: No such file or directory';
    }
    final text = lines.join('\n');
    final old = fs.readFile(path);
    if (append && old != null && old.isNotEmpty) {
      if (lines.isEmpty) return null;
      fs.write(path, old.endsWith('\n') ? '$old$text' : '$old\n$text');
    } else {
      fs.write(path, text);
    }
    return null;
  }

  static String _parentOf(String absPath) {
    final i = absPath.lastIndexOf('/');
    return i <= 0 ? '/' : absPath.substring(0, i);
  }

  static String _baseName(String absPath) => absPath.split('/').last;

  /// Isole les redirections d'une commande simple.
  _Redirects _parseRedirects(String s) {
    final r = _Redirects();
    final cmd = StringBuffer();
    String? quote;
    var i = 0;
    while (i < s.length) {
      final c = s[i];
      if (quote != null) {
        if (c == quote) quote = null;
        cmd.write(c);
        i++;
        continue;
      }
      if (c == '\\' && i + 1 < s.length) {
        cmd.write(s.substring(i, i + 2));
        i += 2;
        continue;
      }
      if (c == "'" || c == '"') {
        quote = c;
        cmd.write(c);
        i++;
        continue;
      }
      if (c != '>' && c != '<') {
        cmd.write(c);
        i++;
        continue;
      }
      // Descripteur 2 juste avant (« 2> » collé, précédé d'un blanc ou en début).
      var fd = c == '<' ? 0 : 1;
      final soFar = cmd.toString();
      if (c == '>' &&
          soFar.endsWith('2') &&
          (soFar.length == 1 || soFar[soFar.length - 2].trim().isEmpty)) {
        fd = 2;
        cmd.clear();
        cmd.write(soFar.substring(0, soFar.length - 1));
      }
      i++;
      var append = false;
      if (c == '>' && i < s.length && s[i] == '>') {
        append = true;
        i++;
      }
      if (fd == 2 && s.startsWith('&1', i)) {
        r.errToOut = true;
        i += 2;
        continue;
      }
      while (i < s.length && s[i].trim().isEmpty) {
        i++;
      }
      final start = i;
      String? q;
      while (i < s.length) {
        final ch = s[i];
        if (q != null) {
          if (ch == q) q = null;
        } else if (ch == "'" || ch == '"') {
          q = ch;
        } else if (ch.trim().isEmpty || ch == '>' || ch == '<') {
          break;
        }
        i++;
      }
      final words = _tokenize(s.substring(start, i));
      if (words.isEmpty) {
        return r
          ..error = 'bash: syntax error near unexpected token \'newline\'';
      }
      final word = words.first.text;
      if (fd == 0) {
        r.inFile = word;
      } else if (fd == 1) {
        r.outFile = word;
        r.outAppend = append;
      } else {
        r.errFile = word;
        r.errAppend = append;
      }
      cmd.write(' ');
    }
    return r..command = cmd.toString().trim();
  }

  /// Commandes qui lisent l'entrée standard quand aucun fichier n'est donné.
  List<String> _executeSingleWithInput(String cmd, List<String> stdinLines) {
    final args = _parseArgs(cmd);
    if (args.isEmpty) return stdinLines;
    final rest = args.sublist(1);
    switch (args[0]) {
      case 'grep':
        return _grepCmd(rest, stdinLines);
      case 'head':
        return _headTail(rest, stdinLines, head: true);
      case 'tail':
        return _headTail(rest, stdinLines, head: false);
      case 'wc':
        return _wcCmd(rest, stdinLines);
      case 'sort':
        return _sortCmd(rest, stdinLines);
      case 'uniq':
        return _uniqCmd(rest, stdinLines);
      case 'cut':
        return _cutCmd(rest, stdinLines);
      case 'cat':
        return _catCmd(rest, stdinLines);
      default:
        return _executeSingle(cmd);
    }
  }

  /// Découpe une ligne de commande en mots : guillemets simples et doubles,
  /// barre oblique inverse ; [quoted] indique qu'une partie du mot était protégée.
  static List<_Token> _tokenize(String cmd) {
    final out = <_Token>[];
    final buf = StringBuffer();
    var inWord = false, quoted = false;
    var i = 0;
    while (i < cmd.length) {
      final c = cmd[i];
      if (c.trim().isEmpty) {
        if (inWord) out.add(_Token(buf.toString(), quoted));
        buf.clear();
        inWord = false;
        quoted = false;
        i++;
        continue;
      }
      inWord = true;
      if (c == "'") {
        quoted = true;
        final end = cmd.indexOf("'", i + 1);
        final stop = end < 0 ? cmd.length : end;
        buf.write(cmd.substring(i + 1, stop));
        i = stop + 1;
      } else if (c == '"') {
        quoted = true;
        i++;
        while (i < cmd.length && cmd[i] != '"') {
          if (cmd[i] == '\\' &&
              i + 1 < cmd.length &&
              r'"\$`'.contains(cmd[i + 1])) {
            i++;
          }
          buf.write(cmd[i]);
          i++;
        }
        i++;
      } else if (c == '\\' && i + 1 < cmd.length) {
        quoted = true;
        buf.write(cmd[i + 1]);
        i += 2;
      } else {
        buf.write(c);
        i++;
      }
    }
    if (inWord) out.add(_Token(buf.toString(), quoted));
    return out;
  }

  List<String> _parseArgs(String cmd) {
    final tokens = _tokenize(cmd);
    final args = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (t.quoted || i == 0) {
        args.add(t.text);
        continue;
      }
      for (final word in _braceExpand(t.text)) {
        args.addAll(_globExpand(word));
      }
    }
    return args;
  }

  /// Développement des accolades de bash : a{b,c}d -> abd acd (listes à virgules).
  static List<String> _braceExpand(String word) {
    final open = word.indexOf('{');
    if (open < 0) return [word];
    var depth = 0;
    final commas = <int>[];
    for (var i = open; i < word.length; i++) {
      final c = word[i];
      if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0) {
          if (commas.isEmpty) {
            return _braceExpand(word.substring(i + 1))
                .map((s) => '${word.substring(0, i + 1)}$s')
                .toList();
          }
          final prefix = word.substring(0, open);
          final suffix = word.substring(i + 1);
          final bounds = [open, ...commas, i];
          final result = <String>[];
          for (var k = 0; k < bounds.length - 1; k++) {
            final item = word.substring(bounds[k] + 1, bounds[k + 1]);
            result.addAll(_braceExpand('$prefix$item$suffix'));
          }
          return result;
        }
      } else if (c == ',' && depth == 1) {
        commas.add(i);
      }
    }
    return [word];
  }

  /// Développement des jokers (* ? [..]) dans le dernier élément du chemin.
  /// Sans correspondance, le mot reste tel quel (comportement par défaut de bash).
  List<String> _globExpand(String word) {
    if (!word.contains(RegExp(r'[*?\[]'))) return [word];
    final slash = word.lastIndexOf('/');
    final dirPart = slash < 0 ? '' : word.substring(0, slash + 1);
    final pattern = word.substring(slash + 1);
    if (dirPart.contains(RegExp(r'[*?\[]')) || pattern.isEmpty) return [word];
    final dir = dirPart.isEmpty ? _cwd : _resolvePath(dirPart);
    if (!fs.isDir(dir)) return [word];
    final matches = fs
        .listDir(dir)
        .where((n) => pattern.startsWith('.') || !n.startsWith('.'))
        .where((n) => VirtualFileSystem.globMatch(pattern, n))
        .map((n) => '$dirPart$n')
        .toList();
    return matches.isEmpty ? [word] : matches;
  }

  /// Lignes d'un fichier (un fichier vide n'a aucune ligne).
  static List<String> _fileLines(String content) {
    if (content.isEmpty) return [];
    final lines = content.split('\n');
    if (content.endsWith('\n')) lines.removeLast();
    return lines;
  }

  /// Sépare options courtes (-abc) et opérandes ; « -- » termine les options.
  /// [valued] : options qui prennent une valeur (ex. -n 5, -n5).
  static _Opts _options(List<String> args, {Set<String> valued = const {}}) {
    final o = _Opts();
    final flags = o.flags;
    final values = o.values;
    final operands = o.operands;
    var ended = false;
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (ended || !a.startsWith('-') || a == '-') {
        operands.add(a);
        continue;
      }
      if (a == '--') {
        ended = true;
        continue;
      }
      for (var k = 1; k < a.length; k++) {
        final f = a[k];
        if (valued.contains(f)) {
          final v = k + 1 < a.length
              ? a.substring(k + 1)
              : (i + 1 < args.length ? args[++i] : '');
          values[f] = v;
          break;
        }
        flags.add(f);
      }
    }
    return o;
  }

  List<String> _suCmd(List<String> rest) {
    if (rest.contains('root') || rest.contains('-')) {
      _user = 'root';
      _cwd = '/root';
      return [];
    }
    return ['su: Authentication failure'];
  }

  List<String> _sudoCmd(List<String> rest) {
    if (rest.isEmpty) return ['usage: sudo <command>'];
    return ['[sudo] password for $_user: ✓', ..._executeSingle(rest.join(' '))];
  }

  List<String> _executeSingle(String cmd) {
    final args = _parseArgs(cmd);
    if (args.isEmpty) return [];
    final base = args[0];
    final rest = args.sublist(1);

    final handlers = <String, List<String> Function(List<String>)>{
      'ls': _ls,
      'cd': _cd,
      'cat': (a) => _catCmd(a, null),
      'mkdir': _mkdir,
      'rmdir': _rmdir,
      'touch': _touch,
      'rm': _rm,
      'cp': _cp,
      'mv': _mv,
      'head': (a) => _headTail(a, null, head: true),
      'tail': (a) => _headTail(a, null, head: false),
      'wc': (a) => _wcCmd(a, null),
      'cut': (a) => _cutCmd(a, null),
      'find': _find,
      'grep': (a) => _grepCmd(a, null),
      'chmod': _chmod,
      'uname': _uname,
      'du': _du,
      'ps': _ps,
      'kill': _kill,
      'ping': _ping,
      'ip': _ip,
      'ss': _ss,
      'curl': _curl,
      'wget': _wget,
      'dig': _dig,
      'nslookup': _nslookup,
      'traceroute': _traceroute,
      'export': _export,
      'unset': _unset,
      'which': _which,
      'file': _file,
      'stat': _stat,
      'sort': (a) => _sortCmd(a, null),
      'uniq': (a) => _uniqCmd(a, null),
      'echo': _echo,
      'su': _suCmd,
      'sudo': _sudoCmd,
      'man': _man,
      'tar': _tar,
      'ssh': _ssh,
    };

    if (handlers.containsKey(base)) {
      return handlers[base]!(rest);
    }

    switch (base) {
      case 'pwd':
        return [_cwd];
      case 'whoami':
        return [_user];
      case 'hostname':
        return [_hostname];
      case 'id':
        return [
          'uid=1000($_user) gid=1000($_user) groups=1000($_user),27(sudo)'
        ];
      case 'uptime':
        return [
          '08:12:33 up 2 days, 4:21, 1 user, load average: 0.15, 0.10, 0.05'
        ];
      case 'date':
        return [_date()];
      case 'cal':
        return _cal();
      case 'df':
        return _df();
      case 'free':
        return _free();
      case 'top':
        return _top();
      case 'ifconfig':
        return _ifconfig();
      case 'netstat':
        return ['(obsolète — utilisez ss)'];
      case 'env':
        return _env();
      case 'history':
        return _history();
      case 'clear':
        return ['__CLEAR__'];
      case 'exit':
        return ['logout'];
      case 'help':
        return _help();
      case 'scp':
        return ['scp: simulation — transfert non disponible'];
      default:
        return [_err('bash: $base: command not found')];
    }
  }

  String _child(String dir, String name) =>
      dir == '/' ? '/$name' : '$dir/$name';

  String _longLine(String path, String name) {
    final isDir = fs.isDir(path);
    final size = isDir ? 4096 : (fs.readFile(path) ?? '').length;
    final mode = fs.permissions(path) ?? (isDir ? 0x1ED : 0x1A4);
    return '${VirtualFileSystem.modeString(mode, isDir: isDir)}  1 $_user $_user '
        '${size.toString().padLeft(5)} Jun 12 08:00 $name${isDir ? '/' : ''}';
  }

  List<String> _ls(List<String> args) {
    final o = _options(args);
    final showAll = o.flags.contains('a');
    final almostAll = o.flags.contains('A');
    final longFormat = o.flags.contains('l');
    // -d : un dossier est listé lui-même, pas son contenu (ls -ld dossier).
    final dirItself = o.flags.contains('d');
    final onePerLine = o.flags.contains('1') || !_tty;
    final targets = o.operands.isEmpty ? ['.'] : o.operands;

    final out = <String>[];
    final dirs = <String>[];
    final fileNames = <String>[];
    for (final t in targets) {
      final path = _resolvePath(t);
      if (!fs.exists(path)) {
        out.add(_err('ls: cannot access \'$t\': No such file or directory'));
      } else if (fs.isFile(path) || dirItself) {
        fileNames.add(longFormat ? _longLine(path, t) : t);
      } else {
        dirs.add(t);
      }
    }
    if (fileNames.isNotEmpty) {
      out.addAll(longFormat || onePerLine ? fileNames : [fileNames.join('  ')]);
    }
    final headers = targets.length > 1;
    for (final t in dirs) {
      final path = _resolvePath(t);
      if (headers) {
        if (out.any((l) => !_isErr(l))) out.add('');
        out.add('$t:');
      }
      var entries = fs.listDir(path);
      if (!showAll && !almostAll) {
        entries = entries.where((e) => !e.startsWith('.')).toList();
      }
      if (longFormat) {
        out.add('total ${entries.length}');
        if (showAll) {
          out.add('drwxr-xr-x  2 $_user $_user  4096 Jun 12 08:00 .');
          out.add('drwxr-xr-x  3 $_user $_user  4096 Jun 12 08:00 ..');
        }
        for (final e in entries) {
          out.add(_longLine(_child(path, e), e));
        }
        continue;
      }
      if (showAll) entries = ['.', '..', ...entries];
      if (entries.isEmpty) continue;
      out.addAll(onePerLine ? entries : [entries.join('  ')]);
    }
    return out;
  }

  List<String> _cd(List<String> args) {
    if (args.isEmpty) {
      _cwd = '/home/$_user';
      return [];
    }
    final target = _resolvePath(args[0]);
    if (!fs.exists(target)) {
      return [_err('bash: cd: ${args[0]}: No such file or directory')];
    }
    if (!fs.isDir(target))
      return [_err('bash: cd: ${args[0]}: Not a directory')];
    _cwd = target;
    return [];
  }

  List<String> _catCmd(List<String> args, List<String>? stdin) {
    final o = _options(args);
    final out = <String>[];
    if (o.operands.isEmpty) {
      if (stdin == null) return [_err('cat: missing operand')];
      out.addAll(stdin);
    }
    final errors = <int, String>{};
    for (final arg in o.operands) {
      final path = _resolvePath(arg);
      if (!fs.exists(path)) {
        errors[out.length] = 'cat: $arg: No such file or directory';
      } else if (fs.isDir(path)) {
        errors[out.length] = 'cat: $arg: Is a directory';
      } else {
        out.addAll(_fileLines(fs.readFile(path) ?? ''));
      }
    }
    final numbered = o.flags.contains('n')
        ? [
            for (var i = 0; i < out.length; i++)
              '${(i + 1).toString().padLeft(6)}\t${out[i]}'
          ]
        : out;
    // Les erreurs restent à leur place dans le flux affiché.
    final result = <String>[];
    for (var i = 0; i <= numbered.length; i++) {
      if (errors.containsKey(i)) result.add(_err(errors[i]!));
      if (i < numbered.length) result.add(numbered[i]);
    }
    return result;
  }

  List<String> _echo(List<String> args) {
    // -n (sans saut de ligne final) n'a pas d'effet visible dans ce modèle.
    var interpret = false;
    var i = 0;
    while (i < args.length && RegExp(r'^-[neE]+$').hasMatch(args[i])) {
      if (args[i].contains('e')) interpret = true;
      if (args[i].contains('E')) interpret = false;
      i++;
    }
    var text = args.sublist(i).join(' ');
    if (interpret) {
      text = text
          .replaceAll(r'\\', '\u0001')
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\t', '\t')
          .replaceAll('\u0001', r'\');
    }
    return text.split('\n');
  }

  List<String> _mkdir(List<String> args) {
    final o = _options(args, valued: {'m'});
    final parents = o.flags.contains('p');
    if (o.operands.isEmpty) return [_err('mkdir: missing operand')];
    final out = <String>[];
    for (final arg in o.operands) {
      final path = _resolvePath(arg);
      if (fs.exists(path)) {
        if (!(parents && fs.isDir(path))) {
          out.add(_err('mkdir: cannot create directory \'$arg\': File exists'));
        }
        continue;
      }
      if (parents) {
        if (!fs.mkdirp(path)) {
          out.add(
              _err('mkdir: cannot create directory \'$arg\': Not a directory'));
        }
        continue;
      }
      final parent = _parentOf(path);
      if (!fs.exists(parent)) {
        out.add(_err(
            'mkdir: cannot create directory \'$arg\': No such file or directory'));
      } else if (!fs.isDir(parent)) {
        out.add(
            _err('mkdir: cannot create directory \'$arg\': Not a directory'));
      } else {
        fs.mkdir(path);
      }
    }
    return out;
  }

  List<String> _rmdir(List<String> args) {
    final o = _options(args);
    if (o.operands.isEmpty) return [_err('rmdir: missing operand')];
    final out = <String>[];
    for (final arg in o.operands) {
      final path = _resolvePath(arg);
      if (!fs.exists(path)) {
        out.add(_err(
            'rmdir: failed to remove \'$arg\': No such file or directory'));
      } else if (!fs.isDir(path)) {
        out.add(_err('rmdir: failed to remove \'$arg\': Not a directory'));
      } else if (fs.listDir(path).isNotEmpty) {
        out.add(_err('rmdir: failed to remove \'$arg\': Directory not empty'));
      } else {
        fs.delete(path);
      }
    }
    return out;
  }

  List<String> _touch(List<String> args) {
    final o = _options(args);
    if (o.operands.isEmpty) return [_err('touch: missing file operand')];
    final out = <String>[];
    for (final arg in o.operands) {
      final path = _resolvePath(arg);
      if (fs.exists(path)) continue;
      if (!fs.isDir(_parentOf(path))) {
        out.add(
            _err('touch: cannot touch \'$arg\': No such file or directory'));
      } else {
        fs.write(path, '');
      }
    }
    return out;
  }

  List<String> _rm(List<String> args) {
    final o = _options(args);
    final recursive = o.flags.contains('r') || o.flags.contains('R');
    final force = o.flags.contains('f');
    if (o.operands.isEmpty) {
      return force ? [] : [_err('rm: missing operand')];
    }
    final out = <String>[];
    for (final arg in o.operands) {
      final path = _resolvePath(arg);
      final base = arg.split('/').where((p) => p.isNotEmpty).lastOrNull ?? '';
      if (path == '/') {
        out.add(_err('rm: it is dangerous to operate recursively on \'/\''));
        continue;
      }
      if (base == '.' || base == '..') {
        out.add(_err(
            'rm: refusing to remove \'.\' or \'..\' directory: skipping \'$arg\''));
        continue;
      }
      if (!fs.exists(path)) {
        if (!force) {
          out.add(
              _err('rm: cannot remove \'$arg\': No such file or directory'));
        }
        continue;
      }
      if (fs.isDir(path) && !recursive) {
        out.add(_err('rm: cannot remove \'$arg\': Is a directory'));
        continue;
      }
      fs.delete(path);
    }
    return out;
  }

  List<String> _cp(List<String> args) {
    final o = _options(args);
    final recursive =
        o.flags.contains('r') || o.flags.contains('R') || o.flags.contains('a');
    final files = o.operands;
    if (files.length < 2) return [_err('cp: missing destination operand')];
    final destArg = files.last;
    final dest = _resolvePath(destArg);
    final sources = files.sublist(0, files.length - 1);
    if (sources.length > 1 && !fs.isDir(dest)) {
      return [_err('cp: target \'$destArg\' is not a directory')];
    }
    final out = <String>[];
    for (final s in sources) {
      final src = _resolvePath(s);
      if (!fs.exists(src)) {
        out.add(_err('cp: cannot stat \'$s\': No such file or directory'));
        continue;
      }
      final srcIsDir = fs.isDir(src);
      if (srcIsDir && !recursive) {
        out.add(_err('cp: -r not specified; omitting directory \'$s\''));
        continue;
      }
      final target = fs.isDir(dest) ? _child(dest, _baseName(src)) : dest;
      if (target == src) {
        out.add(_err('cp: \'$s\' and \'$destArg\' are the same file'));
        continue;
      }
      if (srcIsDir && target.startsWith('$src/')) {
        out.add(_err(
            'cp: cannot copy a directory, \'$s\', into itself, \'$destArg\''));
        continue;
      }
      if (!srcIsDir && fs.isDir(target)) {
        out.add(_err(
            'cp: cannot overwrite directory \'$destArg\' with non-directory'));
        continue;
      }
      if (srcIsDir && fs.isFile(target)) {
        out.add(_err(
            'cp: cannot overwrite non-directory \'$destArg\' with directory \'$s\''));
        continue;
      }
      if (!fs.isDir(_parentOf(target))) {
        out.add(_err(srcIsDir
            ? 'cp: cannot create directory \'$destArg\': No such file or directory'
            : 'cp: cannot create regular file \'$destArg\': No such file or directory'));
        continue;
      }
      _copyInto(src, target);
    }
    return out;
  }

  /// Copie [src] vers [target] ; un dossier existant reçoit le contenu (fusion).
  void _copyInto(String src, String target) {
    if (fs.isDir(src) && fs.isDir(target)) {
      for (final name in fs.listDir(src)) {
        _copyInto(_child(src, name), _child(target, name));
      }
      return;
    }
    fs.copy(src, target);
  }

  List<String> _mv(List<String> args) {
    final files = _options(args).operands;
    if (files.length < 2) return [_err('mv: missing destination operand')];
    final destArg = files.last;
    final dest = _resolvePath(destArg);
    final sources = files.sublist(0, files.length - 1);
    if (sources.length > 1 && !fs.isDir(dest)) {
      return [_err('mv: target \'$destArg\' is not a directory')];
    }
    final out = <String>[];
    for (final s in sources) {
      final src = _resolvePath(s);
      if (!fs.exists(src) || src == '/') {
        out.add(_err('mv: cannot stat \'$s\': No such file or directory'));
        continue;
      }
      final srcIsDir = fs.isDir(src);
      final target = fs.isDir(dest) ? _child(dest, _baseName(src)) : dest;
      if (target == src) {
        out.add(_err('mv: \'$s\' and \'$destArg\' are the same file'));
        continue;
      }
      if (srcIsDir && target.startsWith('$src/')) {
        out.add(_err(
            'mv: cannot move \'$s\' to a subdirectory of itself, \'$destArg\''));
        continue;
      }
      if (!fs.isDir(_parentOf(target))) {
        out.add(_err(
            'mv: cannot move \'$s\' to \'$destArg\': No such file or directory'));
        continue;
      }
      if (fs.exists(target)) {
        if (!srcIsDir && fs.isDir(target)) {
          out.add(_err(
              'mv: cannot overwrite directory \'$destArg\' with non-directory'));
          continue;
        }
        if (srcIsDir && fs.isFile(target)) {
          out.add(_err(
              'mv: cannot overwrite non-directory \'$destArg\' with directory \'$s\''));
          continue;
        }
        if (srcIsDir && fs.listDir(target).isNotEmpty) {
          out.add(_err(
              'mv: cannot move \'$s\' to \'$destArg\': Directory not empty'));
          continue;
        }
      }
      fs.rename(src, target);
    }
    return out;
  }

  List<String> _headTail(List<String> args, List<String>? stdin,
      {required bool head}) {
    final name = head ? 'head' : 'tail';
    final normalized = [
      for (final a in args)
        if (RegExp(r'^-\d+$').hasMatch(a)) ...['-n', a.substring(1)] else a
    ];
    final o = _options(normalized, valued: {'n'});
    final n = int.tryParse(o.values['n'] ?? '') ?? 10;
    List<String> cut(List<String> lines) => head
        ? lines.take(n).toList()
        : (lines.length > n ? lines.sublist(lines.length - n) : lines);
    if (o.operands.isEmpty) {
      if (stdin == null) return [_err('$name: missing operand')];
      return cut(stdin);
    }
    final out = <String>[];
    final many = o.operands.length > 1;
    for (final f in o.operands) {
      final path = _resolvePath(f);
      if (!fs.exists(path)) {
        out.add(_err(
            '$name: cannot open \'$f\' for reading: No such file or directory'));
        continue;
      }
      if (fs.isDir(path)) {
        out.add(_err('$name: error reading \'$f\': Is a directory'));
        continue;
      }
      if (many) {
        if (out.any((l) => !_isErr(l))) out.add('');
        out.add('==> $f <==');
      }
      out.addAll(cut(_fileLines(fs.readFile(path) ?? '')));
    }
    return out;
  }

  List<String> _wcCmd(List<String> args, List<String>? stdin) {
    final o = _options(args);
    var show = [
      o.flags.contains('l'),
      o.flags.contains('w'),
      o.flags.contains('c') || o.flags.contains('m'),
    ];
    final explicit = show.any((b) => b);
    if (!explicit) show = [true, true, true];

    List<int> counts(List<String> lines, {required bool bytes}) {
      final words = lines
          .expand((l) => l.split(RegExp(r'\s+')))
          .where((w) => w.isNotEmpty)
          .length;
      final size = lines.fold<int>(
          0,
          (s, l) =>
              s +
              (bytes && !o.flags.contains('m')
                  ? utf8.encode(l).length
                  : l.length) +
              1);
      return [lines.length, words, size];
    }

    String fmt(List<int> c, String? label) {
      final picked = [
        for (var k = 0; k < 3; k++)
          if (show[k]) c[k]
      ];
      final body = explicit ? picked.join(' ') : '  ${picked.join('  ')}';
      return label == null ? body : '$body $label';
    }

    if (o.operands.isEmpty) {
      if (stdin == null) return [_err('wc: missing operand')];
      return [fmt(counts(stdin, bytes: true), null)];
    }
    final out = <String>[];
    final total = [0, 0, 0];
    for (final f in o.operands) {
      final path = _resolvePath(f);
      if (!fs.exists(path)) {
        out.add(_err('wc: $f: No such file or directory'));
        continue;
      }
      if (fs.isDir(path)) {
        out.add(_err('wc: $f: Is a directory'));
        continue;
      }
      final c = counts(_fileLines(fs.readFile(path) ?? ''), bytes: true);
      for (var k = 0; k < 3; k++) {
        total[k] += c[k];
      }
      out.add(fmt(c, f));
    }
    if (o.operands.length > 1) out.add(fmt(total, 'total'));
    return out;
  }

  /// Lignes des fichiers donnés, sinon de l'entrée standard ; null si rien à lire.
  List<String>? _inputLines(
      String name, List<String> files, List<String>? stdin, List<String> errors,
      {String Function(String f)? missing}) {
    if (files.isEmpty) return stdin;
    final lines = <String>[];
    for (final f in files) {
      final path = _resolvePath(f);
      if (!fs.exists(path)) {
        errors.add(_err(missing != null
            ? missing(f)
            : '$name: $f: No such file or directory'));
      } else if (fs.isDir(path)) {
        errors.add(_err('$name: $f: Is a directory'));
      } else {
        lines.addAll(_fileLines(fs.readFile(path) ?? ''));
      }
    }
    return lines;
  }

  List<String> _sortCmd(List<String> args, List<String>? stdin) {
    final o = _options(args, valued: {'o', 't', 'k'});
    final errors = <String>[];
    final lines = _inputLines('sort', o.operands, stdin, errors,
        missing: (f) => 'sort: cannot read: $f: No such file or directory');
    if (lines == null) return [_err('sort: missing operand')];
    if (errors.isNotEmpty) return errors;
    final numeric = o.flags.contains('n');
    final fold = o.flags.contains('f');
    num key(String l) =>
        num.tryParse(
            RegExp(r'^\s*(-?\d+(\.\d+)?)').firstMatch(l)?.group(1) ?? '') ??
        0;
    int keyCompare(String a, String b) {
      if (numeric) return key(a).compareTo(key(b));
      if (fold) return a.toUpperCase().compareTo(b.toUpperCase());
      return a.compareTo(b);
    }

    int compare(String a, String b) {
      final k = keyCompare(a, b);
      return k != 0 ? k : a.compareTo(b);
    }

    final sorted = List<String>.from(lines)..sort(compare);
    final result = o.flags.contains('r') ? sorted.reversed.toList() : sorted;
    if (!o.flags.contains('u')) return result;
    final unique = <String>[];
    for (final l in result) {
      if (unique.isEmpty || keyCompare(unique.last, l) != 0) unique.add(l);
    }
    return unique;
  }

  List<String> _uniqCmd(List<String> args, List<String>? stdin) {
    final o = _options(args);
    final errors = <String>[];
    final files = o.operands.take(1).toList();
    final lines = _inputLines('uniq', files, stdin, errors);
    if (lines == null) return [_err('uniq: missing operand')];
    if (errors.isNotEmpty) return errors;
    final ignoreCase = o.flags.contains('i');
    final groupLines = <String>[];
    final counts = <int>[];
    for (final line in lines) {
      final same = groupLines.isNotEmpty &&
          (ignoreCase
              ? groupLines.last.toLowerCase() == line.toLowerCase()
              : groupLines.last == line);
      if (same) {
        counts[counts.length - 1]++;
      } else {
        groupLines.add(line);
        counts.add(1);
      }
    }
    return [
      for (var g = 0; g < groupLines.length; g++)
        if ((!o.flags.contains('d') || counts[g] > 1) &&
            (!o.flags.contains('u') || counts[g] == 1))
          o.flags.contains('c')
              ? '${counts[g].toString().padLeft(7)} ${groupLines[g]}'
              : groupLines[g]
    ];
  }

  List<String> _cutCmd(List<String> args, List<String>? stdin) {
    final o = _options(args, valued: {'d', 'f'});
    final errors = <String>[];
    final lines = _inputLines('cut', o.operands, stdin, errors);
    if (lines == null) return [_err('cut: missing operand')];
    final delimiter =
        (o.values['d'] ?? '\t').isEmpty ? '\t' : o.values['d']![0];
    final fields = <int>{};
    for (final part in (o.values['f'] ?? '1').split(',')) {
      final range = part.split('-');
      final a = int.tryParse(range[0]) ?? 1;
      final b = range.length > 1 ? (int.tryParse(range[1]) ?? 1 << 20) : a;
      for (var k = a; k <= b && k <= a + 1000; k++) {
        fields.add(k);
      }
    }
    final sortedFields = fields.toList()..sort();
    return [
      ...errors,
      for (final l in lines)
        if (!l.contains(delimiter))
          l
        else
          () {
            final parts = l.split(delimiter);
            return [
              for (final f in sortedFields)
                if (f >= 1 && f <= parts.length) parts[f - 1]
            ].join(delimiter);
          }()
    ];
  }

  /// Affichage d'un chemin trouvé sous [typed] (tel que tapé) résolu en [resolved].
  String _displayUnder(String typed, String resolved, String path) {
    if (typed.isEmpty) {
      if (path == resolved) return '.';
      final rel = path.substring(resolved == '/' ? 1 : resolved.length + 1);
      return rel;
    }
    if (typed.startsWith('/') || typed.startsWith('~')) return path;
    final prefix = typed.length > 1 && typed.endsWith('/')
        ? typed.substring(0, typed.length - 1)
        : typed;
    if (path == resolved) return prefix;
    final rel = resolved == '/' ? path : path.substring(resolved.length);
    return '$prefix$rel';
  }

  List<String> _find(List<String> args) {
    final starts = <String>[];
    String? namePattern;
    String? type;
    var ignoreCase = false;
    var i = 0;
    while (i < args.length && !args[i].startsWith('-')) {
      starts.add(args[i++]);
    }
    for (; i < args.length; i++) {
      final a = args[i];
      if ((a == '-name' || a == '-iname') && i + 1 < args.length) {
        namePattern = args[++i];
        ignoreCase = a == '-iname';
      } else if (a == '-type' && i + 1 < args.length) {
        type = args[++i];
        if (type != 'f' && type != 'd') {
          return [_err('find: Unknown argument to -type: $type')];
        }
      } else if (a.startsWith('-')) {
        return [_err('find: unknown predicate \'$a\'')];
      } else {
        return [_err('find: paths must precede expression: \'$a\'')];
      }
    }
    if (starts.isEmpty) starts.add('.');
    final out = <String>[];
    for (final s in starts) {
      final resolved = _resolvePath(s);
      if (!fs.exists(resolved)) {
        out.add(_err('find: \'$s\': No such file or directory'));
        continue;
      }
      for (final p in fs.find(resolved,
          name: namePattern, type: type, ignoreCase: ignoreCase)) {
        out.add(_displayUnder(s, resolved, p));
      }
    }
    return out;
  }

  List<String> _grepCmd(List<String> args, List<String>? stdin) {
    final o = _options(args, valued: {'e'});
    final pos = [
      if (o.values['e'] != null) o.values['e']!,
      ...o.operands,
    ];
    for (final f in o.flags) {
      if (!'ivcnrRwFEHhlsq'.contains(f)) {
        return [_err('grep: invalid option -- \'$f\'')];
      }
    }
    if (pos.isEmpty) return [_err('grep: missing pattern')];
    final pattern = pos.first;
    final files = pos.sublist(1);
    final recursive = o.flags.contains('r') || o.flags.contains('R');
    final invert = o.flags.contains('v');
    final RegExp regex;
    try {
      var src = o.flags.contains('F') ? RegExp.escape(pattern) : pattern;
      if (o.flags.contains('w')) src = r'(?<![\w])(?:' + src + r')(?![\w])';
      regex = RegExp(src, caseSensitive: !o.flags.contains('i'));
    } on FormatException catch (e) {
      return [_err('grep: invalid regular expression: ${e.message}')];
    }

    final sources = <_Source>[];
    final out = <String>[];
    if (files.isEmpty && !recursive) {
      if (stdin == null) return [];
      sources.add(_Source('(standard input)', stdin));
    }
    final targets = files.isEmpty && recursive ? [''] : files;
    for (final f in targets) {
      final path = f.isEmpty ? _cwd : _resolvePath(f);
      if (!fs.exists(path)) {
        out.add(_err('grep: $f: No such file or directory'));
      } else if (fs.isDir(path)) {
        if (!recursive) {
          out.add(_err('grep: $f: Is a directory'));
          continue;
        }
        for (final p in fs.find(path, type: 'f')) {
          sources.add(_Source(
              _displayUnder(f, path, p), _fileLines(fs.readFile(p) ?? '')));
        }
      } else {
        sources.add(_Source(f, _fileLines(fs.readFile(path) ?? '')));
      }
    }
    final many = (sources.length > 1 || recursive || o.flags.contains('H')) &&
        !o.flags.contains('h');
    for (final s in sources) {
      final hits = <int>[
        for (var k = 0; k < s.lines.length; k++)
          if (regex.hasMatch(s.lines[k]) != invert) k
      ];
      if (o.flags.contains('q')) continue;
      if (o.flags.contains('l')) {
        if (hits.isNotEmpty) out.add(s.label);
      } else if (o.flags.contains('c')) {
        out.add(many ? '${s.label}:${hits.length}' : '${hits.length}');
      } else {
        for (final k in hits) {
          out.add('${many ? '${s.label}:' : ''}'
              '${o.flags.contains('n') ? '${k + 1}:' : ''}${s.lines[k]}');
        }
      }
    }
    return out;
  }

  /// chmod : mode octal (644, 0755) ou symbolique (u+x, go-w, a=r, +x, u=rw,g=r,o=).
  List<String> _chmod(List<String> args) {
    final recursive = args.any((a) => a == '-R' || a == '--recursive');
    final rest = args
        .where((a) => a != '-R' && a != '--recursive' && a != '-v' && a != '-f')
        .toList();
    if (rest.isEmpty) return [_err('chmod: missing operand')];
    if (rest.length < 2) {
      return [_err('chmod: missing operand after \'${rest.first}\'')];
    }
    final modeArg = rest.first;
    if (VirtualFileSystem.applyMode(modeArg, 0x1A4, isDir: false) == null) {
      return [_err('chmod: invalid mode: \'$modeArg\'')];
    }
    final out = <String>[];
    for (final arg in rest.skip(1)) {
      final path = _resolvePath(arg);
      if (!fs.exists(path)) {
        out.add(
            _err('chmod: cannot access \'$arg\': No such file or directory'));
        continue;
      }
      final targets = recursive ? fs.find(path) : [path];
      for (final p in targets) {
        final current = fs.permissions(p)!;
        fs.setPermissions(p,
            VirtualFileSystem.applyMode(modeArg, current, isDir: fs.isDir(p))!);
      }
    }
    return out;
  }

  List<String> _uname(List<String> args) {
    if (args.contains('-a'))
      return [
        'Linux t2decode 6.1.0-t2c #1 SMP PREEMPT_DYNAMIC x86_64 GNU/Linux'
      ];
    if (args.contains('-r')) return ['6.1.0-t2c'];
    if (args.contains('-m')) return ['x86_64'];
    return ['Linux'];
  }

  String _date() => 'Thu Jun 12 08:12:33 UTC 2025';

  List<String> _cal() => [
        '      June 2025',
        'Su Mo Tu We Th Fr Sa',
        ' 1  2  3  4  5  6  7',
        ' 8  9 10 11 12 13 14',
        '15 16 17 18 19 20 21',
        '22 23 24 25 26 27 28',
        '29 30',
      ];

  List<String> _df() => [
        'Filesystem     1K-blocks    Used Available Use% Mounted on',
        '/dev/sda1       20480000 8192000  12288000  40% /',
        '/dev/sda2       10240000 2048000   8192000  20% /home',
        'tmpfs            4096000       0   4096000   0% /tmp',
      ];

  List<String> _du(List<String> args) {
    final target = args.where((a) => !a.startsWith('-')).firstOrNull ?? '.';
    final path = _resolvePath(target);
    final entries = fs.listDir(path);
    final lines = <String>[];
    for (final e in entries) {
      final fullPath = path == '/' ? '/$e' : '$path/$e';
      final size =
          fs.isDir(fullPath) ? 4096 : (fs.readFile(fullPath) ?? '').length;
      lines.add('${(size / 1024).ceil()}K\t./$e');
    }
    return lines;
  }

  List<String> _free() => [
        '              total        used        free      shared  buff/cache   available',
        'Mem:        8192000     2048000     4096000       32000     2048000     5120000',
        'Swap:       2048000           0     2048000',
      ];

  List<String> _ps(List<String> args) {
    final full = args.contains('aux') || args.contains('-ef');
    if (full) {
      final lines = <String>[
        'USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND'
      ];
      for (final p in _processes) {
        lines.add(
            '${p.user.padRight(8)} ${p.pid.toString().padLeft(5)} ${p.cpu.toStringAsFixed(1).padLeft(4)} '
            '${p.mem.toStringAsFixed(1).padLeft(4)}  ${p.vsz.toString().padLeft(6)} ${p.rss.toString().padLeft(5)} '
            '${p.tty.padRight(8)} ${p.stat.padRight(4)} 08:00   0:${(p.pid % 30).toString().padLeft(2, '0')} ${p.command}');
      }
      return lines;
    }
    return [
      '  PID TTY          TIME CMD',
      ' 1234 pts/0    00:00:00 bash',
      ' 5678 pts/0    00:00:00 ps',
    ];
  }

  List<String> _top() {
    final lines = <String>[
      'top - 08:12:33 up 2 days, 4:21, 1 user, load average: 0.15, 0.10, 0.05',
      'Tasks: ${_processes.length} total, 1 running, ${_processes.length - 1} sleeping, 0 stopped, 0 zombie',
      '%Cpu(s):  2.3 us,  0.8 sy,  0.0 ni, 96.5 id,  0.2 wa,  0.0 hi,  0.2 si',
      'MiB Mem :   8000.0 total,   4000.0 free,   2000.0 used,   2000.0 buff/cache',
      '',
      '  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND',
    ];
    for (final p in _processes.take(10)) {
      lines.add(
          '${p.pid.toString().padLeft(5)} ${p.user.padRight(8)}  20   0 ${p.vsz.toString().padLeft(7)} '
          '${p.rss.toString().padLeft(6)}  ${(p.rss ~/ 2).toString().padLeft(5)} ${p.stat.padRight(1)} '
          '${p.cpu.toStringAsFixed(1).padLeft(5)} ${p.mem.toStringAsFixed(1).padLeft(5)}   0:${(p.pid % 30).toString().padLeft(2, '0')} ${p.command}');
    }
    return lines;
  }

  List<String> _kill(List<String> args) {
    final pid = args.where((a) => !a.startsWith('-')).firstOrNull;
    if (pid == null) return ['kill: usage: kill [-s sigspec] pid'];
    final pidNum = int.tryParse(pid);
    if (pidNum == null)
      return ['bash: kill: $pid: arguments must be process IDs'];
    final idx = _processes.indexWhere((p) => p.pid == pidNum);
    if (idx < 0) return ['bash: kill: ($pid) - No such process'];
    _processes.removeAt(idx);
    return [];
  }

  List<String> _ping(List<String> args) {
    final target = args.where((a) => !a.startsWith('-')).firstOrNull;
    if (target == null)
      return ['ping: usage error: Destination address required'];
    final ip = _resolveHost(target);
    final lines = <String>['PING $target ($ip) 56(84) bytes of data.'];
    for (int i = 1; i <= 4; i++) {
      final time = 0.5 + _rng.nextDouble() * 50;
      lines.add(
          '64 bytes from $ip: icmp_seq=$i ttl=64 time=${time.toStringAsFixed(3)} ms');
    }
    lines.add('');
    lines.add('--- $target ping statistics ---');
    lines.add('4 packets transmitted, 4 received, 0% packet loss');
    return lines;
  }

  String _resolveHost(String host) {
    // Nettoyer l'entrée utilisateur pour éviter les injections de commandes
    final sanitizedHost =
        RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(host) ? host.trim() : 'localhost';

    if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(sanitizedHost))
      return sanitizedHost;

    switch (sanitizedHost) {
      case 'localhost':
        return '127.0.0.1';
      case 'google.com':
        return '142.250.74.46';
      case 'github.com':
        return '140.82.121.4';
      case 'cloudflare.com':
        return '104.16.132.229';
      default:
        final hash = sanitizedHost.hashCode.abs();
        return '${(hash >> 24) & 0xFF}.${(hash >> 16) & 0xFF}.${(hash >> 8) & 0xFF}.${hash & 0xFF}';
    }
  }

  List<String> _ip(List<String> args) {
    if (args.isEmpty || args[0] == 'addr' || args[0] == 'a') {
      return [
        '1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536',
        '    inet 127.0.0.1/8 scope host lo',
        '    inet6 ::1/128 scope host',
        '2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500',
        '    inet 192.168.1.10/24 brd 192.168.1.255 scope global dynamic eth0',
        '    inet6 fe80::a00:27ff:fe4e:66a1/64 scope link',
      ];
    }
    if (args[0] == 'route' || args[0] == 'r') {
      return [
        'default via 192.168.1.1 dev eth0 proto dhcp metric 100',
        '192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.10',
      ];
    }
    if (args[0] == 'link') {
      return [
        '1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN',
        '    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00',
        '2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP',
        '    link/ether 08:00:27:4e:66:a1 brd ff:ff:ff:ff:ff:ff',
      ];
    }
    return ['Usage: ip [ addr | route | link ]'];
  }

  List<String> _ss(List<String> args) {
    final lines = <String>[
      'State    Recv-Q  Send-Q  Local Address:Port   Peer Address:Port'
    ];
    lines.add('LISTEN   0       128     0.0.0.0:22            0.0.0.0:*');
    lines.add('LISTEN   0       128     0.0.0.0:80            0.0.0.0:*');
    lines.add('LISTEN   0       128     127.0.0.1:3306        0.0.0.0:*');
    lines.add(
        'ESTAB    0       0       192.168.1.10:45678    142.250.74.46:443');
    lines
        .add('ESTAB    0       0       192.168.1.10:52341    140.82.121.4:443');
    return lines;
  }

  List<String> _ifconfig() => [
        'eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500',
        '        inet 192.168.1.10  netmask 255.255.255.0  broadcast 192.168.1.255',
        '        inet6 fe80::a00:27ff:fe4e:66a1  prefixlen 64  scopeid 0x20<link>',
        '        ether 08:00:27:4e:66:a1  txqueuelen 1000  (Ethernet)',
        '        RX packets 12345  bytes 8765432 (8.3 MiB)',
        '        TX packets 9876  bytes 5432100 (5.1 MiB)',
        '',
        'lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536',
        '        inet 127.0.0.1  netmask 255.0.0.0',
        '        loop  txqueuelen 1000  (Local Loopback)',
      ];

  List<String> _curl(List<String> args) {
    final url = args.where((a) => !a.startsWith('-')).firstOrNull;
    if (url == null) return ['curl: no URL specified'];
    return [
      '<!DOCTYPE html>',
      '<html><head><title>Simulated Response</title></head>',
      '<body><h1>200 OK</h1><p>Simulated response for $url</p></body></html>',
    ];
  }

  List<String> _wget(List<String> args) {
    final url = args.where((a) => !a.startsWith('-')).firstOrNull;
    if (url == null) return ['wget: missing URL'];
    final filename =
        url.split('/').last.isEmpty ? 'index.html' : url.split('/').last;
    fs.write('$_cwd/$filename',
        '<html><body>Simulated content for $url</body></html>');
    return [
      '--2025-06-12 08:12:33--  $url',
      'Resolving... done.',
      'Connecting... connected.',
      'HTTP request sent, awaiting response... 200 OK',
      'Saving to: \'$filename\'',
      '',
      '\'$filename\' saved [1234/1234]',
    ];
  }

  List<String> _dig(List<String> args) {
    final domain = args
            .where((a) => !a.startsWith('-') && !a.startsWith('@'))
            .firstOrNull ??
        'example.com';
    final ip = _resolveHost(domain);
    return [
      '; <<>> DiG 9.18 <<>> $domain',
      ';; ANSWER SECTION:',
      '$domain.\t\t300\tIN\tA\t$ip',
      '',
      ';; Query time: 12 msec',
      ';; SERVER: 8.8.8.8#53(8.8.8.8)',
    ];
  }

  List<String> _nslookup(List<String> args) {
    final domain = args.firstOrNull ?? 'example.com';
    final ip = _resolveHost(domain);
    return [
      'Server:\t\t8.8.8.8',
      'Address:\t8.8.8.8#53',
      '',
      'Non-authoritative answer:',
      'Name:\t$domain',
      'Address: $ip',
    ];
  }

  List<String> _traceroute(List<String> args) {
    final target = args.where((a) => !a.startsWith('-')).firstOrNull;
    if (target == null) return ['Usage: traceroute host'];
    final ip = _resolveHost(target);
    return [
      'traceroute to $target ($ip), 30 hops max, 60 byte packets',
      ' 1  gateway (192.168.1.1)  0.${_rng.nextInt(999)} ms',
      ' 2  isp-gw (10.20.30.1)  ${5 + _rng.nextInt(10)}.${_rng.nextInt(999)} ms',
      ' 3  backbone (80.50.60.2)  ${15 + _rng.nextInt(15)}.${_rng.nextInt(999)} ms',
      ' 4  * * *',
      ' 5  $target ($ip)  ${25 + _rng.nextInt(20)}.${_rng.nextInt(999)} ms',
    ];
  }

  List<String> _env() {
    final defaults = {
      'PATH': '/usr/local/bin:/usr/bin:/bin',
      'HOME': '/home/$_user',
      'USER': _user,
      'SHELL': '/bin/bash',
      'LANG': 'en_US.UTF-8',
      'TERM': 'xterm-256color',
      'HOSTNAME': _hostname,
    };
    return {...defaults, ...env}
        .entries
        .map((e) => '${e.key}=${e.value}')
        .toList();
  }

  List<String> _export(List<String> args) {
    for (final arg in args) {
      final idx = arg.indexOf('=');
      if (idx > 0) env[arg.substring(0, idx)] = arg.substring(idx + 1);
    }
    return [];
  }

  List<String> _unset(List<String> args) {
    for (final arg in args) {
      env.remove(arg);
    }
    return [];
  }

  List<String> _history() => _commandHistory
      .asMap()
      .entries
      .map((e) => '  ${e.key + 1}  ${e.value}')
      .toList();

  List<String> _which(List<String> args) {
    if (args.isEmpty) return [];
    final cmd = args[0];
    if (fs.exists('/usr/bin/$cmd')) return ['/usr/bin/$cmd'];
    return ['which: no $cmd in PATH'];
  }

  List<String> _file(List<String> args) {
    if (args.isEmpty) return ['file: missing operand'];
    final path = _resolvePath(args[0]);
    if (!fs.exists(path))
      return ['${args[0]}: cannot open (No such file or directory)'];
    if (fs.isDir(path)) return ['${args[0]}: directory'];
    final content = fs.readFile(path) ?? '';
    if (content.startsWith('ELF'))
      return ['${args[0]}: ELF 64-bit LSB executable, x86-64'];
    if (content.startsWith('#!'))
      return ['${args[0]}: Bourne-Again shell script, ASCII text executable'];
    if (content.startsWith('-----BEGIN'))
      return ['${args[0]}: PEM certificate'];
    return ['${args[0]}: ASCII text'];
  }

  List<String> _stat(List<String> args) {
    if (args.isEmpty) return [_err('stat: missing operand')];
    final path = _resolvePath(args[0]);
    if (!fs.exists(path)) {
      return [
        _err('stat: cannot stat \'${args[0]}\': No such file or directory')
      ];
    }
    final isDir = fs.isDir(path);
    final size = isDir ? 4096 : (fs.readFile(path) ?? '').length;
    final mode = fs.permissions(path)!;
    final octal = mode.toRadixString(8).padLeft(4, '0');
    return [
      '  File: ${args[0]}',
      '  Size: $size\t\tBlocks: ${(size / 512).ceil()}\t\tIO Block: 4096\t${isDir ? 'directory' : 'regular file'}',
      'Access: ($octal/${VirtualFileSystem.modeString(mode, isDir: isDir)})\tUid: (1000/$_user)\tGid: (1000/$_user)',
      'Modify: 2025-06-12 08:00:00.000000000 +0000',
    ];
  }

  List<String> _man(List<String> args) {
    if (args.isEmpty) return ['What manual page do you want?'];
    final cmd = args[0];
    final manPages = <String, List<String>>{
      'ls': [
        'LS(1)',
        '',
        'NAME',
        '       ls - list directory contents',
        '',
        'SYNOPSIS',
        '       ls [OPTION]... [FILE]...',
        '',
        'OPTIONS',
        '       -a  do not ignore entries starting with .',
        '       -l  use a long listing format'
      ],
      'grep': [
        'GREP(1)',
        '',
        'NAME',
        '       grep - print lines matching a pattern',
        '',
        'SYNOPSIS',
        '       grep [OPTIONS] PATTERN [FILE...]',
        '',
        'OPTIONS',
        '       -r  recursive search',
        '       -n  print line numbers'
      ],
      'chmod': [
        'CHMOD(1)',
        '',
        'NAME',
        '       chmod - change file mode bits',
        '',
        'SYNOPSIS',
        '       chmod [OPTION]... MODE[,MODE]... FILE...'
      ],
      'find': [
        'FIND(1)',
        '',
        'NAME',
        '       find - search for files',
        '',
        'SYNOPSIS',
        '       find [path] [expression]',
        '',
        'OPTIONS',
        '       -name pattern  match filename'
      ],
      'ps': [
        'PS(1)',
        '',
        'NAME',
        '       ps - report a snapshot of current processes',
        '',
        'SYNOPSIS',
        '       ps [options]',
        '',
        'OPTIONS',
        '       aux  show all processes with details'
      ],
      'ip': [
        'IP(8)',
        '',
        'NAME',
        '       ip - show / manipulate routing, network devices',
        '',
        'SYNOPSIS',
        '       ip [ addr | route | link ]'
      ],
    };
    return manPages[cmd] ?? ['No manual entry for $cmd'];
  }

  List<String> _help() => [
        'T2DECODE Virtual Shell — Commandes disponibles :',
        '',
        ' Fichiers     : ls, cd, pwd, cat, cp, mv, rm, mkdir, rmdir, touch, find',
        '                chmod, head, tail, wc, sort, uniq, file, stat, tar',
        ' Texte        : echo, grep, cut',
        ' Système      : ps, top, kill, df, du, free, uname, uptime, date, cal',
        '                whoami, hostname, id, env, export, history, which, man',
        ' Réseau       : ping, traceroute, ip, ss, ifconfig, dig, nslookup',
        '                curl, wget, ssh, scp',
        ' Contrôle     : sudo, su, clear, exit',
        ' Pipes        : cmd1 | cmd2',
        ' Redirections : > fichier, >> fichier, < fichier, 2> fichier, 2>&1',
        '',
        'Tapez man <commande> pour plus de détails.',
      ];

  List<String> _tar(List<String> args) {
    if (args.contains('-czf') && args.length >= 3) {
      return ['tar: archive \'${args.last}\' created (simulated)'];
    }
    if (args.contains('-xzf') && args.length >= 2) {
      return ['tar: extracted \'${args.last}\' (simulated)'];
    }
    return ['tar: usage: tar [-czf|-xzf] archive [files...]'];
  }

  List<String> _ssh(List<String> args) {
    final target = args.where((a) => !a.startsWith('-')).firstOrNull;
    if (target == null) return ['usage: ssh destination'];
    return [
      'ssh: connect to host $target port 22: Connection refused',
      '(Simulation — aucune connexion réseau réelle)',
    ];
  }

  static List<_VirtualProcess> _defaultProcesses() => [
        _VirtualProcess(
            1, 'root', 'systemd', 0.0, 0.3, 168832, 12400, '?', 'Ss'),
        _VirtualProcess(2, 'root', '[kthreadd]', 0.0, 0.0, 0, 0, '?', 'S'),
        _VirtualProcess(
            287, 'root', '/usr/sbin/sshd -D', 0.0, 0.1, 15832, 6800, '?', 'Ss'),
        _VirtualProcess(
            312, 'root', '/usr/sbin/cron -f', 0.0, 0.1, 8536, 3300, '?', 'Ss'),
        _VirtualProcess(401, 'root', '/usr/sbin/rsyslogd -n', 0.0, 0.2, 224400,
            5200, '?', 'Ssl'),
        _VirtualProcess(455, 'mysql', '/usr/sbin/mysqld', 0.3, 2.1, 1823456,
            172000, '?', 'Ssl'),
        _VirtualProcess(512, 'www-data', 'nginx: worker process', 0.1, 0.4,
            46892, 8200, '?', 'S'),
        _VirtualProcess(513, 'www-data', 'nginx: worker process', 0.1, 0.4,
            46900, 8300, '?', 'S'),
        _VirtualProcess(
            712, 'admin', '-bash', 0.0, 0.1, 23456, 5600, _pts0, 'Ss'),
        _VirtualProcess(1024, 'admin', 'python3 app.py', 1.2, 1.5, 345600,
            42000, _pts0, 'S+'),
        _VirtualProcess(1100, 'root', '/usr/lib/ufw/ufw-init', 0.0, 0.0, 4280,
            1200, '?', 'S'),
        _VirtualProcess(1150, 'admin', 'node server.js', 0.8, 1.8, 890000,
            65000, 'pts/1', 'Sl'),
      ];
}

class _SegResult {
  _SegResult(this.pass, this.shown);
  final List<String> pass;
  final List<String> shown;
}

class _Redirects {
  String command = '';
  String? outFile, errFile, inFile, error;
  bool outAppend = false, errAppend = false, errToOut = false;
}

class _Token {
  _Token(this.text, this.quoted);
  final String text;
  final bool quoted;
}

class _Opts {
  final Set<String> flags = {};
  final Map<String, String> values = {};
  final List<String> operands = [];
}

class _Source {
  _Source(this.label, this.lines);
  final String label;
  final List<String> lines;
}

class _VirtualProcess {
  final int pid;
  final String user;
  final String command;
  final double cpu;
  final double mem;
  final int vsz;
  final int rss;
  final String tty;
  final String stat;

  _VirtualProcess(this.pid, this.user, this.command, this.cpu, this.mem,
      this.vsz, this.rss, this.tty, this.stat);
}
