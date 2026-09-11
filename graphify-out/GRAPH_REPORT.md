# Graph Report - quickshell  (2026-09-11)

## Corpus Check
- 11 files · ~14,474 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 131 nodes · 142 edges · 30 communities (5 shown, 25 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 3 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `89840faf`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Quickshell Top Bar Screenshot
- ClipboardDaemon
- BluezAgent
- main
- clip_daemon.py
- apply-profile.sh
- Unused Code Report
- ryzenadj-balanced.sh
- ryzenadj-gaming.sh
- ryzenadj-power-save.sh
- 🚀 Quickshell Desktop Shell para Hyprland
- 📸 Demostración Visual
- rules/graphify.md
- workflows/graphify.md
- Btop Activity Monitor Icon
- Htop Activity Monitor Icon
- Quick Settings Control Center Screenshot
- Dynamic Island Clock Screenshot
- Dynamic Island Media Controls Screenshot
- Dynamic Island Media Screenshot
- Spotlight App Launcher Screenshot
- Notification Center Screenshot
- Critical Battery Alert Screenshot
- Brightness OSD Screenshot
- Microphone OSD Screenshot
- Volume OSD Screenshot
- Window Switcher Screenshot
- System Tray and Hardware Indicators Screenshot
- Workspaces and Taskbar Screenshot
- Active Wallpaper State Path

## God Nodes (most connected - your core abstractions)
1. `Unused Code Report` - 33 edges
2. `ClipboardDaemon` - 16 edges
3. `BluezAgent` - 14 edges
4. `🚀 Quickshell Desktop Shell para Hyprland` - 7 edges
5. `📸 Demostración Visual` - 5 edges
6. `Paneles Desplegables` - 5 edges
7. `📦 Instalación desde Cero en Fedora` - 5 edges
8. `main()` - 4 edges
9. `send_client()` - 4 edges
10. `main()` - 4 edges

## Surprising Connections (you probably didn't know these)
- `main()` --calls--> `BluezAgent`  [EXTRACTED]
  services/bt_agent.py → services/bt_agent.py  _Bridges community 2 → community 3_
- `main()` --calls--> `ClipboardDaemon`  [EXTRACTED]
  services/clip_daemon.py → services/clip_daemon.py  _Bridges community 1 → community 4_

## Import Cycles
- None detected.

## Communities (30 total, 25 thin omitted)

### Community 1 - "ClipboardDaemon"
Cohesion: 0.24
Nodes (3): ClipboardDaemon, Reads JSON commands from Quickshell via standard input, Check if there is an existing clipboard item at startup

### Community 4 - "clip_daemon.py"
Cohesion: 0.36
Nodes (5): get_cache_path(), get_sock_path(), main(), Single-shot client invoked by wl-paste --watch, send_client()

### Community 6 - "Unused Code Report"
Cohesion: 0.06
Nodes (33): components/BarButton.qml, components/BarToolTip.qml, components/Pill.qml, components/TrayMenu.qml, modules/bar/Bar.qml, modules/center/CenterIslandModule.qml, modules/center/ClockView.qml, modules/center/MediaView.qml (+25 more)

### Community 10 - "🚀 Quickshell Desktop Shell para Hyprland"
Cohesion: 0.12
Nodes (15): 1. Habilitar Copr e Instalar Quickshell, 2. Paquetes y Dependencias del Sistema, 3. Tipografía e Iconos, 4. Permisos de Usuario (Control de Brillo), Atajos de Teclado Recomendados, Autoinicio, Descarga e instalación de la fuente:, 📋 Detalle de para qué sirve cada dependencia: (+7 more)

### Community 11 - "📸 Demostración Visual"
Cohesion: 0.22
Nodes (9): Barra Superior Completa (Top Bar), ⚙️ Centro de Control (Quick Settings), 🔔 Centro de Notificaciones, 🔀 Conmutador de Ventanas (Alt + Tab), 📸 Demostración Visual, 🔍 Lanzador de Aplicaciones (Spotlight), Módulos Principales, 🎛️ Notificaciones en Pantalla (OSD) y Alertas (+1 more)

## Knowledge Gaps
- **73 isolated node(s):** `apply-profile.sh script`, `ryzenadj-balanced.sh script`, `ryzenadj-gaming.sh script`, `ryzenadj-power-save.sh script`, `graphify` (+68 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 86 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **25 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `🚀 Quickshell Desktop Shell para Hyprland` connect `🚀 Quickshell Desktop Shell para Hyprland` to `📸 Demostración Visual`?**
  _High betweenness centrality (0.025) - this node is a cross-community bridge._
- **Why does `ClipboardDaemon` connect `ClipboardDaemon` to `clip_daemon.py`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **What connects `apply-profile.sh script`, `ryzenadj-balanced.sh script`, `ryzenadj-gaming.sh script` to the rest of the system?**
  _73 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Unused Code Report` be split into smaller, more focused modules?**
  _Cohesion score 0.058823529411764705 - nodes in this community are weakly interconnected._
- **Should `🚀 Quickshell Desktop Shell para Hyprland` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._