// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
import 'package:flutter/material.dart';
import 'package:tutodecode/core/theme/app_theme.dart';

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
  final ScrollController _scrollController = ScrollController();
  
  final List<String> _history = [];
  String _currentPath = '';

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
    _history.add('T2DECODE Simulation Terminal v1.0.0');
    _history.add('Type "help" to see available commands.');
    _history.add('');
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
    if (input.trim().isEmpty) {
      setState(() {
        _history.add('${widget.username}@${widget.hostname}:$_currentPath\$ ');
      });
      _scrollToBottom();
      return;
    }

    final cmd = input.trim();
    setState(() {
      _history.add('${widget.username}@${widget.hostname}:$_currentPath\$ $cmd');
      
      final parts = cmd.split(' ');
      final base = parts[0].toLowerCase();
      
      switch (base) {
        case 'clear':
          _history.clear();
          break;
        case 'help':
          _history.addAll([
            'Available commands:',
            '  ls       - List directory contents',
            '  pwd      - Print working directory',
            '  whoami   - Print current user id',
            '  echo     - Print text',
            '  ping     - Send ICMP ECHO_REQUEST',
            '  clear    - Clear terminal',
            '  sudo     - Execute a command as superuser',
          ]);
          break;
        case 'pwd':
          _history.add(_currentPath == '~' ? '/home/${widget.username}' : _currentPath);
          break;
        case 'whoami':
          _history.add(widget.username);
          break;
        case 'ls':
          _history.add('Desktop  Documents  Downloads  Music  Pictures  Public  Templates  Videos');
          break;
        case 'echo':
          _history.add(parts.skip(1).join(' '));
          break;
        case 'ping':
          if (parts.length > 1) {
            final target = parts[1];
            _history.addAll([
              'PING $target (192.168.1.42) 56(84) bytes of data.',
              '64 bytes from $target (192.168.1.42): icmp_seq=1 ttl=64 time=0.034 ms',
              '64 bytes from $target (192.168.1.42): icmp_seq=2 ttl=64 time=0.041 ms',
              '64 bytes from $target (192.168.1.42): icmp_seq=3 ttl=64 time=0.039 ms',
            ]);
          } else {
            _history.add('ping: usage error: Destination address required');
          }
          break;
        case 'sudo':
          _history.add('[sudo] password for ${widget.username}:');
          _history.add('Sorry, try again.');
          break;
        default:
          _history.add('bash: $base: command not found');
      }
    });
    
    _inputController.clear();
    Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Vrai noir de terminal
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
          // Header (Barre de titre macOS/Linux style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                _buildWindowControl(Colors.redAccent),
                const SizedBox(width: 8),
                _buildWindowControl(Colors.orangeAccent),
                const SizedBox(width: 8),
                _buildWindowControl(Colors.greenAccent),
                const Spacer(),
                const Text(
                  'bash — 80x24',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
                ),
                const Spacer(),
              ],
            ),
          ),
          
          // Corps du terminal
          Expanded(
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _history.length + 1,
                  itemBuilder: (context, index) {
                    if (index < _history.length) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _history[index],
                          style: const TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    }
                    // Input line
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.username}@${widget.hostname}:$_currentPath\$ ',
                          style: const TextStyle(
                            color: Color(0xFF4ADE80), // Vert fluo classique
                            fontSize: 14,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            focusNode: _focusNode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
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

  Widget _buildWindowControl(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
