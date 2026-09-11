pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    // Ruta del fondo de pantalla actualmente activo
    property string currentWallpaper: Quickshell.env("HOME") + "/.config/hypr/media/neighbor.png"

    // Lista de wallpapers detectados: [{ name: "neighbor", path: "/..." }]
    property var wallpapers: []

    // Archivo para persistir la selección del usuario
    readonly property string stateFilePath: Quickshell.env("HOME") + "/.config/quickshell/state/wallpaper.txt"

    // Proceso para guardar la selección de forma persistente
    Process {
        id: saveProc
    }

    // Proceso para leer la selección guardada al inicio
    Process {
        id: readStateProc
        command: ["sh", "-c", "cat " + root.stateFilePath + " 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                let saved = data.trim();
                if (saved.length > 0) {
                    root.currentWallpaper = saved;
                }
            }
        }
    }

    // Proceso para escanear los wallpapers disponibles en el sistema
    Process {
        id: scanProc
        command: [
            "sh", "-c",
            "find -L \"$HOME/.config/hypr/media\" \"$HOME/Pictures/Wallpapers\" \"$HOME/Pictures\" -maxdepth 1 -type f \\( -iname \"*.png\" -o -iname \"*.jpg\" -o -iname \"*.jpeg\" -o -iname \"*.webp\" \\) 2>/dev/null | grep -v 'hyprshot' | sort"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                let line = data.trim();
                if (line.length === 0) return;
                let parts = line.split("/");
                let filename = parts[parts.length - 1];
                let name = filename.replace(/\.[^/.]+$/, "");

                // Evitar duplicados
                let exists = false;
                for (let i = 0; i < root.wallpapers.length; i++) {
                    if (root.wallpapers[i].path === line) {
                        exists = true;
                        break;
                    }
                }
                if (!exists) {
                    let newList = root.wallpapers.slice();
                    newList.push({
                        name: name,
                        filename: filename,
                        path: line
                    });
                    root.wallpapers = newList;
                }
            }
        }
    }

    function scanWallpapers() {
        root.wallpapers = [];
        if (scanProc.running) scanProc.running = false;
        scanProc.running = true;
    }

    function setWallpaper(path) {
        if (!path || path === root.currentWallpaper) return;
        let cleanPath = path.trim();
        root.currentWallpaper = cleanPath;

        // Persistir en disco
        if (saveProc.running) saveProc.running = false;
        saveProc.command = ["sh", "-c", "mkdir -p $(dirname " + root.stateFilePath + ") && echo '" + cleanPath + "' > " + root.stateFilePath];
        saveProc.running = true;
    }

    function next() {
        if (!root.wallpapers || root.wallpapers.length <= 1) return;
        let idx = -1;
        for (let i = 0; i < root.wallpapers.length; i++) {
            if (root.wallpapers[i].path === root.currentWallpaper) {
                idx = i;
                break;
            }
        }
        let nextIdx = (idx + 1) % root.wallpapers.length;
        root.setWallpaper(root.wallpapers[nextIdx].path);
    }

    function prev() {
        if (!root.wallpapers || root.wallpapers.length <= 1) return;
        let idx = -1;
        for (let i = 0; i < root.wallpapers.length; i++) {
            if (root.wallpapers[i].path === root.currentWallpaper) {
                idx = i;
                break;
            }
        }
        let prevIdx = (idx - 1 + root.wallpapers.length) % root.wallpapers.length;
        root.setWallpaper(root.wallpapers[prevIdx].path);
    }

    Component.onCompleted: {
        readStateProc.running = true;
        scanWallpapers();
    }
}
