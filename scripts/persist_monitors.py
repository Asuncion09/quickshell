#!/usr/bin/env python3
import json
import os
import re
import sys

def main():
    home = os.path.expanduser("~")
    state_file = os.path.join(home, ".config/quickshell/state/monitors.json")
    lua_file = os.path.join(home, ".config/hypr/modules/monitors.lua")

    if not os.path.exists(state_file):
        print(f"State file {state_file} does not exist.")
        return 0

    if not os.path.exists(lua_file):
        print(f"Hyprland monitors file {lua_file} does not exist.")
        return 0

    try:
        with open(state_file, "r", encoding="utf-8") as f:
            monitors = json.load(f)
    except Exception as e:
        print(f"Error reading monitors JSON: {e}")
        return 1

    try:
        with open(lua_file, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading monitors.lua: {e}")
        return 1

    # Filtrar monitores reales (excluyendo headless para no contaminar configuración física)
    real_monitors = [m for m in monitors if not m.get("name", "").startswith("HEADLESS-")]

    updated_content = content

    for m in real_monitors:
        name = m.get("name")
        if not name:
            continue

        # Formatear parámetros (respetar la resolución activa/aplicada, no el primer modo disponible)
        mode = m.get("mode") or m.get("activeMode")
        if not mode:
            w = m.get("width")
            h = m.get("height")
            rr = m.get("refreshRate")
            if w and h:
                mode = f"{w}x{h}@{rr}" if rr else f"{w}x{h}"
            elif m.get("availableModes") and len(m.get("availableModes")) > 0:
                mode = m.get("availableModes")[0]
            else:
                mode = "preferred"
        mode = re.sub(r'Hz$', '', str(mode), flags=re.IGNORECASE)
        x = m.get("x", 0)
        y = m.get("y", 0)
        pos = f"{x}x{y}"
        scale = m.get("scale", 1.0)
        transform = m.get("transform", 0)

        # Buscar bloque existente hl.monitor para este output
        pattern = rf'hl\.monitor\(\s*\{{[^}}]*output\s*=\s*"{re.escape(name)}"[^}}]*\}}\s*\)'
        
        # Generar nuevo bloque Lua
        block_lines = [
            "hl.monitor({",
            f'  output = "{name}",',
            f'  mode = "{mode}",',
            f'  position = "{pos}",',
            f'  scale = {scale},',
        ]
        if transform > 0:
            block_lines.append(f'  transform = {transform},')
        if m.get("disabled", False):
            block_lines.append('  disabled = true,')
        block_lines.append("})")
        new_block = "\n".join(block_lines)

        if re.search(pattern, updated_content):
            updated_content = re.sub(pattern, new_block, updated_content, count=1)
        else:
            # Si no existe, insertar antes del bloque fallback o antes de workspace_rule
            fallback_match = re.search(r'(--\s*Fallback[^\n]*\n)?hl\.monitor\(\s*\{{[^}}]*output\s*=\s*""', updated_content)
            if fallback_match:
                insert_idx = fallback_match.start()
                updated_content = updated_content[:insert_idx] + new_block + "\n\n" + updated_content[insert_idx:]
            else:
                updated_content = new_block + "\n\n" + updated_content

    # Guardar copia de respaldo y escribir atómicamente
    bak_file = lua_file + ".bak"
    try:
        with open(bak_file, "w", encoding="utf-8") as f:
            f.write(content)
        tmp_file = lua_file + ".tmp"
        with open(tmp_file, "w", encoding="utf-8") as f:
            f.write(updated_content)
        os.replace(tmp_file, lua_file)
        print(f"Successfully persisted monitors to {lua_file}")
    except Exception as e:
        print(f"Error writing monitors.lua: {e}")
        return 1

    return 0

if __name__ == "__main__":
    sys.exit(main())
