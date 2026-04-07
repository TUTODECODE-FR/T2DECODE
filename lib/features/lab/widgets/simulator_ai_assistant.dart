// ============================================================
// SimulatorAIAssistant — onglet IA réutilisable pour tous les simulateurs
// Utilise OllamaService (offline, local LLM)
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutodecode/core/providers/settings_provider.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/ghost_ai/service/ollama_service.dart';

class _AiMessage {
  final String text;
  final bool isUser;
  final bool isStreaming;
  const _AiMessage({required this.text, required this.isUser, this.isStreaming = false});
  _AiMessage copyWith({String? text, bool? isStreaming}) =>
      _AiMessage(text: text ?? this.text, isUser: isUser, isStreaming: isStreaming ?? this.isStreaming);
}

/// Widget IA intégrable dans n'importe quel simulateur du Lab.
///
/// [topic]             : domaine du simulateur (ex: "réseau", "Linux")
/// [systemPrompt]      : contexte métier envoyé au modèle
/// [suggestedQuestions]: questions pré-mâchées affichées en chips
/// [accentColor]       : couleur du simulateur parent
class SimulatorAIAssistant extends StatefulWidget {
  final String topic;
  final String systemPrompt;
  final List<String> suggestedQuestions;
  final Color accentColor;

  const SimulatorAIAssistant({
    super.key,
    required this.topic,
    required this.systemPrompt,
    required this.suggestedQuestions,
    required this.accentColor,
  });

  @override
  State<SimulatorAIAssistant> createState() => _SimulatorAIAssistantState();
}

class _SimulatorAIAssistantState extends State<SimulatorAIAssistant> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_AiMessage> _messages = [];
  bool _loading = false;
  StreamSubscription<OllamaChunk>? _streamSub;

  @override
  void dispose() {
    _streamSub?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    _inputController.clear();

    setState(() {
      _messages.add(_AiMessage(text: text, isUser: true));
      _messages.add(_AiMessage(text: '', isUser: false, isStreaming: true));
      _loading = true;
    });
    _scrollToBottom();

    final model = context.read<SettingsProvider>().ollamaModel;
    final history = _messages
        .where((m) => !m.isStreaming)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
        .toList();

    // Ajoute la question courante (non encore dans history)
    final msgs = [...history, {'role': 'user', 'content': text}];

    StringBuffer buffer = StringBuffer();
    try {
      _streamSub = OllamaService.stream(
        model,
        msgs.cast<Map<String, String>>(),
        system: widget.systemPrompt,
      ).listen(
        (chunk) {
          if (!chunk.isThinking) {
            buffer.write(chunk.text);
            setState(() {
              _messages[_messages.length - 1] =
                  _messages.last.copyWith(text: buffer.toString(), isStreaming: true);
            });
            _scrollToBottom();
          }
        },
        onDone: () {
          setState(() {
            _messages[_messages.length - 1] =
                _messages.last.copyWith(text: buffer.toString(), isStreaming: false);
            _loading = false;
          });
        },
        onError: (e) {
          setState(() {
            _messages[_messages.length - 1] =
                _messages.last.copyWith(text: '⚠️ Erreur : $e', isStreaming: false);
            _loading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _messages[_messages.length - 1] =
            _messages.last.copyWith(text: '⚠️ Ollama indisponible : $e', isStreaming: false);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.accentColor.withOpacity(0.08),
            border: Border(bottom: BorderSide(color: widget.accentColor.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: widget.accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Assistant IA — ${widget.topic}',
                style: TextStyle(
                  color: widget.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Ollama local',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 10),
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: _messages.isEmpty ? _buildEmpty() : _buildMessages(),
        ),

        // Suggestions
        if (_messages.isEmpty) _buildSuggestions(),

        // Input
        _buildInput(),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy_outlined, color: widget.accentColor.withOpacity(0.4), size: 56),
          const SizedBox(height: 12),
          Text(
            'Pose ta question sur\n${widget.topic}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final msg = _messages[i];
        return Align(
          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: msg.isUser
                  ? widget.accentColor.withOpacity(0.2)
                  : TdcColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: msg.isUser
                    ? widget.accentColor.withOpacity(0.4)
                    : Colors.white.withOpacity(0.06),
              ),
            ),
            child: msg.isStreaming && msg.text.isEmpty
                ? SizedBox(
                    width: 40,
                    child: LinearProgressIndicator(
                      color: widget.accentColor,
                      backgroundColor: Colors.white10,
                    ),
                  )
                : SelectableText(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser ? Colors.white : Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: widget.suggestedQuestions.map((q) {
          return GestureDetector(
            onTap: () => _send(q),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.accentColor.withOpacity(0.3)),
              ),
              child: Text(
                q,
                style: TextStyle(color: widget.accentColor, fontSize: 11),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TdcColors.surface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !_loading,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Pose ta question…',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _send,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _loading ? null : () => _send(_inputController.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _loading
                    ? Colors.white10
                    : widget.accentColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _loading ? Icons.hourglass_top : Icons.send,
                color: _loading ? Colors.white24 : Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
