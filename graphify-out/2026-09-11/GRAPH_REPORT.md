# Graph Report - quickshell  (2026-09-11)

## Corpus Check
- Corpus is ~14,474 words - fits in a single context window. You may not need a graph.

## Summary
- 81 nodes · 112 edges · 11 communities (5 shown, 6 thin omitted)
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 12 edges (avg confidence: 0.91)
- Token cost: 1,250 input · 850 output

## Community Hubs (Navigation)
- Dynamic Island & UI Modules
- Clipboard Daemon Operations
- Bluetooth D-Bus Pairing Agent
- Shell Architecture & Navigation
- Clipboard Daemon Service Runtime
- Control Center & Hardware Profiles
- Agent Knowledge System
- RyzenAdj Balanced Profile
- RyzenAdj Gaming Profile
- RyzenAdj Power Save Profile
- Network Management Integration

## God Nodes (most connected - your core abstractions)
1. `ClipboardDaemon` - 16 edges
2. `BluezAgent` - 14 edges
3. `Quickshell Desktop Shell for Hyprland` - 9 edges
4. `Dynamic Island Top Bar Architecture` - 7 edges
5. `On-Screen Display System and Critical Battery Alert` - 6 edges
6. `main()` - 4 edges
7. `send_client()` - 4 edges
8. `main()` - 4 edges
9. `get_sock_path()` - 3 edges
10. `Quick Settings Control Center` - 3 edges

## Surprising Connections (you probably didn't know these)
- `Btop Activity Monitor Icon` --references--> `Quickshell Desktop Shell for Hyprland`  [EXTRACTED]
  assets/icons/btop.svg → README.md
- `Htop Activity Monitor Icon` --references--> `Quickshell Desktop Shell for Hyprland`  [EXTRACTED]
  assets/icons/htop.svg → README.md
- `Workspaces and Taskbar Screenshot` --references--> `Quickshell Desktop Shell for Hyprland`  [EXTRACTED]
  assets/screenshots/workspaces_taskbar.png → README.md
- `Quickshell Top Bar Screenshot` --references--> `Dynamic Island Top Bar Architecture`  [EXTRACTED]
  assets/screenshots/bar.png → README.md
- `Dynamic Island Clock Screenshot` --references--> `Dynamic Island Top Bar Architecture`  [EXTRACTED]
  assets/screenshots/island_clock.png → README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Dynamic Island Experience Suite** — readme_dynamic_island, readme_launcher_spotlight, readme_notification_center, readme_osd_system [INFERRED 0.85]

## Communities (11 total, 6 thin omitted)

### Community 0 - "Dynamic Island & UI Modules"
Cohesion: 0.12
Nodes (16): Quickshell Top Bar Screenshot, Dynamic Island Clock Screenshot, Dynamic Island Media Controls Screenshot, Dynamic Island Media Screenshot, Spotlight App Launcher Screenshot, Notification Center Screenshot, Critical Battery Alert Screenshot, Brightness OSD Screenshot (+8 more)

### Community 1 - "Clipboard Daemon Operations"
Cohesion: 0.24
Nodes (3): ClipboardDaemon, Reads JSON commands from Quickshell via standard input, Check if there is an existing clipboard item at startup

### Community 3 - "Shell Architecture & Navigation"
Cohesion: 0.18
Nodes (10): Btop Activity Monitor Icon, Htop Activity Monitor Icon, Window Switcher Screenshot, Workspaces and Taskbar Screenshot, Quickshell Desktop Shell for Hyprland, Window Switcher Alt-Tab, Unused Code and Dead Symbol Audit, main() (+2 more)

### Community 4 - "Clipboard Daemon Service Runtime"
Cohesion: 0.36
Nodes (5): get_cache_path(), get_sock_path(), main(), Single-shot client invoked by wl-paste --watch, send_client()

### Community 5 - "Control Center & Hardware Profiles"
Cohesion: 0.33
Nodes (5): Quick Settings Control Center Screenshot, System Tray and Hardware Indicators Screenshot, Quick Settings Control Center, apply-profile.sh script, Active Power Profile State

## Knowledge Gaps
- **27 isolated node(s):** `apply-profile.sh script`, `ryzenadj-balanced.sh script`, `ryzenadj-gaming.sh script`, `ryzenadj-power-save.sh script`, `PipeWire WirePlumber Audio Management` (+22 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 36 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Quickshell Desktop Shell for Hyprland` connect `Shell Architecture & Navigation` to `Dynamic Island & UI Modules`, `Control Center & Hardware Profiles`?**
  _High betweenness centrality (0.251) - this node is a cross-community bridge._
- **Why does `Dynamic Island Top Bar Architecture` connect `Dynamic Island & UI Modules` to `Shell Architecture & Navigation`?**
  _High betweenness centrality (0.179) - this node is a cross-community bridge._
- **Why does `BluezAgent` connect `Bluetooth D-Bus Pairing Agent` to `Shell Architecture & Navigation`?**
  _High betweenness centrality (0.152) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `Quickshell Desktop Shell for Hyprland` (e.g. with `Dynamic Island Top Bar Architecture` and `Window Switcher Alt-Tab`) actually correct?**
  _`Quickshell Desktop Shell for Hyprland` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 5 inferred relationships involving `Dynamic Island Top Bar Architecture` (e.g. with `Quickshell Desktop Shell for Hyprland` and `Spotlight Application Launcher`) actually correct?**
  _`Dynamic Island Top Bar Architecture` has 5 INFERRED edges - model-reasoned connections that need verification._
- **What connects `apply-profile.sh script`, `ryzenadj-balanced.sh script`, `ryzenadj-gaming.sh script` to the rest of the system?**
  _27 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Dynamic Island & UI Modules` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._