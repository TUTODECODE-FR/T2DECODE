import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/features/ghost_ai/service/ollama_service.dart';
import 'package:tutodecode/features/courses/service/rag_service.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/theme/premium_ui.dart';
import 'package:tutodecode/core/responsive/responsive.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/widgets/tdc_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─── Prompt système ──────────────────────────────────────────────────────────
const _kSystem = '''Tu es Ghost, assistant technique de T2CODE. Regles strictes :
- Reponds en francais, TOUJOURS court et direct (3-5 lignes max pour une question simple)
- PAS d\'introduction, PAS de recapitulatif, PAS de "Bien sur !"
- Va droit au but : reponds uniquement a ce qui est demande
- Code uniquement si la question porte sur du code, sinon texte simple
- Si la reponse necessite un exemple, 1 seul exemple concis suffit
- Jamais de listes a puces si une phrase suffit
- Si la demande est ambigue, pose 1-2 questions de clarification AVANT de conclure
- Si tu n\'es pas certain, dis-le clairement et propose une verification/une methode
- Fais un effort de comprehension: reformule en 1 phrase ce que l\'utilisateur veut faire''';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});
  @override State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with TickerProviderStateMixin {
  final _inputCtrl    = TextEditingController();
  final _scrollCtrl   = ScrollController();
  final _inputFocus   = FocusNode();
  final List<_Msg>    _msgs    = [];

  OllamaStatus? _status;
  String?       _model;
  bool          _checking = true;
  bool          _streaming = false;
  StreamSubscription? _sub;
  Timer? _pollTimer;
  bool _polling = false;

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _init();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pollStatus());
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateShell();
    });
  }

  void _updateShell() {
    final running = _status?.running ?? false;
    context.read<ShellProvider>().updateShell(
      title: 'Ghost AI',
      showBackButton: true,
      actions: [
        if (running && (_status?.models.isNotEmpty ?? false))
          _buildModelPicker(context),
        if (_msgs.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: TdcColors.textMuted),
            onPressed: _clear,
            tooltip: 'Effacer la conversation',
          ),
      ],
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pollTimer?.cancel();
    _pulseCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final s = await OllamaService.checkStatus();
    if (!mounted) return;
    setState(() {
      _status   = s;
      _checking = false;
      if (s.running && s.models.isNotEmpty) _model = s.models.first;
    });
    _updateShell();
  }

  Future<void> _pollStatus() async {
    if (_polling || !mounted) return;
    _polling = true;
    try {
      final prevRunning = _status?.running;
      final s = await OllamaService.checkStatus(
        includeModels: false,
        versionTimeout: const Duration(seconds: 3),
        tagsTimeout: const Duration(seconds: 5),
      );

      if (!mounted) return;
      final runningChanged = prevRunning != s.running;
      if (runningChanged || (_status == null)) {
        setState(() {
          _status = OllamaStatus(running: s.running, version: s.version, models: _status?.models ?? const [], error: s.error);
          if (!s.running) _model = null;
        });
        _updateShell();
      }

      // Si Ollama vient de revenir, charger la liste de modèles une fois.
      if (runningChanged && s.running) {
        final full = await OllamaService.checkStatus(
          includeModels: true,
          versionTimeout: const Duration(seconds: 8),
          tagsTimeout: const Duration(seconds: 10),
        );
        if (!mounted) return;
        setState(() {
          _status = full;
          if (full.models.isNotEmpty) _model ??= full.models.first;
        });
        _updateShell();
      }
    } finally {
      _polling = false;
    }
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _streaming || _model == null) return;

    _inputCtrl.clear();
    _inputFocus.requestFocus();

    setState(() {
      _msgs.add(_Msg(role: 'user', text: text));
      _msgs.add(_Msg(role: 'assistant', text: ''));
      _streaming = true;
    });
    _scrollBottom();
    _updateShell(); // Update to show clear button if first message

    final history = _msgs
        .where((m) => m.role != 'error' && m.text.isNotEmpty)
        .map((m) => {'role': m.role, 'content': m.text})
        .toList(growable: false);

    try {
      final contextText = await RagService().findRelevantContext(text);
      final finalSystemPrompt = contextText != null 
          ? "$_kSystem\n\nCONTEXTE RELEVANT DES COURS :\n$contextText"
          : _kSystem;

      _sub = OllamaService.stream(_model!, history, system: finalSystemPrompt).listen(
        (chunk) {
          if (!mounted) return;
          setState(() {
            final last = _msgs.last;
            if (chunk.isThinking) {
              _msgs[_msgs.length - 1] = last.withThinking(last.thinking + chunk.text);
            } else {
              _msgs[_msgs.length - 1] = last.withText(last.text + chunk.text);
            }
          });
          _scrollBottom();
        },
        onDone: () {
          if (!mounted) return;
          final last = _msgs.isNotEmpty ? _msgs.last : null;
          if (last != null && last.role == 'assistant' && last.text.isEmpty && last.thinking.isNotEmpty) {
            setState(() {
              _msgs[_msgs.length - 1] = _Msg(role: 'assistant', text: last.thinking, thinking: '');
            });
          }
          setState(() => _streaming = false);
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _msgs[_msgs.length - 1] = _Msg(role: 'error', text: '**Connexion interrompue**\n\nOllama ne répond plus. Lancez-le (ou réessayez plus tard).');
            _status = const OllamaStatus(running: false, error: 'Ollama indisponible');
            _model = null;
            _streaming = false;
          });
          _updateShell();
        },
        cancelOnError: true,
      );
    } catch (e) {
      setState(() {
        _msgs[_msgs.length - 1] = _Msg(role: 'error', text: '**Erreur :** ${e.toString()}');
        _streaming = false;
      });
    }
  }

  void _stop() {
    _sub?.cancel();
    setState(() => _streaming = false);
  }

  void _clear() {
    setState(() => _msgs.clear());
    _updateShell();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final courseTitle = args?['title'] as String?;

    return Container(
      color: TdcColors.bg,
      child: Column(children: [
        if (_checking) const LinearProgressIndicator(color: TdcColors.accent, backgroundColor: Colors.transparent, minHeight: 1),
        _buildStatusHeader(),
        if (courseTitle != null) _buildContextBadge(context, courseTitle),
        Expanded(child: _msgs.isEmpty ? _buildEmpty(context) : _buildMessages(context)),
        if (_streaming) _buildStreamingBar(context),
        _buildInput(context),
      ]),
    );
  }

  Widget _buildStatusHeader() {
    final running = _status?.running ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: TdcColors.surface.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: TdcColors.border.withOpacity(0.3))),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: running ? TdcColors.info : TdcColors.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          running ? 'IA locale disponible' : 'IA locale indisponible (Ollama)',
          style: TextStyle(
            color: running ? TdcColors.info : TdcColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!running && !_checking) ...[
          const Spacer(),
          TextButton.icon(
            onPressed: _init,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Réessayer', style: TextStyle(fontSize: 10)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
          ),
        ],
        if (!running && !_checking) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/ai-config'),
            icon: const Icon(Icons.tune, size: 14),
            label: const Text('Configurer', style: TextStyle(fontSize: 10)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
          ),
        ],
      ]),
    );
  }

  Widget _buildModelPicker(BuildContext context) {
    return Center(
      child: Container(
        height: 32,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: TdcColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: TdcColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _model,
            items: (_status?.models ?? []).map((m) => DropdownMenuItem(
              value: m,
              child: Text(m.split(':').first, style: const TextStyle(color: Colors.white, fontSize: 12)),
            )).toList(),
            onChanged: (v) {
              setState(() => _model = v);
              _updateShell();
            },
            dropdownColor: TdcColors.surface,
            icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildContextBadge(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: TdcColors.accent.withOpacity(0.1),
      child: Row(children: [
        const Icon(Icons.auto_stories, size: 14, color: TdcColors.accent),
        const SizedBox(width: 8),
        const Text('FOCUS : ', style: TextStyle(color: TdcColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
        Expanded(child: Text(title, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.auto_awesome, color: TdcColors.accent, size: 64).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
        const SizedBox(height: 24),
        const Text('Ghost AI', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          _status?.running == true
              ? 'Prêt à vous aider (IA 100% locale).'
              : 'Ollama est optionnel. Sans lui, l’application reste 100% utilisable.',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
        ),
        if (_status?.running != true) ...[
          const SizedBox(height: 20),
          Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TdcColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TdcColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.info_outline, size: 16, color: TdcColors.info),
                SizedBox(width: 8),
                Text('IA locale (optionnelle)', style: TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              Text(
                'Activez Ollama pour débloquer le chat IA. Sinon, ignorez cette section: rien n’est bloquant.',
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12, height: 1.4),
              ),
              if ((_status?.error ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Détail: ${_status?.error}',
                  style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11, height: 1.3),
                ),
              ],
              const SizedBox(height: 12),
              Row(children: [
                OutlinedButton.icon(
                  onPressed: _init,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Détecter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TdcColors.textPrimary,
                    side: BorderSide(color: TdcColors.border),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/ai-config'),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Configurer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TdcColors.textPrimary,
                    side: BorderSide(color: TdcColors.border),
                  ),
                ),
              ]),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildMessages(BuildContext context) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(20),
      itemCount: _msgs.length,
      itemBuilder: (_, i) => _buildMessage(context, _msgs[i]),
    );
  }

  Widget _buildMessage(BuildContext context, _Msg msg) {
    final isUser = msg.role == 'user';
    final isError = msg.role == 'error';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? TdcColors.accent.withOpacity(0.1) : TdcColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isUser ? TdcColors.accent.withOpacity(0.3) : TdcColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.thinking.isNotEmpty) ...[
              Text('Réflexion...', style: TextStyle(color: TdcColors.accent.withOpacity(0.5), fontSize: 10, fontStyle: FontStyle.italic)),
              const SizedBox(height: 4),
              Text(msg.thinking, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
              const Divider(height: 16),
            ],
            Text(msg.text, style: TextStyle(color: isError ? TdcColors.info : Colors.white, fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: TdcColors.surface,
      child: Row(children: [
        const Text('Ghost AI génère...', style: TextStyle(color: TdcColors.textMuted, fontSize: 12)),
        const Spacer(),
        TextButton(onPressed: _stop, child: const Text('Arrêter', style: TextStyle(color: TdcColors.danger, fontSize: 12))),
      ]),
    );
  }

  Widget _buildInput(BuildContext context) {
    final canSend = (_status?.running == true) && (_model != null) && !_streaming;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        border: Border(top: BorderSide(color: TdcColors.border)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _inputCtrl,
            focusNode: _inputFocus,
            enabled: canSend,
            onSubmitted: (_) => _send(),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Posez une question...', border: InputBorder.none),
          ),
        ),
        IconButton(
          onPressed: canSend ? _send : null,
          icon: Icon(Icons.send, color: canSend ? TdcColors.accent : TdcColors.textMuted),
        ),
      ]),
    );
  }
}

class _Msg {
  final String role, text, thinking;
  const _Msg({required this.role, required this.text, this.thinking = ''});
  _Msg withText(String t) => _Msg(role: role, text: t, thinking: thinking);
  _Msg withThinking(String t) => _Msg(role: role, text: text, thinking: t);
}
