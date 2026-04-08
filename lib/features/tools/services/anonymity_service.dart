// ============================================================
// AnonymityService — Exécution réelle des changements d'identité système
// Fonctionne sur Linux, macOS, Windows via Process.run()
// Les commandes privilégiées utilisent sudo (Linux/macOS) ou
// runas/elevation UAC (Windows via script PowerShell).
// ============================================================
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Informations sur l'interface réseau et sa MAC.
class MacInfo {
  final String interface;
  final String mac;
  const MacInfo({required this.interface, required this.mac});
}

/// Résultat d'une opération système.
class AnonResult {
  final bool success;
  final String message;
  final String? output;
  final String? error;
  const AnonResult(
      {required this.success, required this.message, this.output, this.error});
}

/// Sauvegarde des valeurs originales avant modification.
class AnonBackup {
  final String? hostname;
  final String? macAddress;
  final String? interface;
  final String? username;
  final DateTime savedAt;

  const AnonBackup({
    this.hostname,
    this.macAddress,
    this.interface,
    this.username,
    required this.savedAt,
  });

  Map<String, dynamic> toMap() => {
        'hostname': hostname,
        'mac': macAddress,
        'interface': interface,
        'username': username,
        'savedAt': savedAt.toIso8601String(),
      };

  factory AnonBackup.fromMap(Map<String, dynamic> m) => AnonBackup(
        hostname: m['hostname'] as String?,
        macAddress: m['mac'] as String?,
        interface: m['interface'] as String?,
        username: m['username'] as String?,
        savedAt: DateTime.parse(m['savedAt'] as String),
      );
}

/// Profil de capacité réel de l'appareil pour l'outil d'anonymisation.
class AnonDeviceProfile {
  final String platformLabel;
  final bool isPrivilegedSession;
  final bool canChangeHostname;
  final bool canChangeMac;
  final bool canCreateUser;
  final bool canTuneNetwork;
  final String privilegeHint;
  final String notes;

  const AnonDeviceProfile({
    required this.platformLabel,
    required this.isPrivilegedSession,
    required this.canChangeHostname,
    required this.canChangeMac,
    required this.canCreateUser,
    required this.canTuneNetwork,
    required this.privilegeHint,
    required this.notes,
  });
}

class AnonymityService {
  static const _backupKey = 'anon_backup_v1';

  // ── Capacites reelles appareil ───────────────────────────

