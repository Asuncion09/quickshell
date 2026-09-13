# Graph Report - quickshell  (2026-09-12)

## Corpus Check
- 15 files · ~20,507 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 146 nodes · 174 edges · 31 communities (6 shown, 23 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 4 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `83b0f9f0`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Quickshell Top Bar Screenshot
- ClipboardDaemon
- BluezAgent
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
2. `ClipboardDaemon` - 20 edges
3. `BluezAgent` - 14 edges
4. `🚀 Quickshell Desktop Shell para Hyprland` - 9 edges
5. `send_client()` - 6 edges
6. `📸 Demostración Visual` - 5 edges
7. `Paneles y Diálogos` - 5 edges
8. `main()` - 4 edges
9. `get_images_dir()` - 4 edges
10. `detect_image()` - 4 edges

## Surprising Connections (you probably didn't know these)
- `main()` --calls--> `ClipboardDaemon`  [EXTRACTED]
  services/clip_daemon.py → services/clip_daemon.py  _Bridges community 1 → community 4_

## Import Cycles
- None detected.

## Communities (31 total, 23 thin omitted)

### Community 1 - "ClipboardDaemon"
Cohesion: 0.19
Nodes (5): ClipboardDaemon, Pruena elementos no fijados con más de 24h de antigüedad o según política de…, Hilo de mantenimiento para limpiar elementos no fijados cada 10 minutos., Reads JSON commands from Quickshell via standard input, Check if there is an existing clipboard item at startup

### Community 2 - "BluezAgent"
Cohesion: 0.24
Nodes (4): method, BluezAgent, main(), on_stdin_read()

### Community 4 - "clip_daemon.py"
Cohesion: 0.23
Nodes (12): detect_image(), get_cache_dir(), get_cache_path(), get_config_path(), get_images_dir(), get_sock_path(), load_config(), main() (+4 more)

### Community 6 - "Unused Code Report"
Cohesion: 0.06
Nodes (33): components/BarButton.qml, components/BarToolTip.qml, components/Pill.qml, components/TrayMenu.qml, modules/bar/Bar.qml, modules/center/CenterIslandModule.qml, modules/center/ClockView.qml, modules/center/MediaView.qml (+25 more)

### Community 10 - "🚀 Quickshell Desktop Shell para Hyprland"
Cohesion: 0.13
Nodes (14): 1. Habilitar Copr para Quickshell, Matugen y Herramientas Hyprland, 2. Paquetes y Dependencias del Sistema, 3. Tipografía e Iconos, Atajos de Teclado Recomendados, Autoinicio, ✨ Características Destacadas, 📡 Control por Terminal / IPC, 🗂️ Estructura del Proyecto (+6 more)

### Community 11 - "📸 Demostración Visual"
Cohesion: 0.22
Nodes (9): Barra Superior Completa (Top Bar), 🎛️ Centro de Control y Submenú de Ajustes (Settings), 🔔 Centro de Notificaciones, 🔀 Conmutador de Ventanas (Alt + Tab), 📸 Demostración Visual, 🔍 Lanzador de Aplicaciones (Spotlight), Módulos Principales, 🎛️ Notificaciones en Pantalla (OSD) y Alertas (+1 more)

## Knowledge Gaps
- **73 isolated node(s):** `apply-profile.sh script`, `ryzenadj-balanced.sh script`, `ryzenadj-gaming.sh script`, `ryzenadj-power-save.sh script`, `graphify` (+68 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 92 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **23 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ClipboardDaemon` connect `ClipboardDaemon` to `clip_daemon.py`?**
  _High betweenness centrality (0.040) - this node is a cross-community bridge._
- **Why does `🚀 Quickshell Desktop Shell para Hyprland` connect `🚀 Quickshell Desktop Shell para Hyprland` to `📸 Demostración Visual`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **What connects `apply-profile.sh script`, `ryzenadj-balanced.sh script`, `ryzenadj-gaming.sh script` to the rest of the system?**
  _73 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Unused Code Report` be split into smaller, more focused modules?**
  _Cohesion score 0.058823529411764705 - nodes in this community are weakly interconnected._
- **Should `🚀 Quickshell Desktop Shell para Hyprland` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._