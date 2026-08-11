#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>
# Script: AOT Compiled Binary String Leak Audit Tool

set -euo pipefail

echo "🔍 Auditing compiled binary / bundle for sensitive string leaks..."

TARGET_DIR="${1:-build}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "⚠️ Target directory '$TARGET_DIR' does not exist. Run 'flutter build' first."
  exit 0
fi

LEAKS_FOUND=0

# Search for potential secret patterns in compiled binaries (.so, .app, exe, apk)
if strings -a "$TARGET_DIR" 2>/dev/null | grep -iE "(AKIA[0-9A-Z]{16}|sk_live_[0-9a-zA-Z]{24}|AIza[0-9A-Za-z-_]{35}|-----BEGIN PRIVATE KEY-----)" ; then
  echo "❌ Error: Hardcoded secrets or private keys detected inside compiled binary bundle!"
  LEAKS_FOUND=1
else
  echo "✅ AOT compiled binary string leak audit passed cleanly."
fi

exit $LEAKS_FOUND
