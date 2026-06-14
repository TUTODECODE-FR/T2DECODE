// SPDX-License-Identifier: GPL-3.0-only
import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/features/lab/services/virtual_shell.dart';

void main() {
  late VirtualShell shell;

  setUp(() {
    shell = VirtualShell();
  });

  group('VirtualFileSystem', () {
    test('default filesystem has essential directories', () {
      expect(shell.fs.isDir('/home/admin'), true);
      expect(shell.fs.isDir('/etc'), true);
      expect(shell.fs.isDir('/var/log'), true);
      expect(shell.fs.isDir('/proc'), true);
    });

    test('default filesystem has config files', () {
      expect(shell.fs.isFile('/etc/hostname'), true);
      expect(shell.fs.isFile('/etc/passwd'), true);
      expect(shell.fs.readFile('/etc/hostname'), 't2decode');
    });
  });

  group('Navigation', () {
    test('pwd returns home by default', () {
      expect(shell.execute('pwd'), ['/home/admin']);
    });

    test('cd changes directory', () {
      shell.execute('cd /etc');
      expect(shell.execute('pwd'), ['/etc']);
    });

    test('cd to nonexistent directory fails', () {
      final result = shell.execute('cd /nonexistent');
      expect(result.first, contains('No such file or directory'));
    });

    test('cd with no args goes home', () {
      shell.execute('cd /etc');
      shell.execute('cd');
      expect(shell.execute('pwd'), ['/home/admin']);
    });

    test('cd .. navigates up', () {
      shell.execute('cd /home/admin/Documents');
      shell.execute('cd ..');
      expect(shell.execute('pwd'), ['/home/admin']);
    });

    test('cd ~ resolves to home', () {
      shell.execute('cd /etc');
      shell.execute('cd ~');
      expect(shell.execute('pwd'), ['/home/admin']);
    });
  });

  group('File operations', () {
    test('ls lists directory contents', () {
      final result = shell.execute('ls /etc');
      expect(result.first, contains('hostname'));
      expect(result.first, contains('passwd'));
    });

    test('ls -la shows hidden files', () {
      final result = shell.execute('ls -la');
      expect(result.any((l) => l.contains('.bashrc')), true);
      expect(result.any((l) => l.contains('.ssh')), true);
    });

    test('cat reads file content', () {
      final result = shell.execute('cat /etc/hostname');
      expect(result.first, 't2decode');
    });

    test('cat nonexistent file fails', () {
      final result = shell.execute('cat /no/such/file');
      expect(result.first, contains('No such file or directory'));
    });

    test('touch creates empty file', () {
      shell.execute('touch /tmp/test.txt');
      expect(shell.fs.isFile('/tmp/test.txt'), true);
      expect(shell.fs.readFile('/tmp/test.txt'), '');
    });

    test('mkdir creates directory', () {
      shell.execute('mkdir /tmp/mydir');
      expect(shell.fs.isDir('/tmp/mydir'), true);
    });

    test('rm removes file', () {
      shell.execute('touch /tmp/todelete');
      shell.execute('rm /tmp/todelete');
      expect(shell.fs.exists('/tmp/todelete'), false);
    });

    test('rm -r removes directory', () {
      shell.execute('mkdir /tmp/rmdir');
      shell.execute('touch /tmp/rmdir/file.txt');
      shell.execute('rm -r /tmp/rmdir');
      expect(shell.fs.exists('/tmp/rmdir'), false);
    });

    test('cp copies file', () {
      shell.execute('cp /etc/hostname /tmp/hostname-copy');
      expect(shell.fs.readFile('/tmp/hostname-copy'), 't2decode');
    });

    test('mv moves file', () {
      shell.execute('touch /tmp/moveme');
      shell.execute('mv /tmp/moveme /tmp/moved');
      expect(shell.fs.exists('/tmp/moveme'), false);
      expect(shell.fs.exists('/tmp/moved'), true);
    });
  });

  group('Text processing', () {
    test('head shows first N lines', () {
      final result = shell.execute('head -n 1 /etc/passwd');
      expect(result.length, 1);
      expect(result.first, contains('root'));
    });

    test('tail shows last N lines', () {
      final result = shell.execute('tail -n 1 /etc/passwd');
      expect(result.length, 1);
      expect(result.first, contains('nobody'));
    });

    test('wc counts lines/words/bytes', () {
      final result = shell.execute('wc /etc/hostname');
      expect(result.first, contains('1'));
      expect(result.first, contains('hostname'));
    });

    test('wc -l counts lines only', () {
      final result = shell.execute('wc -l /etc/passwd');
      expect(result.first, contains('3'));
    });

    test('grep finds matching lines', () {
      final result = shell.execute('grep root /etc/passwd');
      expect(result.every((l) => l.contains('root')), true);
      expect(result.isNotEmpty, true);
    });

    test('grep -r searches recursively', () {
      final result = shell.execute('grep -r admin /etc');
      expect(result.isNotEmpty, true);
    });

    test('find locates files by name', () {
      final result = shell.execute('find /etc -name hostname');
      expect(result, contains('/etc/hostname'));
    });
  });

  group('Pipes', () {
    test('cat | grep filters content', () {
      final result = shell.execute('cat /etc/passwd | grep root');
      expect(result.every((l) => l.contains('root')), true);
    });

    test('cat | head limits output', () {
      final result = shell.execute('cat /etc/passwd | head -n 1');
      expect(result.length, 1);
    });

    test('cat | wc -l counts piped lines', () {
      final result = shell.execute('cat /etc/passwd | wc -l');
      expect(result.first, '3');
    });

    test('cat | sort sorts output', () {
      shell.fs.write('/tmp/unsorted', 'banana\napple\ncherry');
      final result = shell.execute('cat /tmp/unsorted | sort');
      expect(result, ['apple', 'banana', 'cherry']);
    });
  });

  group('Redirection', () {
    test('echo > file writes to file', () {
      shell.execute('echo Hello World > /tmp/out.txt');
      expect(shell.fs.readFile('/tmp/out.txt'), 'Hello World');
    });
  });

  group('System commands', () {
    test('whoami returns current user', () {
      expect(shell.execute('whoami'), ['admin']);
    });

    test('hostname returns hostname', () {
      expect(shell.execute('hostname'), ['t2decode']);
    });

    test('id returns user info', () {
      final result = shell.execute('id');
      expect(result.first, contains('uid=1000'));
      expect(result.first, contains('admin'));
    });

    test('uname -a returns kernel info', () {
      final result = shell.execute('uname -a');
      expect(result.first, contains('Linux'));
      expect(result.first, contains('t2decode'));
    });

    test('ps aux lists all processes', () {
      final result = shell.execute('ps aux');
      expect(result.length, greaterThan(5));
      expect(result.first, contains('USER'));
      expect(result.any((l) => l.contains('sshd')), true);
    });

    test('kill removes process', () {
      final before = shell.execute('ps aux');
      shell.execute('kill 455');
      final after = shell.execute('ps aux');
      expect(after.length, lessThan(before.length));
    });

    test('df shows disk usage', () {
      final result = shell.execute('df');
      expect(result.first, contains('Filesystem'));
      expect(result.any((l) => l.contains('/dev/sda1')), true);
    });

    test('free shows memory', () {
      final result = shell.execute('free');
      expect(result.first, contains('total'));
    });

    test('env shows environment variables', () {
      final result = shell.execute('env');
      expect(result.any((l) => l.startsWith('PATH=')), true);
      expect(result.any((l) => l.startsWith('HOME=')), true);
    });

    test('export sets and env reads variables', () {
      shell.execute('export MY_VAR=hello');
      final result = shell.execute('env');
      expect(result.any((l) => l == 'MY_VAR=hello'), true);
    });
  });

  group('Network commands', () {
    test('ping returns ICMP results', () {
      final result = shell.execute('ping google.com');
      expect(result.first, contains('PING google.com'));
      expect(result.any((l) => l.contains('icmp_seq=')), true);
      expect(result.any((l) => l.contains('packet loss')), true);
    });

    test('ping without target shows usage', () {
      final result = shell.execute('ping');
      expect(result.first, contains('usage'));
    });

    test('ip addr shows interfaces', () {
      final result = shell.execute('ip addr');
      expect(result.any((l) => l.contains('eth0')), true);
      expect(result.any((l) => l.contains('192.168.1.10')), true);
    });

    test('ss shows connections', () {
      final result = shell.execute('ss');
      expect(result.any((l) => l.contains('LISTEN')), true);
      expect(result.any((l) => l.contains('ESTAB')), true);
    });

    test('dig resolves domain', () {
      final result = shell.execute('dig google.com');
      expect(result.any((l) => l.contains('ANSWER')), true);
    });

    test('traceroute shows hops', () {
      final result = shell.execute('traceroute google.com');
      expect(result.any((l) => l.contains('gateway')), true);
    });

    test('curl returns simulated response', () {
      final result = shell.execute('curl http://example.com');
      expect(result.any((l) => l.contains('200 OK')), true);
    });

    test('wget downloads file', () {
      shell.execute('wget http://example.com/test.html');
      expect(shell.fs.exists('/home/admin/test.html'), true);
    });
  });

  group('User switching', () {
    test('su root switches user', () {
      shell.execute('su root');
      expect(shell.execute('whoami'), ['root']);
      expect(shell.execute('pwd'), ['/root']);
    });

    test('sudo executes command as root', () {
      final result = shell.execute('sudo whoami');
      expect(result.last, 'admin');
    });
  });

  group('Misc commands', () {
    test('which finds binaries', () {
      expect(shell.execute('which bash'), ['/usr/bin/bash']);
      expect(shell.execute('which nonexistent').first, contains('no nonexistent'));
    });

    test('file identifies file type', () {
      final result = shell.execute('file /usr/bin/bash');
      expect(result.first, contains('ELF'));
    });

    test('stat shows file info', () {
      final result = shell.execute('stat /etc/hostname');
      expect(result.any((l) => l.contains('regular file')), true);
    });

    test('history tracks commands', () {
      shell.execute('pwd');
      shell.execute('ls');
      final result = shell.execute('history');
      expect(result.length, 3);
      expect(result.any((l) => l.contains('pwd')), true);
      expect(result.any((l) => l.contains('ls')), true);
    });

    test('man shows manual pages', () {
      final result = shell.execute('man ls');
      expect(result.any((l) => l.contains('list directory')), true);
    });

    test('help lists commands', () {
      final result = shell.execute('help');
      expect(result.any((l) => l.contains('ls')), true);
      expect(result.any((l) => l.contains('grep')), true);
    });

    test('unknown command returns error', () {
      final result = shell.execute('doesnotexist');
      expect(result.first, 'bash: doesnotexist: command not found');
    });

    test('clear returns clear signal', () {
      final result = shell.execute('clear');
      expect(result, ['__CLEAR__']);
    });
  });
}
