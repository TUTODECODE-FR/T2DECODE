#!/usr/bin/env python3
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHECKSUM_FILE = ROOT / 'assets' / 'asset_checksums.json'

if not CHECKSUM_FILE.exists():
    print(f"Error: {CHECKSUM_FILE} does not exist", file=sys.stderr)
    sys.exit(1)

try:
    with CHECKSUM_FILE.open('r', encoding='utf-8') as f:
        checksums = json.load(f)
except json.JSONDecodeError as e:
    print(f"Error: {CHECKSUM_FILE} contains invalid JSON: {e}", file=sys.stderr)
    sys.exit(1)

if not isinstance(checksums, dict):
    print(f"Error: {CHECKSUM_FILE} content is not a JSON object (dict)", file=sys.stderr)
    sys.exit(1)

errors = []
for rel_path, expected in checksums.items():
    p = ROOT / rel_path
    if not p.exists():
        errors.append((rel_path, 'MISSING', None))
        continue
    actual = hashlib.sha256(p.read_bytes()).hexdigest()
    if actual != expected:
        errors.append((rel_path, expected, actual))

if not errors:
    print('All checksums match')
    sys.exit(0)

for rel_path, expected, actual in errors:
    if expected == 'MISSING':
        print(f'MISSING: {rel_path}')
    else:
        print(f'MISMATCH: {rel_path} expected={expected} actual={actual}')
sys.exit(2)
