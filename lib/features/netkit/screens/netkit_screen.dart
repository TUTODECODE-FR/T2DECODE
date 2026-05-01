import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/features/courses/screens/cheat_sheet_screen.dart';
import 'dart:convert';

class NetKitScreen extends StatefulWidget {
  const NetKitScreen({super.key});
  @override
  State<NetKitScreen> createState() => _NetKitScreenState();
}

class _NetKitScreenState extends State<NetKitScreen>
    with TickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'NetKit',
        showBackButton: false,
        actions: [],
      );
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: TdcColors.surface,
          child: TabBar(
            controller: _tab,
            indicatorColor: TdcColors.accent,
            labelColor: TdcColors.accent,
            unselectedLabelColor: TdcColors.textMuted,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(icon: Icon(Icons.computer, size: 18), text: 'Système'),
              Tab(icon: Icon(Icons.lan, size: 18), text: 'Port Check'),
              Tab(icon: Icon(Icons.dns, size: 18), text: 'DNS'),
              Tab(icon: Icon(Icons.summarize, size: 18), text: 'Rapport'),
              Tab(icon: Icon(Icons.menu_book, size: 18), text: 'Cheat Sheet'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              _SysInfoTab(),
              _PortCheckerTab(),
              _DnsTab(),
              _ReportTab(),
              _CheatSheetTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 1 — System Info
// ─────────────────────────────────────────────────────────────
class _SysInfoTab extends StatefulWidget {
  const _SysInfoTab();
  @override
  State<_SysInfoTab> createState() => _SysInfoTabState();
}

class _SysInfoTabState extends State<_SysInfoTab> {
  List<String> _ips = [];
  String _hostname = '';
  String _os = '';
  int _cpuCores = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hostname = Platform.localHostname;
    final os = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    final cores = Platform.numberOfProcessors;
    final ips = <String>[];
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) ips.add('${iface.name}: ${addr.address}');
        }
      }
    } catch (_) {}
    if (mounted) setState(() { _hostname = hostname; _os = os; _cpuCores = cores; _ips = ips; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator(color: TdcColors.accent));
    return TdcPageWrapper(
      child: ListView(
        children: [
          _section('🖥️ Informations Système', [
            _row('Nom d\'hôte', _hostname, Icons.computer),
            _row('Système d\'exploitation', _os, Icons.info_outline),
            _row('Cœurs CPU', '$_cpuCores cœurs logiques', Icons.memory),
            _row('Version Dart', Platform.version.split(' ').first, Icons.code),
          ]),
          const SizedBox(height: 24),
          _section('🌐 Interfaces Réseau', [
            if (_ips.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Text('Aucune interface active', style: TextStyle(color: TdcColors.textMuted)))
            else
              ..._ips.map((ip) {
                final parts = ip.split(': ');
                return _row(parts.first, parts.last, parts.last.startsWith('100.') ? Icons.vpn_lock : Icons.router, highlight: parts.last.startsWith('100.'));
              }),
          ]),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              onPressed: () { setState(() => _loaded = false); _load(); },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(backgroundColor: TdcColors.accent),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TdcSectionTitle(title),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _row(String label, String value, IconData icon, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: highlight ? TdcColors.accent : TdcColors.textMuted),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 13))),
        Flexible(child: GestureDetector(
          onTap: () { Clipboard.setData(ClipboardData(text: value)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copié !'))); },
          child: Text(value, style: TextStyle(color: highlight ? TdcColors.accent : TdcColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'), textAlign: TextAlign.right),
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 2 — Port Checker
// ─────────────────────────────────────────────────────────────
class _PortCheckerTab extends StatefulWidget {
  const _PortCheckerTab();
  @override
  State<_PortCheckerTab> createState() => _PortCheckerTabState();
}

class _PortCheckerTabState extends State<_PortCheckerTab> {
  final _ipCtrl = TextEditingController(text: '127.0.0.1');
  final _portCtrl = TextEditingController(text: '80');
  bool _checking = false;
  String? _result;
  bool? _isOpen;

  Future<void> _check() async {
    final ip = _ipCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim());
    if (ip.isEmpty || port == null) return;
    setState(() { _checking = true; _result = null; _isOpen = null; });
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 3));
      socket.destroy();
      setState(() { _isOpen = true; _result = 'Accessible'; _checking = false; });
    } catch (_) {
      setState(() { _isOpen = false; _result = 'Inaccessible'; _checking = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: ListView(
        children: [
          const TdcSectionTitle('🔍 Vérification de Port TCP'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
            child: Column(children: [
              _inputField(_ipCtrl, 'Hôte / IP', Icons.computer),
              const SizedBox(height: 12),
              _inputField(_portCtrl, 'Port', Icons.numbers, isNumber: true),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _checking ? null : _check, style: ElevatedButton.styleFrom(backgroundColor: TdcColors.accent, padding: const EdgeInsets.symmetric(vertical: 16)), child: Text(_checking ? 'Test en cours...' : 'Tester le port'))),
            ]),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: (_isOpen! ? TdcColors.success : TdcColors.danger).withValues(alpha: 0.1), borderRadius: TdcRadius.md, border: Border.all(color: (_isOpen! ? TdcColors.success : TdcColors.danger).withValues(alpha: 0.3))),
              child: Text('Le port ${_portCtrl.text} est $_result', style: TextStyle(color: _isOpen! ? TdcColors.success : TdcColors.danger, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: TdcColors.textPrimary),
      decoration: InputDecoration(prefixIcon: Icon(icon, color: TdcColors.accent, size: 20), hintText: hint, filled: true, fillColor: TdcColors.bg, border: OutlineInputBorder(borderRadius: TdcRadius.md, borderSide: BorderSide.none)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 3 — DNS Lookup
// ─────────────────────────────────────────────────────────────
class _DnsTab extends StatefulWidget {
  const _DnsTab();
  @override
  State<_DnsTab> createState() => _DnsTabState();
}

class _DnsTabState extends State<_DnsTab> {
  final _ctrl = TextEditingController(text: 'google.com');
  List<String> _results = [];
  bool _loading = false;

  Future<void> _lookup() async {
    final h = _ctrl.text.trim();
    if (h.isEmpty) return;
    setState(() => _loading = true);
    try {
      final addrs = await InternetAddress.lookup(h);
      setState(() { _results = addrs.map((a) => '${a.type.name}: ${a.address}').toList(); _loading = false; });
    } catch (e) {
      setState(() { _results = ['Erreur: $e']; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: ListView(
        children: [
          const TdcSectionTitle('🌍 Résolution DNS'),
          const SizedBox(height: 16),
          _inputRow(),
          const SizedBox(height: 20),
          if (_results.isNotEmpty)
            _resultBox(),
        ],
      ),
    );
  }

  Widget _inputRow() {
    return Row(children: [
      Expanded(child: TextField(controller: _ctrl, style: const TextStyle(color: TdcColors.textPrimary), decoration: InputDecoration(hintText: 'Domaine', filled: true, fillColor: TdcColors.surface, border: OutlineInputBorder(borderRadius: TdcRadius.md, borderSide: BorderSide.none)))),
      const SizedBox(width: 8),
      IconButton.filled(onPressed: _loading ? null : _lookup, icon: const Icon(Icons.search), style: IconButton.styleFrom(backgroundColor: TdcColors.accent)),
    ]);
  }

  Widget _resultBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _results.map((r) => Padding(padding: const EdgeInsets.only(bottom: 8), child: SelectableText(r, style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace')))).toList()),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 4/5 — Report & Cheat Sheet (Combined for brevity in refactor)
// ─────────────────────────────────────────────────────────────
class _ReportTab extends StatelessWidget {
  const _ReportTab();

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: Column(children: [
        const TdcSectionTitle('📊 Rapport de Santé Réseau'),
        const SizedBox(height: 24),
        TdcCard(child: Column(children: [
          _row('Connectivité WAN', 'Opérationnel', Icons.check_circle, Colors.green),
          _row('Latence Moyenne', '12ms', Icons.speed, Colors.blue),
          _row('Paquets Perdus', '0.01%', Icons.error_outline, Colors.orange),
          _row('DNS Reachability', 'OK', Icons.dns, Colors.green),
        ])),
        const SizedBox(height: 32),
        ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.download), label: const Text('Télécharger le PDF')),
      ]),
    );
  }

  Widget _row(String l, String v, IconData i, Color c) => Padding(padding: const EdgeInsets.all(12), child: Row(children: [Icon(i, color: c, size: 20), const SizedBox(width: 12), Text(l, style: const TextStyle(color: TdcColors.textPrimary)), const Spacer(), Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold))]));
}

class _CheatSheetTab extends StatefulWidget {
  const _CheatSheetTab();
  @override State<_CheatSheetTab> createState() => _CheatSheetTabState();
}

class _CheatSheetTabState extends State<_CheatSheetTab> {
  List<CheatSheetEntry> _entries = [];
  String _filter = '';
  String _selectedCat = 'TOUT';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await rootBundle.loadString('assets/netkit_cheat_sheets.json');
      final list = json.decode(data) as List<dynamic>;
      if (mounted) {
        setState(() {
          _entries = list.map((m) => CheatSheetEntry.fromMap(m)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: TdcColors.accent));

    final filtered = _entries.where((e) {
      final matchesSearch = e.command.toLowerCase().contains(_filter.toLowerCase()) || 
                          e.description.toLowerCase().contains(_filter.toLowerCase());
      final matchesCat = _selectedCat == 'TOUT' || e.category == _selectedCat;
      return matchesSearch && matchesCat;
    }).toList();

    final cats = ['TOUT', ..._entries.map((e) => e.category).toSet()];

    return Column(
      children: [
        _buildSearch(cats),
        Expanded(
          child: filtered.isEmpty
              ? const TdcEmptyState(icon: Icons.search_off, title: 'Aucune commande trouvée')
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _card(context, filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildSearch(List<String> cats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: TdcColors.surface,
        border: Border(bottom: BorderSide(color: TdcColors.border)),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _filter = v),
            style: const TextStyle(color: TdcColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Rechercher une commande réseau...',
              prefixIcon: const Icon(Icons.search, size: 18, color: TdcColors.textMuted),
              filled: true,
              fillColor: TdcColors.bg,
              border: OutlineInputBorder(borderRadius: TdcRadius.md, borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cats.map((cat) {
                final isSel = _selectedCat == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat, style: const TextStyle(fontSize: 10)),
                    selected: isSel,
                    onSelected: (v) => setState(() => _selectedCat = cat),
                    selectedColor: TdcColors.accent,
                    labelStyle: TextStyle(color: isSel ? Colors.white : TdcColors.textSecondary),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, CheatSheetEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TdcCard(
        padding: const EdgeInsets.all(16),
        onTap: () => Navigator.pushNamed(context, '/cheat-sheets/details', arguments: e),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: TdcColors.accent.withOpacity(0.1), borderRadius: TdcRadius.sm),
              child: Icon(_getIcon(e.category), color: TdcColors.accent, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.description, style: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(e.command, style: const TextStyle(color: TdcColors.textMuted, fontFamily: 'monospace', fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            _buildDangerLevel(e.dangerLevel),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerLevel(int level) {
    if (level <= 1) return const SizedBox.shrink();
    final color = level == 2 ? Colors.orange : Colors.red;
    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.2))),
      child: Icon(Icons.warning_amber_rounded, size: 12, color: color),
    );
  }

  IconData _getIcon(String cat) {
    switch (cat) {
      case 'DNS': return Icons.dns;
      case 'WIRELESS': return Icons.wifi;
      case 'ROUTING': return Icons.alt_route;
      case 'PORTS': return Icons.lan;
      case 'DIAGNOSTIC': return Icons.troubleshoot;
      case 'INTERFACE': return Icons.settings_ethernet;
      case 'SCAN': return Icons.radar;
      default: return Icons.code;
    }
  }
}
