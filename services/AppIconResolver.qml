pragma Singleton
import QtQuick
import Quickshell

// Resolución compartida de iconos de aplicaciones por clase/título.
// Consolida la lógica antes duplicada en TaskbarModule y SwitcherService.
Item {
    id: root

    function resolveAppIcon(appClass, title) {
        if (!appClass) return "";

        let candidates = [];
        let raw = appClass.trim();
        let lower = raw.toLowerCase();

        // 1. Mapeos de nombres conocidos para apps comunes
        if (lower.includes("antigravity")) {
            candidates.push("antigravity-ide", "antigravity", "/opt/Antigravity IDE/resources/app/resources/linux/code.png", "code", "vscode");
        } else if (lower.includes("code") || lower.includes("vscode")) {
            candidates.push("code", "vscode", "visual-studio-code", "com.visualstudio.code");
        } else if (lower.includes("ghostty")) {
            candidates.push("com.mitchellh.ghostty", "ghostty");
        } else if (lower.includes("btop")) {
            candidates.push(Qt.resolvedUrl("../assets/icons/btop.svg"));
        } else if (lower.includes("htop")) {
            candidates.push(Qt.resolvedUrl("../assets/icons/htop.svg"));
        } else if (lower.includes("spotify")) {
            candidates.push("com.spotify.Client", "spotify");
        } else if (lower.includes("steam")) {
            candidates.push("steam");
        } else if (lower.includes("zen")) {
            candidates.push("zen-browser", "zen");
        } else if (lower.includes("firefox")) {
            candidates.push("firefox");
        } else if (lower.includes("nautilus") || lower.includes("files")) {
            candidates.push("org.gnome.Nautilus", "system-file-manager");
        } else if (lower.includes("chrome")) {
            candidates.push("google-chrome", "chromium");
        } else if (lower.includes("discord")) {
            candidates.push("discord", "com.discordapp.Discord");
        } else if (lower.includes("telegram")) {
            candidates.push("telegram", "telegram-desktop", "org.telegram.desktop");
        } else if (lower.includes("gimp")) {
            candidates.push("gimp");
        } else if (lower.includes("obsidian")) {
            candidates.push("obsidian");
        }

        // 2. Probar la clase tal cual y en minúsculas
        candidates.push(raw);
        candidates.push(lower);

        // 3. Probar el último segmento de nombres en formato reverse-DNS (ej. com.example.App -> App)
        let dotParts = raw.split(".");
        if (dotParts.length > 1) {
            let last = dotParts[dotParts.length - 1];
            candidates.push(last);
            candidates.push(last.toLowerCase());
        }

        // Buscar en la base de datos de iconos del sistema o URLs resueltas
        for (let i = 0; i < candidates.length; i++) {
            let name = candidates[i];
            if (name && (name.startsWith("file://") || name.startsWith("http://") || name.startsWith("https://") || name.includes("/"))) {
                return name.startsWith("/") ? ("file://" + name) : name;
            }
            if (name && Quickshell.hasThemeIcon(name)) {
                return Quickshell.iconPath(name);
            }
        }

        return "";
    }
}
