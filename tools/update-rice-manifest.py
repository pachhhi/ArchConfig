#!/usr/bin/env python3
"""Regenerate the integrity manifest for the public rice configuration bundle."""

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1] / 'rice-config'
manifest = ROOT / 'manifest.json'
entries = []

for path in sorted(ROOT.rglob('*')):
    if not path.is_file() or path == manifest:
        continue
    relative = path.relative_to(ROOT).as_posix()
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    entries.append({'path': relative, 'type': 'file', 'sha256': digest})

manifest.write_text(json.dumps(entries, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'Wrote {len(entries)} entries to {manifest.relative_to(ROOT.parent)}')
