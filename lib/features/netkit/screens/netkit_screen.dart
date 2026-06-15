// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// ============================================================
// NetKit — Real Network Diagnostics Toolkit
// All outputs displayed in terminal emulators like real tools.
// ============================================================
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/features/lab/widgets/terminal_emulator.dart';

const _googleCom = 'google.com';
const _githubCom = 'github.com';
const _oneOneOneOne = '1.1.1.1';

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
    _tab = TabController(length: 4, vsync: this);
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
              Tab(icon: Icon(Icons.radar, size: 18), text: 'Port Scanner'),
              Tab(icon: Icon(Icons.dns, size: 18), text: 'DNS'),
              Tab(icon: Icon(Icons.assessment, size: 18), text: 'Diagnostic'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              _SysInfoTab(),
              _PortScannerTab(),
              _DnsTab(),
              _DiagnosticTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 1 — System Info (terminal style)
// ─────────────────────────────────────────────────────────────
class _SysInfoTab extends StatefulWidget {
  const _SysInfoTab();
  @override
  State<_SysInfoTab> createState() => _SysInfoTabState();
}

class _SysInfoTabState extends State<_SysInfoTab> {
  final GlobalKey<TerminalEmulatorState> _termKey = GlobalKey();
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  void _addNeofetchLines(List<TermLine> lines) {
    final hostname = Platform.localHostname;
    final os = Platform.operatingSystem;
    final osVersion = Platform.operatingSystemVersion;
    final cores = Platform.numberOfProcessors;
    final dartVersion = Platform.version.split(' ').first;
    final locale = Platform.localeName;

    lines.add(TermLine('  admin@$hostname', TermColor.cyan));
    lines.add(const TermLine('  ─────────────────────────────', TermColor.gray));
    lines.add(TermLine('  OS:      $os $osVersion', TermColor.white));
    lines.add(TermLine('  Host:    $hostname', TermColor.white));
    
    final kernelName = (os == 'macos' || os == 'ios') ? 'Darwin' : (os == 'windows' ? 'Windows' : 'Linux');
    final kernelVersion = osVersion.contains('(') ? osVersion.split('(').last.replaceAll(')', '') : osVersion;
    lines.add(TermLine('  Kernel:  $kernelName $kernelVersion', TermColor.white));
    
    lines.add(TermLine('  CPU:     $cores cores', TermColor.white));
    lines.add(TermLine('  Dart:    $dartVersion', TermColor.white));
    lines.add(TermLine('  Locale:  $locale', TermColor.white));
  }

  Future<void> _addNetworkInterfaceLines(List<TermLine> lines) async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        lines.add(TermLine('${interfaces.indexOf(iface) + 1}: ${iface.name}: <UP,BROADCAST,MULTICAST>', TermColor.bold));
        for (final addr in iface.addresses) {
          final type = addr.type == InternetAddressType.IPv4 ? 'inet' : 'inet6';
          lines.add(TermLine('    $type ${addr.address}${addr.isLoopback ? ' scope host' : ' scope global'}', addr.isLoopback ? TermColor.gray : TermColor.cyan));
        }
      }
    } catch (_) {
      lines.add(const TermLine('    (impossible de lister les interfaces)', TermColor.red));
    }
  }

  Future<void> _addDnsLines(List<TermLine> lines) async {
    try {
      final result = await InternetAddress.lookup('localhost');
      if (result.isNotEmpty) {
        lines.add(const TermLine('# DNS resolution is working', TermColor.gray));
        lines.add(const TermLine('nameserver 127.0.0.53', TermColor.white));
      }
    } catch (_) {
      lines.add(const TermLine('# DNS resolution unavailable', TermColor.red));
    }
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    final term = _termKey.currentState;
    if (term == null) { _running = false; return; }
    term.clear();

    final lines = <TermLine>[];
    lines.add(const TermLine('\$ neofetch --minimal', TermColor.green));
    lines.add(const TermLine('', TermColor.white));

    _addNeofetchLines(lines);

    lines.add(const TermLine('', TermColor.white));
    lines.add(const TermLine('\$ ip addr show 2>/dev/null || ifconfig -a', TermColor.green));
    await _addNetworkInterfaceLines(lines);

    lines.add(const TermLine('', TermColor.white));
    lines.add(const TermLine('\$ cat /etc/resolv.conf 2>/dev/null', TermColor.green));
    await _addDnsLines(lines);

    lines.add(const TermLine('', TermColor.white));
    lines.add(const TermLine('\$ uptime', TermColor.green));
    final now = DateTime.now();
    final cores = Platform.numberOfProcessors;
    final locale = Platform.localeName;
    lines.add(TermLine(' ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} up, $cores CPUs, locale $locale', TermColor.white));

    await term.playLines(lines, delayMs: 40);
    _running = false;
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _btn('Actualiser', TdcColors.accent, _running ? null : _run),
              const SizedBox(width: 8),
              _btn('Copier', TdcColors.textMuted, () {
                final term = _termKey.currentState;
                if (term != null) {
                  Clipboard.setData(ClipboardData(text: term.plainText));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copié !'), duration: Duration(seconds: 1)));
                }
              }),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TerminalEmulator(
              key: _termKey,
              title: 'admin@netkit: ~ (System Info)',
              accentColor: TdcColors.accent,
              height: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: onTap != null ? color.withValues(alpha: 0.14) : TdcColors.textPrimary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: onTap != null ? color.withValues(alpha: 0.45) : TdcColors.border),
        ),
        child: Text(label, style: TextStyle(color: onTap != null ? color : TdcColors.textMuted, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 2 — Port Scanner (real TCP connect with terminal output)
// ─────────────────────────────────────────────────────────────
enum _PortState { open, closed, filtered }

class _PortScannerTab extends StatefulWidget {
  const _PortScannerTab();
  @override
  State<_PortScannerTab> createState() => _PortScannerTabState();
}

class _PortScannerTabState extends State<_PortScannerTab> {
  final _hostCtrl = TextEditingController(text: '127.0.0.1');
  final _portsCtrl = TextEditingController(text: '22,80,443,3306,5432,8080');
  final GlobalKey<TerminalEmulatorState> _termKey = GlobalKey();
  bool _scanning = false;

  static const _knownPorts = <int, String>{
    21: 'ftp', 22: 'ssh', 23: 'telnet', 25: 'smtp', 53: 'dns',
    80: 'http', 110: 'pop3', 143: 'imap', 443: 'https', 445: 'smb',
    993: 'imaps', 995: 'pop3s', 1433: 'mssql', 1521: 'oracle',
    3306: 'mysql', 3389: 'rdp', 5432: 'postgresql', 5672: 'amqp',
    6379: 'redis', 8080: 'http-alt', 8443: 'https-alt', 9090: 'prometheus',
    9200: 'elasticsearch', 27017: 'mongodb',
  };

  List<int> _parsePorts(String input) {
    final ports = <int>{};
    for (final part in input.split(',')) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        final range = trimmed.split('-');
        if (range.length == 2) {
          final start = int.tryParse(range[0].trim());
          final end = int.tryParse(range[1].trim());
          if (start != null && end != null && start <= end && end <= 65535) {
            // Prevent huge expansions; _scan() enforces a 256-port limit.
            if (end - start + 1 > 256) continue;
            for (int p = start; p <= end; p++) {
              ports.add(p);
            }
          }
        }
      } else {
        final p = int.tryParse(trimmed);
        if (p != null && p > 0 && p <= 65535) ports.add(p);
      }
    }
    return ports.toList()..sort();
  }

  Future<_PortState> _probePort(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
      socket.destroy();
      return _PortState.open;
    } on SocketException {
      return _PortState.closed;
    } catch (_) {
      return _PortState.filtered;
    }
  }

  void _printPortResult(TerminalEmulatorState term, int port, _PortState state) {
    final service = _knownPorts[port] ?? 'unknown';
    final portStr = port.toString().padRight(5);
    switch (state) {
      case _PortState.open:
        term.addLine(TermLine('$portStr/tcp  open     $service', TermColor.green));
        break;
      case _PortState.closed:
        term.addLine(TermLine('$portStr/tcp  closed   $service', TermColor.gray));
        break;
      case _PortState.filtered:
        term.addLine(TermLine('$portStr/tcp  filtered $service', TermColor.yellow));
        break;
    }
  }

  Future<void> _scan() async {
    if (_scanning) return;
    final host = _hostCtrl.text.trim();
    final ports = _parsePorts(_portsCtrl.text);
    if (host.isEmpty || ports.isEmpty) return;

    const maxPorts = 256;
    if (ports.length > maxPorts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez limiter le scan à 256 ports maximum.')),
      );
      return;
    }

    setState(() => _scanning = true);
    final term = _termKey.currentState;
    if (term == null) { setState(() => _scanning = false); return; }
    term.clear();

    final sw = Stopwatch()..start();
    term.addLine(TermLine('\$ nmap -sT $host -p ${_portsCtrl.text.trim()}', TermColor.green));
    term.addLine(const TermLine('', TermColor.white));
    term.addLine(TermLine('Starting T2DECODE Port Scanner at ${_now()}', TermColor.white));
    term.addLine(TermLine('Scanning $host (${ports.length} ports)...', TermColor.white));
    term.addLine(const TermLine('', TermColor.white));
    term.addLine(const TermLine('PORT       STATE    SERVICE', TermColor.yellow));

    int openCount = 0;
    int closedCount = 0;

    for (final port in ports) {
      if (!mounted) break;
      final state = await _probePort(host, port);
      if (state == _PortState.open) {
        openCount++;
      } else {
        closedCount++;
      }
      _printPortResult(term, port, state);
    }

    sw.stop();
    term.addLine(const TermLine('', TermColor.white));
    term.addLine(TermLine('Scan done: ${ports.length} ports scanned in ${(sw.elapsedMilliseconds / 1000).toStringAsFixed(2)}s', TermColor.white));
    term.addLine(TermLine('$openCount open, $closedCount closed/filtered', openCount > 0 ? TermColor.green : TermColor.gray));

    if (mounted) setState(() => _scanning = false);
  }


  String _now() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')} '
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _input(_hostCtrl, 'Hôte / IP', Icons.computer)),
              const SizedBox(width: 8),
              Expanded(child: _input(_portsCtrl, 'Ports (22,80 ou 1-1024)', Icons.numbers)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _scanning ? null : _scan,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _scanning ? TdcColors.textPrimary.withValues(alpha: 0.05) : TdcColors.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _scanning ? TdcColors.border : TdcColors.accent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_scanning)
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: TdcColors.accent))
                      else
                        const Icon(Icons.radar, size: 16, color: TdcColors.accent),
                      const SizedBox(width: 6),
                      Text(_scanning ? 'Scan...' : 'Scanner', style: TextStyle(color: _scanning ? TdcColors.textMuted : TdcColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Plages supportées : 22,80,443 ou 1-1024 ou 80,443,8000-8100', style: TextStyle(color: TdcColors.textMuted.withValues(alpha: 0.5), fontSize: 10)),
          const SizedBox(height: 10),
          Expanded(
            child: TerminalEmulator(
              key: _termKey,
              title: 'admin@netkit: Port Scanner',
              accentColor: TdcColors.info,
              height: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: TdcColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: TdcColors.accent, size: 16),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 11),
        filled: true,
        fillColor: TdcColors.surface,
        border: const OutlineInputBorder(borderRadius: TdcRadius.md, borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        isDense: true,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 3 — DNS Lookup (enriched with timing, multiple queries)
// ─────────────────────────────────────────────────────────────
class _DnsTab extends StatefulWidget {
  const _DnsTab();
  @override
  State<_DnsTab> createState() => _DnsTabState();
}

class _DnsTabState extends State<_DnsTab> {
  final _ctrl = TextEditingController(text: _googleCom);
  final GlobalKey<TerminalEmulatorState> _termKey = GlobalKey();

  bool _loading = false;

  Future<void> _lookup() async {
    final domain = _ctrl.text.trim();
    if (domain.isEmpty || _loading) return;
    setState(() => _loading = true);
    final term = _termKey.currentState;
    if (term == null) { setState(() => _loading = false); return; }
    term.clear();

    final lines = <TermLine>[];
    lines.add(TermLine('\$ dig $domain ANY +stats', TermColor.green));
    lines.add(const TermLine('', TermColor.white));
    lines.add(TermLine('; <<>> T2DECODE DiG 1.0 <<>> $domain ANY', TermColor.gray));
    lines.add(const TermLine(';; global options: +cmd', TermColor.gray));

    final sw = Stopwatch()..start();
    try {
      final ipv4 = await InternetAddress.lookup(domain, type: InternetAddressType.IPv4);
      final ipv4Time = sw.elapsedMilliseconds;

      sw.reset();
      List<InternetAddress> ipv6 = [];
      try {
        ipv6 = await InternetAddress.lookup(domain, type: InternetAddressType.IPv6);
      } catch (_) {}
      final ipv6Time = sw.elapsedMilliseconds;
      sw.stop();

      lines.add(const TermLine('', TermColor.white));
      lines.add(const TermLine(';; ANSWER SECTION:', TermColor.yellow));

      for (final addr in ipv4) {
        lines.add(TermLine('$domain.     300    IN    A       ${addr.address}', TermColor.cyan));
      }
      for (final addr in ipv6) {
        lines.add(TermLine('$domain.     300    IN    AAAA    ${addr.address}', TermColor.cyan));
      }

      if (ipv4.isNotEmpty && ipv4.first.host != domain) {
        lines.add(TermLine('$domain.     300    IN    CNAME   ${ipv4.first.host}.', TermColor.white));
      }

      lines.add(const TermLine('', TermColor.white));
      lines.add(const TermLine(';; STATISTICS:', TermColor.yellow));
      lines.add(TermLine(';; Query time (A):    $ipv4Time ms', TermColor.white));
      if (ipv6.isNotEmpty) {
        lines.add(TermLine(';; Query time (AAAA): $ipv6Time ms', TermColor.white));
      }
      lines.add(TermLine(';; WHEN: ${_now()}', TermColor.gray));
      lines.add(TermLine(';; MSG SIZE  rcvd: ${ipv4.length + ipv6.length} records', TermColor.gray));

      lines.add(const TermLine('', TermColor.white));
      lines.add(TermLine(';; Total: ${ipv4.length} A + ${ipv6.length} AAAA records resolved', TermColor.green));

    } catch (e) {
      sw.stop();
      lines.add(const TermLine('', TermColor.white));
      lines.add(const TermLine(';; connection timed out; no servers could be reached', TermColor.red));
      lines.add(TermLine(';; Error: $e', TermColor.red));
    }

    await term.playLines(lines, delayMs: 50);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _batchLookup() async {
    if (_loading) return;
    setState(() => _loading = true);
    final term = _termKey.currentState;
    if (term == null) { setState(() => _loading = false); return; }
    term.clear();

    final domains = [_googleCom, 'cloudflare.com', _githubCom, 'mozilla.org', 'wikipedia.org'];
    term.addLine(TermLine('\$ for d in $_googleCom cloudflare.com $_githubCom mozilla.org wikipedia.org; do dig +short \$d; done', TermColor.green));
    term.addLine(const TermLine('', TermColor.white));
    term.addLine(const TermLine('DOMAIN                    IPv4              TIME', TermColor.yellow));
    term.addLine(const TermLine('─────────────────────────────────────────────────', TermColor.gray));

    for (final domain in domains) {
      if (!mounted) break;
      final sw = Stopwatch()..start();
      try {
        final addrs = await InternetAddress.lookup(domain, type: InternetAddressType.IPv4);
        sw.stop();
        final ip = addrs.isNotEmpty ? addrs.first.address : '???';
        term.addLine(TermLine(
          '${domain.padRight(26)}${ip.padRight(18)}${sw.elapsedMilliseconds}ms',
          sw.elapsedMilliseconds < 50 ? TermColor.green : sw.elapsedMilliseconds < 200 ? TermColor.yellow : TermColor.red,
        ));
      } catch (_) {
        sw.stop();
        term.addLine(TermLine('${domain.padRight(26)}FAILED${''.padRight(12)}${sw.elapsedMilliseconds}ms', TermColor.red));
      }
    }

    term.addLine(const TermLine('', TermColor.white));
    term.addLine(const TermLine('Done.', TermColor.green));
    if (mounted) setState(() => _loading = false);
  }

  String _now() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')} '
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: TdcColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.dns, color: TdcColors.accent, size: 16),
                    hintText: 'Domaine à résoudre',
                    hintStyle: TextStyle(fontSize: 11),
                    filled: true, fillColor: TdcColors.surface,
                    border: OutlineInputBorder(borderRadius: TdcRadius.md, borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _lookup(),
                ),
              ),
              const SizedBox(width: 8),
              _actionBtn('dig', TdcColors.info, _loading ? null : _lookup),
              const SizedBox(width: 6),
              _actionBtn('Batch', TdcColors.warning, _loading ? null : _batchLookup),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TerminalEmulator(
              key: _termKey,
              title: 'admin@netkit: DNS Resolver',
              accentColor: TdcColors.info,
              height: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: onTap != null ? color.withValues(alpha: 0.14) : TdcColors.textPrimary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: onTap != null ? color.withValues(alpha: 0.45) : TdcColors.border),
        ),
        child: Text(label, style: TextStyle(color: onTap != null ? color : TdcColors.textMuted, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab 4 — Network Diagnostic (real latency, connectivity tests)
// ─────────────────────────────────────────────────────────────
class _DiagnosticTab extends StatefulWidget {
  const _DiagnosticTab();
  @override
  State<_DiagnosticTab> createState() => _DiagnosticTabState();
}

class _DiagnosticTabState extends State<_DiagnosticTab> {
  final GlobalKey<TerminalEmulatorState> _termKey = GlobalKey();
  bool _running = false;

  Future<Duration?> _tcpPing(String host, int port) async {
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
      sw.stop();
      socket.destroy();
      return sw.elapsed;
    } catch (_) {
      sw.stop();
      return null;
    }
  }

  String _getConnectionStatus(int svcOk, int svcHostsLength) {
    if (svcOk == svcHostsLength) return 'OK';
    if (svcOk > 0) return 'DEGRADED';
    return 'DOWN';
  }

  TermColor _getConnectionColor(String connStatus) {
    if (connStatus == 'OK') return TermColor.green;
    if (connStatus == 'DEGRADED') return TermColor.yellow;
    return TermColor.red;
  }

  String _getDnsStatus(int dnsOk, int dnsTargetsLength) {
    if (dnsOk == dnsTargetsLength) return 'OK';
    if (dnsOk > 0) return 'PARTIAL';
    return 'FAILED';
  }

  TermColor _getDnsColor(String dnsStatus) {
    if (dnsStatus == 'OK') return TermColor.green;
    if (dnsStatus == 'PARTIAL') return TermColor.yellow;
    return TermColor.red;
  }

  TermColor _getLatencyColor(double latency) {
    if (latency < 50) return TermColor.green;
    if (latency < 150) return TermColor.yellow;
    return TermColor.red;
  }

  int _getLatencyPoints(double latency) {
    if (latency < 100) return 25;
    if (latency < 300) return 15;
    return 5;
  }

  TermColor _getScoreColor(int score) {
    if (score >= 80) return TermColor.green;
    if (score >= 50) return TermColor.yellow;
    return TermColor.red;
  }

  Future<void> _diagInterfaces(TerminalEmulatorState term) async {
    term.addLine(const TermLine('[1/5] Checking network interfaces...', TermColor.cyan));
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      final active = interfaces.where((i) => i.addresses.any((a) => !a.isLoopback)).toList();
      if (active.isNotEmpty) {
        for (final iface in active) {
          for (final addr in iface.addresses.where((a) => !a.isLoopback)) {
            term.addLine(TermLine('  ✓ ${iface.name}: ${addr.address}', TermColor.green));
          }
        }
      } else {
        term.addLine(const TermLine('  ✗ No active network interfaces found', TermColor.red));
      }
    } catch (e) {
      term.addLine(TermLine('  ✗ Error: $e', TermColor.red));
    }
  }

  Future<int> _diagDns(TerminalEmulatorState term, List<String> dnsTargets) async {
    term.addLine(const TermLine('[2/5] Testing DNS resolution...', TermColor.cyan));
    int dnsOk = 0;
    for (final target in dnsTargets) {
      if (!mounted) break;
      final sw = Stopwatch()..start();
      try {
        await InternetAddress.lookup(target);
        sw.stop();
        dnsOk++;
        term.addLine(TermLine('  ✓ $target resolved in ${sw.elapsedMilliseconds}ms', TermColor.green));
      } catch (_) {
        sw.stop();
        term.addLine(TermLine('  ✗ $target FAILED (${sw.elapsedMilliseconds}ms)', TermColor.red));
      }
    }
    return dnsOk;
  }

  Future<void> _diagLatency(TerminalEmulatorState term, List<String> pingHosts, List<String> pingNames, List<double> latencies) async {
    term.addLine(const TermLine('[3/5] Measuring latency (TCP connect)...', TermColor.cyan));
    final pingPorts = [443, 443, 443];
    for (int t = 0; t < pingHosts.length; t++) {
      if (!mounted) break;
      final durations = <int>[];
      for (int i = 0; i < 3; i++) {
        final d = await _tcpPing(pingHosts[t], pingPorts[t]);
        if (d != null) durations.add(d.inMilliseconds);
      }
      if (durations.isNotEmpty) {
        final avg = durations.reduce((a, b) => a + b) / durations.length;
        latencies.add(avg);
        final color = _getLatencyColor(avg);
        term.addLine(TermLine('  ✓ ${pingNames[t].padRight(18)} ${avg.toStringAsFixed(1)}ms avg (${durations.length}/3 ok)', color));
      } else {
        term.addLine(TermLine('  ✗ ${pingNames[t].padRight(18)} unreachable', TermColor.red));
      }
    }
  }

  Future<int> _diagServices(TerminalEmulatorState term, List<String> svcHosts, List<String> svcNames) async {
    term.addLine(const TermLine('[4/5] Testing common services...', TermColor.cyan));
    final svcPorts = [443, 443, 53];
    int svcOk = 0;
    for (int s = 0; s < svcHosts.length; s++) {
      if (!mounted) break;
      final d = await _tcpPing(svcHosts[s], svcPorts[s]);
      if (d != null) {
        svcOk++;
        term.addLine(TermLine('  ✓ ${svcNames[s].padRight(22)} ${d.inMilliseconds}ms', TermColor.green));
      } else {
        term.addLine(TermLine('  ✗ ${svcNames[s].padRight(22)} unreachable', TermColor.red));
      }
    }
    return svcOk;
  }

  void _diagSummary(TerminalEmulatorState term, int dnsOk, int dnsTargetsLength, int svcOk, int svcHostsLength, List<double> latencies, double avgLatency) {
    term.addLine(const TermLine('[5/5] Generating report...', TermColor.cyan));
    term.addLine(const TermLine('', TermColor.white));
    term.addLine(const TermLine('══════════════ RAPPORT ══════════════', TermColor.bold));
    term.addLine(const TermLine('', TermColor.white));

    final connStatus = _getConnectionStatus(svcOk, svcHostsLength);
    final connColor = _getConnectionColor(connStatus);
    final dnsStatus = _getDnsStatus(dnsOk, dnsTargetsLength);
    final dnsColor = _getDnsColor(dnsStatus);

    term.addLine(TermLine('  Connectivity:    $connStatus', connColor));
    term.addLine(TermLine('  DNS Resolution:  $dnsStatus ($dnsOk/$dnsTargetsLength)', dnsColor));
    term.addLine(TermLine('  Avg Latency:     ${avgLatency.toStringAsFixed(1)}ms', _getLatencyColor(avgLatency)));
    term.addLine(TermLine('  Services:        $svcOk/$svcHostsLength reachable', svcOk == svcHostsLength ? TermColor.green : TermColor.yellow));
    term.addLine(const TermLine('', TermColor.white));

    // Overall score
    final latencyPoints = _getLatencyPoints(avgLatency);
    final score = ((dnsOk / dnsTargetsLength) * 25 + (svcOk / svcHostsLength) * 25 + (latencies.isNotEmpty ? 25 : 0) + latencyPoints).round();
    final scoreColor = _getScoreColor(score);
    term.addLine(TermLine('  Health Score:    $score/100', scoreColor));
    term.addLine(const TermLine('', TermColor.white));
    term.addLine(TermLine('Diagnostic complete at ${_now()}', TermColor.gray));
  }

  Future<void> _runDiagnostic() async {
    if (_running) return;
    setState(() => _running = true);
    final term = _termKey.currentState;
    if (term == null) { setState(() => _running = false); return; }
    term.clear();

    term.addLine(const TermLine('\$ netkit-diagnostic --full', TermColor.green));
    term.addLine(const TermLine('', TermColor.white));
    term.addLine(TermLine('T2DECODE Network Diagnostic — ${_now()}', TermColor.bold));
    term.addLine(const TermLine('════════════════════════════════════════════════════', TermColor.gray));
    term.addLine(const TermLine('', TermColor.white));

    // 1. Local interfaces
    await _diagInterfaces(term);
    term.addLine(const TermLine('', TermColor.white));

    // 2. DNS resolution
    final dnsTargets = [_googleCom, 'cloudflare.com', _githubCom];
    final dnsOk = await _diagDns(term, dnsTargets);
    term.addLine(const TermLine('', TermColor.white));

    // 3. TCP connectivity
    final pingHosts = [_oneOneOneOne, '8.8.8.8', '208.67.222.222'];
    final pingNames = ['Cloudflare DNS', 'Google DNS', 'OpenDNS'];
    final latencies = <double>[];
    await _diagLatency(term, pingHosts, pingNames, latencies);
    term.addLine(const TermLine('', TermColor.white));

    // 4. Common services
    final svcHosts = [_googleCom, _githubCom, _oneOneOneOne];
    final svcNames = ['HTTPS (Google)', 'HTTPS (GitHub)', 'DNS (Cloudflare)'];
    final svcOk = await _diagServices(term, svcHosts, svcNames);
    term.addLine(const TermLine('', TermColor.white));

    // 5. Summary
    final avgLatency = latencies.isNotEmpty ? latencies.reduce((a, b) => a + b) / latencies.length : 0.0;
    _diagSummary(term, dnsOk, dnsTargets.length, svcOk, svcHosts.length, latencies, avgLatency);

    if (mounted) setState(() => _running = false);
  }

  Future<void> _runLatencyTest() async {
    if (_running) return;
    setState(() => _running = true);
    final term = _termKey.currentState;
    if (term == null) { setState(() => _running = false); return; }
    term.clear();

    term.addLine(const TermLine('\$ ping -c 10 1.1.1.1  (TCP connect simulation)', TermColor.green));
    term.addLine(const TermLine('PING 1.1.1.1 (1.1.1.1): TCP port 443', TermColor.white));

    final times = <int>[];
    for (int i = 1; i <= 10; i++) {
      if (!mounted) break;
      final d = await _tcpPing(_oneOneOneOne, 443);
      if (d != null) {
        times.add(d.inMilliseconds);
        term.addLine(TermLine('tcp_seq=$i ttl=57 time=${d.inMilliseconds}ms', TermColor.white));
      } else {
        term.addLine(TermLine('tcp_seq=$i Request timeout', TermColor.red));
      }
    }

    term.addLine(const TermLine('', TermColor.white));
    term.addLine(const TermLine('--- 1.1.1.1 ping statistics ---', TermColor.white));
    final loss = ((10 - times.length) / 10 * 100).toStringAsFixed(0);
    term.addLine(TermLine('10 packets transmitted, ${times.length} received, $loss% loss', int.parse(loss) == 0 ? TermColor.green : TermColor.yellow));

    if (times.isNotEmpty) {
      times.sort();
      final min = times.first;
      final max = times.last;
      final avg = (times.reduce((a, b) => a + b) / times.length).toStringAsFixed(1);
      term.addLine(TermLine('rtt min/avg/max = $min/$avg/$max ms', TermColor.white));
    }

    if (mounted) setState(() => _running = false);
  }


  String _now() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')} '
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _actionBtn('Diagnostic complet', TdcColors.success, _running ? null : _runDiagnostic),
              const SizedBox(width: 8),
              _actionBtn('Ping test (10x)', TdcColors.info, _running ? null : _runLatencyTest),
              const Spacer(),
              if (_running)
                const Row(children: [
                  SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: TdcColors.accent)),
                  SizedBox(width: 6),
                  Text('Running...', style: TextStyle(color: TdcColors.textTertiary, fontSize: 10)),
                ]),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TerminalEmulator(
              key: _termKey,
              title: 'admin@netkit: Network Diagnostic',
              accentColor: TdcColors.success,
              height: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: onTap != null ? color.withValues(alpha: 0.14) : TdcColors.textPrimary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: onTap != null ? color.withValues(alpha: 0.45) : TdcColors.border),
        ),
        child: Text(label, style: TextStyle(color: onTap != null ? color : TdcColors.textMuted, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
      ),
    );
  }
}

