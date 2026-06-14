#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path

ASSETS = [
    'assets/courses.json',
    'assets/cheat_sheets.json',
    'assets/netkit_cheat_sheets.json',
    'assets/manifest.json',
    'assets/logo.png',
]

out = {}
for p in ASSETS:
    b = Path(p).read_bytes()
    h = hashlib.sha256(b).hexdigest()
    out[p] = h

Path('assets/asset_checksums.json').write_text(json.dumps(out, indent=2, ensure_ascii=False) + '\n')
print('Wrote assets/asset_checksums.json')
