// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

enum TermColor { white, green, yellow, red, blue, cyan, gray, bold }

class TermLine {
  final String text;
  final TermColor color;
  const TermLine(this.text, [this.color = TermColor.white]);
}

class TerminalEmulator extends StatefulWidget {
  final String title;
  final Color accentColor;
  final double height;

  const TerminalEmulator({
    super.key,
    this.title = 'Terminal',
    this.accentColor = TdcColors.success,
    this.height = 320,
  });

  @override
  State<TerminalEmulator> createState() => TerminalEmulatorState();
}

class TerminalEmulatorState extends State<TerminalEmulator> {
  final List<TermLine> _lines = [];
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _playTimer;
  bool _playing = false;

  @override
  void dispose() {
    _playTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void clear() {
    setState(() => _lines.clear());
  }

  void addLine(TermLine line) {
    setState(() => _lines.add(line));
    _scrollToBottom();
  }

  void addLines(List<TermLine> lines) {
    setState(() => _lines.addAll(lines));
    _scrollToBottom();
  }

  Future<void> playLines(List<TermLine> lines, {int delayMs = 80}) async {
    if (_playing) return;
    _playing = true;
    for (final line in lines) {
      if (!mounted || !_playing) break;
      setState(() => _lines.add(line));
      _scrollToBottom();
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    _playing = false;
  }

  Future<void> typeLines(List<TermLine> lines, {int charDelayMs = 15, int lineDelayMs = 40}) async {
    if (_playing) return;
    _playing = true;
    for (final line in lines) {
      if (!mounted || !_playing) break;
      final idx = _lines.length;
      setState(() => _lines.add(TermLine('', line.color)));
      for (int i = 0; i <= line.text.length; i++) {
        if (!mounted || !_playing) break;
        setState(() => _lines[idx] = TermLine(line.text.substring(0, i), line.color));
        await Future.delayed(Duration(milliseconds: charDelayMs));
      }
      _scrollToBottom();
      await Future.delayed(Duration(milliseconds: lineDelayMs));
    }
    _playing = false;
  }

  void stop() {
    _playing = false;
    _playTimer?.cancel();
  }

  bool get isPlaying => _playing;

  String get plainText => _lines.map((l) => l.text).join('\n');

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 30), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent + 40);
      }
    });
  }

  Color _colorFor(TermColor c) {
    switch (c) {
      case TermColor.white: return const Color(0xFFE0E0E0);
      case TermColor.green: return const Color(0xFF4ADE80);
      case TermColor.yellow: return const Color(0xFFFBBF24);
      case TermColor.red: return const Color(0xFFF87171);
      case TermColor.blue: return const Color(0xFF60A5FA);
      case TermColor.cyan: return const Color(0xFF22D3EE);
      case TermColor.gray: return const Color(0xFF6B7280);
      case TermColor.bold: return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0C),
        borderRadius: TdcRadius.md,
        border: Border.all(color: widget.accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Row(
              children: [
                _dot(const Color(0xFFFF5F56)),
                const SizedBox(width: 6),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 6),
                _dot(const Color(0xFF27C93F)),
                const Spacer(),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.accentColor.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 42),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(10),
              itemCount: _lines.length,
              itemBuilder: (_, i) {
                final line = _lines[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    line.text,
                    style: TextStyle(
                      color: _colorFor(line.color),
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.35,
                      fontWeight: line.color == TermColor.bold ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
