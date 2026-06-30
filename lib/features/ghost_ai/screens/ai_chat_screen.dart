// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/features/ghost_ai/providers/ai_tutor_provider.dart';
import 'package:tutodecode/features/ghost_ai/service/ollama_service.dart';
import 'package:tutodecode/features/courses/service/rag_service.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/core/providers/shell_provider.dart';
import 'package:tutodecode/core/providers/settings_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─── Prompt système ──────────────────────────────────────────────────────────
const _kSystem = '''Tu es Ghost, assistant technique de T2DECODE. Regles strictes :
- Reponds en francais, TOUJOURS court et direct (3-5 lignes max pour une question simple)
- PAS d'introduction, PAS de recapitulatif, PAS de "Bien sur !"
- Va droit au but : reponds uniquement a ce qui est demande
- Code uniquement si la question porte sur du code, sinon texte simple
- Si la reponse necessite un exemple, 1 seul exemple concis suffit
- Jamais de listes a puces si une phrase suffit
- Si la demande est ambigue, pose 1-2 questions de clarification AVANT de conclure
- Si tu n'es pas certain, dis-le clairement et propose une verification/une methode
- Fais un effort de comprehension: reformule en 1 phrase ce que l'utilisateur veut faire''';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});
  @override State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with TickerProviderStateMixin {
  final _inputCtrl    = TextEditingController();
  final _scrollCtrl   = ScrollController();
  final _inputFocus   = FocusNode();
  final List<_Msg>    _msgs    = [];

  bool          _streaming = false;
  StreamSubscription? _sub;

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiTutor = context.read<AiTutorProvider>();
      aiTutor.checkOllamaConnection();
      _updateShell(aiTutor);
      _requestInputFocus();
    });
  }

  void _requestInputFocus() {
    if (!mounted) return;
    _inputFocus.requestFocus();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _inputFocus.requestFocus();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_inputFocus.hasFocus) _inputFocus.requestFocus();
    });
  }

  void _updateShell(AiTutorProvider aiTutor) {
    final running = aiTutor.isConnected;
    context.read<ShellProvider>().updateShell(
      title: 'Ghost AI',
      showBackButton: true,
      actions: [
        if (running && aiTutor.availableModels.isNotEmpty)
          _buildModelPicker(context, aiTutor),
        if (_msgs.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: TdcColors.textMuted),
            onPressed: () => _clear(aiTutor),
            tooltip: 'Effacer la conversation',
          ),
      ],
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulseCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _detect() {
    context.read<AiTutorProvider>().checkOllamaConnection();
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

  Future<void> _send(AiTutorProvider aiTutor) async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _streaming) return;

    _inputCtrl.clear();
    _requestInputFocus();

    final hasModels = aiTutor.availableModels.isNotEmpty;
    final modelSelected = aiTutor.availableModels.contains(aiTutor.selectedModel) ? aiTutor.selectedModel : (hasModels ? aiTutor.availableModels.first : null);

    // Si l'IA locale n'est pas connectée ou pas de modèle
    if (!aiTutor.isConnected || modelSelected == null) {
      setState(() {
        _msgs.add(_Msg(role: 'user', text: text));
        _msgs.add(const _Msg(
          role: 'assistant',
          text: 'Bonjour ! Je suis Ghost AI. 🤖\n\n'
              'Il semble que l\'IA locale (Ollama) ne soit pas encore configurée ou active. '
              'Pour une réponse complète et intelligente, allez dans **Paramètres > IA** pour l\'activer, '
              'ou lancez `ollama serve` sur votre Mac.',
        ));
      });
      _scrollBottom();
      _updateShell(aiTutor);
      return;
    }

    setState(() {
      _msgs.add(_Msg(role: 'user', text: text));
      _msgs.add(const _Msg(role: 'assistant', text: ''));
      _streaming = true;
    });
    _scrollBottom();
    _updateShell(aiTutor);

    // ── Mode Normal : appel à Ollama ─────────────────────────────────────
    final history = _msgs
        .where((m) => m.role != 'error' && m.text.isNotEmpty)
        .map((m) => {'role': m.role, 'content': m.text})
        .toList(growable: false);

    try {
      final contextText = await RagService().findRelevantContext(text);
      final finalSystemPrompt = contextText != null 
          ? "$_kSystem\n\nCONTEXTE RELEVANT DES COURS :\n$contextText"
          : _kSystem;

      _sub = OllamaService.stream(modelSelected, history, system: finalSystemPrompt).listen(
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
            _msgs[_msgs.length - 1] = _Msg(
              role: 'error',
              text: "⚠️ **Erreur IA:**\n\n${e.toString()}\n\n"
                  "Vérifiez qu'Ollama est bien installé et en cours d'exécution sur votre Mac.\n"
                  "_Commande : `ollama serve`_",
            );
            _streaming = false;
          });
          aiTutor.checkOllamaConnection();
          _updateShell(aiTutor);
        },
        cancelOnError: true,
      );
    } catch (e) {
      setState(() {
        _msgs[_msgs.length - 1] = _Msg(
          role: 'error',
          text: "⚠️ **Erreur IA:**\n\n${e.toString()}\n\n"
              "Vérifiez qu'Ollama est bien installé et en cours d'exécution sur votre Mac.",
        );
        _streaming = false;
      });
    }
  }

  void _stop() {
    _sub?.cancel();
    setState(() => _streaming = false);
  }

  void _clear(AiTutorProvider aiTutor) {
    setState(() => _msgs.clear());
    _updateShell(aiTutor);
  }

  @override
  Widget build(BuildContext context) {
    final aiTutor = context.watch<AiTutorProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateShell(aiTutor);
    });

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final courseTitle = args?['title'] as String?;

    return Material(
      color: TdcColors.bg,
      child: SelectionArea(
        child: Column(children: [
          if (aiTutor.isCheckingOllama) const LinearProgressIndicator(color: TdcColors.accent, backgroundColor: Colors.transparent, minHeight: 1),
          _buildStatusHeader(aiTutor),
          if (courseTitle != null) _buildContextBadge(context, courseTitle),
          Expanded(child: _msgs.isEmpty ? _buildEmpty(aiTutor) : _buildMessages(context)),
          if (_streaming) _buildStreamingBar(context),
          _buildInput(context, aiTutor),
        ]),
      ),
    );
  }

  Widget _buildStatusHeader(AiTutorProvider aiTutor) {
    final running = aiTutor.isConnected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: TdcColors.surface.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: TdcColors.border.withValues(alpha: 0.3))),
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
        if (!running && !aiTutor.isCheckingOllama) ...[
          const Spacer(),
          TextButton.icon(
            onPressed: _detect,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Réessayer', style: TextStyle(fontSize: 10)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
          ),
        ],
        if (!running && !aiTutor.isCheckingOllama) ...[
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

  Widget _buildModelPicker(BuildContext context, AiTutorProvider aiTutor) {
    final hasModels = aiTutor.availableModels.isNotEmpty;
    final modelSelected = aiTutor.availableModels.contains(aiTutor.selectedModel) ? aiTutor.selectedModel : (hasModels ? aiTutor.availableModels.first : null);

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
            value: modelSelected,
            items: aiTutor.availableModels.map((m) => DropdownMenuItem(
              value: m,
              child: Text(m.split(':').first, style: const TextStyle(color: Colors.white, fontSize: 12)),
            )).toList(),
            onChanged: (v) {
              if (v != null) {
                aiTutor.selectModel(v);
                _updateShell(aiTutor);
              }
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
      color: TdcColors.accent.withValues(alpha: 0.1),
      child: Row(children: [
        const Icon(Icons.auto_stories, size: 14, color: TdcColors.accent),
        const SizedBox(width: 8),
        const Text('FOCUS : ', style: TextStyle(color: TdcColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
        Expanded(child: Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _buildEmpty(AiTutorProvider aiTutor) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.auto_awesome, color: TdcColors.accent, size: 64).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
        const SizedBox(height: 24),
        const Text('Ghost AI', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          aiTutor.isConnected
              ? 'Prêt à vous aider (IA 100% locale).'
              : 'Ollama est optionnel. Sans lui, l’application reste 100% utilisable.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
        ),
        if (!aiTutor.isConnected) ...[
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
              const Row(children: [
                Icon(Icons.info_outline, size: 16, color: TdcColors.info),
                SizedBox(width: 8),
                Text('IA locale (optionnelle)', style: TextStyle(color: TdcColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              Text(
                'Activez Ollama pour débloquer le chat IA. Sinon, ignorez cette section: rien n’est bloquant.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, height: 1.4),
              ),
              if ((aiTutor.errorMessage ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Détail: ${aiTutor.errorMessage}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11, height: 1.3),
                ),
              ],
              const SizedBox(height: 12),
              Row(children: [
                OutlinedButton.icon(
                  onPressed: _detect,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Détecter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TdcColors.textPrimary,
                    side: const BorderSide(color: TdcColors.border),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/ai-config'),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Configurer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TdcColors.textPrimary,
                    side: const BorderSide(color: TdcColors.border),
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
          color: isUser ? TdcColors.accent.withValues(alpha: 0.1) : TdcColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isUser ? TdcColors.accent.withValues(alpha: 0.3) : TdcColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.thinking.isNotEmpty) ...[
              Text('Réflexion...', style: TextStyle(color: TdcColors.accent.withValues(alpha: 0.5), fontSize: 10, fontStyle: FontStyle.italic)),
              const SizedBox(height: 4),
              Text(msg.thinking, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
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

  Widget _buildInput(BuildContext context, AiTutorProvider aiTutor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: TdcColors.surface,
        border: Border(top: BorderSide(color: TdcColors.border)),
      ),
      child: Row(children: [
        Expanded(
          child: MouseRegion(
            cursor: SystemMouseCursors.text,
            child: TextField(
              controller: _inputCtrl,
              focusNode: _inputFocus,
              enabled: true,
              autofocus: true,
              onSubmitted: (_) => _send(aiTutor),
              onTap: _requestInputFocus, // Forcer le focus au clic
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: TdcColors.accent,
              decoration: InputDecoration(
                hintText: 'Posez une question...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: _streaming ? null : () => _send(aiTutor),
          icon: Icon(Icons.send, color: _streaming ? TdcColors.textMuted : TdcColors.accent),
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
