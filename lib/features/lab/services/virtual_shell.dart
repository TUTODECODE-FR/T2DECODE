// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'dart:math';

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
class VirtualFileSystem {
  final Map<String, _FSNode> _nodes = {};

  VirtualFileSystem() {
    _init();
  }

  void _init() {
    _mkdirp('/');
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
    _writeFile('/etc/passwd',
        'root:x:0:0:root:/root:/bin/bash\n'
        'admin:x:1000:1000:admin:/home/admin:/bin/bash\n'
        'nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin');
    _writeFile('/etc/shadow', 'root:!:19000:0:99999:7:::\nadmin:\$6\$rounds=...:19000:0:99999:7:::');
    _writeFile('/etc/group', 'root:x:0:\nadmin:x:1000:admin\nsudo:x:27:admin');
    _writeFile('/etc/os-release',
        'NAME="T2DECODE Linux"\nVERSION="1.0"\nID=t2decode\nPRETTY_NAME="T2DECODE Linux 1.0"');
    _writeFile('/etc/resolv.conf', 'nameserver 8.8.8.8\nnameserver 1.1.1.1');
    _writeFile('/etc/hosts', '127.0.0.1\tlocalhost\n127.0.1.1\tt2decode\n::1\tlocalhost');
    _writeFile('/etc/fstab', '/dev/sda1  /     ext4  defaults  0 1\n/dev/sda2  /home ext4  defaults  0 2');
    _writeFile('/etc/crontab', '# m h dom mon dow user command\n*/5 * * * * root /usr/bin/apt-get update');
    _writeFile('/home/admin/.bashrc',
        '# ~/.bashrc\nexport PATH="/usr/local/bin:/usr/bin:/bin"\nexport EDITOR=nano\nalias ll="ls -la"');
    _writeFile('/home/admin/.ssh/authorized_keys', '# Aucune clé configurée');
    _writeFile('/home/admin/Documents/notes.txt', 'Bienvenue dans T2DECODE.\nCe fichier est un exemple.');
    _writeFile('/home/admin/Documents/readme.md', '# T2DECODE\nPlateforme pédagogique offline.');
    _writeFile('/var/log/syslog',
        'Jun 12 08:00:01 t2decode CRON[1234]: (root) CMD (apt-get update)\n'
        'Jun 12 08:01:12 t2decode sshd[5678]: Accepted publickey for admin\n'
        'Jun 12 08:05:33 t2decode kernel: [UFW BLOCK] IN=eth0 OUT= SRC=10.0.0.5 DST=192.168.1.10');
    _writeFile('/var/log/auth.log',
        'Jun 12 07:55:00 t2decode sshd[4321]: Failed password for root from 10.0.0.99\n'
        'Jun 12 08:01:12 t2decode sshd[5678]: Accepted publickey for admin from 192.168.1.5');
    _writeFile('/proc/cpuinfo', 'processor\t: 0\nmodel name\t: T2C vCPU @ 2.4GHz\ncpu cores\t: 4');
    _writeFile('/proc/meminfo', 'MemTotal:       8192000 kB\nMemFree:        4096000 kB\nMemAvailable:   5120000 kB');
    _writeFile('/proc/version', 'Linux version 6.1.0-t2c (gcc 12.2) #1 SMP PREEMPT_DYNAMIC');

    for (final cmd in ['bash', 'ls', 'cat', 'cp', 'mv', 'rm', 'grep', 'find',
        'chmod', 'chown', 'mkdir', 'touch', 'echo', 'ps', 'kill', 'ping',
        'ip', 'ss', 'curl', 'wget', 'ssh', 'scp', 'tar', 'gzip', 'nano',
        'vim', 'head', 'tail', 'wc', 'sort', 'uniq', 'cut', 'awk', 'sed']) {
      _writeFile('/usr/bin/$cmd', 'ELF binary');
    }
  }

  void _mkdirp(String path) {
    _nodes[path] = _FSNode.directory(path);
  }

  void _writeFile(String path, String content) {
    _nodes[path] = _FSNode.file(path, content);
  }

