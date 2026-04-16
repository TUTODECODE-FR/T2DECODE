// ============================================================
// GhostLinkScreen — Liste des pairs P2P découverts
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';
import '../service/ghost_link_service.dart';

class GhostLinkScreen extends StatefulWidget {
  const GhostLinkScreen({super.key});
  @override
  State<GhostLinkScreen> createState() => _GhostLinkScreenState();
}

class _GhostLinkScreenState extends State<GhostLinkScreen> {
  static const _color = Color(0xFF8B5CF6);
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: 'Ghost Link',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link, color: _color),
            tooltip: 'Ajouter une IP manuellement',
            onPressed: () => _showAddPeerDialog(context),
          ),
          Consumer<GhostLinkService>(
            builder: (context, gl, _) => IconButton(
              icon: Icon(
                  gl.isRunning
                      ? Icons.wifi_tethering
                      : Icons.wifi_tethering_off,
                  color: gl.isRunning ? _color : TdcColors.textMuted),
              tooltip:
                  gl.isRunning ? 'Arrêter Ghost Link' : 'Démarrer Ghost Link',
              onPressed: () => _toggle(gl),
            ),
          ),
        ],
      );
    });
  }

  Future<void> _showAddPeerDialog(BuildContext context) async {
    final ipController = TextEditingController();
    final nameController = TextEditingController();
    final gl = context.read<GhostLinkService>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TdcColors.surface,
        title: const Text('Ajouter un pair',
            style: TextStyle(color: TdcColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                  labelText: 'Adresse IP', hintText: 'ex: 192.168.1.50'),
              style: const TextStyle(color: TdcColors.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'Nom (optionnel)', hintText: 'ex: Mon PC'),
              style: const TextStyle(color: TdcColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (ipController.text.isNotEmpty) {
                gl.addManualPeer(
                    ipController.text.trim(), nameController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Recherche de ${ipController.text}...')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _color),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(GhostLinkService gl) async {
    if (gl.isRunning) {
      await gl.stop();
    } else {
      setState(() => _starting = true);
      final ok = await gl.start();
      if (!ok && mounted) {
        final detail = gl.lastStartError?.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              detail == null || detail.isEmpty
                  ? 'Impossible de démarrer Ghost Link. Vérifiez vos permissions réseau.'
                  : 'Impossible de démarrer Ghost Link. $detail',
            ),
            backgroundColor: TdcColors.warning,
          ),
        );
      }
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GhostLinkService>(
      builder: (context, gl, _) {
        return TdcPageWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(gl),
              const SizedBox(height: 24),
              if (!gl.isRunning) _buildOfflinePanel(gl) else _buildPeerList(gl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(GhostLinkService gl) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [_color.withOpacity(0.15), _color.withOpacity(0.05)]),
        borderRadius: TdcRadius.lg,
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: isMobile
          ? Column(
              children: [
                Row(
                  children: [
                    _buildHeaderIcon(gl),
                    const SizedBox(width: 12),
                    Expanded(child: _buildHeaderInfo(gl)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: _buildHeaderAction(gl)),
              ],
            )
          : Row(
              children: [
                _buildHeaderIcon(gl),
                const SizedBox(width: 16),
                Expanded(child: _buildHeaderInfo(gl)),
                const SizedBox(width: 16),
                _buildHeaderAction(gl),
              ],
            ),
    );
  }

  Widget _buildHeaderIcon(GhostLinkService gl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: _color.withOpacity(0.2), shape: BoxShape.circle),
      child: Icon(
          gl.isRunning ? Icons.wifi_tethering : Icons.wifi_tethering_off,
          color: _color,
          size: 24),
    );
  }

  Widget _buildHeaderInfo(GhostLinkService gl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('Ghost Link',
              style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          _StatusBadge(running: gl.isRunning),
        ]),
        const SizedBox(height: 2),
        Text(
          gl.isRunning ? 'IP: ${gl.localIp}' : 'Messagerie P2P locale',
          style: const TextStyle(color: TdcColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: gl.stealthMode,
              onChanged: (v) => gl.setStealthMode(v),
              activeColor: _color,
            ),
          ),
          Text(gl.stealthMode ? 'Mode Stealth ACTIF' : 'Mode Découverte PUBLIC',
              style: TextStyle(
                  color:
                      gl.stealthMode ? TdcColors.success : TdcColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ]),
      ],
    );
  }

  Widget _buildHeaderAction(GhostLinkService gl) {
    if (gl.isRunning) {
      return OutlinedButton.icon(
        onPressed: () => _toggle(gl),
        icon: const Icon(Icons.stop, size: 14),
        label: const Text('Arrêter'),
        style: OutlinedButton.styleFrom(
          foregroundColor: TdcColors.danger,
          side: const BorderSide(color: TdcColors.danger),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: _starting ? null : () => _toggle(gl),
      icon: _starting
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.play_arrow, size: 14),
      label: Text(_starting ? 'Démarrage...' : 'Démarrer'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _buildOfflinePanel(GhostLinkService gl) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.wifi_off,
              size: 64, color: TdcColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 20),
          const Text('Ghost Link est arrêté',
              style: TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
              'Démarrez Ghost Link pour découvrir\nles appareils sur votre réseau local.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: TdcColors.textSecondary, fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _starting ? null : () => _toggle(gl),
            icon: const Icon(Icons.wifi_tethering),
            label: const Text('Démarrer Ghost Link'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _color,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerList(GhostLinkService gl) {
    if (gl.peers.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated searching indicator
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(seconds: 2),
                builder: (_, v, child) =>
                    Opacity(opacity: 0.4 + 0.6 * v, child: child),
                child:
                    Icon(Icons.radar, size: 64, color: _color.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              const Text('Recherche de pairs...',
                  style: TextStyle(
                      color: TdcColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Les appareils sur votre WiFi apparaîtront ici.',
                  style:
                      TextStyle(color: TdcColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              const Text('Lancez Ghost Link sur un autre appareil.',
                  style: TextStyle(color: TdcColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${gl.peers.length} pair(s) détecté(s)',
              style: const TextStyle(
                  color: TdcColors.textMuted, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: gl.peers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _PeerCard(peer: gl.peers[i], accentColor: _color),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeerCard extends StatelessWidget {
  final GhostPeer peer;
  final Color accentColor;
  const _PeerCard({required this.peer, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return TdcCard(
      onTap: () =>
          Navigator.pushNamed(context, '/ghost-link/chat', arguments: peer),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: accentColor.withOpacity(0.15),
            child: Text(
              peer.name.isNotEmpty ? peer.name[0].toUpperCase() : '?',
              style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(peer.name,
                        style: const TextStyle(
                            color: TdcColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    if (peer.isManual) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('MANUEL',
                            style: TextStyle(
                                color: accentColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                    if (peer.protocolVersion >= 2) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.lock,
                          color: TdcColors.success.withOpacity(0.7), size: 12),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Text(peer.ip,
                        style: const TextStyle(
                            color: TdcColors.textMuted,
                            fontFamily: 'monospace',
                            fontSize: 12)),
                    if (peer.isPinned) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.push_pin,
                          color: accentColor.withOpacity(0.5), size: 10),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                        peer.isPinned
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        size: 16,
                        color:
                            peer.isPinned ? accentColor : TdcColors.textMuted),
                    onPressed: () =>
                        context.read<GhostLinkService>().togglePin(peer.id),
                    visualDensity: VisualDensity.compact,
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: peer.isOnline
                            ? TdcColors.success
                            : TdcColors.danger),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Icon(Icons.chevron_right, color: TdcColors.textMuted, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool running;
  const _StatusBadge({required this.running});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            (running ? TdcColors.success : TdcColors.danger).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: (running ? TdcColors.success : TdcColors.danger)
                .withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: running ? TdcColors.success : TdcColors.danger)),
        const SizedBox(width: 5),
        Text(running ? 'En ligne' : 'Hors ligne',
            style: TextStyle(
                color: running ? TdcColors.success : TdcColors.danger,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
