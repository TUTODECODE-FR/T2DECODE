import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/providers/settings_provider.dart';
import 'package:tutodecode/core/services/storage_service.dart';
import 'package:tutodecode/core/services/tool_log_service.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';

class SafeToolsScreen extends StatefulWidget {
  const SafeToolsScreen({super.key});

  @override
  State<SafeToolsScreen> createState() => _SafeToolsScreenState();
}

class _SafeToolsScreenState extends State<SafeToolsScreen> {
  final _storage = StorageService();
  final _logs = ToolLogService();

  Map<String, bool> _perms = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPerms();
  }

  Future<void> _loadPerms() async {
    final p = await _storage.getToolPermissions();
    if (!mounted) return;
    setState(() {
      _perms = p;
      _loading = false;
    });
  }

  bool _allowed(String id, {bool defaultValue = true}) => _perms[id] ?? defaultValue;

  Future<void> _setAllowed(String id, bool value) async {
    final next = {..._perms, id: value};
    setState(() => _perms = next);
    await _storage.setToolPermissions(next);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return TdcPageWrapper(
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: TdcColors.accent))
          : ListView(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Multi-Tools Sécurisés',
                        style: TextStyle(color: TdcColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (settings.zeroNetworkMode)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: TdcColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: TdcColors.danger.withOpacity(0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.wifi_off, size: 14, color: TdcColors.danger),
                            SizedBox(width: 6),
                            Text('Réseau désactivé', style: TextStyle(color: TdcColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Outils whitelistés, sans exécution de commandes arbitraires. Tout fonctionne hors-ligne.',
                  style: TextStyle(color: TdcColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                _section(
                  title: 'Permissions (Sandbox)',
                  children: [
                    _permSwitch('net_info', 'Réseau (lecture seule)', 'Affiche l’état radio et l’IP locale', Icons.lan),
                    _permSwitch('device_info', 'Système (lecture seule)', 'Affiche les informations de l’appareil', Icons.memory),
                    _permSwitch('storage_scan', 'Stockage (lecture seule)', 'Mesure l’espace utilisé par l’app', Icons.storage),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _logs.clear();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logs outils effacés.')));
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Effacer les logs'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _section(
                  title: 'Outils',
                  children: [
                    _toolTile(
                      id: 'net_info',
                      title: 'Diagnostic Réseau',
                      subtitle: 'Connectivité + IP/SSID (si dispo)',
                      icon: Icons.network_check,
                      onRun: _allowed('net_info') ? _runNetworkDiag : null,
                    ),
                    _toolTile(
                      id: 'device_info',
                      title: 'Infos Système',
                      subtitle: 'Modèle, OS, version, etc.',
                      icon: Icons.info_outline,
                      onRun: _allowed('device_info') ? _runDeviceInfo : null,
                    ),
                    _toolTile(
                      id: 'storage_scan',
                      title: 'Stockage App',
                      subtitle: 'Modules, backups, snapshots',
                      icon: Icons.folder_open,
                      onRun: _allowed('storage_scan') ? _runStorageScan : null,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.lg,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _permSwitch(String id, String title, String subtitle, IconData icon) {
    return SwitchListTile.adaptive(
      value: _allowed(id),
      onChanged: (v) => _setAllowed(id, v),
      title: Row(
        children: [
          Icon(icon, size: 18, color: TdcColors.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(color: TdcColors.textPrimary))),
        ],
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: TdcColors.textMuted)),
      activeColor: TdcColors.accent,
    );
  }

  Widget _toolTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Future<void> Function()? onRun,
  }) {
    return ListTile(
      leading: Icon(icon, color: TdcColors.accent),
      title: Text(title, style: const TextStyle(color: TdcColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(color: TdcColors.textMuted)),
      trailing: ElevatedButton(
        onPressed: onRun,
        child: const Text('Lancer'),
      ),
    );
  }

  Future<void> _runNetworkDiag() async {
    await _logs.log(toolId: 'net_info', action: 'run');
    final conn = await Connectivity().checkConnectivity();
    final info = NetworkInfo();

    String? wifiIp;
    String? wifiName;
    try {
      wifiIp = await info.getWifiIP();
      wifiName = await info.getWifiName();
    } catch (_) {}

    await _logs.log(toolId: 'net_info', action: 'result', meta: {
      'connectivity': conn.map((e) => e.name).toList(),
      if (wifiIp != null) 'wifiIP': wifiIp,
      if (wifiName != null) 'wifiName': wifiName,
    });

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TdcColors.surface,
        title: const Text('Diagnostic Réseau', style: TextStyle(color: TdcColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connectivité: ${conn.map((e) => e.name).join(', ')}', style: const TextStyle(color: TdcColors.textSecondary)),
            if (wifiName != null) Text('Wi‑Fi: $wifiName', style: const TextStyle(color: TdcColors.textSecondary)),
            if (wifiIp != null) Text('IP: $wifiIp', style: const TextStyle(color: TdcColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Future<void> _runDeviceInfo() async {
    await _logs.log(toolId: 'device_info', action: 'run');
    final di = DeviceInfoPlugin();
    final Map<String, dynamic> out = {};
    try {
      if (kIsWeb) {
        final web = await di.webBrowserInfo;
        out.addAll({
          'browser': web.browserName.name,
          'platform': web.platform,
        });
      } else if (Platform.isAndroid) {
        final a = await di.androidInfo;
        out.addAll({'model': a.model, 'brand': a.brand, 'sdkInt': a.version.sdkInt});
      } else if (Platform.isIOS) {
        final i = await di.iosInfo;
        out.addAll({'model': i.utsname.machine, 'system': i.systemName, 'version': i.systemVersion});
      } else if (Platform.isMacOS) {
        final m = await di.macOsInfo;
        out.addAll({'model': m.model, 'os': m.osRelease, 'arch': m.arch});
      } else if (Platform.isWindows) {
        final w = await di.windowsInfo;
        out.addAll({'computerName': w.computerName, 'buildNumber': w.buildNumber});
      } else if (Platform.isLinux) {
        final l = await di.linuxInfo;
        out.addAll({'name': l.name, 'version': l.version, 'id': l.id});
      }
    } catch (_) {}

    await _logs.log(toolId: 'device_info', action: 'result', meta: out);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TdcColors.surface,
        title: const Text('Infos Système', style: TextStyle(color: TdcColors.textPrimary)),
        content: Text(out.entries.map((e) => '${e.key}: ${e.value}').join('\n'), style: const TextStyle(color: TdcColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Future<void> _runStorageScan() async {
    await _logs.log(toolId: 'storage_scan', action: 'run');
    final docs = await getApplicationDocumentsDirectory();
    final modules = Directory('${docs.path}/TUTODECODE_Modules');
    final backups = Directory('${docs.path}/TUTODECODE_ModuleBackups');
    final snapshots = Directory('${docs.path}/TUTODECODE_Snapshots');

    final sizes = <String, int>{
      'modules': await _dirSize(modules),
      'backups': await _dirSize(backups),
      'snapshots': await _dirSize(snapshots),
    };
    await _logs.log(toolId: 'storage_scan', action: 'result', meta: sizes);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TdcColors.surface,
        title: const Text('Stockage App', style: TextStyle(color: TdcColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modules: ${_prettyBytes(sizes['modules'] ?? 0)}', style: const TextStyle(color: TdcColors.textSecondary)),
            Text('Backups: ${_prettyBytes(sizes['backups'] ?? 0)}', style: const TextStyle(color: TdcColors.textSecondary)),
            Text('Snapshots: ${_prettyBytes(sizes['snapshots'] ?? 0)}', style: const TextStyle(color: TdcColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Future<int> _dirSize(Directory dir) async {
    try {
      if (!await dir.exists()) return 0;
      var total = 0;
      await for (final e in dir.list(recursive: true, followLinks: false)) {
        if (e is File) {
          try {
            total += await e.length();
          } catch (_) {}
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  String _prettyBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var b = bytes.toDouble();
    var u = 0;
    while (b >= 1024 && u < units.length - 1) {
      b /= 1024;
      u++;
    }
    return '${b.toStringAsFixed(1)} ${units[u]}';
  }
}