  bool exists(String path) => _nodes.containsKey(path);
  bool isDir(String path) => _nodes[path]?.isDirectory ?? false;
  bool isFile(String path) => _nodes[path]?.isFile ?? false;

  String? readFile(String path) => _nodes[path]?.content;

  void write(String path, String content) {
    _nodes[path] = _FSNode.file(path, content);
  }

  void mkdir(String path) {
    _nodes[path] = _FSNode.directory(path);
  }

  void delete(String path) {
    _nodes.removeWhere((k, _) => k == path || k.startsWith('$path/'));
  }

  void rename(String from, String to) {
    final node = _nodes.remove(from);
    if (node != null) {
      _nodes[to] = node;
      if (node.isDirectory) {
        final children = _nodes.keys.where((k) => k.startsWith('$from/')).toList();
        for (final child in children) {
          final n = _nodes.remove(child);
          if (n != null) _nodes[child.replaceFirst(from, to)] = n;
        }
      }
    }
  }

  List<String> listDir(String path) {
    final prefix = path == '/' ? '/' : '$path/';
    final entries = <String>{};
    for (final key in _nodes.keys) {
      if (key == path) continue;
      if (!key.startsWith(prefix)) continue;
      final rest = key.substring(prefix.length);
      final firstSegment = rest.split('/').first;
      if (firstSegment.isNotEmpty) entries.add(firstSegment);
    }
    return entries.toList()..sort();
  }

  List<String> find(String startPath, {String? name}) {
    final results = <String>[];
    for (final key in _nodes.keys) {
      if (!key.startsWith(startPath)) continue;
      if (name != null) {
        final baseName = key.split('/').last;
        if (!_globMatch(name, baseName)) continue;
      }
      results.add(key);
    }
    return results..sort();
  }

  bool _globMatch(String pattern, String text) {
    final regex = RegExp('^${pattern.replaceAll('.', r'\.').replaceAll('*', '.*')}\$');
    return regex.hasMatch(text);
  }

  List<String> grep(String pattern, String path, {bool recursive = false}) {
    final results = <String>[];
    final targets = <String>[];
    if (recursive && isDir(path)) {
      targets.addAll(_nodes.keys.where((k) => k.startsWith(path) && _nodes[k]!.isFile));
    } else if (isFile(path)) {
      targets.add(path);
    }
    final RegExp regex;
    try {
      regex = RegExp(pattern, caseSensitive: true);
    } on FormatException catch (e) {
      throw FormatException('grep: invalid regular expression: ${e.message}');
    }
    for (final t in targets) {
      final content = _nodes[t]!.content ?? '';
      final lines = content.split('\n');
      for (int i = 0; i < lines.length; i++) {
        if (regex.hasMatch(lines[i])) {
          results.add(recursive ? '$t:${i + 1}:${lines[i]}' : '${i + 1}:${lines[i]}');
        }
      }
    }
    return results;
  }

}

class _FSNode {
  final String path;
  final bool isDirectory;
  final String? content;
  final int permissions;

  _FSNode.file(this.path, this.content) : permissions = 0x1A4, isDirectory = false; // 644
  _FSNode.directory(this.path) : permissions = 0x1ED, isDirectory = true, content = null; // 755

  bool get isFile => !isDirectory;
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


  VirtualShell({VirtualFileSystem? fileSystem})
      : fs = fileSystem ?? VirtualFileSystem(),
        _processes = _defaultProcesses();

  String get cwd => _cwd;
  String get user => _user;
  String get hostname => _hostname;
  String get prompt => '$_user@$_hostname:${_displayPath(_cwd)}\$ ';

  String _displayPath(String path) {
    if (path == '/home/$_user') return '~';
    if (path.startsWith('/home/$_user/')) return '~${path.substring('/home/$_user'.length)}';
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
    final trimmed = input.trim();
    if (trimmed.isEmpty) return [];
    _commandHistory.add(trimmed);

    // Handle pipes simply
    if (trimmed.contains(' | ')) {
      return _executePipe(trimmed);
    }

    // Handle output redirection
    if (trimmed.contains(' > ')) {
      return _executeRedirect(trimmed);
    }

    return _executeSingle(trimmed);
  }

