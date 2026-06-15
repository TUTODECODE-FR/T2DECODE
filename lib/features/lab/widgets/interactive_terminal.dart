// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutodecode/core/theme/app_theme.dart';
import 'package:tutodecode/features/lab/services/virtual_shell.dart';

class InteractiveTerminal extends StatefulWidget {
  final String hostname;
  final String username;
  final String initialPath;

  const InteractiveTerminal({
    super.key,
    this.hostname = 't2decode',
    this.username = 'admin',
    this.initialPath = '~',
  });

  @override
  State<InteractiveTerminal> createState() => _InteractiveTerminalState();
}

class _InteractiveTerminalState extends State<InteractiveTerminal> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _keyListenerNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final List<_TermLine> _lines = [];
  late final VirtualShell _shell;
  final List<String> _cmdHistory = [];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    _shell = VirtualShell();
    _lines.add(_TermLine('T2DECODE Virtual Shell v2.0.0 — Linux Simulation Engine', _TermLineType.system));
    _lines.add(_TermLine('Type "help" for available commands. Filesystem, pipes and redirection supported.', _TermLineType.system));
    _lines.add(_TermLine('', _TermLineType.system));
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleCommand(String input) {
    final trimmed = input.trim();

    setState(() {
      _lines.add(_TermLine('${_shell.prompt}$trimmed', _TermLineType.prompt));

      if (trimmed.isNotEmpty) {
        _cmdHistory.add(trimmed);
        _historyIndex = _cmdHistory.length;
        final output = _shell.execute(trimmed);
        for (final line in output) {
          if (line == '__CLEAR__') {
            _lines.clear();
          } else {
            _lines.add(_TermLine(line, _TermLineType.output));
          }
        }
      }
    });

    _inputController.clear();
    Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
    _focusNode.requestFocus();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_cmdHistory.isNotEmpty && _historyIndex > 0) {
        _historyIndex--;
        _inputController.text = _cmdHistory[_historyIndex];
        _inputController.selection = TextSelection.fromPosition(TextPosition(offset: _inputController.text.length));
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_historyIndex < _cmdHistory.length - 1) {
        _historyIndex++;
        _inputController.text = _cmdHistory[_historyIndex];
      } else {
        _historyIndex = _cmdHistory.length;
        _inputController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: TdcRadius.md,
        border: Border.all(color: TdcColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                _dot(Colors.redAccent),
                const SizedBox(width: 8),
                _dot(Colors.orangeAccent),
                const SizedBox(width: 8),
                _dot(Colors.greenAccent),
                const Spacer(),
                Text(
                  '${_shell.user}@${_shell.hostname}: ${_shell.cwd}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
                ),
                const Spacer(),
              ],
            ),
          ),

          Expanded(
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _lines.length + 1,
                  itemBuilder: (context, index) {
                    if (index < _lines.length) {
                      final line = _lines[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          line.text,
                          style: TextStyle(
                            color: line.color,
                            fontSize: 13,
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                        ),
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _shell.prompt,
                          style: const TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 13,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: _handleKeyEvent,
                            child: TextField(
                              controller: _inputController,
                              focusNode: _focusNode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              cursorColor: Colors.white,
                              cursorWidth: 8,
                              onSubmitted: _handleCommand,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

enum _TermLineType { prompt, output, system, error }

class _TermLine {
  final String text;
  final _TermLineType type;

  _TermLine(this.text, this.type);

  Color get color {
    switch (type) {
      case _TermLineType.prompt: return const Color(0xFF4ADE80);
      case _TermLineType.output: return const Color(0xFFE0E0E0);
      case _TermLineType.system: return const Color(0xFF60A5FA);
      case _TermLineType.error: return const Color(0xFFF87171);
    }
  }
}