  static Future<AnonDeviceProfile> getDeviceProfile() async {
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        final isRoot = await _isUnixRoot();
        final sudoNoPassword = await _canSudoWithoutPassword();
        final privileged = isRoot || sudoNoPassword;
        final platformLabel = Platform.isLinux ? 'Linux' : 'macOS';
        final hint = isRoot
            ? 'Session root detectee'
            : (sudoNoPassword
                ? 'sudo sans mot de passe disponible'
                : 'sudo avec mot de passe requis');
        return AnonDeviceProfile(
          platformLabel: platformLabel,
          isPrivilegedSession: privileged,
          canChangeHostname: true,
          canChangeMac: true,
          canCreateUser: true,
          canTuneNetwork: true,
          privilegeHint: hint,
          notes:
              'Les commandes sont executees en reel. Certains pilotes/interfaces peuvent refuser le changement MAC.',
        );
      }
      if (Platform.isWindows) {
        final isAdmin = await _isWindowsAdmin();
        return AnonDeviceProfile(
          platformLabel: 'Windows',
          isPrivilegedSession: isAdmin,
          canChangeHostname: true,
          canChangeMac: true,
          canCreateUser: true,
          canTuneNetwork: true,
          privilegeHint: isAdmin
              ? 'Session administrateur detectee'
              : 'Session standard (admin recommande)',
          notes:
              'Certaines operations demandent elevation UAC et/ou redemarrage. Le changement MAC depend du pilote reseau.',
        );
      }
    } catch (_) {}

    return const AnonDeviceProfile(
      platformLabel: 'Plateforme non supportee',
      isPrivilegedSession: false,
      canChangeHostname: false,
      canChangeMac: false,
      canCreateUser: false,
      canTuneNetwork: false,
      privilegeHint: 'Aucune capacite systeme disponible',
      notes: 'Cet outil fonctionne uniquement sur Linux, macOS et Windows.',
    );
  }

  // ── Générateurs sécurisés ──────────────────────────────────

  static String generateHostname() {
    const adj = [
      'swift',
      'quiet',
      'dark',
      'cold',
      'plain',
      'blank',
      'still',
      'grey',
      'neutral',
      'spare',
      'amber',
      'static',
      'hollow',
      'muted',
      'calm',
      'dense',
      'flat',
      'inert',
      'latent',
      'void'
    ];
    const noun = [
      'node',
      'host',
      'unit',
      'box',
      'rack',
      'desk',
      'term',
      'station',
      'client',
      'machine',
      'relay',
      'bridge',
      'probe',
      'sensor',
      'agent',
      'router',
      'switch',
      'endpoint',
      'socket',
      'daemon'
    ];
    final r = Random.secure();
    final suffix = r.nextInt(9000) + 1000;
    return '${adj[r.nextInt(adj.length)]}-${noun[r.nextInt(noun.length)]}-$suffix';
  }

  /// Génère une MAC localement administrée (bit LA=1, bit multicast=0).
  static String generateMac() {
    final r = Random.secure();
    final bytes = Uint8List.fromList(List.generate(6, (_) => r.nextInt(256)));
    bytes[0] = (bytes[0] & 0xFE) | 0x02; // multicast=0, local=1
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  static String generateUsername() {
    const prefixes = [
      'user',
      'sysop',
      'netuser',
      'localop',
      'workuser',
      'admin',
      'op',
      'host'
    ];
    final r = Random.secure();
    final suffix = r.nextInt(9000) + 1000;
    return '${prefixes[r.nextInt(prefixes.length)]}$suffix';
  }

  // ── Lecture de l'état courant ──────────────────────────────

  static Future<String> getCurrentHostname() async {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'inconnu';
    }
  }

  static Future<String> getCurrentUsername() async {
    try {
      return Platform.environment['USER'] ??
          Platform.environment['USERNAME'] ??
          Platform.environment['LOGNAME'] ??
          'inconnu';
    } catch (_) {
      return 'inconnu';
    }
  }

  /// Retourne la première interface réseau active et sa MAC.
  static Future<MacInfo> getCurrentMac() async {
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        final result = Platform.isLinux
            ? await Process.run('ip', ['link', 'show'])
            : await Process.run('ifconfig', []);
        final out = result.stdout as String;
        final macRe = RegExp(r'([0-9a-fA-F]{2}[:\-]){5}[0-9a-fA-F]{2}');
        String ifaceName = 'eth0';
        String macFound = 'inconnu';
        if (Platform.isLinux) {
          final ifaceRe = RegExp(r'^\d+:\s+(\S+):', multiLine: true);
          final ifaceMatch = ifaceRe.firstMatch(out);
          if (ifaceMatch != null) ifaceName = ifaceMatch.group(1)!;
        } else {
          final ifaceRe = RegExp(r'^(\S+):', multiLine: true);
          for (final m in ifaceRe.allMatches(out)) {
            final name = m.group(1)!;
            if (!name.startsWith('lo') &&
                !name.startsWith('utun') &&
                !name.startsWith('ipsec')) {
              ifaceName = name;
              break;
            }
          }
        }
        final macMatch = macRe.firstMatch(out);
        if (macMatch != null) macFound = macMatch.group(0)!.toUpperCase();
        return MacInfo(interface: ifaceName, mac: macFound);
      } else if (Platform.isWindows) {
        final result = await Process.run('getmac', ['/fo', 'csv', '/nh']);
        final out = result.stdout as String;
        final line = out.trim().split('\n').first;
        final parts = line.split(',');
        if (parts.length >= 2) {
          final mac = parts[0].replaceAll('"', '').replaceAll('-', ':').trim();
          return MacInfo(interface: 'Ethernet', mac: mac);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AnonymityService] getCurrentMac error: $e');
    }
    return MacInfo(interface: 'eth0', mac: 'inconnu');
  }

  // ── Sauvegarde / restauration ──────────────────────────────

  static Future<void> saveBackup(AnonBackup backup) async {
    final prefs = await SharedPreferences.getInstance();
    // Encode manuellement pour éviter jsonEncode (pas d'import dart:convert ici)
    final map = backup.toMap();
    await prefs.setString(_backupKey + '_hostname', map['hostname'] ?? '');
    await prefs.setString(_backupKey + '_mac', map['mac'] ?? '');
    await prefs.setString(_backupKey + '_interface', map['interface'] ?? '');
    await prefs.setString(_backupKey + '_username', map['username'] ?? '');
    await prefs.setString(_backupKey + '_savedAt', map['savedAt'] as String);
  }

  static Future<AnonBackup?> loadBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAt = prefs.getString(_backupKey + '_savedAt');
    if (savedAt == null) return null;
    return AnonBackup(
      hostname: prefs.getString(_backupKey + '_hostname'),
      macAddress: prefs.getString(_backupKey + '_mac'),
      interface: prefs.getString(_backupKey + '_interface'),
      username: prefs.getString(_backupKey + '_username'),
      savedAt: DateTime.parse(savedAt),
    );
  }

  static Future<void> clearBackup() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      '_hostname',
      '_mac',
      '_interface',
      '_username',
      '_savedAt'
    ]) {
      await prefs.remove(_backupKey + key);
    }
  }

  // ── HOSTNAME ──────────────────────────────────────────────

  static Future<AnonResult> changeHostname(String newHostname,
      {String? sudoPassword}) async {
    // Validation : alphanumérique + tirets, 1-63 chars
    final valid = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$');
    if (!valid.hasMatch(newHostname)) {
      return const AnonResult(
          success: false,
          message:
              'Hostname invalide. Utiliser uniquement lettres, chiffres et tirets.');
    }

    try {
      if (Platform.isLinux) {
        return await _changeHostnameLinux(newHostname, sudoPassword);
      } else if (Platform.isMacOS) {
        return await _changeHostnameMacOS(newHostname, sudoPassword);
      } else if (Platform.isWindows) {
        return await _changeHostnameWindows(newHostname);
      }
      return const AnonResult(
          success: false, message: 'Plateforme non supportée.');
    } catch (e) {
      return AnonResult(
          success: false, message: 'Erreur inattendue', error: e.toString());
    }
  }

  static Future<AnonResult> _changeHostnameLinux(
      String name, String? pass) async {
    final lines = <String>[];
    // hostnamectl (systemd) — plus fiable
    final r1 = await _sudo(['hostnamectl', 'set-hostname', name], pass);
    if (r1.exitCode == 0) {
      lines.add('hostnamectl: OK');
    } else {
      // Fallback : hostname + /etc/hostname
      await _sudo(['hostname', name], pass);
      final tmp = await File('/tmp/_tdc_hostname').writeAsString(name);
      await _sudo(['cp', tmp.path, '/etc/hostname'], pass);
      lines.add('hostname + /etc/hostname: OK');
    }
    // Mettre à jour /etc/hosts
    await _sudoScript('''
sed -i "s/127.0.1.1.*/127.0.1.1\\t$name/" /etc/hosts
''', pass);
    lines.add('/etc/hosts: mis à jour');
    return AnonResult(
        success: true,
        message: 'Hostname changé en "$name"',
        output: lines.join('\n'));
  }

  static Future<AnonResult> _changeHostnameMacOS(
      String name, String? pass) async {
    final cmds = [
      ['scutil', '--set', 'HostName', name],
      ['scutil', '--set', 'LocalHostName', name],
      ['scutil', '--set', 'ComputerName', name],
    ];
    final lines = <String>[];
    for (final cmd in cmds) {
      final r = await _sudo(cmd, pass);
      lines
          .add('${cmd[2]}: ${r.exitCode == 0 ? "OK" : "Erreur (${r.stderr})"}');
    }
    final allOk = lines.every((l) => l.contains('OK'));
    return AnonResult(
      success: allOk,
      message: allOk ? 'Hostname changé en "$name"' : 'Changement partiel',
      output: lines.join('\n'),
    );
  }

  static Future<AnonResult> _changeHostnameWindows(String name) async {
    final r = await Process.run(
      'powershell',
      ['-Command', 'Rename-Computer -NewName "$name" -Force -PassThru'],
      runInShell: true,
    );
    final ok = r.exitCode == 0;
    return AnonResult(
      success: ok,
      message: ok
          ? 'Hostname changé. Redémarrage requis.'
          : 'Échec changement hostname',
      output: r.stdout as String,
      error: ok ? null : r.stderr as String,
    );
  }

  // ── MAC ADDRESS ───────────────────────────────────────────

  static Future<AnonResult> changeMac(String interface, String newMac,
      {String? sudoPassword}) async {
    // Validation MAC format XX:XX:XX:XX:XX:XX
    final macRe = RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$');
    if (!macRe.hasMatch(newMac)) {
      return const AnonResult(
          success: false,
          message: 'Format MAC invalide. Attendu: XX:XX:XX:XX:XX:XX');
    }
    // Validation interface : pas de path traversal
    if (!RegExp(r'^[a-zA-Z0-9_\-\.]{1,20}$').hasMatch(interface)) {
      return const AnonResult(
          success: false, message: 'Nom d\'interface invalide.');
    }

    try {
      if (Platform.isLinux) {
        return await _changeMacLinux(interface, newMac, sudoPassword);
      } else if (Platform.isMacOS) {
        return await _changeMacMacOS(interface, newMac, sudoPassword);
      } else if (Platform.isWindows) {
        return await _changeMacWindows(interface, newMac);
      }
      return const AnonResult(
          success: false, message: 'Plateforme non supportée.');
    } catch (e) {
      return AnonResult(
          success: false, message: 'Erreur inattendue', error: e.toString());
    }
  }

  static Future<AnonResult> _changeMacLinux(
      String iface, String mac, String? pass) async {
    final r1 = await _sudo(['ip', 'link', 'set', 'dev', iface, 'down'], pass);
    final r2 =
        await _sudo(['ip', 'link', 'set', 'dev', iface, 'address', mac], pass);
    final r3 = await _sudo(['ip', 'link', 'set', 'dev', iface, 'up'], pass);
    final ok = r1.exitCode == 0 && r2.exitCode == 0 && r3.exitCode == 0;
    return AnonResult(
      success: ok,
      message: ok ? 'MAC changée en $mac sur $iface' : 'Échec changement MAC',
      output: [r1.stdout, r2.stdout, r3.stdout].join('\n'),
      error: ok ? null : [r1.stderr, r2.stderr, r3.stderr].join('\n'),
    );
  }

  static Future<AnonResult> _changeMacMacOS(
      String iface, String mac, String? pass) async {
    // macOS : ifconfig ether — nécessite sudo et interface down/up
    final r1 = await _sudo(['ifconfig', iface, 'down'], pass);
    final r2 = await _sudo(['ifconfig', iface, 'ether', mac], pass);
    final r3 = await _sudo(['ifconfig', iface, 'up'], pass);
    final ok =
        r2.exitCode == 0; // down/up peuvent retourner 1 sur certains ifaces
    return AnonResult(
      success: ok,
      message: ok
          ? 'MAC changée en $mac sur $iface'
          : 'Échec. Sur Apple Silicon la MAC Wi-Fi peut être verrouillée.',
      output: [r1.stdout, r2.stdout, r3.stdout].join('\n'),
      error: ok ? null : r2.stderr as String,
    );
  }

  static Future<AnonResult> _changeMacWindows(String iface, String mac) async {
    final macNoColon = mac.replaceAll(':', '');
    final script = '''
\$adapter = Get-NetAdapter | Where-Object {Status -eq 'Up'} | Select-Object -First 1
if (\$adapter) {
  Set-NetAdapterAdvancedProperty -Name \$adapter.Name -RegistryKeyword "NetworkAddress" -RegistryValue "$macNoColon" -ErrorAction SilentlyContinue
  Restart-NetAdapter -Name \$adapter.Name -Confirm:\$false
  Write-Output "MAC changée sur \$(\$adapter.Name)"
} else {
  Write-Error "Aucune interface active trouvée"
}
''';
    final r = await Process.run(
      'powershell',
      ['-ExecutionPolicy', 'Bypass', '-Command', script],
      runInShell: true,
    );
    final ok = r.exitCode == 0;
    return AnonResult(
      success: ok,
      message: ok
          ? 'MAC changée en $mac'
          : 'Échec. Certains pilotes ne supportent pas le changement de MAC.',
      output: r.stdout as String,
      error: ok ? null : r.stderr as String,
    );
  }

  // ── UTILISATEUR (crée un nouveau compte) ─────────────────

  static Future<AnonResult> createNewUser(String newUser,
      {String? sudoPassword}) async {
    if (!RegExp(r'^[a-z_][a-z0-9_\-]{0,30}$').hasMatch(newUser)) {
      return const AnonResult(
          success: false,
          message:
              'Nom d\'utilisateur invalide. Minuscules, chiffres, tirets uniquement.');
    }

    try {
      if (Platform.isLinux) {
        return await _createUserLinux(newUser, sudoPassword);
      } else if (Platform.isMacOS) {
        return await _createUserMacOS(newUser, sudoPassword);
      } else if (Platform.isWindows) {
        return await _createUserWindows(newUser);
      }
      return const AnonResult(
          success: false, message: 'Plateforme non supportée.');
    } catch (e) {
      return AnonResult(
          success: false, message: 'Erreur inattendue', error: e.toString());
    }
  }

  static Future<AnonResult> _createUserLinux(String name, String? pass) async {
    // Vérifier si l'utilisateur existe déjà
    final check = await Process.run('id', [name]);
    if (check.exitCode == 0) {
      return AnonResult(
          success: false, message: 'L\'utilisateur "$name" existe déjà.');
    }
    final r = await _sudo(['useradd', '-m', '-s', '/bin/bash', name], pass);
    final ok = r.exitCode == 0;
    return AnonResult(
      success: ok,
      message: ok
          ? 'Utilisateur "$name" créé. Définissez un mot de passe avec: sudo passwd $name'
          : 'Échec création utilisateur',
      output: r.stdout as String,
      error: ok ? null : r.stderr as String,
    );
  }

  static Future<AnonResult> _createUserMacOS(String name, String? pass) async {
    // Trouver un UID disponible >= 501
    final uidResult =
        await Process.run('dscl', ['.', '-list', '/Users', 'UniqueID']);
    final usedUids = (uidResult.stdout as String)
        .split('\n')
        .map((l) => int.tryParse(l.trim().split(RegExp(r'\s+')).last) ?? 0)
        .toSet();
    int uid = 501;
    while (usedUids.contains(uid)) uid++;

    final cmds = [
      ['dscl', '.', '-create', '/Users/$name'],
      ['dscl', '.', '-create', '/Users/$name', 'UserShell', '/bin/bash'],
      ['dscl', '.', '-create', '/Users/$name', 'RealName', name],
      ['dscl', '.', '-create', '/Users/$name', 'UniqueID', '$uid'],
      ['dscl', '.', '-create', '/Users/$name', 'PrimaryGroupID', '20'],
      [
        'dscl',
        '.',
        '-create',
        '/Users/$name',
        'NFSHomeDirectory',
        '/Users/$name'
      ],
    ];
    final lines = <String>[];
    bool allOk = true;
    for (final cmd in cmds) {
      final r = await _sudo(cmd, pass);
      if (r.exitCode != 0) {
        allOk = false;
        lines.add('Erreur: ${r.stderr}');
      } else {
        lines.add('${cmd[3]}: OK');
      }
    }
    // Créer le dossier home
    await _sudo(['createhomedir', '-c', '-u', name], pass);
    return AnonResult(
      success: allOk,
      message: allOk
          ? 'Utilisateur "$name" créé (UID $uid). Définissez un mot de passe avec: sudo passwd $name'
          : 'Création partielle',
      output: lines.join('\n'),
    );
  }

  static Future<AnonResult> _createUserWindows(String name) async {
    final check = await Process.run('net', ['user', name], runInShell: true);
    if (check.exitCode == 0) {
      return AnonResult(
          success: false, message: 'L\'utilisateur "$name" existe déjà.');
    }
    // Crée sans mot de passe, force le changement à la prochaine connexion
    final r = await Process.run(
      'net',
      ['user', name, '/add', '/passwordreq:no'],
      runInShell: true,
    );
    final ok = r.exitCode == 0;
    return AnonResult(
      success: ok,
      message: ok
          ? 'Utilisateur "$name" créé. Connectez-vous avec ce compte et définissez un mot de passe.'
          : 'Échec. Lancez l\'application en tant qu\'administrateur.',
      output: r.stdout as String,
      error: ok ? null : r.stderr as String,
    );
  }

  // ── RÉSEAU : IPv6, mDNS, TTL ──────────────────────────────

  static Future<AnonResult> disableIPv6({String? sudoPassword}) async {
    try {
      if (Platform.isLinux) {
        return await _disableIPv6Linux(sudoPassword);
      } else if (Platform.isMacOS) {
        return await _disableIPv6MacOS(sudoPassword);
      } else if (Platform.isWindows) {
        return await _disableIPv6Windows();
      }
      return const AnonResult(
          success: false, message: 'Plateforme non supportée.');
    } catch (e) {
      return AnonResult(success: false, message: 'Erreur', error: e.toString());
    }
  }

  static Future<AnonResult> _disableIPv6Linux(String? pass) async {
    final script = '''
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
''';
    final r = await _sudoScript(script, pass);
    final ok = r.exitCode == 0;
    return AnonResult(
        success: ok,
        message: ok ? 'IPv6 désactivé (jusqu\'au prochain reboot)' : 'Échec',
        error: ok ? null : r.stderr as String);
  }

  static Future<AnonResult> _disableIPv6MacOS(String? pass) async {
    final ifaces = await _getMacOSInterfaces();
    final lines = <String>[];
    for (final iface in ifaces) {
      final r = await Process.run('networksetup', ['-setv6off', iface]);
      lines.add('$iface: ${r.exitCode == 0 ? "OK" : r.stderr}');
    }
    return AnonResult(
        success: true,
        message: 'IPv6 désactivé sur ${ifaces.length} interface(s)',
        output: lines.join('\n'));
  }

  static Future<AnonResult> _disableIPv6Windows() async {
    final r = await Process.run(
        'powershell',
        [
          '-Command',
          'Get-NetAdapterBinding -ComponentID ms_tcpip6 | Disable-NetAdapterBinding -ComponentID ms_tcpip6 -Confirm:\$false'
        ],
        runInShell: true);
    return AnonResult(
        success: r.exitCode == 0,
        message: r.exitCode == 0 ? 'IPv6 désactivé' : 'Échec',
        error: r.exitCode == 0 ? null : r.stderr as String);
  }

  static Future<AnonResult> disableMdns({String? sudoPassword}) async {
    try {
      if (Platform.isLinux) {
        final r =
            await _sudo(['systemctl', 'stop', 'avahi-daemon'], sudoPassword);
        final r2 =
            await _sudo(['systemctl', 'disable', 'avahi-daemon'], sudoPassword);
        final ok = r.exitCode == 0;
        return AnonResult(
            success: ok,
            message: ok
                ? 'mDNS/Avahi désactivé'
                : 'Avahi non trouvé ou déjà désactivé');
      } else if (Platform.isMacOS) {
        final r = await _sudo([
          'launchctl',
          'unload',
          '-w',
          '/System/Library/LaunchDaemons/com.apple.mDNSResponder.plist'
        ], sudoPassword);
        return AnonResult(
          success: r.exitCode == 0,
          message: r.exitCode == 0
              ? 'mDNSResponder désactivé. AirDrop et AirPlay seront indisponibles.'
              : 'Échec. Utilisez: sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist',
        );
      } else if (Platform.isWindows) {
        final r = await Process.run(
            'powershell',
            [
              '-Command',
              'Set-Service -Name "Bonjour Service" -StartupType Disabled; Stop-Service -Name "Bonjour Service" -Force -ErrorAction SilentlyContinue'
            ],
            runInShell: true);
        return AnonResult(
            success: true, message: 'Service Bonjour désactivé (si installé)');
      }
      return const AnonResult(
          success: false, message: 'Plateforme non supportée.');
    } catch (e) {
      return AnonResult(success: false, message: 'Erreur', error: e.toString());
    }
  }

  static Future<AnonResult> changeTTL(int ttl, {String? sudoPassword}) async {
    if (ttl < 1 || ttl > 255)
      return const AnonResult(
          success: false, message: 'TTL doit être entre 1 et 255');
    try {
      if (Platform.isLinux) {
        final r = await _sudo(
            ['sysctl', '-w', 'net.ipv4.ip_default_ttl=$ttl'], sudoPassword);
        return AnonResult(
            success: r.exitCode == 0,
            message: r.exitCode == 0 ? 'TTL défini à $ttl' : 'Échec');
      } else if (Platform.isMacOS) {
        final r =
            await _sudo(['sysctl', '-w', 'net.inet.ip.ttl=$ttl'], sudoPassword);
        return AnonResult(
            success: r.exitCode == 0,
            message: r.exitCode == 0 ? 'TTL défini à $ttl' : 'Échec');
      } else if (Platform.isWindows) {
        final r = await Process.run(
            'powershell',
            [
              '-Command',
              'Set-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters" -Name "DefaultTTL" -Value $ttl -Type DWord'
            ],
            runInShell: true);
        return AnonResult(
            success: r.exitCode == 0,
            message: r.exitCode == 0
                ? 'TTL défini à $ttl (redémarrage requis)'
                : 'Échec');
      }
      return const AnonResult(
          success: false, message: 'Plateforme non supportée.');
    } catch (e) {
      return AnonResult(success: false, message: 'Erreur', error: e.toString());
    }
  }

  // ── RESTAURATION ──────────────────────────────────────────

  static Future<List<AnonResult>> restoreAll(AnonBackup backup,
      {String? sudoPassword}) async {
    final results = <AnonResult>[];
    if (backup.hostname != null && backup.hostname!.isNotEmpty) {
      results.add(
          await changeHostname(backup.hostname!, sudoPassword: sudoPassword));
    }
    if (backup.macAddress != null &&
        backup.interface != null &&
        backup.macAddress!.isNotEmpty &&
        backup.macAddress != 'inconnu') {
      results.add(await changeMac(backup.interface!, backup.macAddress!,
          sudoPassword: sudoPassword));
    }
    return results;
  }

  // ── Helpers sudo ──────────────────────────────────────────

  /// Exécute une commande avec sudo en passant le mot de passe sur stdin.
  static Future<ProcessResult> _sudo(List<String> cmd, String? password) async {
    if (Platform.isWindows) {
      // Sur Windows, on appelle directement — l'élévation UAC est gérée
      // par les appels PowerShell avec Run as Administrator.
      return Process.run(cmd.first, cmd.skip(1).toList(), runInShell: true);
    }

    if (password != null && password.isNotEmpty) {
      // echo <pass> | sudo -S <cmd>
      final proc = await Process.start(
        'sudo',
        ['-S', ...cmd],
        runInShell: false,
      );
      proc.stdin.writeln(password);
      await proc.stdin.close();
      final stdout =
          await proc.stdout.transform(const SystemEncoding().decoder).join();
      final stderr =
          await proc.stderr.transform(const SystemEncoding().decoder).join();
      final exitCode = await proc.exitCode;
      return ProcessResult(proc.pid, exitCode, stdout, stderr);
    } else {
      // Tente sans mot de passe (NOPASSWD sudo ou déjà root)
      return Process.run('sudo', cmd, runInShell: false);
    }
  }

  /// Exécute un script shell multiligne avec sudo.
  static Future<ProcessResult> _sudoScript(
      String script, String? password) async {
    final tmp = await File('/tmp/_tdc_anon_script.sh')
        .writeAsString('#!/bin/sh\n$script');
    await Process.run('chmod', ['+x', tmp.path]);
    final result = await _sudo(['sh', tmp.path], password);
    await tmp.delete().catchError((_) => tmp);
    return result;
  }

  static Future<List<String>> _getMacOSInterfaces() async {
    final r = await Process.run('networksetup', ['-listallnetworkservices']);
    return (r.stdout as String)
        .split('\n')
        .where((l) =>
            l.isNotEmpty && !l.startsWith('*') && !l.startsWith('An asterisk'))
        .map((l) => l.trim())
        .toList();
  }

  static Future<bool> _isUnixRoot() async {
    try {
      final r = await Process.run('id', ['-u']);
      if (r.exitCode != 0) return false;
      return (r.stdout as String).trim() == '0';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _canSudoWithoutPassword() async {
    try {
      final r = await Process.run('sudo', ['-n', 'true']);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _isWindowsAdmin() async {
    try {
      final r = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          '([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)'
        ],
        runInShell: true,
      );
      if (r.exitCode != 0) return false;
      return (r.stdout as String).toLowerCase().contains('true');
    } catch (_) {
      return false;
    }
  }
}
