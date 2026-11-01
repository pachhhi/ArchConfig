#!/usr/bin/env python3
"""Restore a reviewed rice bundle with per-file backups and hash checks."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sys
from datetime import datetime


def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def remap_home_refs(value, home):
    """Map an archived /home/<user> prefix to the selected destination home."""
    return re.sub(
        r"(?<![A-Za-z0-9._-])/home/[^/\s]+",
        lambda _: str(home),
        value,
    )


def restore(rice_config, home):
    rice_config = rice_config.resolve()
    home = home.resolve()
    entries = json.loads((rice_config / 'manifest.json').read_text())
    backup = home / '.local/state/archconfig-backups' / datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    # Verify every stored regular file before changing any destination.
    for entry in entries:
        relative = Path(entry['path'])
        if relative.is_absolute() or '..' in relative.parts:
            raise ValueError('Unsafe manifest path')
        if entry['type'] == 'file' and sha(rice_config / relative) != entry['sha256']:
            raise ValueError('Rice configuration hash mismatch: ' + str(relative))
    changed = unchanged = 0
    skipped = []
    for entry in entries:
        relative = Path(entry['path'])
        if relative.parts[0] == 'home':
            target_relative = Path(*relative.parts[1:])
        elif relative.parts[:4] == ('system', 'usr', 'share', 'themes'):
            target_relative = Path('.local/share/themes', *relative.parts[4:])
        elif relative.parts[:4] == ('system', 'usr', 'share', 'fonts'):
            target_relative = Path('.local/share/fonts/archconfig-system', *relative.parts[4:])
        else:
            skipped.append(str(relative) + ': unsupported destination')
            continue
        target = home / target_relative
        # Do not follow an existing directory symlink out of the user's home.
        if not target.parent.resolve().is_relative_to(home):
            skipped.append(str(target_relative) + ': parent points outside home')
            continue
        source = rice_config / relative
        link = None
        data = None
        if entry['type'] == 'symlink':
            link = remap_home_refs(entry['target'], home)
            resolved = Path(link) if os.path.isabs(link) else target.parent / link
            # External app binaries are dependencies, not included in the rice.
            if os.path.isabs(link) and not resolved.exists():
                skipped.append(str(target_relative) + ': missing external link target ' + link)
                continue
            same = target.is_symlink() and os.readlink(target) == link
        else:
            data = source.read_bytes()
            if b'\x00' not in data:
                try:
                    text = remap_home_refs(data.decode('utf-8'), home)
                    data = text.encode('utf-8')
                except UnicodeDecodeError:
                    pass
            same = target.is_file() and not target.is_symlink() and target.read_bytes() == data
        if same:
            unchanged += 1
            continue
        if target.exists() or target.is_symlink():
            if target.is_dir() and not target.is_symlink():
                skipped.append(str(target_relative) + ': directory conflicts with file')
                continue
            saved = backup / target_relative
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, saved, follow_symlinks=False)
            target.unlink()
        target.parent.mkdir(parents=True, exist_ok=True)
        if link is not None:
            target.symlink_to(link)
        else:
            target.write_bytes(data)
            shutil.copymode(source, target)
        changed += 1
    backup.mkdir(parents=True, exist_ok=True)
    (backup / 'RESTORE-REPORT.txt').write_text(
        f'Rice configuration: {rice_config}\nChanged: {changed}\nUnchanged: {unchanged}\n'
        + '\n'.join(skipped) + '\n')
    print(f'Restored: {changed}; unchanged: {unchanged}; skipped: {len(skipped)}')
    print(f'Previous files and report: {backup}')
    for item in skipped:
        if 'external link' in item:
            print('Dependency not included:', item)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit('Usage: restore-rice.py RICE_CONFIG TARGET_HOME')
    restore(Path(sys.argv[1]), Path(sys.argv[2]))
