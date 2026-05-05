import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/features/ghost_ai/service/ollama_service.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/responsive/responsive.dart';
import 'package:tutodecode/core/services/storage_service.dart';
import 'package:tutodecode/core/security/ollama_host.dart';
import 'package:tutodecode/core/providers/settings_provider.dart';

class AIConfigScreen extends StatefulWidget {
  const AIConfigScreen({super.key});
  @override
  State<AIConfigScreen> createState() => _AIConfigScreenState();
}

class _AIConfigScreenState extends State<AIConfigScreen> {
  OllamaStatus? _status;
  bool _checking = false;
  bool _demoMode = false;
  String? _pullingModel;
  final _hostController = TextEditingController();
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _loadHost();
  }

  Future<void> _loadHost() async {
    final host = await _storage.getOllamaHost();
    setState(() => _hostController.text = host);
    _checkOllama();
    // Lire le mode démo actuel
    final dm = await _storage.getDemoMode();
    if (mounted) setState(() => _demoMode = dm);
  }

  Future<void> _saveHost() async {
    String raw = _hostController.text.trim();
    if (raw.isEmpty) return;

    // Default scheme: http for loopback, https otherwise.
    if (!raw.contains('://')) {
      final lower = raw.toLowerCase();
      final isLoopback = lower.startsWith('localhost') || lower.startsWith('127.0.0.1');
      raw = '${isLoopback ? 'http' : 'https'}://$raw';
    }

    // Normalisation + validation centralisée (défense en profondeur).
    final String normalized;
    try {
      normalized = OllamaHost.normalize(raw);
    } on FormatException catch (e) {
      final msg = e.message == 'Host not allowed'
          ? 'Sécurité : HTTP autorisé uniquement sur localhost. Utilisez https:// pour un serveur LAN/VPN.'
          : 'Adresse invalide. Exemple: http://localhost:11434';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: TdcColors.danger,
      ));
      return;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Adresse invalide. Exemple: http://localhost:11434'),
        backgroundColor: TdcColors.danger,
      ));
      return;
    }

    _hostController.text = normalized;
    await _storage.saveOllamaHost(normalized);
    _checkOllama();
  }

  Future<void> _checkOllama() async {
    setState(() => _checking = true);
    final status = await OllamaService.checkStatus();
    setState(() {
      _status = status;
      _checking = false;
    });
  }

  void _copyCommand(String cmd) {
    Clipboard.setData(ClipboardData(text: cmd));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Commande copiée !', style: TextStyle(color: TdcColors.textPrimary)),
      backgroundColor: TdcColors.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: TdcRadius.md),
      duration: Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TdcColors.bg,
      appBar: AppBar(
        title: Text('Configuration IA Locale'),
        backgroundColor: TdcColors.bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: TdcColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _checking
                ? SizedBox(
                    width: TdcAdaptive.space(context, 18), 
                    height: TdcAdaptive.space(context, 18), 
                    child: CircularProgressIndicator(strokeWidth: 2, color: TdcColors.accent))
                : Icon(Icons.refresh, color: TdcColors.textSecondary, size: TdcAdaptive.icon(context, 20)),
            tooltip: 'Vérifier à nouveau',
            onPressed: _checking ? null : _checkOllama,
          ),
          SizedBox(width: TdcAdaptive.space(context, 8)),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(TdcAdaptive.padding(context, TdcSpacing.xl)),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: TdcAdaptive.space(context, 760)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Statut Ollama
                _buildStatusCard(context),
                SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),

                // ── Configuration du Serveur
                _buildHostConfig(context),
                SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),

                // ── Si Ollama est lancé : modèles installés
                if (_status?.running == true) ...[
                  _buildInstalledModels(context),
                  SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),
                ],

                // ── Modèles recommandés
                _buildRecommendedModels(context),
                SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),

                // ── Guide d'installation si absent
                if (_status?.running == false) ...[
                  _buildInstallGuide(context),
                  SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),
                ],

                // ── Commandes utiles
                _buildUsefulCommands(context),
                SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),

                // ── Mode Démo (Apple Review)
                _buildDemoModeSection(context),
                SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),

                // ── Accès à distance
                _buildRemoteAccessGuide(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Carte statut ───────────────────────────────────────────
  Widget _buildStatusCard(BuildContext context) {
    final isRunning = _status?.running ?? false;
    final color = _checking
        ? TdcColors.warning
        : (isRunning ? TdcColors.success : TdcColors.danger);
    final icon = _checking
        ? Icons.hourglass_top
        : (isRunning ? Icons.check_circle : Icons.cancel);
    final statusText = _checking
        ? 'Vérification en cours…'
        : (isRunning
            ? 'Ollama est en ligne  ${_status?.version != null ? "— v${_status!.version}" : ""}'
            : (_status?.error ?? 'Ollama n\'est pas détecté'));
    final subText = _checking
        ? 'Ping sur ${_hostController.text}…'
        : (isRunning
            ? '${_status!.models.length} modèle(s) installé(s) · Port 11434'
            : 'Installez ou démarrez Ollama pour activer l\'IA locale\n${_status?.error ?? ""}');

    return Container(
      padding: EdgeInsets.all(TdcAdaptive.padding(context, TdcSpacing.lg)),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.lg,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(TdcAdaptive.padding(context, 14)),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: TdcAdaptive.icon(context, 28)),
          ),
          SizedBox(width: TdcAdaptive.space(context, TdcSpacing.md)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusText, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: TdcText.bodyLarge(context))),
                SizedBox(height: TdcAdaptive.space(context, 4)),
                Text(subText, style: TextStyle(color: TdcColors.textSecondary, fontSize: TdcText.bodySmall(context))),
              ],
            ),
          ),
          if (!_checking)
            OutlinedButton.icon(
              onPressed: _checkOllama,
              icon: Icon(Icons.refresh, size: TdcAdaptive.icon(context, 15)),
              label: Text('Rafraîchir', style: TextStyle(fontSize: TdcText.button(context))),
              style: OutlinedButton.styleFrom(
                foregroundColor: TdcColors.textSecondary,
                side: BorderSide(color: TdcColors.border),
                padding: EdgeInsets.symmetric(
                  horizontal: TdcAdaptive.padding(context, 14), 
                  vertical: TdcAdaptive.padding(context, 10)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Modèles installés ──────────────────────────────────────
  Widget _buildInstalledModels(BuildContext context) {
    final models = _status?.models ?? [];
    return _buildSection(
      context: context,
      icon: Icons.inventory_2,
      title: 'Modèles installés',
      child: models.isEmpty
          ? _buildEmptyState('Aucun modèle installé.\nUtilisez `ollama pull <modèle>` pour en ajouter un.')
          : Column(
              children: models.map((m) => _buildModelRow(
                context: context,
                name: m,
                isInstalled: true,
                onAction: null,
              )).toList(),
            ),
    );
  }

  // ── Modèles recommandés ────────────────────────────────────
  Widget _buildRecommendedModels(BuildContext context) {
    return _buildSection(
      context: context,
      icon: Icons.auto_awesome,
      title: 'Modèles recommandés pour TutoDeCode',
      child: Column(
        children: kRecommendedModels.map((m) {
          final isInstalled = _status?.models.any((installed) =>
                  installed.startsWith(m['id']!)) ??
              false;
          final isPulling = _pullingModel == m['id'];
          return _buildRecommendedCard(context, m, isInstalled, isPulling);
        }).toList(),
      ),
    );
  }

  Widget _buildRecommendedCard(BuildContext context, Map<String, String> model, bool isInstalled, bool isPulling) {
    final pullCmd = 'ollama pull ${model['id']}';
    final isMobile = TdcBreakpoints.isMobile(context);
    
    return Container(
      margin: EdgeInsets.only(bottom: TdcAdaptive.space(context, TdcSpacing.sm)),
      padding: EdgeInsets.all(TdcAdaptive.padding(context, TdcSpacing.md)),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        borderRadius: TdcRadius.md,
        border: Border.all(
          color: isInstalled ? TdcColors.success.withOpacity(0.3) : TdcColors.border,
        ),
      ),
      child: isMobile 
      ? Column(
          children: [
            Row(
              children: [
                _buildModelAvatar(context, isInstalled),
                SizedBox(width: TdcAdaptive.space(context, TdcSpacing.md)),
                Expanded(child: _buildModelInfo(context, model, isInstalled)),
              ],
            ),
            SizedBox(height: TdcAdaptive.space(context, TdcSpacing.md)),
            _buildModelAction(context, isInstalled, pullCmd),
          ],
        )
      : Row(
        children: [
          _buildModelAvatar(context, isInstalled),
          SizedBox(width: TdcAdaptive.space(context, TdcSpacing.md)),
          Expanded(child: _buildModelInfo(context, model, isInstalled)),
          SizedBox(width: TdcAdaptive.space(context, TdcSpacing.md)),
          _buildModelAction(context, isInstalled, pullCmd),
        ],
      ),
    );
  }

  Widget _buildModelAvatar(BuildContext context, bool isInstalled) {
    return Container(
      padding: EdgeInsets.all(TdcAdaptive.padding(context, 10)),
      decoration: BoxDecoration(
        color: isInstalled
            ? TdcColors.success.withOpacity(0.1)
            : TdcColors.accentDim,
        borderRadius: TdcRadius.sm,
      ),
      child: Icon(
        isInstalled ? Icons.check_circle : Icons.memory,
        color: isInstalled ? TdcColors.success : TdcColors.accent,
        size: TdcAdaptive.icon(context, 22),
      ),
    );
  }

  Widget _buildModelInfo(BuildContext context, Map<String, String> model, bool isInstalled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: TdcAdaptive.space(context, 8),
          children: [
            Text(model['label']!, style: TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: TdcText.body(context))),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: TdcColors.surface, borderRadius: BorderRadius.circular(4)),
              child: Text(model['size']!, style: TextStyle(color: TdcColors.textMuted, fontSize: TdcText.label(context), fontWeight: FontWeight.bold)),
            ),
            if (isInstalled)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: TdcColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text('installé', style: TextStyle(color: TdcColors.success, fontSize: TdcText.label(context), fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        SizedBox(height: TdcAdaptive.space(context, 4)),
        Text(model['desc']!, style: TextStyle(color: TdcColors.textSecondary, fontSize: TdcText.bodySmall(context))),
      ],
    );
  }

  Widget _buildModelAction(BuildContext context, bool isInstalled, String pullCmd) {
    if (!isInstalled) {
      return InkWell(
        onTap: () => _copyCommand(pullCmd),
        borderRadius: TdcRadius.sm,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: TdcAdaptive.padding(context, 10), 
            vertical: TdcAdaptive.padding(context, 7)),
          decoration: BoxDecoration(
            color: TdcColors.surface,
            borderRadius: TdcRadius.sm,
            border: Border.all(color: TdcColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.terminal, size: TdcAdaptive.icon(context, 14), color: TdcColors.accent),
              SizedBox(width: TdcAdaptive.space(context, 6)),
              Text(pullCmd, style: TextStyle(fontFamily: 'monospace', fontSize: TdcText.label(context), color: TdcColors.accent)),
              SizedBox(width: TdcAdaptive.space(context, 8)),
              Icon(Icons.copy, size: TdcAdaptive.icon(context, 13), color: TdcColors.textMuted),
            ],
          ),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/ai'),
        icon: Icon(Icons.chat, size: TdcAdaptive.icon(context, 15)),
        label: Text('Utiliser', style: TextStyle(fontSize: TdcText.button(context))),
        style: ElevatedButton.styleFrom(
          backgroundColor: TdcColors.accent,
          padding: EdgeInsets.symmetric(
            horizontal: TdcAdaptive.padding(context, 14), 
            vertical: TdcAdaptive.padding(context, 10)),
        ),
      );
    }
  }

  Widget _buildModelRow({required BuildContext context, required String name, required bool isInstalled, VoidCallback? onAction}) {
    return Container(
      margin: EdgeInsets.only(bottom: TdcAdaptive.space(context, 8)),
      padding: EdgeInsets.symmetric(
        horizontal: TdcAdaptive.padding(context, TdcSpacing.md), 
        vertical: TdcAdaptive.padding(context, TdcSpacing.sm + 2)),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt,
        borderRadius: TdcRadius.sm,
        border: Border.all(color: TdcColors.success.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(Icons.circle, size: TdcAdaptive.icon(context, 8), color: TdcColors.success),
        SizedBox(width: TdcAdaptive.space(context, TdcSpacing.sm)),
        Text(name, 
          style: TextStyle(
            color: TdcColors.textPrimary, 
            fontFamily: 'monospace', 
            fontSize: TdcText.body(context))),
        const Spacer(),
        Icon(Icons.check, size: TdcAdaptive.icon(context, 16), color: TdcColors.success),
      ]),
    );
  }

  // ── Guide installation ─────────────────────────────────────
  int _selectedOS = 0; // 0: Windows, 1: Mac, 2: Linux, 3: Mobile

  Widget _buildInstallGuide(BuildContext context) {
    return _buildSection(
      context: context,
      icon: Icons.download,
      title: 'Guide d\'installation Multi-Plateforme',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ollama exécute des IA (Llama, Mistral) localement sur votre machine, 100% hors-ligne.',
            style: TextStyle(color: TdcColors.textSecondary, fontSize: TdcText.body(context), height: 1.6),
          ),
          SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),
          
          // Sélecteur d'OS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildOSChip(0, 'Windows', Icons.desktop_windows),
                SizedBox(width: TdcAdaptive.space(context, 8)),
                _buildOSChip(1, 'macOS', Icons.apple),
                SizedBox(width: TdcAdaptive.space(context, 8)),
                _buildOSChip(2, 'Linux', Icons.terminal),
                SizedBox(width: TdcAdaptive.space(context, 8)),
                _buildOSChip(3, 'Mobile', Icons.phone_android),
              ],
            ),
          ),
          
          SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),
          Divider(color: TdcColors.border, height: 1),
          SizedBox(height: TdcAdaptive.space(context, TdcSpacing.lg)),

          // Contenu selon l'OS
          if (_selectedOS == 0) _buildWindowsGuide(context),
          if (_selectedOS == 1) _buildMacGuide(context),
          if (_selectedOS == 2) _buildLinuxGuide(context),
          if (_selectedOS == 3) _buildMobileGuide(context),
        ],
      ),
    );
  }

  Widget _buildOSChip(int index, String label, IconData icon) {
    final isSelected = _selectedOS == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (v) => setState(() => _selectedOS = index),
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : TdcColors.textMuted),
      backgroundColor: TdcColors.surfaceAlt,
      selectedColor: TdcColors.accent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : TdcColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? TdcColors.accent : TdcColors.border),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildWindowsGuide(BuildContext context) {
    return Column(
      children: [
        _buildInstallStep(context, '1', 'Télécharger l\'installeur',
            'Téléchargez le fichier "OllamaSetup.exe" sur le site officiel.',
            trailing: _buildLinkButton('ollama.com/download/windows')),
        _buildInstallStep(context, '2', 'Lancer l\'installation',
            'Exécutez le setup et suivez les étapes. Ollama s\'ajoutera à votre barre des tâches.'),
        _buildInstallStep(context, '3', 'Premier modèle',
            'Ouvrez un terminal (CMD ou PowerShell) et tapez :',
            command: 'ollama pull mistral'),
        _buildInstallStep(context, '4', 'Terminé', 'Le statut en haut de cette page passera au vert.', isLast: true),
      ],
    );
  }

  Widget _buildMacGuide(BuildContext context) {
    return Column(
      children: [
        _buildInstallStep(context, '1', 'Télécharger pour Mac',
            'Téléchargez l\'archive .zip pour macOS.',
            trailing: _buildLinkButton('ollama.com/download/mac')),
        _buildInstallStep(context, '2', 'Déplacer dans Applications',
            'Extrayez l\'application et glissez-la dans votre dossier /Applications.'),
        _buildInstallStep(context, '3', 'Autoriser l\'ouverture',
            'Lancez Ollama. Si Mac bloque l\'ouverture, allez dans Réglages > Confidentialité et Sécurité > Ouvrir quand même.'),
        _buildInstallStep(context, '4', 'Installer en ligne de commande',
            'Outillez votre Terminal en tapant :',
            command: 'ollama pull llama3', isLast: true),
      ],
    );
  }

  Widget _buildLinuxGuide(BuildContext context) {
    return Column(
      children: [
        _buildInstallStep(context, '1', 'Installation automatique',
            'Copiez et collez cette commande dans votre terminal pour installer Ollama via le script officiel.',
            command: 'curl -fsSL https://ollama.com/install.sh | sh'),
        _buildInstallStep(context, '2', 'Vérifier le service',
            'Le service systemd démarre automatiquement. Vérifiez avec :',
            command: 'systemctl status ollama'),
        _buildInstallStep(context, '3', 'Télécharger un modèle',
            'Activez l\'IA en tapant :',
            command: 'ollama pull mistral', isLast: true),
      ],
    );
  }

  Widget _buildMobileGuide(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TdcColors.warning.withOpacity(0.1),
            borderRadius: TdcRadius.md,
            border: Border.all(color: TdcColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: TdcColors.warning),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Ollama ne tourne pas encore nativement SUR mobile. Cette application s\'y connecte via votre réseau local.',
                  style: TextStyle(color: TdcColors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        _buildInstallStep(context, '1', 'Configurer le serveur (PC/Mac)',
            'Par défaut, Ollama n\'écoute que sur localhost. Pour autoriser le mobile, définissez la variable d\'environnement :',
            command: 'OLLAMA_HOST=0.0.0.0'),
        _buildInstallStep(context, '2', 'Trouver votre IP locale',
            'Sur votre ordinateur, trouvez votre IP (ex: 192.168.1.15).'),
        _buildInstallStep(context, '3', 'Connecter l\'App',
            'Dans les réglages de cette application mobile, remplacez "localhost" par votre IP réelle.', isLast: true),
      ],
    );
  }

  Widget _buildLinkButton(String url) {
    return OutlinedButton.icon(
      onPressed: () => _copyCommand('https://$url'),
      icon: Icon(Icons.open_in_new, size: 14),
      label: Text(url),
      style: OutlinedButton.styleFrom(
        foregroundColor: TdcColors.accent,
        side: BorderSide(color: TdcColors.accent.withOpacity(0.4)),
      ),
    );
  }

  Widget _buildInstallStep(BuildContext context, String num, String title, String desc, {String? command, Widget? trailing, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(children: [
            Container(
              width: TdcAdaptive.space(context, 28), 
              height: TdcAdaptive.space(context, 28),
              decoration: BoxDecoration(color: TdcColors.accentDim, shape: BoxShape.circle, border: Border.all(color: TdcColors.accent.withOpacity(0.3))),
              child: Center(child: Text(num, style: TextStyle(color: TdcColors.accent, fontSize: TdcText.bodySmall(context), fontWeight: FontWeight.bold))),
            ),
            if (!isLast) Expanded(child: Container(width: 1, color: TdcColors.border, margin: EdgeInsets.symmetric(vertical: TdcAdaptive.space(context, 4)))),
          ]),
          SizedBox(width: TdcAdaptive.space(context, TdcSpacing.md)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: TdcAdaptive.space(context, TdcSpacing.md)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.w600, fontSize: TdcText.body(context))),
                  SizedBox(height: TdcAdaptive.space(context, 4)),
                  Text(desc, style: TextStyle(color: TdcColors.textSecondary, fontSize: TdcText.bodySmall(context), height: 1.5)),
                  if (command != null) ...[
                    SizedBox(height: TdcAdaptive.space(context, TdcSpacing.sm)),
                    InkWell(
                      onTap: () => _copyCommand(command),
                      borderRadius: TdcRadius.sm,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: TdcAdaptive.padding(context, 12), 
                          vertical: TdcAdaptive.padding(context, 8)),
                        decoration: BoxDecoration(color: const Color(0xFF1A1D2E), borderRadius: TdcRadius.sm, border: Border.all(color: TdcColors.border)),
                        child: Row(children: [
                          Text('\$ $command', style: TextStyle(fontFamily: 'monospace', color: TdcColors.success, fontSize: TdcText.bodySmall(context))),
                          const Spacer(),
                          Icon(Icons.copy, size: TdcAdaptive.icon(context, 14), color: TdcColors.textMuted),
                        ]),
                      ),
                    ),
                  ],
                  if (trailing != null) ...[SizedBox(height: TdcAdaptive.space(context, TdcSpacing.sm)), trailing],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Commandes utiles ───────────────────────────────────────
  Widget _buildUsefulCommands(BuildContext context) {
    final commands = [
      {'cmd': 'ollama list', 'desc': 'Lister les modèles installés'},
      {'cmd': 'ollama run mistral', 'desc': 'Lancer Mistral en mode interactif'},
      {'cmd': 'ollama ps', 'desc': 'Voir les modèles en cours d\'exécution'},
      {'cmd': 'ollama rm mistral', 'desc': 'Supprimer un modèle'},
    ];

    return _buildSection(
      context: context,
      icon: Icons.terminal,
      title: 'Commandes rapides',
      child: Column(
        children: commands.map((c) {
          return InkWell(
            onTap: () => _copyCommand(c['cmd']!),
            borderRadius: TdcRadius.sm,
            child: Container(
              margin: EdgeInsets.only(bottom: TdcAdaptive.space(context, 8)),
              padding: EdgeInsets.symmetric(
                horizontal: TdcAdaptive.padding(context, TdcSpacing.md), 
                vertical: TdcAdaptive.padding(context, TdcSpacing.sm + 2)),
              decoration: BoxDecoration(color: TdcColors.surfaceAlt, borderRadius: TdcRadius.sm, border: Border.all(color: TdcColors.border)),
              child: Row(children: [
                Text('\$ ', style: TextStyle(color: TdcColors.textMuted, fontFamily: 'monospace', fontSize: TdcText.bodySmall(context))),
                Text(c['cmd']!, style: TextStyle(color: TdcColors.accent, fontFamily: 'monospace', fontSize: TdcText.bodySmall(context))),
                SizedBox(width: TdcAdaptive.space(context, TdcSpacing.md)),
                Expanded(child: Text(c['desc']!, style: TextStyle(color: TdcColors.textMuted, fontSize: TdcText.label(context)))),
                Icon(Icons.copy, size: TdcAdaptive.icon(context, 14), color: TdcColors.textMuted),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Mode Démo (Apple Review) ───────────────────────────────
  Widget _buildDemoModeSection(BuildContext context) {
    return _buildSection(
      context: context,
      icon: Icons.science_outlined,
      title: 'Mode Démo (Test sans Ollama)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activez ce mode pour tester l\'interface du chat IA sans avoir Ollama installé. '
            'Les réponses sont simulées (mock) — aucun appel réseau n\'est effectué.',
            style: TextStyle(
              color: TdcColors.textSecondary,
              fontSize: TdcText.bodySmall(context),
              height: 1.5,
            ),
          ),
          SizedBox(height: TdcAdaptive.space(context, 16)),
          Container(
            padding: EdgeInsets.all(TdcAdaptive.padding(context, TdcSpacing.md)),
            decoration: BoxDecoration(
              color: _demoMode
                  ? const Color(0xFF2A1F00)
                  : TdcColors.surfaceAlt,
              borderRadius: TdcRadius.md,
              border: Border.all(
                color: _demoMode
                    ? const Color(0xFFFFB300).withOpacity(0.5)
                    : TdcColors.border,
              ),
            ),
            child: Row(children: [
              Icon(
                Icons.science_outlined,
                size: TdcAdaptive.icon(context, 20),
                color: _demoMode
                    ? const Color(0xFFFFB300)
                    : TdcColors.textMuted,
              ),
              SizedBox(width: TdcAdaptive.space(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode Démo',
                      style: TextStyle(
                        color: _demoMode
                            ? const Color(0xFFFFB300)
                            : TdcColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: TdcText.body(context),
                      ),
                    ),
                    SizedBox(height: TdcAdaptive.space(context, 2)),
                    Text(
                      _demoMode
                          ? 'Actif — Réponses simulées, zéro appel réseau'
                          : 'Inactif — Ollama requis pour le chat IA',
                      style: TextStyle(
                        color: TdcColors.textSecondary,
                        fontSize: TdcText.label(context),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _demoMode,
                activeThumbColor: const Color(0xFFFFB300),
                onChanged: (value) async {
                  final settings = context.read<SettingsProvider>();
                  await settings.setDemoMode(value);
                  setState(() => _demoMode = value);
                },
              ),
            ]),
          ),
          if (_demoMode) ...[
            SizedBox(height: TdcAdaptive.space(context, 12)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: TdcAdaptive.padding(context, 14),
                vertical: TdcAdaptive.padding(context, 10),
              ),
              decoration: BoxDecoration(
                color: TdcColors.surface,
                borderRadius: TdcRadius.sm,
                border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFFFFB300)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Le mode démo est destiné aux tests (ex: Apple Review). '
                    'Désactivez-le pour retrouver le chat IA complet avec Ollama.',
                    style: TextStyle(
                      color: TdcColors.textSecondary,
                      fontSize: TdcText.label(context),
                      height: 1.4,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  // ── Accès à Distance ───────────────────────────────────────
  Widget _buildRemoteAccessGuide(BuildContext context) {
    return _buildSection(
      context: context,
      icon: Icons.vpn_lock,
      title: 'Accès à distance (VPN & LAN)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRemoteTip(
            context,
            '1. Configuration du Serveur (IMPORTANT)',
            'Par défaut, Ollama refuse les connexions externes. Sur le serveur, vous DEVEZ définir ces variables d\'environnement :',
            Icons.settings_suggest,
          ),
          Container(
            margin: const EdgeInsets.only(left: 30, top: 4, bottom: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF1A1D2E), borderRadius: TdcRadius.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEnvLine('OLLAMA_HOST', '0.0.0.0'),
                const SizedBox(height: 4),
                _buildEnvLine('OLLAMA_ORIGINS', '*'),
              ],
            ),
          ),
          _buildRemoteTip(
            context,
            '2. VPN & Réseau',
            'Utilisez Tailscale ou Zerotier pour un accès sécurisé. Copiez l\'IP VPN du serveur et collez-la dans "Adresse du Serveur" ci-dessus.',
            Icons.lan,
          ),
          const SizedBox(height: 16),
          _buildRemoteTip(
            context,
            '3. Dépannage',
            'Si le statut est rouge, vérifiez que le pare-feu du serveur autorise le port 11434.',
            Icons.bug_report_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildEnvLine(String key, String value) {
    return Row(
      children: [
        Text('$key=', style: const TextStyle(color: TdcColors.textMuted, fontFamily: 'monospace', fontSize: 11)),
        Text(value, style: const TextStyle(color: TdcColors.success, fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.copy, size: 10, color: TdcColors.textMuted),
          onPressed: () => _copyCommand('$key=$value'),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildRemoteTip(BuildContext context, String title, String desc, IconData icon, {VoidCallback? onCopy}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: TdcColors.accent.withOpacity(0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14))),
                  if (onCopy != null)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 12, color: TdcColors.textMuted),
                      onPressed: onCopy,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: TdcColors.textSecondary, fontSize: 13, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  Widget _buildSection({required BuildContext context, required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(TdcAdaptive.padding(context, TdcSpacing.lg)),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: TdcRadius.lg,
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: TdcAdaptive.icon(context, 18), color: TdcColors.accent),
            SizedBox(width: TdcAdaptive.space(context, TdcSpacing.sm)),
            Text(title, style: TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: TdcText.bodyLarge(context))),
          ]),
          SizedBox(height: TdcAdaptive.space(context, TdcSpacing.md)),
          Divider(color: TdcColors.border, height: 1),
          SizedBox(height: TdcAdaptive.space(context, TdcSpacing.md)),
          child,
        ],
      ),
    );
  }

  // ── Configuration du Serveur ─────────────────────────────
  Widget _buildHostConfig(BuildContext context) {
    return _buildSection(
      context: context,
      icon: Icons.lan,
      title: 'Adresse du Serveur Ollama',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Par défaut local (localhost). Pour un serveur distant/LAN, utilisez plutôt https:// (reverse proxy) : le HTTP en clair est refusé hors localhost.',
            style: TextStyle(color: TdcColors.textSecondary, fontSize: TdcText.bodySmall(context)),
          ),
          SizedBox(height: TdcAdaptive.space(context, 16)),
          Row(
            children: [
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.text,
                  child: TextField(
                    controller: _hostController,
                    style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace', fontSize: 14),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'http://localhost:11434',
                      filled: true,
                      fillColor: TdcColors.surfaceAlt,
                      border: OutlineInputBorder(borderRadius: TdcRadius.sm, borderSide: const BorderSide(color: TdcColors.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _saveHost(),
                    onTap: () => FocusScope.of(context).requestFocus(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _checking ? null : _saveHost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TdcColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: const Text('Appliquer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: TdcAdaptive.padding(context, TdcSpacing.md)),
      child: Text(text, style: TextStyle(color: TdcColors.textMuted, fontSize: TdcText.bodySmall(context), height: 1.6)),
    );
  }
}
