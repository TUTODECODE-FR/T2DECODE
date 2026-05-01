// ============================================================
// AI Tutor Screen — Interface de l'assistant IA local
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/features/ghost_ai/providers/ai_tutor_provider.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _messageController = TextEditingController();
  final _topicController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Assistant IA',
        showBackButton: true,
        actions: [],
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _topicController.dispose();
    _bridgeIpController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  final _bridgeIpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<AiTutorProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Barre de statut discrète — uniquement visible quand connecté
            if (provider.isConnected) _buildConnectedBar(provider),
            if (!provider.isTutoring) _buildWelcomeScreen(provider),
            if (provider.isTutoring) _buildTutorInterface(provider),
          ],
        );
      },
    );
  }

  /// Barre discrète affiché UNIQUEMENT quand Ollama est connecté.
  Widget _buildConnectedBar(AiTutorProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        border: Border(bottom: BorderSide(color: TdcColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: TdcColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tuteur IA actif · ${provider.selectedModel}',
              style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12),
            ),
          ),
          if (provider.isLoading)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: TdcColors.accent),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen(AiTutorProvider provider) {
    return Expanded(
      child: Column(
        children: [
          // Onglets — visibles dans tous les cas
          Container(
            decoration: BoxDecoration(
              color: TdcColors.surface,
              border: Border(bottom: BorderSide(color: TdcColors.border)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: TdcColors.accent,
              labelColor: TdcColors.accent,
              unselectedLabelColor: TdcColors.textSecondary,
              tabs: const [
                Tab(text: 'Tuteur'),
                Tab(text: 'Sessions'),
                Tab(text: 'Réglages'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewSessionTab(provider),
                _buildSessionsTab(provider),
                _buildSettingsTab(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewSessionTab(AiTutorProvider provider) {
    // Si pas connecté → afficher l'écran d'accueil inclusif (pas d'erreur)
    if (!provider.isConnected) {
      return _buildSetupScreen(provider);
    }
    // Connecté → interface normale de démarrage de session
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nouvelle session',
            style: TextStyle(
              color: TdcColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choisissez un sujet pour démarrer une session personnalisée.',
            style: TextStyle(color: TdcColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),
          const Text(
            'Mode de tutorat',
            style: TextStyle(color: TdcColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          _buildModeSelector(provider),
          const SizedBox(height: 28),
          const Text(
            'Sujet',
            style: TextStyle(color: TdcColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _topicController,
            style: const TextStyle(color: TdcColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Ex: Linux, Réseaux, Sécurité...',
              prefixIcon: Icon(Icons.topic, size: 20),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.suggestedTopics.map((topic) {
              return ActionChip(
                label: Text(topic),
                onPressed: () {
                  _topicController.text = topic;
                  setState(() {});
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _topicController.text.trim().isNotEmpty
                  ? () => _startNewSession(provider)
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Démarrer la session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TdcColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Écran de configuration inclusif ──────────────────────────────────────

  Widget _buildSetupScreen(AiTutorProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête accueillant — pas d'alerte, pas de rouge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TdcColors.accentDim,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.smart_toy_outlined, color: TdcColors.accent, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tuteur IA Ghost',
                      style: TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '100% local · zéro cloud · souverain',
                      style: TextStyle(color: TdcColors.accent, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TdcColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TdcColors.border),
            ),
            child: const Text(
              'Le tuteur IA fonctionne avec Ollama, un moteur de langage qui tourne entièrement sur votre réseau local. '
              'Voici les différentes façons de l\'activer — choisissez celle qui correspond à votre situation.',
              style: TextStyle(color: TdcColors.textSecondary, fontSize: 13, height: 1.5),
            ),
          ),

          const SizedBox(height: 28),

          // ── Option 1 : Mode Autonome ──────────────────────────────
          _buildSetupOption(
            icon: Icons.computer,
            color: TdcColors.accent,
            title: 'Mode Autonome',
            subtitle: 'Ollama tourne sur cet appareil',
            description:
                'Idéal pour les PC/Mac avec 8 Go de RAM minimum. '
                'Installez Ollama (ollama.com), lancez-le, puis appuyez sur "Détecter".',
            badge: 'Recommandé',
            badgeColor: TdcColors.accent,
            action: provider.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: TdcColors.accent),
                  )
                : TextButton.icon(
                    onPressed: () => provider.checkOllamaConnection(),
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Détecter'),
                    style: TextButton.styleFrom(foregroundColor: TdcColors.accent),
                  ),
          ),

          const SizedBox(height: 16),

          // ── Option 2 : Pont Souverain ─────────────────────────────
          _buildSetupOption(
            icon: Icons.hub_outlined,
            color: TdcColors.electric,
            title: 'Pont Souverain',
            subtitle: 'Se connecter à Ollama sur un autre appareil du réseau local',
            description:
                'Votre PC de bureau ou un Raspberry Pi fait tourner Ollama ? '
                'Entrez son adresse IP locale (ex: 192.168.1.42). '
                'La connexion reste dans votre réseau — aucun cloud, aucune fuite.',
            badge: 'LAN uniquement',
            badgeColor: TdcColors.electric,
            action: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _bridgeIpController,
                  style: const TextStyle(color: TdcColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '192.168.1.42',
                    prefixText: 'http://',
                    prefixStyle: const TextStyle(color: TdcColors.textMuted, fontSize: 13),
                    suffixText: ':11434',
                    suffixStyle: const TextStyle(color: TdcColors.textMuted, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: TdcColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: TdcColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: TdcColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    final ip = _bridgeIpController.text.trim();
                    if (ip.isNotEmpty) {
                      provider.updateOllamaUrl('http://$ip:11434');
                    }
                  },
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Se connecter'),
                  style: TextButton.styleFrom(foregroundColor: TdcColors.electric),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Option 3 : Sans IA ────────────────────────────────────
          _buildSetupOption(
            icon: Icons.menu_book_outlined,
            color: TdcColors.textSecondary,
            title: 'Continuer sans tuteur IA',
            subtitle: 'L\'application est 100% fonctionnelle sans Ollama',
            description:
                'Les cours, cheat sheets, labs, outils réseau et tout le reste '
                'sont disponibles immédiatement. '
                'Le tuteur interactif est un bonus — pas une obligation.',
            badge: 'Toujours disponible',
            badgeColor: TdcColors.textSecondary,
            action: null, // Pas d'action — le reste de l'app est accessible via la nav
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSetupOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String description,
    required String badge,
    required Color badgeColor,
    required Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: TdcColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action,
          ],
        ],
      ),
    );
  }

  Widget _buildModeSelector(AiTutorProvider provider) {
    return Column(
      children: TutorMode.values.map((mode) {
        final isSelected = provider.currentMode == mode;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => provider.setTutorMode(mode),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? mode.color.withOpacity(0.1) : TdcColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? mode.color.withOpacity(0.3) : TdcColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      mode.icon,
                      color: isSelected ? mode.color : TdcColors.textMuted,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.displayName,
                            style: TextStyle(
                              color: isSelected ? mode.color : TdcColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mode.description,
                            style: const TextStyle(
                              color: TdcColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: mode.color, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSessionsTab(AiTutorProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Sessions Précédentes',
                style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (provider.sessions.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _showClearSessionsDialog(provider),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Tout effacer'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
            ],
          ),
        ),
        Expanded(
          child: provider.sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, color: TdcColors.textMuted, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune session précédente',
                        style: TextStyle(color: TdcColors.textMuted, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Démarrez votre première session de tutorat',
                        style: TextStyle(color: TdcColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.sessions.length,
                  itemBuilder: (context, index) {
                    return _buildSessionCard(provider.sessions[index], provider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(TutorSession session, AiTutorProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: TdcColors.surface,
      child: InkWell(
        onTap: () => provider.selectSession(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: session.mode.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      session.mode.displayName,
                      style: TextStyle(
                        color: session.mode.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: TdcColors.textMuted, size: 16),
                    onSelected: (value) {
                      if (value == 'delete') {
                        provider.deleteSession(session.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                session.title,
                style: const TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                session.topic,
                style: const TextStyle(
                  color: TdcColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.message, color: TdcColors.textMuted, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${session.messages.length} messages',
                    style: const TextStyle(
                      color: TdcColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, color: TdcColors.textMuted, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(session.updatedAt ?? session.createdAt),
                    style: const TextStyle(
                      color: TdcColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab(AiTutorProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paramètres IA',
            style: TextStyle(
              color: TdcColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // URL Ollama
          const Text(
            'URL Ollama',
            style: TextStyle(
              color: TdcColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: 'http://localhost:11434',
            style: const TextStyle(color: TdcColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'http://localhost:11434',
              prefixIcon: const Icon(Icons.link, size: 20),
              filled: true,
              fillColor: TdcColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onFieldSubmitted: (value) => provider.updateOllamaUrl(value),
          ),
          
          const SizedBox(height: 24),
          
          // Modèle sélectionné
          const Text(
            'Modèle IA',
            style: TextStyle(
              color: TdcColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TdcColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TdcColors.border),
            ),
            child: provider.availableModels.isEmpty
                ? const Text(
                    'Aucun modèle disponible',
                    style: TextStyle(color: TdcColors.textMuted),
                  )
                : DropdownButton<String>(
                    value: provider.selectedModel,
                    isExpanded: true,
                    items: provider.availableModels.map((model) {
                      return DropdownMenuItem(
                        value: model,
                        child: Text(model),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) provider.selectModel(value);
                    },
                  ),
          ),
          
          const SizedBox(height: 32),
          
          // Statistiques
          const Text(
            'Statistiques d\'Utilisation',
            style: TextStyle(
              color: TdcColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatistics(provider),
        ],
      ),
    );
  }

  Widget _buildStatistics(AiTutorProvider provider) {
    final stats = provider.getStatistics();
    
    return Card(
      color: TdcColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow('Sessions totales', '${stats['totalSessions']}'),
            _buildStatRow('Messages échangés', '${stats['totalMessages']}'),
            _buildStatRow('Sujets couverts', '${stats['topicsCovered']}'),
            _buildStatRow('Messages/session', stats['averageMessagesPerSession']),
            _buildStatRow('Mode préféré', stats['mostUsedMode']),
            if (stats['lastActivity'] != null)
              _buildStatRow('Dernière activité', _formatDate(stats['lastActivity'])),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: TdcColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: TdcColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorInterface(AiTutorProvider provider) {
    return Expanded(
      child: Column(
        children: [
          _buildTutorHeader(provider),
          Expanded(
            child: _buildMessagesArea(provider),
          ),
          _buildInputArea(provider),
        ],
      ),
    );
  }

  Widget _buildTutorHeader(AiTutorProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surfaceAlt.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: TdcColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: provider.currentMode.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              provider.currentMode.displayName,
              style: TextStyle(
                color: provider.currentMode.color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.currentSession?.title ?? 'Session',
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  provider.currentTopic ?? 'Sujet',
                  style: const TextStyle(
                    color: TdcColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showSessionOptions(provider),
            icon: const Icon(Icons.more_vert, color: TdcColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea(AiTutorProvider provider) {
    return Container(
      color: const Color(0xFF0D1117),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: provider.currentMessages.length,
        itemBuilder: (context, index) {
          final message = provider.currentMessages[index];
          return _buildMessageBubble(message, provider);
        },
      ),
    );
  }

  Widget _buildMessageBubble(TutorMessage message, AiTutorProvider provider) {
    final isUser = message.isFromUser;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: TdcColors.accent,
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? TdcColors.accent : TdcColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isUser ? Radius.circular(16) : Radius.circular(4),
                      bottomRight: isUser ? Radius.circular(4) : Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : TdcColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: const TextStyle(
                        color: TdcColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    if (!isUser) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => provider.regenerateResponse(message.id),
                        child: const Icon(
                          Icons.refresh,
                          color: TdcColors.textMuted,
                          size: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(AiTutorProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (provider.isStreaming)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: TdcColors.surfaceAlt,
            child: Row(
              children: [
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: TdcColors.accent),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Ghost génère...', style: TextStyle(color: TdcColors.textMuted, fontSize: 12)),
                ),
                TextButton(
                  onPressed: provider.stopStreaming,
                  child: const Text('Arrêter', style: TextStyle(color: TdcColors.accent, fontSize: 12)),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TdcColors.surface,
            border: Border(top: BorderSide(color: TdcColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  enabled: !provider.isStreaming,
                  style: const TextStyle(color: TdcColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Posez votre question...',
                    filled: true,
                    fillColor: TdcColors.surfaceAlt.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _isComposing = value.isNotEmpty),
                  onSubmitted: (_) => _sendMessage(provider),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: _isComposing && !provider.isLoading && !provider.isStreaming
                    ? () => _sendMessage(provider)
                    : null,
                backgroundColor: _isComposing && !provider.isStreaming
                    ? TdcColors.accent
                    : TdcColors.surfaceAlt,
                mini: true,
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _startNewSession(AiTutorProvider provider) {
    final topic = _topicController.text.trim();
    if (topic.isNotEmpty) {
      provider.createNewSession('Session: $topic', topic);
      _topicController.clear();
    }
  }

  void _sendMessage(AiTutorProvider provider) {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      provider.sendMessage(message);
      _messageController.clear();
      setState(() => _isComposing = false);
      
      // Scroll vers le bas
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _showSessionOptions(AiTutorProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TdcColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: TdcColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history, color: TdcColors.textSecondary),
                  title: const Text('Retour aux sessions'),
                  onTap: () {
                    Navigator.pop(context);
                    provider.clearCurrentSession();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Supprimer cette session'),
                  onTap: () {
                    Navigator.pop(context);
                    if (provider.currentSession != null) {
                      provider.deleteSession(provider.currentSession!.id);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearSessionsDialog(AiTutorProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TdcColors.surface,
        title: const Text('Effacer toutes les sessions?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implémenter la suppression de toutes les sessions
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Effacer tout'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
