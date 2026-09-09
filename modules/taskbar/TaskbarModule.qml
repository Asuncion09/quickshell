import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Io
import "../../theme"
import "../../components"

Item {
    id: root

    // Versión de evento para reactividad inmediata ante cambios en Hyprland
    property int _eventVersion: 0

    // Historial para mantener un orden estable de ventanas (orden de apertura / creación)
    property var _windowOrder: []

    function updateWindowOrder() {
        if (!Hyprland.toplevels || !Hyprland.toplevels.values) return;
        let currentAddrs = [];
        for (let i = 0; i < Hyprland.toplevels.values.length; i++) {
            let top = Hyprland.toplevels.values[i];
            if (top && top.address) currentAddrs.push(top.address);
        }
        let updated = root._windowOrder.filter(a => currentAddrs.includes(a));
        for (let i = 0; i < currentAddrs.length; i++) {
            if (!updated.includes(currentAddrs[i])) {
                updated.push(currentAddrs[i]);
            }
        }
        root._windowOrder = updated;
    }

    Component.onCompleted: {
        root.updateWindowOrder();
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event) return;
            let n = event.name;
            if (n === "openwindow" || n === "closewindow" || n === "movewindow" || n === "movewindowv2"
             || n === "activewindow" || n === "activewindowv2" || n === "workspace"
             || n === "windowtitle" || n === "windowtitlev2") {
                root.updateWindowOrder();
                root._eventVersion++;
            }
        }
    }

    // Procesos auxiliares de respaldo si Hyprland.dispatch no estuviera disponible
    Process {
        id: focusProc
        command: ["hyprctl", "dispatch", "hl.dsp.focus({ window = \"address:0x0\" })"]
    }

    Process {
        id: closeProc
        command: ["hyprctl", "dispatch", "hl.dsp.window.close({ window = \"address:0x0\" })"]
    }

    function focusWindow(address, workspaceId, toplevel) {
        // 1. Intentar el método nativo Wayland si está presente
        if (toplevel && toplevel.wayland && typeof toplevel.wayland.activate === "function") {
            toplevel.wayland.activate();
        }

        // 2. Dispatch vía hyprctl Lua (cambia de workspace y enfoca la ventana automáticamente)
        if (focusProc.running) focusProc.running = false;
        focusProc.command = ["hyprctl", "dispatch", "hl.dsp.focus({ window = \"address:" + address + "\" })"];
        focusProc.running = true;
    }

    function closeWindow(address, toplevel) {
        if (toplevel && toplevel.wayland && typeof toplevel.wayland.close === "function") {
            toplevel.wayland.close();
        }

        if (closeProc.running) closeProc.running = false;
        closeProc.command = ["hyprctl", "dispatch", "hl.dsp.window.close({ window = \"address:" + address + "\" })"];
        closeProc.running = true;
    }

    // ID del espacio de trabajo activo
    readonly property int currentWorkspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    // Dirección de la ventana enfocada actualmente
    readonly property string activeAddress: {
        let _dep = root._eventVersion;
        if (Hyprland.activeToplevel && Hyprland.activeToplevel.address) {
            return Hyprland.activeToplevel.address;
        }
        return "";
    }

    // Resuelve el icono a color oficial del tema para la aplicación
    function resolveAppIcon(appClass, title) {
        if (!appClass) return "";

        let candidates = [];
        let raw = appClass.trim();
        let lower = raw.toLowerCase();

        // 1. Mapeos de nombres conocidos para apps comunes
        if (lower.includes("code") || lower.includes("vscode")) {
            candidates.push("code", "vscode", "visual-studio-code", "com.visualstudio.code");
        } else if (lower.includes("ghostty")) {
            candidates.push("com.mitchellh.ghostty", "ghostty");
        } else if (lower.includes("btop")) {
            candidates.push(Qt.resolvedUrl("../../assets/icons/btop.svg"));
        } else if (lower.includes("htop")) {
            candidates.push(Qt.resolvedUrl("../../assets/icons/htop.svg"));
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

    // Determina si un toplevel es una ventana real de aplicación o un popup/tooltip efímero
    function isRealWindow(top) {
        if (!top) return false;

        let ipc = top.lastIpcObject || {};
        if (ipc.mapped === false || ipc.hidden === true) return false;

        let windowWs = top.workspace ? top.workspace.id : (ipc.workspace ? ipc.workspace.id : -1);
        if (windowWs <= 0) return false;

        // Descartar ventanas dummy / auxiliares de 1x1 o 0x0 (superficies de arrastre o transparentes)
        if (ipc.size && Array.isArray(ipc.size)) {
            if (ipc.size[0] <= 1 && ipc.size[1] <= 1) return false;
        }

        let rawTitle = ((top.title !== undefined && top.title !== null) ? top.title : (ipc.title || "")).trim();
        let appClass = (ipc.class || (top.wayland ? top.wayland.appId : "") || "").trim();
        let lowerClass = appClass.toLowerCase();
        let lowerTitle = rawTitle.toLowerCase();

        // 1. Filtrar popups, tooltips y menús hover de Steam (Tienda, Biblioteca, Comunidad, Usuario)
        if (lowerClass.includes("steam")) {
            // En Steam (XWayland), los submenús emergentes al hacer hover tienen título vacío
            if (rawTitle === "") return false;
            // Notificaciones flotantes emergentes (toasts de mensajes/amigos)
            if (lowerTitle.includes("notificationtoasts")) return false;
            // Ventanas invisibles o procesos de fondo de Steam
            if (lowerTitle === "special" || lowerClass === "steamwebhelper") return false;
        }

        // 2. Ventanas sin clase ni título (fantasmas o auxiliares de arrastre)
        if (appClass === "" && rawTitle === "") return false;

        // 3. Ventanas XWayland sin título (suelen ser popups, dropdowns o tooltips que X11 expone como toplevel)
        if (ipc.xwayland && rawTitle === "") return false;

        return true;
    }

    // Lista reactiva de todas las ventanas abiertas en el sistema
    readonly property var activeWindows: {
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
            let isFocused = top.activated || (root.activeAddress !== "" && root.activeAddress === addr);
            let isCurrentWs = windowWs === root.currentWorkspaceId;

            list.push({
                address: addr,
                title: title,
                appClass: appClass,
                workspaceId: windowWs,
                isCurrentWs: isCurrentWs,
                isFocused: isFocused,
                iconSource: root.resolveAppIcon(appClass, title),
                toplevel: top
            });
        }

        // Ordenar por workspace y luego por orden de apertura estable (nunca por título)
        list.sort((a, b) => {
            if (a.workspaceId !== b.workspaceId) return a.workspaceId - b.workspaceId;
            let idxA = root._windowOrder.indexOf(a.address);
            let idxB = root._windowOrder.indexOf(b.address);
            if (idxA !== -1 && idxB !== -1) return idxA - idxB;
            if (idxA !== -1) return -1;
            if (idxB !== -1) return 1;
            return a.address.localeCompare(b.address);
        });

        return list;
    }

    readonly property bool hasWindows: activeWindows.length > 0

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: contentRow.implicitWidth
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.activeWindows

            Item {
                id: taskItem
                required property var modelData

                readonly property bool isFocused: taskItem.modelData.isFocused
                readonly property bool isHovered: taskMouse.containsMouse

                width: 26
                height: 28
                implicitWidth: 26
                implicitHeight: 28

                // 1. Cápsula de fondo sutil (Tile activo / Hover Surface sin bordes sólidos)
                Rectangle {
                    id: activeTile
                    anchors.centerIn: parent
                    width: 26
                    height: 24
                    radius: 7

                    color: {
                        if (taskItem.isFocused) {
                            return taskMouse.pressed ? Qt.rgba(1, 1, 1, 0.16) : (taskItem.isHovered ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.10));
                        }
                        if (taskItem.isHovered) {
                            return Qt.rgba(1, 1, 1, 0.05);
                        }
                        return "transparent";
                    }

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }

                // 2. Icono a color de la aplicación (16x16 para centrado simétrico exacto de 5px a cada lado)
                IconImage {
                    id: appIcon
                    anchors.centerIn: activeTile
                    width: 16
                    height: 16
                    source: taskItem.modelData.iconSource
                    visible: taskItem.modelData.iconSource !== ""
                    opacity: taskItem.isFocused ? 1.0 : (taskItem.isHovered ? 0.95 : 0.72)

                    scale: taskMouse.pressed ? 0.90 : ((taskItem.isHovered && !taskItem.isFocused) ? 1.08 : 1.0)

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animFast
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.3
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animFast }
                    }
                }

                // 3. Fallback si no tiene icono temático SVG/PNG (100% centrado)
                Text {
                    anchors.centerIn: activeTile
                    visible: taskItem.modelData.iconSource === ""
                    text: ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: taskItem.isFocused ? Theme.text : (taskItem.isHovered ? Theme.text : Theme.textSecondary)
                    opacity: taskItem.isFocused ? 1.0 : (taskItem.isHovered ? 0.95 : 0.72)

                    scale: taskMouse.pressed ? 0.90 : ((taskItem.isHovered && !taskItem.isFocused) ? 1.08 : 1.0)

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animFast
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.3
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animFast }
                    }
                }

                MouseArea {
                    id: taskMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            // Clic izquierdo: Cambia al workspace donde reside la ventana y le da foco
                            root.focusWindow(taskItem.modelData.address, taskItem.modelData.workspaceId, taskItem.modelData.toplevel);
                        } else if (mouse.button === Qt.MiddleButton) {
                            // Clic central: Cerrar ventana
                            root.closeWindow(taskItem.modelData.address, taskItem.modelData.toplevel);
                        }
                    }
                }

                BarToolTip {
                    targetItem: taskItem
                    text: taskItem.modelData.title + (taskItem.modelData.workspaceId > 0 ? "  •  Workspace " + taskItem.modelData.workspaceId : "")
                    hovered: taskMouse.containsMouse
                }
            }
        }
    }
}
