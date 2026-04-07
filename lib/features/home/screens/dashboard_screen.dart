import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/responsive/responsive.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';
import 'package:tutodecode/features/ghost_ai/service/ollama_service.dart';
import 'package:tutodecode/features/ghost_link/service/ghost_link_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  OllamaStatus? _aiStatus;
  double _cpuLoad = 0.12;
  double _ramUsage = 0.45;
  final Random _rng = Random();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _startSim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'NOC Dashboard',
        showBackButton: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _checkStatus),
        ],
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSim() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _cpuLoad = (0.10 + _rng.nextDouble() * 0.40).clamp(0.0, 1.0);
          _ramUsage = (0.40 + _rng.nextDouble() * 0.10).clamp(0.0, 1.0);
        });
      }
    });
  }

  Future<void> _checkStatus() async {
    final s = await OllamaService.checkStatus();
    if (mounted) setState(() => _aiStatus = s);
  }

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: ListView(
        children: [
          const Text('Network Operations Center', style: TextStyle(color: TdcColors.accent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text('Diagnostic en Temps Réel', style: TextStyle(color: TdcColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          
          Wrap(
            spacing: 16, runSpacing: 16,
            children: [
              _stat('CPU Load', '${(_cpuLoad * 100).toInt()}%', _cpuLoad, Icons.memory, TdcColors.accent),
              _stat('RAM Usage', '${(_ramUsage * 100).toInt()}%', _ramUsage, Icons.speed, const Color(0xFF8B5CF6)),
              _stat('AI Models', '${_aiStatus?.models.length ?? 0} actifs', (_aiStatus?.models.length ?? 0) / 10, Icons.smart_toy, TdcColors.success),
            ],
          ),
          
          const SizedBox(height: 32),
          ResponsiveBuilder(builder: (context, type) {
            final isDesktop = type.isDesktop;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isDesktop ? 2 : 1,
                  child: Column(children: [
                    _section('États des Services', [
                      _service('Ollama API', _aiStatus?.running ?? false),
                      Consumer<GhostLinkService>(
                        builder: (context, gl, _) => InkWell(
                          onTap: () => Navigator.pushNamed(context, '/ghost-link'),
                          child: Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: gl.isRunning ? TdcColors.success : TdcColors.textMuted)),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Ghost Link', style: const TextStyle(color: TdcColors.textSecondary, fontSize: 13))),
                            Text(gl.isRunning ? '${gl.peers.length} pair(s)' : 'Inactif',
                              style: TextStyle(color: gl.isRunning ? TdcColors.success : TdcColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 12, color: TdcColors.textMuted),
                          ])),
                        ),
                      ),
                      _service('Local Storage', true),
                    ]),
                    const SizedBox(height: 16),
                    _recent(),
                  ]),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _tools()),
                ],
              ],
            );
          }),
          if (!TdcBreakpoints.isDesktop(context)) ...[
            const SizedBox(height: 16),
            _tools(),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _stat(String title, String val, double progress, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: color, size: 18),
          Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ]),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress, minHeight: 2, backgroundColor: TdcColors.surfaceAlt, valueColor: AlwaysStoppedAnimation(color)),
      ]),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _service(String name, bool status) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: status ? TdcColors.success : TdcColors.danger)),
      const SizedBox(width: 12),
      Expanded(child: Text(name, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 13))),
      Text(status ? 'OK' : 'ERR', style: TextStyle(color: status ? TdcColors.success : TdcColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
    ]));
  }

  Widget _recent() {
    return _section('Sessions Récentes', [
      _tile('Ghost Link', 'Connexion établie', '2m', Icons.link),
      _tile('Ollama', 'Génération Phi-3', '15m', Icons.auto_awesome),
    ]);
  }

  Widget _tile(String cat, String desc, String time, IconData icon) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
      Icon(icon, size: 14, color: TdcColors.textMuted),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(cat, style: const TextStyle(color: TdcColors.accent, fontWeight: FontWeight.bold, fontSize: 11)),
          Text(time, style: const TextStyle(color: TdcColors.textMuted, fontSize: 9)),
        ]),
        Text(desc, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12)),
      ])),
    ]));
  }

  Widget _tools() {
    return _section('Outils Rapides', [
      _btn('Nettoyer /tmp', Icons.cleaning_services, onTap: _cleanTmp),
      _btn('Logs Système', Icons.terminal, onTap: _showLogs),
    ]);
  }

  void _cleanTmp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulation: Nettoyage du répertoire /tmp effectué.')),
    );
  }

  void _showLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TdcColors.surface,
        title: const Text('Logs Système (Simulation)', style: TextStyle(color: TdcColors.textPrimary)),
        content: Container(
          width: 500,
          height: 300,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.black, borderRadius: TdcRadius.sm),
          child: const SingleChildScrollView(
            child: Text(
              '[INFO] Ollama service started\n[DEBUG] Connecting to p2p mesh...\n[INFO] 127.0.0.1:11434 reachable\n[WARN] High CPU load detected: 85%\n[INFO] Course "Linux Basics" loaded\n[INFO] Dashboard initialized',
              style: TextStyle(color: TdcColors.success, fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Widget _btn(String label, IconData icon, {required VoidCallback onTap}) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: TdcColors.bg, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
        child: Row(children: [
          Icon(icon, size: 16, color: TdcColors.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: TdcColors.textPrimary, fontSize: 12)),
        ]),
      ),
    ));
  }
}
