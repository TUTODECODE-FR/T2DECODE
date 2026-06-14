#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path

j = json.load(open('assets/asset_checksums.json'))
errors = []
for k, v in j.items():
    p = Path(k)
    if not p.exists():
        errors.append((k, 'MISSING', None))
        continue
    h = hashlib.sha256(p.read_bytes()).hexdigest()
    if h != v:
        errors.append((k, v, h))

if not errors:
    print('All checksums match')
    raise SystemExit(0)
else:
    for e in errors:
        if e[1] == 'MISSING':
            print(f'MISSING: {e[0]}')
        else:
            print(f'MISMATCH: {e[0]} expected={e[1]} actual={e[2]}')
    raise SystemExit(2)
