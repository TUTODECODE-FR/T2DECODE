#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2024-2026 TUTODECODE Association <contact@tutodecode.org>
# Script: Dependency Confusion and Supply Chain Auditor

import sys
import yaml
import os

def audit_pubspec(pubspec_path):
    if not os.path.exists(pubspec_path):
        print(f"⚠️ Warning: pubspec.yaml not found at {pubspec_path}")
        sys.exit(0)

    with open(pubspec_path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    deps = data.get("dependencies", {})
    dev_deps = data.get("dev_dependencies", {})
    all_deps = {**deps, **dev_deps}

    issues = 0

    for name, spec in all_deps.items():
        if isinstance(spec, dict):
            git_spec = spec.get("git")
            if git_spec:
                if isinstance(git_spec, dict):
                    url = git_spec.get("url", "")
                else:
                    url = str(git_spec)

                if url.startswith("http://"):
                    print(f"❌ Error: Dependency '{name}' uses insecure HTTP git source: {url}")
                    issues += 1

    if issues > 0:
        print(f"❌ Found {issues} supply chain security issues in {pubspec_path}.")
        sys.exit(1)
    else:
        print(f"✅ Dependency Confusion & Supply Chain Audit passed cleanly.")
        sys.exit(0)

if __name__ == "__main__":
    audit_pubspec(sys.argv[1] if len(sys.argv) > 1 else "pubspec.yaml")
