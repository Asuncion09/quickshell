import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import "../../theme"

RowLayout {
    id: root

    spacing: 2

    // Proceso auxiliar para garantizar el cambio de workspace mediante hyprctl en cualquier circunstancia
    Process {
        id: wsProcess
        command: ["hyprctl", "dispatch", "workspace", "1"]
    }

    // Función robusta para cambiar de workspace
    function switchToWorkspace(id) {
        // 1. Invocar el método nativo activate() en el objeto del workspace si existe
        if (Hyprland.workspaces && Hyprland.workspaces.values) {
            for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                let ws = Hyprland.workspaces.values[i];
                if (ws && ws.id === id && typeof ws.activate === "function") {
                    ws.activate();
                }
            }
        }

        // 2. Ejecutar hyprctl dispatch para garantizar el cambio al 100%
        wsProcess.command = ["hyprctl", "dispatch", "workspace", id.toString()];
        if (!wsProcess.running) {
            wsProcess.running = true;
        }
    }

    // Contador reactivo para forzar reevaluación inmediata ante eventos de ventanas en Hyprland
    property int _eventVersion: 0

    readonly property int _toplevelsCount: (Hyprland.toplevels && Hyprland.toplevels.values) ? Hyprland.toplevels.values.length : 0
    readonly property int _workspacesCount: (Hyprland.workspaces && Hyprland.workspaces.values) ? Hyprland.workspaces.values.length : 0

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event) return;
            let n = event.name;
            if (n === "openwindow"
             || n === "closewindow"
             || n === "movewindow"
             || n === "activewindow"
             || n === "activewindowv2"
             || n === "workspace"
             || n === "createworkspace"
             || n === "destroyworkspace"
             || n === "urgent") {
                root._eventVersion++;
                if (typeof Hyprland.refreshWorkspaces === "function") {
                    Hyprland.refreshWorkspaces();
                }
            }
        }
    }

    // Determina si un toplevel es una ventana real o un popup/dummy/superficie vacía
    function isRealWindow(top) {
        if (!top) return false;

        let ipc = top.lastIpcObject || {};
        if (ipc.mapped === false || ipc.hidden === true) return false;

        let windowWs = top.workspace ? top.workspace.id : (ipc.workspace ? ipc.workspace.id : -1);
        if (windowWs <= 0) return false;

        // Descartar ventanas dummy / auxiliares de 1x1 o 0x0
        if (ipc.size && Array.isArray(ipc.size)) {
            if (ipc.size[0] <= 1 && ipc.size[1] <= 1) return false;
        }

        let rawTitle = ((top.title !== undefined && top.title !== null) ? top.title : (ipc.title || "")).trim();
        let appClass = (ipc.class || (top.wayland ? top.wayland.appId : "") || "").trim();
        let lowerClass = appClass.toLowerCase();
        let lowerTitle = rawTitle.toLowerCase();

        // 1. Filtrar popups, tooltips y menús hover de Steam
        if (lowerClass.includes("steam")) {
            if (rawTitle === "") return false;
            if (lowerTitle.includes("notificationtoasts")) return false;
            if (lowerTitle === "special" || lowerClass === "steamwebhelper") return false;
        }

        // 2. Ventanas sin clase ni título (fantasmas o auxiliares de arrastre)
        if (appClass === "" && rawTitle === "") return false;

        // 3. Ventanas XWayland sin título
        if (ipc.xwayland && rawTitle === "") return false;

        return true;
    }

    // Comprueba si un workspace específico contiene ventanas abiertas
    function hasWindows(wsId) {
        // 1. Comprobar a través del objeto Workspace registrado en Hyprland
        if (Hyprland.workspaces && Hyprland.workspaces.values) {
            for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                let ws = Hyprland.workspaces.values[i];
                if (ws && ws.id === wsId) {
                    if (ws.toplevels && ws.toplevels.values) {
                        for (let j = 0; j < ws.toplevels.values.length; j++) {
                            let top = ws.toplevels.values[j];
                            if (root.isRealWindow(top)) return true;
                        }
                    }
                }
            }
        }

        // 2. Comprobar directamente en la lista de toplevels (ventanas abiertas)
        if (Hyprland.toplevels && Hyprland.toplevels.values) {
            for (let i = 0; i < Hyprland.toplevels.values.length; i++) {
                let top = Hyprland.toplevels.values[i];
                if (!root.isRealWindow(top)) continue;

                let windowWs = top.workspace ? top.workspace.id : (top.lastIpcObject && top.lastIpcObject.workspace ? top.lastIpcObject.workspace.id : -1);
                if (windowWs === wsId) {
                    return true;
                }
            }
        }

        return false;
    }

    // Lista de IDs: incluye persistentemente los workspaces 1 al 5 + cualquier otro abierto
    readonly property var workspaceIds: {
        let _dep = root._eventVersion + root._workspacesCount;
        let set = new Set([1, 2, 3, 4, 5]);

        if (Hyprland.workspaces && Hyprland.workspaces.values) {
            for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                let ws = Hyprland.workspaces.values[i];
                if (ws && ws.id > 0) {
                    set.add(ws.id);
                }
            }
        }

        if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) {
            set.add(Hyprland.focusedWorkspace.id);
        }

        return Array.from(set).sort((a, b) => a - b);
    }

    Repeater {
        model: root.workspaceIds

        // Contenedor con área de clic ampliada para facilitar la interacción
        Item {
            id: wsButton

            required property int modelData

            readonly property int wsId: modelData
            readonly property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId

            // Comprobación reactiva de si contiene ventanas abiertas
            readonly property bool isOccupied: {
                let _dep = root._eventVersion + root._toplevelsCount + root._workspacesCount;
                return root.hasWindows(wsId);
            }
            
            // Comprobación de estado urgente
            readonly property bool isUrgent: {
                let _dep = root._eventVersion;
                if (!Hyprland.workspaces || !Hyprland.workspaces.values) return false;
                for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                    let ws = Hyprland.workspaces.values[i];
                    if (ws && ws.id === wsId && ws.urgent) return true;
                }
                return false;
            }

            implicitWidth: wsPill.implicitWidth + 6
            implicitHeight: 26

            // Píldora visual centrada
            Rectangle {
                id: wsPill
                anchors.centerIn: parent

                implicitWidth: wsButton.isActive ? Theme.wsActiveWidth : Theme.wsInactiveWidth
                implicitHeight: Theme.wsHeight
                radius: Theme.wsRadius

                color: {
                    if (wsButton.isActive) return Theme.wsActiveColor;
                    if (wsButton.isUrgent) return Theme.wsUrgentColor;
                    if (wsButton.isOccupied) return Theme.wsOccupiedColor;
                    return Theme.wsEmptyColor;
                }

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: Theme.animWorkspaces
                        easing.type: Easing.OutCubic
                    }
                }

                scale: wsMouse.pressed ? 0.78 : (wsMouse.containsMouse && !wsButton.isActive ? 1.25 : 1.0)

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.animFast
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.5
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animWorkspaces
                    }
                }
            }

            MouseArea {
                id: wsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    root.switchToWorkspace(wsButton.wsId);
                }
            }
        }
    }
}
