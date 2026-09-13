#!/usr/bin/env python3
import os
import glob
import json

dirs = [
    '/usr/share/sounds',
    os.path.expanduser('~/.local/share/sounds')
]

DESCRIPTIONS = {
    'ocean': {
        'title': 'Ocean',
        'desc': 'Modern KDE Plasma',
        'icon': '󰋋'
    },
    'oxygen': {
        'title': 'Oxygen',
        'desc': 'Classic KDE Plasma',
        'icon': '󰈚'
    },
    'Yaru': {
        'title': 'Yaru',
        'desc': 'Modern Ubuntu',
        'icon': '󰕈'
    },
    'Pop': {
        'title': 'Pop!_OS',
        'desc': 'Subtle Pop!_OS',
        'icon': '󰓃'
    },
    'freedesktop': {
        'title': 'Freedesktop',
        'desc': 'Standard Linux',
        'icon': '󰎆'
    },
    'deepin': {
        'title': 'Deepin',
        'desc': 'Smooth Deepin DDE',
        'icon': '󰓃'
    }
}

themes = []
seen = set()

for base in dirs:
    if not os.path.isdir(base):
        continue
    try:
        entries = sorted(os.listdir(base))
    except Exception:
        continue

    for item in entries:
        theme_dir = os.path.join(base, item)
        idx_file = os.path.join(theme_dir, 'index.theme')
        if os.path.isfile(idx_file) and item not in seen:
            seen.add(item)
            name = item
            comment = ''
            try:
                with open(idx_file, 'r', encoding='utf-8', errors='ignore') as f:
                    for line in f:
                        line = line.strip()
                        if line.startswith('Name=') and (name == item or not name):
                            name = line.split('=', 1)[1].strip()
                        elif line.startswith('Comment=') and not comment:
                            comment = line.split('=', 1)[1].strip()
            except Exception:
                pass

            known = DESCRIPTIONS.get(item, {})
            title = known.get('title', name)
            desc = known.get('desc', comment or 'Tema de sonidos XDG')
            icon = known.get('icon', '󰓃')

            themes.append({
                'id': item,
                'name': title,
                'desc': desc,
                'icon': icon,
                'path': theme_dir
            })

ORDER = {'ocean': 1, 'oxygen': 2, 'Yaru': 3, 'Pop': 4, 'freedesktop': 5}
themes.sort(key=lambda t: ORDER.get(t['id'], 10))

print(json.dumps(themes))
