#!/usr/bin/env python3
"""Read the X11 window list once; fixed glyph map, no icon filesystem access."""
import json
import subprocess

try:
    result = subprocess.run(['wmctrl', '-lx'], check=True, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=2)
except (OSError, subprocess.SubprocessError):
    print('[]')
    raise SystemExit(0)

# Fixed WM_CLASS mapping. Names below were checked against the current GTK
# theme once; Eww/GTK resolves and caches them natively. No filesystem scans.
icons = [
    (('firefox',), 'firefox', '󰈹'),
    (('kitty',), 'kitty', '󰆍'),
    (('terminal', 'xterm', 'alacritty'), 'utilities-terminal', '󰆍'),
    (('discord',), '', '󰙯'),
    (('steam',), 'steam', '󰓓'),
    (('dolphin',), 'org.kde.dolphin', '󰉋'),
    (('thunar', 'nautilus', 'pcmanfm'), 'system-file-manager', '󰉋'),
    (('code', 'code-oss', 'vscode'), '', '󰨞'),
    (('spotify',), '', '󰓇'),
]
windows = []
for line in result.stdout.splitlines():
    fields = line.split(None, 4)
    if len(fields) < 4:
        continue
    app = set(fields[2].lower().split('.'))
    icon_name, icon = next(((name, glyph) for names, name, glyph in icons if app.intersection(names)), ('application-x-executable', '󰣆'))
    windows.append({'id': fields[0], 'title': fields[4] if len(fields) > 4 else '', 'icon': icon, 'icon_name': icon_name})
print(json.dumps(windows, ensure_ascii=False))
