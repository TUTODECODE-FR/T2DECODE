#!/usr/bin/env python3
"""
Zero-Dependency CycloneDX & SPDX Software Bill of Materials (SBOM) Generator for T2DECODE.
Generates standard CycloneDX 1.5 and SPDX 2.3 SBOMs using pure Python standard library.
"""

import json
import hashlib
import os
import sys
import re
from datetime import datetime, timezone

def parse_simple_pubspec(pubspec_path):
    info = {"name": "t2decode", "version": "1.0.3", "description": ""}
    if not os.path.exists(pubspec_path):
        return info
    with open(pubspec_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            line_str = line.strip()
            if line_str.startswith('name:'):
                info['name'] = line_str.split(':', 1)[1].strip().strip('"\'')
            elif line_str.startswith('version:'):
                info['version'] = line_str.split(':', 1)[1].strip().strip('"\'').split('+')[0]
            elif line_str.startswith('description:'):
                info['description'] = line_str.split(':', 1)[1].strip().strip('"\'')
    return info

def parse_pubspec_lock(pubspec_lock_path):
    components = []
    if not os.path.exists(pubspec_lock_path):
        return components

    current_pkg = None
    current_ver = None
    current_source = 'hosted'
    current_dep = 'transitive'

    with open(pubspec_lock_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            indent = len(line) - len(line.lstrip(' '))
            line_str = line.strip()

            # Package entry level (2 spaces indentation)
            if indent == 2 and line_str.endswith(':') and not line_str.startswith('#'):
                if current_pkg and current_ver:
                    components.append({
                        "type": "library",
                        "name": current_pkg,
                        "version": current_ver,
                        "purl": f"pkg:pub/{current_pkg}@{current_ver}",
                        "scope": "required" if "direct" in current_dep else "optional",
                        "description": f"Dart/Flutter library from {current_source}"
                    })
                current_pkg = line_str[:-1]
                current_ver = None
                current_source = 'hosted'
                current_dep = 'transitive'
            elif indent >= 4 and current_pkg:
                if line_str.startswith('version:'):
                    current_ver = line_str.split(':', 1)[1].strip().strip('"\'')
                elif line_str.startswith('source:'):
                    current_source = line_str.split(':', 1)[1].strip().strip('"\'')
                elif line_str.startswith('dependency:'):
                    current_dep = line_str.split(':', 1)[1].strip().strip('"\'')

    if current_pkg and current_ver:
        components.append({
            "type": "library",
            "name": current_pkg,
            "version": current_ver,
            "purl": f"pkg:pub/{current_pkg}@{current_ver}",
            "scope": "required" if "direct" in current_dep else "optional",
            "description": f"Dart/Flutter library from {current_source}"
        })

    return components

def generate_sbom():
    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    pubspec_path = os.path.join(root_dir, 'pubspec.yaml')
    pubspec_lock_path = os.path.join(root_dir, 'pubspec.lock')
    output_cyclonedx = os.path.join(root_dir, 'sbom-cyclonedx.json')
    output_spdx = os.path.join(root_dir, 'sbom-spdx.json')

    pubspec_info = parse_simple_pubspec(pubspec_path)
    components = parse_pubspec_lock(pubspec_lock_path)

    app_name = pubspec_info['name']
    version_str = pubspec_info['version']
    description = pubspec_info['description'] or "Offline-first cybersecurity and systems learning platform"

    now_iso = datetime.now(timezone.utc).isoformat()

    # 1. CycloneDX 1.5 SBOM
    cyclonedx_sbom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "serialNumber": f"urn:uuid:t2decode-{version_str}-{hashlib.md5(now_iso.encode()).hexdigest()}",
        "version": 1,
        "metadata": {
            "timestamp": now_iso,
            "tools": [
                {
                    "vendor": "Association TUTODECODE",
                    "name": "T2DECODE SBOM Engine",
                    "version": "2.0.0"
                }
            ],
            "authors": [
                {
                    "name": "Maxime MARTIN CIVET",
                    "email": "contact@tutodecode.org"
                }
            ],
            "component": {
                "type": "application",
                "name": app_name,
                "version": version_str,
                "description": description,
                "licenses": [
                    {
                        "license": {
                            "id": "GPL-3.0-only"
                        }
                    }
                ],
                "purl": f"pkg:generic/tutodecode/{app_name}@{version_str}"
            }
        },
        "components": components
    }

    with open(output_cyclonedx, 'w', encoding='utf-8') as f:
        json.dump(cyclonedx_sbom, f, indent=2)
    print(f"✅ CycloneDX SBOM generated: {output_cyclonedx} ({len(components)} packages indexed)")

    # 2. SPDX 2.3 SBOM
    spdx_sbom = {
        "spdxVersion": "SPDX-2.3",
        "dataLicense": "CC0-1.0",
        "SPDXID": "SPDXRef-DOCUMENT",
        "name": f"{app_name}-{version_str}-SBOM",
        "documentNamespace": f"https://tutodecode.org/spdx/{app_name}/{version_str}",
        "creationInfo": {
            "created": now_iso,
            "creators": [
                "Organization: Association TUTODECODE",
                "Person: Maxime MARTIN CIVET",
                "Tool: T2DECODE-SPDX-Engine-2.0"
            ]
        },
        "packages": [
            {
                "name": app_name,
                "SPDXID": "SPDXRef-Package-T2DECODE",
                "versionInfo": version_str,
                "downloadLocation": "https://gitlab.com/tutodecode-org/T2DECODE",
                "licenseConcluded": "GPL-3.0-only",
                "licenseDeclared": "GPL-3.0-only",
                "supplier": "Organization: Association TUTODECODE"
            }
        ]
    }
    for comp in components:
        spdx_sbom["packages"].append({
            "name": comp["name"],
            "SPDXID": f"SPDXRef-Package-{comp['name']}",
            "versionInfo": comp["version"],
            "downloadLocation": f"https://pub.dev/packages/{comp['name']}",
            "licenseConcluded": "NOASSERTION",
            "externalRefs": [
                {
                    "referenceCategory": "PACKAGE-MANAGER",
                    "referenceType": "purl",
                    "referenceLocator": comp["purl"]
                }
            ]
        })

    with open(output_spdx, 'w', encoding='utf-8') as f:
        json.dump(spdx_sbom, f, indent=2)
    print(f"✅ SPDX 2.3 SBOM generated: {output_spdx}")

if __name__ == "__main__":
    generate_sbom()
