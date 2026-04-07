import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
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
                  'Web: certaines fonctions de stockage local sont limitées par le navigateur.',
                  style: TextStyle(color: TdcColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                _section(
                  title: 'Permissions (Sandbox)',
                  children: [
                    _permSwitch('net_info', 'Réseau (lecture seule)', 'Affiche l’état radio et l’IP locale', Icons.lan),
                    _permSwitch('device_info', 'Système (lecture seule)', 'Affiche les informations du navigateur', Icons.memory),
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
                      title: 'Diagnostic Réseau',
                      subtitle: 'Connectivité + IP/SSID (si dispo)',
                      icon: Icons.network_check,
                      onRun: _allowed('net_info') ? _runNetworkDiag : null,
                    ),
                    _toolTile(
                      title: 'Infos Système',
                      subtitle: 'Navigateur, plateforme',
                      icon: Icons.info_outline,
                      onRun: _allowed('device_info') ? _runDeviceInfo : null,
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
    required String title,
    required String subtitle,
    required IconData icon,
    required Future<void> Function()? onRun,
  }) {
    return ListTile(
      leading: Icon(icon, color: TdcColors.accent),
      title: Text(title, style: const TextStyle(color: TdcColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(color: TdcColors.textMuted)),
      trailing: ElevatedButton(onPressed: onRun, child: const Text('Lancer')),
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
        content: Text('Connectivité: ${conn.map((e) => e.name).join(', ')}', style: const TextStyle(color: TdcColors.textSecondary)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }

  Future<void> _runDeviceInfo() async {
    await _logs.log(toolId: 'device_info', action: 'run');
    final di = DeviceInfoPlugin();
    final web = await di.webBrowserInfo;
    final out = {
      'browser': web.browserName.name,
      'platform': web.platform,
      if (!kReleaseMode) 'userAgent': web.userAgent,
    };
    await _logs.log(toolId: 'device_info', action: 'result', meta: out);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TdcColors.surface,
        title: const Text('Infos Système', style: TextStyle(color: TdcColors.textPrimary)),
        content: Text(out.entries.map((e) => '${e.key}: ${e.value}').join('\n'), style: const TextStyle(color: TdcColors.textSecondary)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }
}

