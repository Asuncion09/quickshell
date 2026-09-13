pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    property string currentFont: "JetBrainsMono Nerd Font Propo"
    property var availableFonts: []

    readonly property string currentFontName: {
        for (let i = 0; i < root.availableFonts.length; i++) {
            if (root.availableFonts[i].id === root.currentFont) {
                return root.availableFonts[i].name;
            }
        }
        return root.currentFont;
    }

    readonly property string stateFontPath: Quickshell.env("HOME") + "/.config/quickshell/state/font.txt"
    readonly property string scanScriptPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/list_fonts.py"

    Process {
        id: saveFontProc
    }

    Process {
        id: scanProc
        command: ["python3", root.scanScriptPath]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    let list = JSON.parse(data.trim());
                    if (Array.isArray(list) && list.length > 0) {
                        root.availableFonts = list;
                    }
                } catch (e) {
                    console.warn("[FontService] Error parsing font list:", e);
                }
            }
        }
    }

    Process {
        id: readFontStateProc
        command: ["sh", "-c", "cat " + root.stateFontPath + " 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                let saved = data.trim();
                if (saved.length > 0) {
                    root.currentFont = saved;
                    Theme.fontFamily = saved;
                }
            }
        }
    }

    function scanFonts() {
        if (scanProc.running) scanProc.running = false;
        scanProc.running = true;
    }

    function setFont(fontId) {
        if (!fontId || fontId === "") return;
        root.currentFont = fontId;
        Theme.fontFamily = fontId;

        if (saveFontProc.running) saveFontProc.running = false;
        saveFontProc.command = [
            "sh", "-c",
            "mkdir -p $(dirname " + root.stateFontPath + ") && echo -n '" + fontId + "' > " + root.stateFontPath
        ];
        saveFontProc.running = true;
    }

    Component.onCompleted: {
        root.scanFonts();
        readFontStateProc.running = true;
    }
}
