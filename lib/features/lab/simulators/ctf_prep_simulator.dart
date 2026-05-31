// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/lab/widgets/lab_widgets.dart';
import 'package:tutodecode/features/lab/widgets/simulator_ai_assistant.dart';

class CtfPrepSimulator extends StatefulWidget {
  const CtfPrepSimulator({super.key});

  @override
  State<CtfPrepSimulator> createState() => _CtfPrepSimulatorState();
}

class _CtfPrepSimulatorState extends State<CtfPrepSimulator>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // États du CTF
  int _score = 0;
  final Map<int, bool> _completedChallenges = {
    1: false,
    2: false,
    3: false,
  };

  // Contrôles des formulaires de soumission de flag
  final Map<int, TextEditingController> _flagControllers = {
    1: TextEditingController(),
    2: TextEditingController(),
    3: TextEditingController(),
  };

  // Réponses attendues (flags)
  static const _flags = {
    1: 'TDC{B4S364_1S_N0T_CR7PT0}',
    2: 'TDC{K3RN3L_3NV_V4RS_FL4G}',
    3: 'TDC{192.168.1.200}',
  };

  // États des défis individuels
  // Défi 2 : Terminal simulé
  final List<String> _terminalHistory = [
    'T2DECODE Linux Sandbox v1.0.2',
    'Tapez "help" pour voir les commandes disponibles.',
    '',
  ];
  final TextEditingController _terminalInputCtrl = TextEditingController();
  final ScrollController _terminalScrollCtrl = ScrollController();
  String _currentDir = '/home/user';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _flagControllers.values) {
      controller.dispose();
    }
    _terminalInputCtrl.dispose();
    _terminalScrollCtrl.dispose();
    super.dispose();
  }

  // Docker Compose et listes d'origine pour l'onglet Guide
  static const _dockerComposeTemplate = r'''version: "3.9"
services:
  target:
    # Exemple: image pré-téléchargée (air-gapped friendly)
    # image: bkimminich/juice-shop:latest
    image: YOUR_LOCAL_IMAGE_TAG
    container_name: t2decode_target
    ports:
      - "127.0.0.1:8080:3000"
    environment:
      - NODE_ENV=production
    restart: unless-stopped

  notes:
    # Un conteneur "notes" purement local pour garder les infos du scénario.
    image: alpine:3.20
    container_name: t2decode_notes
    command: ["sh", "-lc", "printf '%s\n' 'T2DECODE CTF PREP' 'Scénario local — ne pas exposer sur Internet.'; sleep 365d"]
    restart: unless-stopped
''';

  static const _networkChecklist = <String>[
    'Isoler le lab (host-only / VLAN dédié / VMnet) : pas d’accès Internet.',
    'Ne jamais exposer les services vulnérables en WAN (NAT/UPnP désactivés).',
    'Utiliser des snapshots (avant/après) pour rejouer un scénario proprement.',
    'Journaliser localement (Sysmon/Windows Event Logs, journald, Suricata, etc.).',
    'Chiffrer/limiter les exports (USB, ZIP) si environnement sensible.',
  ];

  static const _limitations = <String>[
    'Pas de données temps réel (threat intel, flux live) sans import manuel.',
    'Contenus à préparer et mettre à jour soi‑même (packs, exports, modules).',
    'Moins de “cloud-native” en air‑gapped (mais on peut simuler localement).',
  ];

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copié dans le presse‑papiers.')),
    );
  }

  void _validateFlag(int id) {
    final input = _flagControllers[id]?.text.trim() ?? '';
    if (input == _flags[id]) {
      setState(() {
        if (!_completedChallenges[id]!) {
          _completedChallenges[id] = true;
          _score += 100;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: TdcColors.success,
          content: Row(
            children: [
              Icon(Icons.stars, color: Colors.white),
              SizedBox(width: 8),
              Text('Bravo ! Flag correct. +100 XP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: TdcColors.danger,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Flag incorrect. Essayez encore !', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }
  }

  // Interprétation des commandes dans le terminal simulé
  void _executeTerminalCommand(String rawCmd) {
    final cmd = rawCmd.trim();
    if (cmd.isEmpty) return;

    setState(() {
      _terminalHistory.add('$_currentDir \$ $cmd');
      
      final parts = cmd.split(' ');
      final commandName = parts[0].toLowerCase();
      final args = parts.sublist(1);

      switch (commandName) {
        case 'help':
          _terminalHistory.addAll([
            'Commandes supportées :',
            '  ls [-a]      Lister le contenu du dossier',
            '  cat <file>   Afficher le contenu d\'un fichier',
            '  cd <dir>     Changer de dossier',
            '  pwd          Afficher le chemin absolu actuel',
            '  clear        Vider l\'écran',
            '  help         Afficher cette aide',
          ]);
          break;
        case 'clear':
          _terminalHistory.clear();
          break;
        case 'pwd':
          _terminalHistory.add(_currentDir);
          break;
        case 'ls':
          bool showAll = args.contains('-a');
          if (_currentDir == '/home/user') {
            if (showAll) {
              _terminalHistory.addAll(['.', '..', '.env', 'readme.txt', 'welcome.sh']);
            } else {
              _terminalHistory.addAll(['readme.txt', 'welcome.sh']);
            }
          } else if (_currentDir == '/home/user/secrets') {
            _terminalHistory.addAll(['config.json']);
          } else {
            _terminalHistory.add('Dossier vide.');
          }
          break;
        case 'cd':
          if (args.isEmpty || args[0] == '~') {
            _currentDir = '/home/user';
          } else if (args[0] == '..' || args[0] == '../') {
            if (_currentDir == '/home/user/secrets') {
              _currentDir = '/home/user';
            } else {
              _terminalHistory.add('cd: Permission non accordée pour remonter au-delà de /home/user');
            }
          } else if (args[0] == 'secrets' || args[0] == './secrets') {
            if (_currentDir == '/home/user') {
              _currentDir = '/home/user/secrets';
            } else {
              _terminalHistory.add('cd: secrets: Dossier introuvable');
            }
          } else {
            _terminalHistory.add('cd: ${args[0]}: Dossier introuvable');
          }
          break;
        case 'cat':
          if (args.isEmpty) {
            _terminalHistory.add('usage: cat <filename>');
          } else {
            final file = args[0];
            if (_currentDir == '/home/user') {
              if (file == 'readme.txt') {
                _terminalHistory.addAll([
                  '=== T2DECODE SANDBOX README ===',
                  'Ce terminal simule un environnement Linux basique.',
                  'Quelque chose d\'intéressant se cache dans les fichiers cachés.',
                  'Utilisez "ls -a" pour voir tous les fichiers !',
                ]);
              } else if (file == 'welcome.sh') {
                _terminalHistory.add('echo "Bienvenue dans le Sandbox !"');
              } else if (file == '.env') {
                _terminalHistory.addAll([
                  '# CONFIGURATION DES COMPOSANTS',
                  'DB_HOST=localhost',
                  'DB_PORT=5432',
                  'SECRET_KEY=TDC{K3RN3L_3NV_V4RS_FL4G}',
                  'DEBUG=false',
                ]);
              } else {
                _terminalHistory.add('cat: $file: Fichier introuvable');
              }
            } else if (_currentDir == '/home/user/secrets') {
              if (file == 'config.json') {
                _terminalHistory.add('{"api_url": "http://127.0.0.1:8080", "status": "active"}');
              } else {
                _terminalHistory.add('cat: $file: Fichier introuvable');
              }
            } else {
              _terminalHistory.add('cat: $file: Fichier introuvable');
            }
          }
          break;
        default:
          _terminalHistory.add('bash: $commandName: commande introuvable');
      }
      
      _terminalHistory.add('');
      _terminalInputCtrl.clear();
    });

    // Scroller vers le bas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_terminalScrollCtrl.hasClients) {
        _terminalScrollCtrl.animateTo(
          _terminalScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TdcColors.bg,
      child: Column(
        children: [
          // Header général avec XP et progression
          LabGlassContainer(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag, color: TdcColors.accent, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'DÉFIS CAPTURE THE FLAG (CTF)',
                      style: TextStyle(
                        color: TdcColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: TdcColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: TdcColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars, color: TdcColors.accent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '$_score XP / 300',
                            style: const TextStyle(
                              color: TdcColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const LabNotice(
                  title: 'Entraînement Souverain',
                  message:
                      'Défis 100% hors-ligne exécutés localement. Trouvez les flags au format TDC{...} et soumettez-les pour valider les étapes.',
                  icon: Icons.shield_outlined,
                  color: TdcColors.accent,
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: TdcColors.surfaceAlt.withValues(alpha: 0.3),
            child: TabBar(
              controller: _tabController,
              indicatorColor: TdcColors.accent,
              labelColor: TdcColors.accent,
              unselectedLabelColor: TdcColors.textMuted,
              isScrollable: true,
              tabs: const [
                Tab(text: '🚩 Défis CTF'),
                Tab(text: '📋 Guide Local'),
                Tab(text: '⚙️ Docker template'),
                Tab(text: '🤖 IA'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChallengesTab(),
                _buildGuideTab(),
                _buildDockerTab(),
                const SimulatorAIAssistant(
                  topic: 'Capture The Flag (CTF)',
                  accentColor: TdcColors.accent,
                  systemPrompt:
                      'Tu es Ghost, le tuteur IA spécialisé en cybersécurité et en résolution de défis CTF. '
                      'Ton but est d\'orienter l\'utilisateur pour qu\'il résolve lui-même les défis de cet écran. '
                      'Donne des indices pertinents, explique les notions (comme la base64, les fichiers cachés, '
                      'l\'analyse de logs) mais ne donne JAMAIS directement le flag exact en clair. '
                      'Sois pédagogue et encourageant.',
                  suggestedQuestions: [
                    'Comment décoder du Base64 ?',
                    'Comment voir les fichiers cachés dans un terminal ?',
                    'Quelle est la différence entre encodage et chiffrement ?',
                    'Comment repérer une adresse IP suspecte dans les logs ?',
                    'Un indice pour le défi 2 ?',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildChallengeCard(
          id: 1,
          title: 'Défi 1 : Cryptographie (Le Message Encodé)',
          desc: 'Nous avons intercepté un message suspect envoyé par un serveur. Le protocole de transmission indique qu\'il s\'agit de données encodées en base64.\n'
              'Décoder la chaîne suivante pour révéler le flag :\n'
              'VERDe0I0UzM2NF8xU19OMFRfQ1I3UFQwfQ==',
          hint: 'Astuce : Utilisez le décodeur Base64 dans la section Outils de l\'application ou décodez-le manuellement.',
          points: 100,
        ),
        const SizedBox(height: 16),
        _buildChallengeCard(
          id: 2,
          title: 'Défi 2 : Système (Recherche dans le Sandbox)',
          desc: 'Un administrateur système distrait a laissé une clé secrète dans un fichier de configuration caché du répertoire utilisateur.\n'
              'Explorez le terminal simulé ci-dessous pour trouver ce fichier caché et afficher son contenu.',
          hint: 'Astuce : La commande "ls -a" permet de lister les fichiers cachés (qui commencent par un point).',
          points: 100,
          interactiveWidget: _buildTerminalSandbox(),
        ),
        const SizedBox(height: 16),
        _buildChallengeCard(
          id: 3,
          title: 'Défi 3 : Analyse de logs d\'intrusion',
          desc: 'Un de nos serveurs a subi une attaque par force brute. Analysez les logs ci-dessous pour identifier l\'adresse IP de l\'attaquant qui a réussi à se connecter.\n'
              'Soumettez le flag sous la forme TDC{adresse_ip} (ex: TDC{192.168.1.1}).',
          hint: 'Astuce : Recherchez la ligne de connexion réussie ("Accepted password") et relevez l\'IP correspondante.',
          points: 100,
          interactiveWidget: _buildLogsDump(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChallengeCard({
    required int id,
    required String title,
    required String desc,
    required String hint,
    required int points,
    Widget? interactiveWidget,
  }) {
    final completed = _completedChallenges[id]!;
    return LabGlassContainer(
      padding: const EdgeInsets.all(16),
      borderColor: completed ? TdcColors.success.withValues(alpha: 0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                completed ? Icons.check_circle : Icons.lock_outline,
                color: completed ? TdcColors.success : TdcColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$points pts',
                style: TextStyle(
                  color: completed ? TdcColors.success : TdcColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: const TextStyle(color: TdcColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          if (interactiveWidget != null) ...[
            const SizedBox(height: 12),
            interactiveWidget,
          ],
          const SizedBox(height: 12),
          Text(
            hint,
            style: const TextStyle(color: TdcColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _flagControllers[id],
                  enabled: !completed,
                  style: const TextStyle(color: TdcColors.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    labelText: completed ? 'DÉFI RÉUSSI !' : 'Soumettre le flag (TDC{...})',
                    labelStyle: TextStyle(color: completed ? TdcColors.success : TdcColors.textMuted),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.outlined_flag),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: completed ? null : () => _validateFlag(id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TdcColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
                child: const Text('Valider'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalSandbox() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF030303),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TdcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête du terminal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: TdcColors.surfaceAlt,
              border: Border(bottom: BorderSide(color: TdcColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 14, color: TdcColors.accent),
                const SizedBox(width: 8),
                const Text(
                  'TERMINAL LINUX SIMULÉ',
                  style: TextStyle(color: TdcColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const Spacer(),
                Text(
                  _currentDir,
                  style: const TextStyle(color: TdcColors.textMuted, fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          // Historique
          Expanded(
            child: ListView.builder(
              controller: _terminalScrollCtrl,
              padding: const EdgeInsets.all(10),
              itemCount: _terminalHistory.length,
              itemBuilder: (context, index) {
                final line = _terminalHistory[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    line,
                    style: const TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
          // Entrée terminal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: TdcColors.border)),
              color: Color(0xFF050505),
            ),
            child: Row(
              children: [
                const Text('\$ ', style: TextStyle(color: TdcColors.accent, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                Expanded(
                  child: TextField(
                    controller: _terminalInputCtrl,
                    style: const TextStyle(color: TdcColors.textPrimary, fontFamily: 'monospace', fontSize: 12),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Tapez une commande...',
                      hintStyle: TextStyle(color: TdcColors.textMuted, fontSize: 12),
                    ),
                    onSubmitted: _executeTerminalCommand,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsDump() {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF030303),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TdcColors.border),
      ),
      child: const SingleChildScrollView(
        child: SelectableText(
          'May 27 09:12:01 server-prod sshd[1204]: Invalid user guest from 192.168.1.105 port 45293\n'
          'May 27 09:12:05 server-prod sshd[1204]: Failed password for invalid user guest from 192.168.1.105 port 45293\n'
          'May 27 09:12:12 server-prod sshd[1205]: Invalid user admin from 192.168.1.106 port 45310\n'
          'May 27 09:12:15 server-prod sshd[1205]: Failed password for invalid user admin from 192.168.1.106 port 45310\n'
          'May 27 09:12:30 server-prod sshd[1206]: Failed password for root from 192.168.1.105 port 45322\n'
          'May 27 09:13:02 server-prod sshd[1207]: Connection closed by authenticating user root 192.168.1.105 port 45322\n'
          'May 27 09:14:15 server-prod sshd[1208]: Failed password for root from 192.168.1.106 port 45340\n'
          'May 27 09:15:00 server-prod sshd[1209]: Accepted password for root from 192.168.1.200 port 22 ssh2\n'
          'May 27 09:15:02 server-prod sshd[1209]: pam_unix(sshd:session): session opened for user root by (uid=0)\n'
          'May 27 09:15:10 server-prod sshd[1209]: Received disconnect from 192.168.1.200 port 22:11: user request\n'
          'May 27 09:15:12 server-prod sshd[1209]: pam_unix(sshd:session): session closed for user root',
          style: TextStyle(
            color: Color(0xFFC8A2C8),
            fontFamily: 'monospace',
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildGuideTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LabGlassContainer(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.router_outlined, color: TdcColors.network, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Checklist réseau (recommandé)',
                    style: TextStyle(color: TdcColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                children: _networkChecklist
                    .map((t) => _bulletRow(Icons.check, TdcColors.success, t))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LabGlassContainer(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: TdcColors.textMuted, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Limites & compromis (offline-first)',
                    style: TextStyle(color: TdcColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                children: _limitations
                    .map((t) => _bulletRow(Icons.remove, TdcColors.textMuted, t))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDockerTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LabGlassContainer(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.layers_outlined, color: TdcColors.cloud, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Template docker-compose (air‑gapped friendly)',
                    style: TextStyle(color: TdcColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Utilise une image locale (pré‑téléchargée). '
                'Le port est bindé sur 127.0.0.1 pour éviter toute exposition.',
                style: TextStyle(color: TdcColors.textMuted.withValues(alpha: 0.95), fontSize: 12, height: 1.3),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TdcColors.border),
                ),
                child: const SelectableText(
                  _dockerComposeTemplate,
                  style: TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 11,
                    height: 1.35,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _copy(context, _dockerComposeTemplate),
                  icon: const Icon(Icons.copy, size: 16, color: TdcColors.accent),
                  label: const Text('Copier le template', style: TextStyle(color: TdcColors.accent)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _bulletRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: TdcColors.textMuted,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
