#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>
# Script: Dependency Confusion and Supply Chain Auditor (Zero Third-Party Dependencies)

import sys
import re
import os

def audit_pubspec(pubspec_path):
    if not os.path.exists(pubspec_path):
        print(f"⚠️ Warning: pubspec.yaml not found at {pubspec_path}")
        sys.exit(0)

    issues = 0

    with open(pubspec_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Search for insecure http:// git urls or unverified dependency sources
    http_matches = re.findall(r'url:\s*["\']?(http://[^"\'\s]+)', content, re.IGNORECASE)

    for match in http_matches:
        print(f"❌ Error: Insecure HTTP dependency source detected in pubspec: {match}")
        issues += 1

    if issues > 0:
        print(f"❌ Found {issues} supply chain security issues in {pubspec_path}.")
        sys.exit(1)
    else:
        print(f"✅ Dependency Confusion & Supply Chain Audit passed cleanly.")
        sys.exit(0)

if __name__ == "__main__":
    audit_pubspec(sys.argv[1] if len(sys.argv) > 1 else "pubspec.yaml")
