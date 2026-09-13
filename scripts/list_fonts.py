#!/usr/bin/env python3
import subprocess
import json

installed = set()
try:
    out = subprocess.check_output(['fc-list', ':', 'family'], text=True)
    for line in out.splitlines():
        for f in line.split(','):
            installed.add(f.strip())
except Exception:
    pass

CANDIDATES = [
    { 'id': 'JetBrainsMono Nerd Font Propo', 'name': 'JetBrains Mono', 'desc': 'Proportional • Default' },
    { 'id': 'JetBrainsMono Nerd Font', 'name': 'JetBrains Mono (Mono)', 'desc': 'Fixed width monospace' },
    { 'id': 'CaskaydiaCove Nerd Font', 'name': 'Caskaydia Cove', 'desc': 'Modern & geometric' },
    { 'id': 'Hack Nerd Font', 'name': 'Hack', 'desc': 'Crisp developer font' },
    { 'id': 'Iosevka Nerd Font', 'name': 'Iosevka', 'desc': 'Narrow & compact' },
    { 'id': 'Agave Nerd Font Propo', 'name': 'Agave', 'desc': 'Minimal retro geometric' },
    { 'id': 'Roboto', 'name': 'Roboto', 'desc': 'Clean sans-serif UI' },
    { 'id': 'Cantarell', 'name': 'Cantarell', 'desc': 'Humanistic GNOME sans' },
    { 'id': 'Adwaita Sans', 'name': 'Adwaita Sans', 'desc': 'Modern Fedora interface' }
]

available = [c for c in CANDIDATES if c['id'] in installed]
print(json.dumps(available))
