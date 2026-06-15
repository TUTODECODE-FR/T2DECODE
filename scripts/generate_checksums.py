#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = [
    ROOT / 'assets' / 'courses.json',
    ROOT / 'assets' / 'cheat_sheets.json',
    ROOT / 'assets' / 'netkit_cheat_sheets.json',
    ROOT / 'assets' / 'manifest.json',
    ROOT / 'assets' / 'logo.png',
]

out = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in ASSETS}

(ROOT / 'assets' / 'asset_checksums.json').write_text(
    json.dumps(out, indent=2, ensure_ascii=False) + '\n',
    encoding='utf-8',
)
print('Wrote assets/asset_checksums.json')
