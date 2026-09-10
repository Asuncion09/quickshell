pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Item {
    id: root

    property bool isOpen: false
    property int selectedIndex: 0
    property int _eventVersion: 0
    property var displayedWindows: []

    // Historial MRU (Most Recently Used) de direcciones de ventana
    property var _mruAddresses: []

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event) return;
            let n = event.name;
            if (n === "openwindow" || n === "closewindow" || n === "movewindow" || n === "movewindowv2"
             || n === "activewindow" || n === "activewindowv2" || n === "workspace"
             || n === "windowtitle" || n === "windowtitlev2") {
                root._eventVersion++;
                
                // Actualizar historial MRU si cambió la ventana activa y el switcher está cerrado
                if (!root.isOpen && Hyprland.activeToplevel && Hyprland.activeToplevel.address) {
                    root.recordFocus(Hyprland.activeToplevel.address);
                }
            }
        }
    }

    function recordFocus(address) {
        if (!address) return;
        let list = root._mruAddresses.filter(a => a !== address);
        list.unshift(address);
        if (list.length > 30) list.pop();
        root._mruAddresses = list;
    }

    Process {
        id: focusProc
    }

    Process {
        id: closeProc
    }

    property bool testHold: false

    Timer {
        id: testHoldTimer
        interval: 1800
        repeat: false
        onTriggered: {
            root.testHold = false;
            if (root.isOpen) root.close();
        }
    }

    function preview() {
        root.testHold = true;
        root.open();
        testHoldTimer.restart();
    }

    Process {
        id: altStateProc
        command: ["hyprctl", "repl", "print(hl.is_key_down(\"Alt_L\") or hl.is_key_down(\"Alt_R\"))"]
        stdout: SplitParser {
            onRead: data => {
                let trimmed = data.trim();
                if (trimmed === "false" && root.isOpen && !root.testHold) {
                    root.select();
                }
            }
        }
    }

    Timer {
        id: altPollTimer
        interval: 60
        repeat: true
        running: root.isOpen
        onTriggered: {
            if (root.isOpen && !altStateProc.running) {
                altStateProc.running = true;
            }
        }
    }

    Timer {
        id: focusTimer
        interval: 35
        repeat: false
        property string targetAddr: ""
        property int targetWs: 0
        onTriggered: {
            if (targetAddr !== "") {
                root.executeFocus(targetAddr, targetWs);
            }
        }
    }

    function executeFocus(address, workspaceId) {
        if (!address) return;
        let cleanAddr = address.startsWith("0x") ? address : ("0x" + address);

        if (focusProc.running) focusProc.running = false;
        let ws = (workspaceId && workspaceId > 0) ? workspaceId : 0;
        let luaCmd = "local ws = " + ws + "; "
                   + "local addr = \"" + cleanAddr + "\"; "
                   + "if ws > 0 then hl.dispatch(hl.dsp.focus({ workspace = ws })) end; "
                   + "hl.dispatch(hl.dsp.focus({ window = \"address:\" .. addr })); "
                   + "for _, w in ipairs(hl.get_windows()) do "
                   + "  if w.address:lower() == addr:lower() and w.at and w.size then "
                   + "    local cx = math.floor(w.at.x + w.size.x / 2); "
                   + "    local cy = math.floor(w.at.y + w.size.y / 2); "
                   + "    hl.dispatch(hl.dsp.cursor.move({ x = cx, y = cy })); "
                   + "    break; "
                   + "  end; "
                   + "end;";

        focusProc.command = ["hyprctl", "repl", luaCmd];
        focusProc.running = true;
    }

    function focusWindow(address, toplevel, workspaceId) {
        if (!address) return;
        focusTimer.targetAddr = address;
        focusTimer.targetWs = (workspaceId && workspaceId > 0) ? workspaceId : 0;
        focusTimer.restart();
    }

    function closeWindow(address, toplevel) {
        if (!address) return;
        let cleanAddr = address.startsWith("0x") ? address : ("0x" + address);
        if (toplevel && toplevel.wayland && typeof toplevel.wayland.close === "function") {
            toplevel.wayland.close();
        }

        if (closeProc.running) closeProc.running = false;
        closeProc.command = ["hyprctl", "repl", "hl.dispatch(hl.dsp.window.close({ window = \"address:" + cleanAddr + "\" }))"];
        closeProc.running = true;
    }

    function isRealWindow(top) {
        if (!top) return false;

        let ipc = top.lastIpcObject || {};
        if (ipc.mapped === false || ipc.hidden === true) return false;

        let windowWs = top.workspace ? top.workspace.id : (ipc.workspace ? ipc.workspace.id : -1);
        if (windowWs <= 0) return false;

        if (ipc.size && Array.isArray(ipc.size)) {
            if (ipc.size[0] <= 1 && ipc.size[1] <= 1) return false;
        }

        let rawTitle = ((top.title !== undefined && top.title !== null) ? top.title : (ipc.title || "")).trim();
        let appClass = (ipc.class || (top.wayland ? top.wayland.appId : "") || "").trim();
        let lowerClass = appClass.toLowerCase();
        let lowerTitle = rawTitle.toLowerCase();

        if (lowerClass.includes("steam")) {
            if (rawTitle === "") return false;
            if (lowerTitle.includes("notificationtoasts")) return false;
            if (lowerTitle === "special" || lowerClass === "steamwebhelper") return false;
        }

        if (appClass === "" && rawTitle === "") return false;
        if (ipc.xwayland && rawTitle === "") return false;

        return true;
    }

    function resolveAppName(appClass, rawTitle) {
        if (!appClass) return rawTitle || "Ventana";
        let lower = appClass.toLowerCase();
        if (lower.includes("code") || lower.includes("vscode")) return "VS Code";
        if (lower.includes("antigravity")) return "Antigravity IDE";
        if (lower.includes("ghostty")) return "Ghostty";
        if (lower.includes("spotify")) return "Spotify";
        if (lower.includes("zen")) return "Zen Browser";
        if (lower.includes("firefox")) return "Firefox";
        if (lower.includes("nautilus") || lower.includes("files")) return "Archivos";
        if (lower.includes("chrome")) return "Google Chrome";
        if (lower.includes("discord")) return "Discord";
        if (lower.includes("telegram")) return "Telegram";
        if (lower.includes("steam")) return "Steam";
        if (lower.includes("obsidian")) return "Obsidian";

        let parts = appClass.split(".");
        let last = parts[parts.length - 1];
        if (last && last.length > 0) {
            return last.charAt(0).toUpperCase() + last.slice(1);
        }
        return appClass;
    }

    function resolveAppIcon(appClass, title) {
        if (!appClass) return "";

        let candidates = [];
        let raw = appClass.trim();
        let lower = raw.toLowerCase();

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

        candidates.push(raw);
        candidates.push(lower);

        let dotParts = raw.split(".");
        if (dotParts.length > 1) {
            let last = dotParts[dotParts.length - 1];
            candidates.push(last);
            candidates.push(last.toLowerCase());
        }

        for (let i = 0; i < candidates.length; i++) {
            let name = candidates[i];
            if (name.startsWith("/") || name.startsWith("file://")) {
                return name;
            }
            if (name && Quickshell.hasThemeIcon(name)) {
                return Quickshell.iconPath(name);
            }
        }

        return "";
    }

    // Lista ordenada de todas las ventanas abiertas en todos los workspaces
    readonly property var windows: {
        let _dep = root._eventVersion;
        let list = [];

        if (!Hyprland.toplevels || !Hyprland.toplevels.values) return list;

        for (let i = 0; i < Hyprland.toplevels.values.length; i++) {
            let top = Hyprland.toplevels.values[i];
            if (!root.isRealWindow(top)) continue;

            let ipc = top.lastIpcObject || {};
            let windowWs = top.workspace ? top.workspace.id : (ipc.workspace ? ipc.workspace.id : -1);
            let appClass = ipc.class || (top.wayland ? top.wayland.appId : "") || "";
            let title = top.title || ipc.title || appClass || "Ventana";
            let addr = top.address || "";
            let isFocused = top.activated || (Hyprland.activeToplevel && Hyprland.activeToplevel.address === addr);

            list.push({
                address: addr,
                title: title,
                appClass: appClass,
                appName: root.resolveAppName(appClass, title),
                workspaceId: windowWs,
                isFocused: isFocused,
                iconSource: root.resolveAppIcon(appClass, title),
                toplevel: top
            });
        }

        // Ordenar según el historial MRU (la ventana enfocada primero, luego la anterior, etc.)
        let mru = root._mruAddresses;
        list.sort((a, b) => {
            let idxA = mru.indexOf(a.address);
            let idxB = mru.indexOf(b.address);

            // Si ambos están en MRU, respeta el orden reciente
            if (idxA !== -1 && idxB !== -1) return idxA - idxB;
            if (idxA !== -1) return -1;
            if (idxB !== -1) return 1;

            // De lo contrario por workspace
            if (a.workspaceId !== b.workspaceId) return a.workspaceId - b.workspaceId;
            return a.title.localeCompare(b.title);
        });

        return list;
    }

    readonly property var currentWindow: {
        let list = root.displayedWindows.length > 0 ? root.displayedWindows : root.windows;
        if (list.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < list.length) {
            return list[root.selectedIndex];
        }
        return null;
    }

    function open() {
        let curAddr = Hyprland.activeToplevel ? Hyprland.activeToplevel.address : "";
        if (curAddr !== "") {
            root.recordFocus(curAddr);
        }

        // Tomar instantánea fija de las ventanas para que los iconos no salten mientras esté visible
        let w = root.windows;
        root.displayedWindows = w;
        let count = w.length;
        if (count <= 0) return;

        root.selectedIndex = (count > 1) ? 1 : 0;
        root.isOpen = true;

        // Comprobación inmediata por si el usuario soltó Alt en un toque ultra rápido
        if (altStateProc.running) altStateProc.running = false;
        altStateProc.running = true;
    }

    function close() {
        root.isOpen = false;
    }

    function next() {
        let list = root.displayedWindows.length > 0 ? root.displayedWindows : root.windows;
        let count = list.length;
        if (count <= 0) return;

        if (!root.isOpen) {
            root.open();
        } else {
            root.selectedIndex = (root.selectedIndex + 1) % count;
        }
    }

    function prev() {
        let list = root.displayedWindows.length > 0 ? root.displayedWindows : root.windows;
        let count = list.length;
        if (count <= 0) return;

        if (!root.isOpen) {
            root.open();
            root.selectedIndex = (count > 1) ? count - 1 : 0;
        } else {
            root.selectedIndex = (root.selectedIndex - 1 + count) % count;
        }
    }

    function select() {
        if (!root.isOpen) return;

        let win = root.currentWindow;
        root.close();
        if (win) {
            root.focusWindow(win.address, win.toplevel, win.workspaceId);
            root.recordFocus(win.address);
        }
    }

    function selectIndex(index) {
        let list = root.displayedWindows.length > 0 ? root.displayedWindows : root.windows;
        root.close();
        if (index >= 0 && index < list.length) {
            let win = list[index];
            root.focusWindow(win.address, win.toplevel, win.workspaceId);
            root.recordFocus(win.address);
        }
    }

    function hoverIndex(index) {
        let list = root.displayedWindows.length > 0 ? root.displayedWindows : root.windows;
        if (index >= 0 && index < list.length) {
            root.selectedIndex = index;
        }
    }

    function cancel() {
        root.close();
    }

    function closeCurrent() {
        if (!root.isOpen) return;
        let win = root.currentWindow;
        if (!win) return;

        root.closeWindow(win.address, win.toplevel);

        // Actualizar lista visible eliminando la ventana sin desordenar las demás
        let newList = root.displayedWindows.filter(w => w.address !== win.address);
        root.displayedWindows = newList;

        if (newList.length <= 0) {
            root.close();
        } else if (root.selectedIndex >= newList.length) {
            root.selectedIndex = Math.max(0, newList.length - 1);
        }
    }
}