  List<String> _executePipe(String input) {
    final parts = input.split(' | ').map((s) => s.trim()).toList();
    var prevOutput = _executeSingle(parts.first);
    for (int i = 1; i < parts.length; i++) {
      prevOutput = _executeSingleWithInput(parts[i], prevOutput);
    }
    return prevOutput;
  }

  List<String> _executeRedirect(String input) {
    final parts = input.split(' > ');
    final output = _executeSingle(parts[0].trim());
    if (parts.length >= 2) {
      final target = _resolvePath(parts[1].trim());
      fs.write(target, output.join('\n'));
      return [];
    }
    return output;
  }

  List<String> _pipeGrep(List<String> args, List<String> stdinLines) {

    if (args.length < 2) return stdinLines;
    try {
      final pattern = RegExp(args[1]);
      return stdinLines.where((l) => pattern.hasMatch(l)).toList();
    } on FormatException catch (e) {
      return ['grep: invalid regular expression: ${e.message}'];
    }
  }

  List<String> _pipeHead(List<String> args, List<String> stdinLines) {
    final n = args.length > 2 && args[1] == '-n' ? int.tryParse(args[2]) ?? 10 : 10;
    return stdinLines.take(n).toList();
  }

  List<String> _pipeTail(List<String> args, List<String> stdinLines) {
    final n = args.length > 2 && args[1] == '-n' ? int.tryParse(args[2]) ?? 10 : 10;
    return stdinLines.length > n ? stdinLines.sublist(stdinLines.length - n) : stdinLines;
  }

  List<String> _pipeWc(List<String> args, List<String> stdinLines) {
    if (args.contains('-l')) return ['${stdinLines.length}'];
    final words = stdinLines.expand((l) => l.split(RegExp(r'\s+'))).where((w) => w.isNotEmpty).length;
    final chars = stdinLines.fold<int>(0, (s, l) => s + l.length + 1);
    return ['  ${stdinLines.length}  $words  $chars'];
  }

  List<String> _pipeSort(List<String> args, List<String> stdinLines) {
    final sorted = List<String>.from(stdinLines);
    if (args.contains('-r')) {
      sorted.sort((a, b) => b.compareTo(a));
    } else {
      sorted.sort();
    }
    return sorted;
  }

  List<String> _pipeUniq(List<String> stdinLines) {
    final result = <String>[];
    for (final line in stdinLines) {
      if (result.isEmpty || result.last != line) result.add(line);
    }
    return result;
  }

  List<String> _pipeCut(List<String> args, List<String> stdinLines) {
    final dIdx = args.indexOf('-d');
    final fIdx = args.indexOf('-f');
    final delimiter = dIdx >= 0 && dIdx + 1 < args.length ? args[dIdx + 1] : '\t';
    final field = fIdx >= 0 && fIdx + 1 < args.length ? int.tryParse(args[fIdx + 1]) ?? 1 : 1;
    return stdinLines.map((l) {
      final parts = l.split(delimiter);
      return field <= parts.length ? parts[field - 1] : '';
    }).toList();
  }

  List<String> _executeSingleWithInput(String cmd, List<String> stdinLines) {
    final args = _parseArgs(cmd);
    if (args.isEmpty) return stdinLines;
    final base = args[0];
    switch (base) {
      case 'grep': return _pipeGrep(args, stdinLines);
      case 'head': return _pipeHead(args, stdinLines);
      case 'tail': return _pipeTail(args, stdinLines);
      case 'wc': return _pipeWc(args, stdinLines);
      case 'sort': return _pipeSort(args, stdinLines);
      case 'uniq': return _pipeUniq(stdinLines);
      case 'cut': return _pipeCut(args, stdinLines);
      default: return stdinLines;
    }
  }


