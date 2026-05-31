// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2024-2025 TUTODECODE Association <contact@tutodecode.org>
// Terminal placeholder: real interactive terminal requires native/web integration (eg. webview/webcontainer)
class TerminalService {
  Future<String> runCommand(String cmd) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return 'Output (placeholder) for: $cmd';
  }
}
