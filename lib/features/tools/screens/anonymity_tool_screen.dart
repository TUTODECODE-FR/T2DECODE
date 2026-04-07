// ============================================================
// Outil Anonymat & Identité Réseau — Exécution réelle
// ============================================================
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';
import '../services/anonymity_service.dart';

class AnonymityToolScreen extends StatefulWidget {
  const AnonymityToolScreen({super.key});
  @override
  State<AnonymityToolScreen> createState() => _AnonymityToolScreenState();
}

class _AnonymityToolScreenState extends State<AnonymityToolScreen> {
  // Valeurs actuelles lues depuis le système
  String _curHostname = '…';
  String _curMac = '…';
  String _curInterface = 'eth0';
  String _curUsername = '…';
  bool _loading = true;

  // Valeurs générées / saisies
  final _hostnameCtrl = TextEditingController();
  final _macCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _sudoCtrl = TextEditingController();
  bool _showSudo = false;

  // TTL
  int _ttl = 128;

  // Sauvegarde originale
  AnonBackup? _backup;
  bool _backupExists = false;

  // Logs d'opérations
  final List<_OpLog> _logs = [];
  bool _anyRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Anonymat & Identité Réseau',
        showBackButton: true,
        actions: [],
      );
    });
    _loadCurrentValues();
  }

  @override
  void dispose() {
    _hostnameCtrl.dispose();
    _macCtrl.dispose();
    _usernameCtrl.dispose();
    _sudoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentValues() async {
    setState(() => _loading = true);
    final hn = await AnonymityService.getCurrentHostname();
    final user = await AnonymityService.getCurrentUsername();
    final macInfo = await AnonymityService.getCurrentMac(); // MacInfo
    final backup = await AnonymityService.loadBackup();
    if (!mounted) return;
    setState(() {
      _curHostname = hn;
      _curMac = macInfo.mac;
      _curInterface = macInfo.interface;
      _curUsername = user;
      _hostnameCtrl.text = AnonymityService.generateHostname();
      _macCtrl.text = AnonymityService.generateMac();
      _usernameCtrl.text = AnonymityService.generateUsername();
      _backup = backup;
      _backupExists = backup != null;
      _loading = false;
    });
  }

  void _regenerateAll() {
    setState(() {
      _hostnameCtrl.text = AnonymityService.generateHostname();
      _macCtrl.text = AnonymityService.generateMac();
      _usernameCtrl.text = AnonymityService.generateUsername();
    });
  }

  String? get _sudoPassword => _sudoCtrl.text.trim().isEmpty ? null : _sudoCtrl.text.trim();

  Future<void> _saveBackupIfNeeded() async {
    if (_backupExists) return;
    final b = AnonBackup(
      hostname: _curHostname,
      macAddress: _curMac,
      interface: _curInterface,
      username: _curUsername,
      savedAt: DateTime.now(),
    );
    await AnonymityService.saveBackup(b);
    setState(() { _backup = b; _backupExists = true; });
  }

  void _addLog(String title, AnonResult result) {
    setState(() {
      _logs.insert(0, _OpLog(
        title: title,
        success: result.success,
        message: result.message,
        detail: [result.output, result.error].where((s) => s != null && s.isNotEmpty).join('\n'),
        time: DateTime.now(),
      ));
    });
  }

  Future<void> _run(String title, Future<AnonResult> Function() action) async {
    if (_anyRunning) return;
    setState(() => _anyRunning = true);
    try {
      final result = await action();
      _addLog(title, result);
      if (result.success) await _loadCurrentValues();
    } finally {
      if (mounted) setState(() => _anyRunning = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return TdcPageWrapper(
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: TdcColors.accent))
          : ListView(
              children: [
                _buildWarningBanner(),
                const SizedBox(height: 16),
                _buildCurrentState(),
                const SizedBox(height: 20),
                _buildSudoField(),
                const SizedBox(height: 20),
                _buildSection('Hostname', Icons.computer, _buildHostnameCard()),
                const SizedBox(height: 16),
                _buildSection('MAC Address', Icons.wifi, _buildMacCard()),
                const SizedBox(height: 16),
                _buildSection('Créer un nouvel utilisateur', Icons.person_add, _buildUserCard()),
                const SizedBox(height: 16),
                _buildSection('Réseau : IPv6 / mDNS / TTL', Icons.settings_ethernet, _buildNetCard()),
                if (_backupExists) ...[
                  const SizedBox(height: 20),
                  _buildRestoreCard(),
                ],
                if (_logs.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildLogs(),
                ],
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.09),
        borderRadius: TdcRadius.md,
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
              SizedBox(width: 8),
              Text('CE QUE CET OUTIL NE PEUT PAS FAIRE', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 10),
          _warnRow('Votre IP publique ne changera PAS.',
              'Elle est attribuée par votre FAI. Seul un VPN ou Tor peut la masquer — et encore, votre FAI voit que vous les utilisez. Cet outil n\'en fournit pas.'),
          _warnRow('La MAC ne sort pas du réseau local.',
              'Les routeurs ne propagent pas la MAC sur Internet. Elle n\'est visible que sur votre LAN.'),
          _warnRow('Les empreintes logicielles restent.',
              'User-Agent, canvas fingerprint, timezone, résolution d\'écran — les sites web peuvent toujours vous identifier.'),
          _warnRow('Ces changements sont généralement temporaires.',
              'Hostname et MAC sont restaurés au reboot sauf configuration permanente supplémentaire.'),
        ],
      ),
    );
  }

  Widget _warnRow(String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, height: 1.4),
          children: [
            TextSpan(text: '⚠ $title ', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
            TextSpan(text: detail, style: const TextStyle(color: TdcColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('ÉTAT ACTUEL', style: TextStyle(color: TdcColors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const Spacer(),
              InkWell(
                onTap: _loadCurrentValues,
                borderRadius: TdcRadius.sm,
                child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.refresh, size: 16, color: TdcColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _stateRow('Hostname', _curHostname, Icons.computer),
          _stateRow('MAC ($_curInterface)', _curMac, Icons.wifi),
          _stateRow('Utilisateur', _curUsername, Icons.person),
          _stateRow('OS', _osLabel(), Icons.devices),
        ],
      ),
    );
  }

  String _osLabel() {
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    return 'Inconnu';
  }

  Widget _stateRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: TdcColors.textMuted),
          const SizedBox(width: 8),
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold))),
          InkWell(
            onTap: () { Clipboard.setData(ClipboardData(text: value)); },
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.copy, size: 12, color: TdcColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildSudoField() {
    if (Platform.isWindows) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MOT DE PASSE SUDO', style: TextStyle(color: TdcColors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text('Requis pour les opérations système. Non sauvegardé — utilisé uniquement lors de l\'exécution.', style: TextStyle(color: TdcColors.textMuted, fontSize: 11)),
          const SizedBox(height: 10),
          TextField(
            controller: _sudoCtrl,
            obscureText: !_showSudo,
            style: const TextStyle(color: TdcColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Mot de passe sudo…',
              hintStyle: const TextStyle(color: TdcColors.textMuted),
              filled: true,
              fillColor: TdcColors.surfaceAlt,
              border: OutlineInputBorder(borderRadius: TdcRadius.sm, borderSide: const BorderSide(color: TdcColors.border)),
              suffixIcon: IconButton(
                icon: Icon(_showSudo ? Icons.visibility_off : Icons.visibility, size: 18, color: TdcColors.textMuted),
                onPressed: () => setState(() => _showSudo = !_showSudo),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 14, color: TdcColors.textMuted),
          const SizedBox(width: 8),
          Text(title.toUpperCase(), style: const TextStyle(color: TdcColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        ]),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildHostnameCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _hostnameCtrl,
                style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace', fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Nouveau hostname',
                  filled: true, fillColor: TdcColors.surfaceAlt,
                  border: OutlineInputBorder(borderSide: BorderSide(color: TdcColors.border)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => setState(() => _hostnameCtrl.text = AnonymityService.generateHostname()),
              icon: const Icon(Icons.casino, color: TdcColors.accent, size: 20),
              tooltip: 'Générer',
            ),
          ]),
          const SizedBox(height: 12),
          _buildApplyBtn('Appliquer le hostname', Icons.check, () async {
            await _saveBackupIfNeeded();
            await _run('Hostname → ${_hostnameCtrl.text}', () =>
                AnonymityService.changeHostname(_hostnameCtrl.text.trim(), sudoPassword: _sudoPassword));
          }),
        ],
      ),
    );
  }

  Widget _buildMacCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interface : $_curInterface', style: const TextStyle(color: TdcColors.textMuted, fontSize: 11)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _macCtrl,
                style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace', fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Nouvelle MAC (XX:XX:XX:XX:XX:XX)',
                  filled: true, fillColor: TdcColors.surfaceAlt,
                  border: OutlineInputBorder(borderSide: BorderSide(color: TdcColors.border)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => setState(() => _macCtrl.text = AnonymityService.generateMac()),
              icon: const Icon(Icons.casino, color: TdcColors.accent, size: 20),
              tooltip: 'Générer',
            ),
          ]),
          const SizedBox(height: 8),
          const Text('⚠ Temporaire : restauré au reboot. La MAC ne sort pas du réseau local.', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11)),
          const SizedBox(height: 12),
          _buildApplyBtn('Appliquer la MAC', Icons.wifi, () async {
            await _saveBackupIfNeeded();
            await _run('MAC → ${_macCtrl.text}', () =>
                AnonymityService.changeMac(_curInterface, _macCtrl.text.trim(), sudoPassword: _sudoPassword));
          }),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Un nouveau compte utilisateur sera créé. Le compte actuel reste intact.', style: TextStyle(color: TdcColors.textMuted, fontSize: 11)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _usernameCtrl,
                style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace', fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Nom du nouveau compte',
                  filled: true, fillColor: TdcColors.surfaceAlt,
                  border: OutlineInputBorder(borderSide: BorderSide(color: TdcColors.border)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => setState(() => _usernameCtrl.text = AnonymityService.generateUsername()),
              icon: const Icon(Icons.casino, color: TdcColors.accent, size: 20),
              tooltip: 'Générer',
            ),
          ]),
          const SizedBox(height: 12),
          _buildApplyBtn('Créer l\'utilisateur', Icons.person_add, () async {
            await _run('Créer user ${_usernameCtrl.text}', () =>
                AnonymityService.createNewUser(_usernameCtrl.text.trim(), sudoPassword: _sudoPassword));
          }),
        ],
      ),
    );
  }

  Widget _buildNetCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TdcColors.surface, borderRadius: TdcRadius.md, border: Border.all(color: TdcColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IPv6
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Désactiver IPv6', style: TextStyle(color: TdcColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              const Text('Réduit l\'empreinte réseau. Réversible.', style: TextStyle(color: TdcColors.textMuted, fontSize: 11)),
            ])),
            ElevatedButton(
              onPressed: _anyRunning ? null : () => _run('Désactiver IPv6', () => AnonymityService.disableIPv6(sudoPassword: _sudoPassword)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: TdcColors.textPrimary, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
              child: const Text('Désactiver', style: TextStyle(fontSize: 12)),
            ),
          ]),
          const Divider(height: 20, color: TdcColors.border),
          // mDNS
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Désactiver mDNS/Bonjour', style: TextStyle(color: TdcColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              const Text('⚠ Désactive AirDrop/AirPlay sur macOS.', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11)),
            ])),
            ElevatedButton(
              onPressed: _anyRunning ? null : () => _run('Désactiver mDNS', () => AnonymityService.disableMdns(sudoPassword: _sudoPassword)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: TdcColors.textPrimary, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
              child: const Text('Désactiver', style: TextStyle(fontSize: 12)),
            ),
          ]),
          const Divider(height: 20, color: TdcColors.border),
          // TTL
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Changer le TTL réseau', style: TextStyle(color: TdcColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            const Text('Modifie l\'empreinte OS (fingerprinting). 64=Linux, 128=Windows, 255=macOS/Cisco.', style: TextStyle(color: TdcColors.textMuted, fontSize: 11)),
            const SizedBox(height: 10),
            Row(children: [
              ...[64, 128, 255].map((v) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _ttl = v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _ttl == v ? TdcColors.accent.withOpacity(0.15) : Colors.transparent,
                      borderRadius: TdcRadius.sm,
                      border: Border.all(color: _ttl == v ? TdcColors.accent : TdcColors.border),
                    ),
                    child: Text('$v', style: TextStyle(color: _ttl == v ? TdcColors.accent : TdcColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              )),
              const Spacer(),
              ElevatedButton(
                onPressed: _anyRunning ? null : () => _run('TTL → $_ttl', () => AnonymityService.changeTTL(_ttl, sudoPassword: _sudoPassword)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: TdcColors.textPrimary, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                child: const Text('Appliquer', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ]),
        ],
      ),
    );
  }

  Widget _buildRestoreCard() {
    final b = _backup!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.07),
        borderRadius: TdcRadius.md,
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.restore, color: Color(0xFF10B981), size: 16),
            SizedBox(width: 8),
            Text('RESTAURATION DES VALEURS ORIGINALES', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ]),
          const SizedBox(height: 10),
          if (b.hostname != null) Text('Hostname original : ${b.hostname}', style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12)),
          if (b.macAddress != null) Text('MAC originale : ${b.macAddress}', style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12)),
          Text('Sauvegardé le : ${_fmtDate(b.savedAt)}', style: const TextStyle(color: TdcColors.textMuted, fontSize: 11)),
          const SizedBox(height: 12),
          Row(children: [
            ElevatedButton.icon(
              onPressed: _anyRunning ? null : () async {
                await _run('Restauration', () async {
                  final results = await AnonymityService.restoreAll(_backup!, sudoPassword: _sudoPassword);
                  if (results.isEmpty) return const AnonResult(success: true, message: 'Rien à restaurer');
                  final allOk = results.every((r) => r.success);
                  final msgs = results.map((r) => r.message).join(' | ');
                  return AnonResult(success: allOk, message: msgs);
                });
              },
              icon: const Icon(Icons.restore, size: 16),
              label: const Text('Restaurer', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () async {
                await AnonymityService.clearBackup();
                setState(() { _backup = null; _backupExists = false; });
              },
              child: const Text('Supprimer la sauvegarde', style: TextStyle(color: TdcColors.textMuted, fontSize: 12)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildLogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('JOURNAL DES OPÉRATIONS', style: TextStyle(color: TdcColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const Spacer(),
          TextButton(onPressed: () => setState(() => _logs.clear()), child: const Text('Effacer', style: TextStyle(color: TdcColors.textMuted, fontSize: 11))),
        ]),
        const SizedBox(height: 8),
        ..._logs.take(10).map((log) => _buildLogEntry(log)),
      ],
    );
  }

  Widget _buildLogEntry(_OpLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: log.success ? const Color(0xFF10B981).withOpacity(0.07) : const Color(0xFFEF4444).withOpacity(0.07),
        borderRadius: TdcRadius.sm,
        border: Border.all(color: (log.success ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(log.success ? Icons.check_circle : Icons.error, size: 14, color: log.success ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
            const SizedBox(width: 6),
            Expanded(child: Text(log.title, style: const TextStyle(color: TdcColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
            Text(_fmtTime(log.time), style: const TextStyle(color: TdcColors.textMuted, fontSize: 10)),
          ]),
          const SizedBox(height: 4),
          Text(log.message, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12)),
          if (log.detail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(log.detail, style: const TextStyle(color: TdcColors.textMuted, fontFamily: 'monospace', fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _buildApplyBtn(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _anyRunning ? null : onTap,
        icon: _anyRunning
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: TdcColors.accent,
          foregroundColor: Colors.black,
          disabledBackgroundColor: TdcColors.border,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) => '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} ${_fmtTime(dt)}';
  String _fmtTime(DateTime dt) => '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}';
}

class _OpLog {
  final String title;
  final bool success;
  final String message;
  final String detail;
  final DateTime time;
  _OpLog({required this.title, required this.success, required this.message, required this.detail, required this.time});
}
