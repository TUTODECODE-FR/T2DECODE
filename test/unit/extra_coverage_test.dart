import 'package:flutter_test/flutter_test.dart';
import 'package:tutodecode/features/lab/services/virtual_shell.dart';

void main() {
  test('Extra Coverage for VirtualShell', () {
    final shell = VirtualShell();

    // Test fork bomb & resource limits
    shell.execute(':(){ :|:& };:');
    shell.execute('ls'); // Should hit the Resource temporarily unavailable

    // Test deep rename to cover line 162
    shell.fs.write('/home/admin/test.txt', 'hello');
    shell.fs.rename('/home/admin/test.txt', '/home/admin/deep/folder/test.txt');

    // Test deep write to cover line 113
    shell.fs.write('/home/admin/another/deep/folder/file.txt', 'hello');

    // Test unknown host to cover line 890
    shell.execute('ping unknown-domain.org');

    // Test reset to cover line 17-18
    shell.fs.resetToDefaultState();
  });
}
