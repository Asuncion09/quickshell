## Quickshell UI Design & Styling Rules

All QML code developed or modified in this workspace must adhere to the project's design system:

1. **Zero Hardcoded Colors**: NEVER use hardcoded hex codes (`#ffffff`, `#161616`, etc.). Always use semantic tokens from `theme/Theme.qml` (`Theme.highlight`, `Theme.text`, `Theme.surfaceBase`, `Theme.surfaceHover`, `Theme.surfaceKeyFocus`, `Theme.borderDark`, etc.).
2. **Dual-Theme Compatibility**: Components must dynamically adapt to both `"default"` (Obsidian Blue) and `"matugen"` (Material You extracted from wallpaper).
3. **Typography**: Always use `Theme.fontFamily` (`JetBrainsMono Nerd Font Propo`) and standard Nerd Font icons.
4. **Keyboard Navigation**: All interactive views, modals, and detail panels must implement `handleKey(event)` with visible focus indicators active only during keyboard interaction (`isKeyNavActive`).
5. **Wayland Input Masks**: Keep layer shell surfaces permeable using `mask: Region { ... }`.
6. **Reference Skill**: For detailed component templates, layout structures, and token reference, activate the `quickshell-design` skill (`.agents/skills/quickshell-design/SKILL.md`).