  List<String> _parseArgs(String cmd) {
    final args = <String>[];
    final regex = RegExp(r"""'[^']*'|"[^"]*"|\S+""");
    for (final match in regex.allMatches(cmd)) {
      var token = match.group(0)!;
      if ((token.startsWith("'") && token.endsWith("'")) ||
          (token.startsWith('"') && token.endsWith('"'))) {
        token = token.substring(1, token.length - 1);
      }
      args.add(token);
    }
    return args;
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
      'cat': _cat,
      'mkdir': _mkdir,
      'touch': _touch,
      'rm': _rm,
      'cp': _cp,
      'mv': _mv,
      'head': _head,
      'tail': _tail,
      'wc': _wc,
      'find': _find,
      'grep': _grep,
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
      'sort': _sortCmd,
      'uniq': _uniqCmd,
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
      case 'pwd': return [_cwd];
      case 'echo': return [rest.join(' ')];
      case 'whoami': return [_user];
      case 'hostname': return [_hostname];
      case 'id': return ['uid=1000($_user) gid=1000($_user) groups=1000($_user),27(sudo)'];
      case 'uptime': return ['08:12:33 up 2 days, 4:21, 1 user, load average: 0.15, 0.10, 0.05'];
      case 'date': return [_date()];
      case 'cal': return _cal();
      case 'df': return _df();
      case 'free': return _free();
      case 'top': return _top();
      case 'ifconfig': return _ifconfig();
      case 'netstat': return ['(obsolète — utilisez ss)'];
      case 'env': return _env();
      case 'history': return _history();
      case 'clear': return ['__CLEAR__'];
      case 'exit': return ['logout'];
      case 'help': return _help();
      case 'scp': return ['scp: simulation — transfert non disponible'];
      default: return ['bash: $base: command not found'];
    }
  }

  List<String> _lsFile(String path, bool longFormat) {
    if (longFormat) {
      final size = (fs.readFile(path) ?? '').length;
      return ['-rw-r--r-- 1 $_user $_user $size Jun 12 08:00 ${path.split('/').last}'];
    }
    return [path.split('/').last];
  }

  List<String> _lsLongFormat(String path, List<String> entries, bool showAll) {
    final lines = <String>['total ${entries.length}'];
    if (showAll) {
      lines.add('drwxr-xr-x  2 $_user $_user 4096 Jun 12 08:00 .');
      lines.add('drwxr-xr-x  3 $_user $_user 4096 Jun 12 08:00 ..');
    }
    for (final e in entries) {
      final fullPath = path == '/' ? '/$e' : '$path/$e';
      final isDir = fs.isDir(fullPath);
      final size = isDir ? 4096 : (fs.readFile(fullPath) ?? '').length;
      final perm = isDir ? 'drwxr-xr-x' : '-rw-r--r--';
      lines.add('$perm  1 $_user $_user ${size.toString().padLeft(5)} Jun 12 08:00 $e${isDir ? '/' : ''}');
    }
    return lines;
  }

  List<String> _ls(List<String> args) {
    final showAll = args.contains('-a') || args.contains('-la') || args.contains('-al');
    final longFormat = args.contains('-l') || args.contains('-la') || args.contains('-al');
    final target = args.where((a) => !a.startsWith('-')).firstOrNull;
    final path = target != null ? _resolvePath(target) : _cwd;

    if (!fs.exists(path)) return ['ls: cannot access \'$target\': No such file or directory'];
    if (fs.isFile(path)) {
      return _lsFile(path, longFormat);
    }

    var entries = fs.listDir(path);
    if (!showAll) entries = entries.where((e) => !e.startsWith('.')).toList();

    if (longFormat) {
      return _lsLongFormat(path, entries, showAll);
    }

    if (showAll) entries = ['.', '..', ...entries];
    return entries.isEmpty ? [] : [entries.join('  ')];
  }


  List<String> _cd(List<String> args) {
    if (args.isEmpty) {
      _cwd = '/home/$_user';
      return [];
    }
    final target = _resolvePath(args[0]);
    if (!fs.exists(target)) return ['bash: cd: ${args[0]}: No such file or directory'];
    if (!fs.isDir(target)) return ['bash: cd: ${args[0]}: Not a directory'];
    _cwd = target;
    return [];
  }

  List<String> _cat(List<String> args) {
    if (args.isEmpty) return ['cat: missing operand'];
    final results = <String>[];
    for (final arg in args.where((a) => !a.startsWith('-'))) {
      final path = _resolvePath(arg);
      if (!fs.exists(path)) {
        results.add('cat: $arg: No such file or directory');
      } else if (fs.isDir(path)) {
        results.add('cat: $arg: Is a directory');
      } else {
        results.addAll((fs.readFile(path) ?? '').split('\n'));
      }
    }
    return results;
  }

  List<String> _mkdir(List<String> args) {
    for (final arg in args.where((a) => !a.startsWith('-'))) {
      final path = _resolvePath(arg);
      if (fs.exists(path)) return ['mkdir: cannot create directory \'$arg\': File exists'];
      fs.mkdir(path);
    }
    return [];
  }

  List<String> _touch(List<String> args) {
    for (final arg in args.where((a) => !a.startsWith('-'))) {
      final path = _resolvePath(arg);
      if (!fs.exists(path)) fs.write(path, '');
    }
    return [];
  }

  List<String> _rm(List<String> args) {
    final recursive = args.contains('-r') || args.contains('-rf') || args.contains('-fr');
    for (final arg in args.where((a) => !a.startsWith('-'))) {
      final path = _resolvePath(arg);
      if (!fs.exists(path)) return ['rm: cannot remove \'$arg\': No such file or directory'];
      if (fs.isDir(path) && !recursive) return ['rm: cannot remove \'$arg\': Is a directory'];
      fs.delete(path);
    }
    return [];
  }

  List<String> _cp(List<String> args) {
    final files = args.where((a) => !a.startsWith('-')).toList();
    if (files.length < 2) return ['cp: missing destination operand'];
    final src = _resolvePath(files[0]);
    final dst = _resolvePath(files[1]);
    if (!fs.exists(src)) return ['cp: cannot stat \'${files[0]}\': No such file or directory'];
    final content = fs.readFile(src);
    if (content != null) {
      final finalDst = fs.isDir(dst) ? '$dst/${src.split('/').last}' : dst;
      fs.write(finalDst, content);
    }
    return [];
  }

  List<String> _mv(List<String> args) {
    final files = args.where((a) => !a.startsWith('-')).toList();
    if (files.length < 2) return ['mv: missing destination operand'];
    final src = _resolvePath(files[0]);
    final dst = _resolvePath(files[1]);
    if (!fs.exists(src)) return ['mv: cannot stat \'${files[0]}\': No such file or directory'];
    final finalDst = fs.isDir(dst) ? '$dst/${src.split('/').last}' : dst;
    fs.rename(src, finalDst);
    return [];
  }

  List<String> _head(List<String> args) {
    int n = 10;
    String? file;
    for (int i = 0; i < args.length; i++) {
      if (args[i] == '-n' && i + 1 < args.length) {
        n = int.tryParse(args[++i]) ?? 10;
      } else if (!args[i].startsWith('-')) {
        file = args[i];
      }
    }
    if (file == null) return ['head: missing operand'];
    final path = _resolvePath(file);
    final content = fs.readFile(path);
    if (content == null) return ['head: cannot open \'$file\': No such file or directory'];
    return content.split('\n').take(n).toList();
  }

  List<String> _tail(List<String> args) {
    int n = 10;
    String? file;
    for (int i = 0; i < args.length; i++) {
      if (args[i] == '-n' && i + 1 < args.length) {
        n = int.tryParse(args[++i]) ?? 10;
      } else if (!args[i].startsWith('-')) {
        file = args[i];
      }
    }
    if (file == null) return ['tail: missing operand'];
    final path = _resolvePath(file);
    final content = fs.readFile(path);
    if (content == null) return ['tail: cannot open \'$file\': No such file or directory'];
    final lines = content.split('\n');
    return lines.length > n ? lines.sublist(lines.length - n) : lines;
  }

  List<String> _wc(List<String> args) {
    final file = args.where((a) => !a.startsWith('-')).firstOrNull;
    if (file == null) return ['wc: missing operand'];
    final path = _resolvePath(file);
    final content = fs.readFile(path);
    if (content == null) return ['wc: $file: No such file or directory'];
    final lines = content.split('\n').length;
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final bytes = content.length;
    if (args.contains('-l')) return ['$lines $file'];
    if (args.contains('-w')) return ['$words $file'];
    if (args.contains('-c')) return ['$bytes $file'];
    return ['  $lines  $words  $bytes $file'];
  }

  List<String> _find(List<String> args) {
    String startPath = _cwd;
    String? namePattern;
    for (int i = 0; i < args.length; i++) {
      if (args[i] == '-name' && i + 1 < args.length) {
        namePattern = args[++i];
      } else if (!args[i].startsWith('-')) {
        startPath = _resolvePath(args[i]);
      }
    }
    return fs.find(startPath, name: namePattern);
  }

  List<String> _grep(List<String> args) {
    final recursive = args.contains('-r') || args.contains('-rn');
    final numbered = args.contains('-n') || args.contains('-rn');
    final positional = args.where((a) => !a.startsWith('-')).toList();
    if (positional.isEmpty) return ['grep: missing pattern'];
    final pattern = positional[0];
    final target = positional.length > 1 ? _resolvePath(positional[1]) : _cwd;
    try {
      final results = fs.grep(pattern, target, recursive: recursive);
      if (!numbered && !recursive) {
        return results.map((r) {
          final colonIdx = r.indexOf(':');
          return colonIdx > 0 ? r.substring(colonIdx + 1) : r;
        }).toList();
      }
      return results;
    } on FormatException catch (e) {
      return [e.message];
    }
  }


  List<String> _chmod(List<String> args) {
    if (args.length < 2) return ['chmod: missing operand'];
    return [];
  }

  List<String> _uname(List<String> args) {
    if (args.contains('-a')) return ['Linux t2decode 6.1.0-t2c #1 SMP PREEMPT_DYNAMIC x86_64 GNU/Linux'];
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
      final size = fs.isDir(fullPath) ? 4096 : (fs.readFile(fullPath) ?? '').length;
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
      final lines = <String>['USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND'];
      for (final p in _processes) {
        lines.add('${p.user.padRight(8)} ${p.pid.toString().padLeft(5)} ${p.cpu.toStringAsFixed(1).padLeft(4)} '
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
      lines.add('${p.pid.toString().padLeft(5)} ${p.user.padRight(8)}  20   0 ${p.vsz.toString().padLeft(7)} '
          '${p.rss.toString().padLeft(6)}  ${(p.rss ~/ 2).toString().padLeft(5)} ${p.stat.padRight(1)} '
          '${p.cpu.toStringAsFixed(1).padLeft(5)} ${p.mem.toStringAsFixed(1).padLeft(5)}   0:${(p.pid % 30).toString().padLeft(2, '0')} ${p.command}');
    }
    return lines;
  }

  List<String> _kill(List<String> args) {
    final pid = args.where((a) => !a.startsWith('-')).firstOrNull;
    if (pid == null) return ['kill: usage: kill [-s sigspec] pid'];
    final pidNum = int.tryParse(pid);
    if (pidNum == null) return ['bash: kill: $pid: arguments must be process IDs'];
    final idx = _processes.indexWhere((p) => p.pid == pidNum);
    if (idx < 0) return ['bash: kill: ($pid) - No such process'];
    _processes.removeAt(idx);
    return [];
  }

  List<String> _ping(List<String> args) {
    final target = args.where((a) => !a.startsWith('-')).firstOrNull;
    if (target == null) return ['ping: usage error: Destination address required'];
    final ip = _resolveHost(target);
    final lines = <String>['PING $target ($ip) 56(84) bytes of data.'];
    for (int i = 1; i <= 4; i++) {
      final time = 0.5 + _rng.nextDouble() * 50;
      lines.add('64 bytes from $ip: icmp_seq=$i ttl=64 time=${time.toStringAsFixed(3)} ms');
    }
    lines.add('');
    lines.add('--- $target ping statistics ---');
    lines.add('4 packets transmitted, 4 received, 0% packet loss');
    return lines;
  }

  String _resolveHost(String host) {
    if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(host)) return host;
    switch (host) {
      case 'localhost': return '127.0.0.1';
      case 'google.com': return '142.250.74.46';
      case 'github.com': return '140.82.121.4';
      case 'cloudflare.com': return '104.16.132.229';
      default:
        final hash = host.hashCode.abs();
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
    final lines = <String>['State    Recv-Q  Send-Q  Local Address:Port   Peer Address:Port'];
    lines.add('LISTEN   0       128     0.0.0.0:22            0.0.0.0:*');
    lines.add('LISTEN   0       128     0.0.0.0:80            0.0.0.0:*');
    lines.add('LISTEN   0       128     127.0.0.1:3306        0.0.0.0:*');
    lines.add('ESTAB    0       0       192.168.1.10:45678    142.250.74.46:443');
    lines.add('ESTAB    0       0       192.168.1.10:52341    140.82.121.4:443');
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
    final filename = url.split('/').last.isEmpty ? 'index.html' : url.split('/').last;
    fs.write('$_cwd/$filename', '<html><body>Simulated content for $url</body></html>');
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
    final domain = args.where((a) => !a.startsWith('-') && !a.startsWith('@')).firstOrNull ?? 'example.com';
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
    return {...defaults, ...env}.entries.map((e) => '${e.key}=${e.value}').toList();
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

  List<String> _history() => _commandHistory.asMap().entries.map((e) => '  ${e.key + 1}  ${e.value}').toList();

  List<String> _which(List<String> args) {
    if (args.isEmpty) return [];
    final cmd = args[0];
    if (fs.exists('/usr/bin/$cmd')) return ['/usr/bin/$cmd'];
    return ['which: no $cmd in PATH'];
  }

  List<String> _file(List<String> args) {
    if (args.isEmpty) return ['file: missing operand'];
    final path = _resolvePath(args[0]);
    if (!fs.exists(path)) return ['${args[0]}: cannot open (No such file or directory)'];
    if (fs.isDir(path)) return ['${args[0]}: directory'];
    final content = fs.readFile(path) ?? '';
    if (content.startsWith('ELF')) return ['${args[0]}: ELF 64-bit LSB executable, x86-64'];
    if (content.startsWith('#!')) return ['${args[0]}: Bourne-Again shell script, ASCII text executable'];
    if (content.startsWith('-----BEGIN')) return ['${args[0]}: PEM certificate'];
    return ['${args[0]}: ASCII text'];
  }

  List<String> _stat(List<String> args) {
    if (args.isEmpty) return ['stat: missing operand'];
    final path = _resolvePath(args[0]);
    if (!fs.exists(path)) return ['stat: cannot stat \'${args[0]}\': No such file or directory'];
    final isDir = fs.isDir(path);
    final size = isDir ? 4096 : (fs.readFile(path) ?? '').length;
    return [
      '  File: ${args[0]}',
      '  Size: $size\t\tBlocks: ${(size / 512).ceil()}\t\tIO Block: 4096\t${isDir ? 'directory' : 'regular file'}',
      'Access: (${isDir ? '0755/drwxr-xr-x' : '0644/-rw-r--r--'})\tUid: (1000/$_user)\tGid: (1000/$_user)',
      'Modify: 2025-06-12 08:00:00.000000000 +0000',
    ];
  }

  List<String> _sortCmd(List<String> args) {
    final file = args.where((a) => !a.startsWith('-')).firstOrNull;
    if (file == null) return ['sort: missing operand'];
    final path = _resolvePath(file);
    final content = fs.readFile(path);
    if (content == null) return ['sort: cannot read: $file: No such file or directory'];
    final lines = content.split('\n');
    if (args.contains('-r')) {
      lines.sort((a, b) => b.compareTo(a));
    } else {
      lines.sort();
    }
    return lines;
  }

  List<String> _uniqCmd(List<String> args) {
    final file = args.where((a) => !a.startsWith('-')).firstOrNull;
    if (file == null) return ['uniq: missing operand'];
    final path = _resolvePath(file);
    final content = fs.readFile(path);
    if (content == null) return ['uniq: $file: No such file or directory'];
    final lines = content.split('\n');
    final result = <String>[];
    for (final line in lines) {
      if (result.isEmpty || result.last != line) result.add(line);
    }
    return result;
  }

  List<String> _man(List<String> args) {
    if (args.isEmpty) return ['What manual page do you want?'];
    final cmd = args[0];
    final manPages = <String, List<String>>{
      'ls': ['LS(1)', '', 'NAME', '       ls - list directory contents', '', 'SYNOPSIS', '       ls [OPTION]... [FILE]...', '', 'OPTIONS', '       -a  do not ignore entries starting with .', '       -l  use a long listing format'],
      'grep': ['GREP(1)', '', 'NAME', '       grep - print lines matching a pattern', '', 'SYNOPSIS', '       grep [OPTIONS] PATTERN [FILE...]', '', 'OPTIONS', '       -r  recursive search', '       -n  print line numbers'],
      'chmod': ['CHMOD(1)', '', 'NAME', '       chmod - change file mode bits', '', 'SYNOPSIS', '       chmod [OPTION]... MODE[,MODE]... FILE...'],
      'find': ['FIND(1)', '', 'NAME', '       find - search for files', '', 'SYNOPSIS', '       find [path] [expression]', '', 'OPTIONS', '       -name pattern  match filename'],
      'ps': ['PS(1)', '', 'NAME', '       ps - report a snapshot of current processes', '', 'SYNOPSIS', '       ps [options]', '', 'OPTIONS', '       aux  show all processes with details'],
      'ip': ['IP(8)', '', 'NAME', '       ip - show / manipulate routing, network devices', '', 'SYNOPSIS', '       ip [ addr | route | link ]'],
    };
    return manPages[cmd] ?? ['No manual entry for $cmd'];
  }

  List<String> _help() => [
    'T2DECODE Virtual Shell — Commandes disponibles :',
    '',
    ' Fichiers     : ls, cd, pwd, cat, cp, mv, rm, mkdir, touch, find, chmod',
    '                head, tail, wc, sort, uniq, file, stat, tar',
    ' Texte        : echo, grep, cut (via pipe)',
    ' Système      : ps, top, kill, df, du, free, uname, uptime, date, cal',
    '                whoami, hostname, id, env, export, history, which, man',
    ' Réseau       : ping, traceroute, ip, ss, ifconfig, dig, nslookup',
    '                curl, wget, ssh, scp',
    ' Contrôle     : sudo, su, clear, exit',
    ' Pipes        : cmd1 | cmd2    Redirection : cmd > fichier',
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
    _VirtualProcess(1, 'root', 'systemd', 0.0, 0.3, 168832, 12400, '?', 'Ss'),
    _VirtualProcess(2, 'root', '[kthreadd]', 0.0, 0.0, 0, 0, '?', 'S'),
    _VirtualProcess(287, 'root', '/usr/sbin/sshd -D', 0.0, 0.1, 15832, 6800, '?', 'Ss'),
    _VirtualProcess(312, 'root', '/usr/sbin/cron -f', 0.0, 0.1, 8536, 3300, '?', 'Ss'),
    _VirtualProcess(401, 'root', '/usr/sbin/rsyslogd -n', 0.0, 0.2, 224400, 5200, '?', 'Ssl'),
    _VirtualProcess(455, 'mysql', '/usr/sbin/mysqld', 0.3, 2.1, 1823456, 172000, '?', 'Ssl'),
    _VirtualProcess(512, 'www-data', 'nginx: worker process', 0.1, 0.4, 46892, 8200, '?', 'S'),
    _VirtualProcess(513, 'www-data', 'nginx: worker process', 0.1, 0.4, 46900, 8300, '?', 'S'),
    _VirtualProcess(712, 'admin', '-bash', 0.0, 0.1, 23456, 5600, 'pts/0', 'Ss'),
    _VirtualProcess(1024, 'admin', 'python3 app.py', 1.2, 1.5, 345600, 42000, 'pts/0', 'S+'),
    _VirtualProcess(1100, 'root', '/usr/lib/ufw/ufw-init', 0.0, 0.0, 4280, 1200, '?', 'S'),
    _VirtualProcess(1150, 'admin', 'node server.js', 0.8, 1.8, 890000, 65000, 'pts/1', 'Sl'),
  ];
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

  _VirtualProcess(this.pid, this.user, this.command, this.cpu, this.mem, this.vsz, this.rss, this.tty, this.stat);
}
