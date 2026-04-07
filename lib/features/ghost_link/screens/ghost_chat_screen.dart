// ============================================================
// GhostChatScreen — Interface de chat par pair
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import '../service/ghost_link_service.dart';

class GhostChatScreen extends StatefulWidget {
  final GhostPeer peer;
  const GhostChatScreen({super.key, required this.peer});

  @override State<GhostChatScreen> createState() => _GhostChatScreenState();
}

class _GhostChatScreenState extends State<GhostChatScreen> {
  static const _color = Color(0xFF8B5CF6);
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellProvider>().updateShell(
        title: widget.peer.name,
        showBackButton: true,
        actions: [],
      );
    });

    // Écouter les nouveaux messages pour scroller
    context.read<GhostLinkService>().addListener(_onNewMessage);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    context.read<GhostLinkService>().removeListener(_onNewMessage);
    super.dispose();
  }

  void _onNewMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() { _sending = true; });
    _ctrl.clear();
    final gl = context.read<GhostLinkService>();
    final ok = await gl.sendMessage(widget.peer, text, expiry: _ephemeralDelay);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Envoi échoué. Vérifiez que l\'appareil est accessible.'), backgroundColor: TdcColors.danger),
      );
    }
    if (mounted) setState(() { _sending = false; });
  }

  Duration? _ephemeralDelay;
  
  void _toggleEphemeral() {
    setState(() {
      if (_ephemeralDelay == null) {
        _ephemeralDelay = const Duration(seconds: 30);
      } else if (_ephemeralDelay!.inSeconds == 30) {
        _ephemeralDelay = const Duration(minutes: 5);
      } else {
        _ephemeralDelay = null;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_ephemeralDelay == null ? 'Messages normaux' : 'Auto-destruction après ${_ephemeralDelay!.inSeconds}s'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _sendFile() async {
    final gl = context.read<GhostLinkService>();
    await gl.sendFile(widget.peer);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GhostLinkService>(
      builder: (context, gl, _) {
        final messages = gl.getConversation(widget.peer.ip);
        return Column(
          children: [
            // Peer info bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: TdcColors.surface,
                border: Border(bottom: BorderSide(color: TdcColors.border)),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _color.withOpacity(0.15),
                  child: Text(widget.peer.name[0].toUpperCase(), style: TextStyle(color: _color, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.peer.name, style: const TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(widget.peer.ip, style: const TextStyle(color: TdcColors.textMuted, fontFamily: 'monospace', fontSize: 11)),
                ])),
                Row(children: [
                  if (widget.peer.protocolVersion >= 2) ...[
                    Icon(Icons.lock, color: TdcColors.success.withOpacity(0.7), size: 12),
                    const SizedBox(width: 4),
                    Text('Sécurisé (AES)', style: TextStyle(color: TdcColors.success.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                  ],
                  const SizedBox(width: 6),
                  Text(widget.peer.isOnline ? 'En ligne' : 'Hors ligne', style: TextStyle(color: widget.peer.isOnline ? TdcColors.success : TdcColors.danger, fontSize: 11)),
                ]),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.analytics_outlined, size: 20, color: TdcColors.textMuted),
                  tooltip: 'Diagnostic distant',
                  onPressed: () => gl.requestRemoteInfo(widget.peer),
                ),
              ]),
            ),

            // Messages
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.forum_outlined, size: 48, color: TdcColors.textMuted.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text('Aucun message encore.', style: TextStyle(color: TdcColors.textMuted, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Dites bonjour à ${widget.peer.name} !', style: const TextStyle(color: TdcColors.textSecondary, fontSize: 13)),
                      ]),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, i) => _MessageBubble(message: messages[i], accentColor: _color),
                    ),
            ),

            // Input bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TdcColors.surface,
                border: Border(top: BorderSide(color: TdcColors.border)),
              ),
              child: Row(children: [
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(skipTraversal: true),
                    onKeyEvent: (key) {
                      if (key is KeyDownEvent &&
                          key.logicalKey == LogicalKeyboardKey.enter &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        _send();
                      }
                    },
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: TdcColors.textPrimary),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Message à ${widget.peer.name}...',
                        hintStyle: const TextStyle(color: TdcColors.textMuted),
                        filled: true,
                        fillColor: TdcColors.bg,
                        border: OutlineInputBorder(borderRadius: TdcRadius.md, borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: TdcRadius.md, borderSide: BorderSide(color: TdcColors.border)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                   icon: const Icon(Icons.attach_file, color: TdcColors.textMuted),
                   onPressed: () => _sendFile(),
                ),
                const SizedBox(width: 4),
                IconButton(
                   icon: const Icon(Icons.timer_outlined, color: TdcColors.textMuted),
                   onPressed: () => _toggleEphemeral(),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: _color, padding: const EdgeInsets.all(12)),
                  ),
                ),
              ]),
            ),
          ],
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final GhostMessage message;
  final Color accentColor;
  const _MessageBubble({required this.message, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isOwn = message.isOwn;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwn) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: accentColor.withOpacity(0.15),
              child: Text(message.fromName.isNotEmpty ? message.fromName[0].toUpperCase() : '?',
                  style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isOwn ? accentColor : TdcColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isOwn ? 16 : 4),
                  bottomRight: Radius.circular(isOwn ? 4 : 16),
                ),
                border: isOwn ? null : Border.all(color: TdcColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isOwn)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(message.fromName, style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  Text(message.text, style: TextStyle(color: isOwn ? Colors.white : TdcColors.textPrimary, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(color: isOwn ? Colors.white.withOpacity(0.6) : TdcColors.textMuted, fontSize: 10),
                  ),
                  if (message.expiry != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 10, color: isOwn ? Colors.white.withOpacity(0.8) : TdcColors.accent),
                        const SizedBox(width: 4),
                        Text('Auto-destruction', style: TextStyle(color: isOwn ? Colors.white.withOpacity(0.8) : TdcColors.accent, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isOwn) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
