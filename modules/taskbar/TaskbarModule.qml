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

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event) return;
            let n = event.name;
            if (n === "openwindow" || n === "closewindow" || n === "movewindow" || n === "movewindowv2"
             || n === "activewindow" || n === "activewindowv2" || n === "workspace"
             || n === "windowtitle" || n === "windowtitlev2") {
                root._eventVersion++;
            }
        }
    }

    // Procesos auxiliares de respaldo si Hyprland.dispatch no estuviera disponible
    Process {
        id: focusProc
        command: ["hyprctl", "dispatch", "focuswindow", "address:0x0"]
    }

    Process {
        id: closeProc
        command: ["hyprctl", "dispatch", "closewindow", "address:0x0"]
    }

    function focusWindow(address, workspaceId, toplevel) {
        // 1. Si la ventana está en otro workspace, cambiar primero al workspace correspondiente
        if (workspaceId > 0 && workspaceId !== root.currentWorkspaceId) {
            if (focusProc.running) focusProc.running = false;
            focusProc.command = ["hyprctl", "dispatch", "workspace", workspaceId.toString()];
            focusProc.running = true;
        }

        // 2. Intentar el método nativo Wayland si está presente
        if (toplevel && toplevel.wayland && typeof toplevel.wayland.activate === "function") {
            toplevel.wayland.activate();
        }

        // 3. Dispatch vía hyprctl para garantizar foco inmediato
        if (focusProc.running) focusProc.running = false;
        focusProc.command = ["hyprctl", "dispatch", "focuswindow", "address:" + address];
        focusProc.running = true;
    }

    function closeWindow(address, toplevel) {
        if (toplevel && toplevel.wayland && typeof toplevel.wayland.close === "function") {
            toplevel.wayland.close();
        }

        if (closeProc.running) closeProc.running = false;
        closeProc.command = ["hyprctl", "dispatch", "closewindow", "address:" + address];
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

        // Buscar en la base de datos de iconos del sistema
        for (let i = 0; i < candidates.length; i++) {
            let name = candidates[i];
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

        // Ordenar por workspace y luego alfabéticamente
        list.sort((a, b) => {
            if (a.workspaceId !== b.workspaceId) return a.workspaceId - b.workspaceId;
            return a.title.localeCompare(b.title);
        });

        return list;
    }

    readonly property bool hasWindows: activeWindows.length > 0

    implicitWidth: contentRow.implicitWidth
    implicitHeight: 26
    width: implicitWidth
    height: implicitHeight

    Row {
        id: contentRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: root.activeWindows

            Item {
                id: taskItem
                required property var modelData

                width: 26
                height: 26
                implicitWidth: 26
                implicitHeight: 26

                // Icono a color de la aplicación
                IconImage {
                    id: appIcon
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    source: taskItem.modelData.iconSource
                    visible: taskItem.modelData.iconSource !== ""
                    opacity: taskItem.modelData.isFocused ? 1.0 : (taskMouse.containsMouse ? 1.0 : 0.80)

                    scale: taskMouse.pressed ? 0.88 : ((taskMouse.containsMouse && !taskItem.modelData.isFocused) ? 1.15 : 1.0)

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animFast
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.4
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animFast }
                    }
                }

                // Fallback si no tiene icono temático SVG/PNG
                Text {
                    anchors.centerIn: parent
                    visible: taskItem.modelData.iconSource === ""
                    text: ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: taskItem.modelData.isFocused ? Theme.highlight : Theme.textSecondary

                    scale: taskMouse.pressed ? 0.88 : ((taskMouse.containsMouse && !taskItem.modelData.isFocused) ? 1.15 : 1.0)

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animFast
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.4
                        }
                    }
                }

                // Línea indicadora iluminada en la base:
                // SOLO aparece debajo de la ventana enfocada (sin marcos ni puntos adicionales)
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1.5
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: taskItem.modelData.isFocused ? 12 : 0
                    height: 2
                    radius: 1
                    color: Theme.highlight
                    visible: width > 0

                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.animNormal
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.3
                        }
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
