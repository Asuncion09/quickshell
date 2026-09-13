pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Tema de sonido actualmente activo (por defecto "ocean" si está instalado, o "freedesktop")
    property string currentTheme: "ocean"
    property bool soundEnabled: true

    // Lista de temas detectados [{ id, name, desc, icon, path }]
    property var soundThemes: []

    readonly property string currentThemeName: {
        for (let i = 0; i < root.soundThemes.length; i++) {
            if (root.soundThemes[i].id === root.currentTheme) {
                return root.soundThemes[i].name;
            }
        }
        return root.currentTheme.charAt(0).toUpperCase() + root.currentTheme.slice(1);
    }

    // Rutas a archivos de estado persistente
    readonly property string stateThemePath: Quickshell.env("HOME") + "/.config/quickshell/state/sound_theme.txt"
    readonly property string stateEnabledPath: Quickshell.env("HOME") + "/.config/quickshell/state/sound_enabled.txt"
    readonly property string scanScriptPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/list_sound_themes.py"

    // --- Procesos de reproducción alternados ---
    property int _procTurn: 0

    Process {
        id: playProc1
    }
    Process {
        id: playProc2
    }
    Process {
        id: previewProc
    }

    // --- Procesos de persistencia ---
    Process {
        id: saveThemeProc
    }
    Process {
        id: saveEnabledProc
    }

    // --- Escaneo de temas disponibles ---
    Process {
        id: scanProc
        command: ["python3", root.scanScriptPath]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    let list = JSON.parse(data.trim());
                    if (Array.isArray(list) && list.length > 0) {
                        root.soundThemes = list;
                    }
                } catch (e) {
                    console.warn("[SoundService] Error al parsear temas de sonido:", e);
                }
            }
        }
    }

    // --- Lectura de estado persistido al inicio ---
    Process {
        id: readThemeStateProc
        command: ["sh", "-c", "cat " + root.stateThemePath + " 2>/dev/null || gsettings get org.gnome.desktop.sound theme-name 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                let saved = data.trim().replace(/'/g, "");
                if (saved.length > 0) {
                    root.currentTheme = saved;
                }
            }
        }
    }

    Process {
        id: readEnabledStateProc
        command: ["sh", "-c", "cat " + root.stateEnabledPath + " 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                let saved = data.trim();
                if (saved === "false" || saved === "0") {
                    root.soundEnabled = false;
                } else if (saved === "true" || saved === "1") {
                    root.soundEnabled = true;
                }
            }
        }
    }

    function scanThemes() {
        if (scanProc.running) scanProc.running = false;
        scanProc.running = true;
    }

    function play(soundId, forceTheme) {
        if (!root.soundEnabled && !forceTheme) return;
        if (!soundId || soundId === "") return;

        let theme = forceTheme || root.currentTheme;
        let proc = (root._procTurn === 0) ? playProc1 : playProc2;
        root._procTurn = (root._procTurn + 1) % 2;

        if (proc.running) proc.running = false;
        proc.command = [
            "sh", "-c",
            "canberra-gtk-play -i " + soundId + " --property=canberra.xdg-theme.name=" + theme + " 2>/dev/null || " +
            "canberra-gtk-play -i " + soundId + " 2>/dev/null"
        ];
        proc.running = true;
    }

    function playFile(filePath) {
        if (!root.soundEnabled) return;
        if (!filePath || filePath === "") return;

        let proc = (root._procTurn === 0) ? playProc1 : playProc2;
        root._procTurn = (root._procTurn + 1) % 2;

        if (proc.running) proc.running = false;
        proc.command = ["canberra-gtk-play", "-f", filePath];
        proc.running = true;
    }

    function preview(soundId, themeId) {
        if (!soundId || !themeId) return;
        if (previewProc.running) previewProc.running = false;
        previewProc.command = [
            "sh", "-c",
            "canberra-gtk-play -i " + soundId + " --property=canberra.xdg-theme.name=" + themeId + " 2>/dev/null || " +
            "canberra-gtk-play -i theme-demo --property=canberra.xdg-theme.name=" + themeId + " 2>/dev/null || " +
            "canberra-gtk-play -i " + soundId + " 2>/dev/null"
        ];
        previewProc.running = true;
    }

    function setTheme(themeId) {
        if (!themeId || themeId === "") return;
        root.currentTheme = themeId;

        // Persistir en state/sound_theme.txt
        if (saveThemeProc.running) saveThemeProc.running = false;
        saveThemeProc.command = [
            "sh", "-c",
            "mkdir -p $(dirname " + root.stateThemePath + ") && echo -n '" + themeId + "' > " + root.stateThemePath +
            " && gsettings set org.gnome.desktop.sound theme-name '" + themeId + "' 2>/dev/null || true"
        ];
        saveThemeProc.running = true;

        // Reproducir sonido de confirmación en el tema recién seleccionado
        root.preview("message-new-instant", themeId);
    }

    function setSoundEnabled(enabled) {
        root.soundEnabled = enabled;

        // Persistir en state/sound_enabled.txt
        if (saveEnabledProc.running) saveEnabledProc.running = false;
        saveEnabledProc.command = [
            "sh", "-c",
            "mkdir -p $(dirname " + root.stateEnabledPath + ") && echo -n '" + (enabled ? "true" : "false") + "' > " + root.stateEnabledPath +
            " && gsettings set org.gnome.desktop.sound event-sounds " + (enabled ? "true" : "false") + " 2>/dev/null || true"
        ];
        saveEnabledProc.running = true;

        if (enabled) {
            root.play("device-added");
        }
    }

    Component.onCompleted: {
        root.scanThemes();
        readThemeStateProc.running = true;
        readEnabledStateProc.running = true;
    }
}
