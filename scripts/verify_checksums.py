#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHECKSUM_FILE = ROOT / 'assets' / 'asset_checksums.json'

with CHECKSUM_FILE.open('r', encoding='utf-8') as f:
    checksums = json.load(f)

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
    raise SystemExit(0)

for rel_path, expected, actual in errors:
    if expected == 'MISSING':
        print(f'MISSING: {rel_path}')
    else:
        print(f'MISMATCH: {rel_path} expected={expected} actual={actual}')
raise SystemExit(2)
