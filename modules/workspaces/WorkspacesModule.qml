import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../theme"

RowLayout {
    id: root

    spacing: 2
    Layout.alignment: Qt.AlignVCenter

    // Ancho fijo de cada casilla de workspace: garantiza que todos los slots permanezcan en su coordenada fija (sin desplazamientos laterales)
    readonly property int slotWidth: Theme.wsActiveWidth

    // Ancho total constante del módulo basado en la cuadrícula de casillas fijas
    readonly property int stableWidth: {
        let count = root.workspaceIds.length;
        if (count <= 0) return 0;
        return (count * root.slotWidth) + ((count - 1) * root.spacing);
    }

    implicitWidth: stableWidth
    Layout.preferredWidth: stableWidth
    width: stableWidth

    // Proceso auxiliar para garantizar el cambio de workspace mediante hyprctl en cualquier circunstancia
    Process {
        id: wsProcess
        command: ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = 1 })"]
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
        if (wsProcess.running) wsProcess.running = false;
        wsProcess.command = ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + id + " })"];
        wsProcess.running = true;
    }

    // Contador reactivo para forzar reevaluación inmediata ante eventos de ventanas en Hyprland
    property int _eventVersion: 0

    readonly property int _toplevelsCount: (Hyprland.toplevels && Hyprland.toplevels.values) ? Hyprland.toplevels.values.length : 0
    readonly property int _workspacesCount: (Hyprland.workspaces && Hyprland.workspaces.values) ? Hyprland.workspaces.values.length : 0

    // Monitor al que pertenece esta barra
    property string monitorName: ""
    onMonitorNameChanged: root.updateWorkspaceIds()

    // Workspace activo visible actualmente en esta pantalla
    property int currentScreenActiveWs: 1

    function updateActiveWsFromFocus() {
        if (Hyprland.focusedWorkspace) {
            let fWs = Hyprland.focusedWorkspace.id;
            if (root.workspaceIds && root.workspaceIds.includes(fWs)) {
                root.currentScreenActiveWs = fWs;
            }
        }
    }

    // Caché estable de IDs de workspaces para evitar que el Repeater destruya/recree delegados
    property var _cachedWorkspaceIds: [1, 2, 3, 4, 5]

    function updateWorkspaceIds() {
        let screensCount = (Hyprland.monitors && Hyprland.monitors.values && Hyprland.monitors.values.length > 0)
            ? Hyprland.monitors.values.length
            : (Quickshell.screens ? Quickshell.screens.length : 1);

        let list = [];

        if (screensCount > 1 && root.monitorName !== "") {
            // Monitor primario / laptop (eDP): exactamente 3 workspaces [1, 2, 3]
            if (root.monitorName.indexOf("eDP") !== -1 || root.monitorName === "eDP-1") {
                list = [1, 2, 3];
            } else {
                // Monitor secundario (HDMI, DP, USB-C): exactamente 2 workspaces [4, 5]
                // Soporte para futuras pantallas adicionales:
                let monIndex = 1;
                if (Quickshell.screens && Quickshell.screens.values) {
                    for (let i = 0; i < Quickshell.screens.values.length; i++) {
                        if (Quickshell.screens.values[i].name === root.monitorName) {
                            monIndex = i;
                            break;
                        }
                    }
                }
                if (monIndex <= 1) {
                    list = [4, 5];
                } else {
                    list = [(monIndex * 2) + 2, (monIndex * 2) + 3];
                }
            }
        } else {
            // Una sola pantalla conectada (pantalla única o laptop sola):
            // Muestra los 5 workspaces completos
            list = [1, 2, 3, 4, 5];
        }

        let arr = list.slice().sort((a, b) => a - b);
        if (arr.length !== root._cachedWorkspaceIds.length || !arr.every((v, idx) => v === root._cachedWorkspaceIds[idx])) {
            root._cachedWorkspaceIds = arr;
        }

        // Si el workspace activo ya no pertenece a la lista visible, ajustar
        if (!root._cachedWorkspaceIds.includes(root.currentScreenActiveWs)) {
            if (Hyprland.focusedWorkspace && root._cachedWorkspaceIds.includes(Hyprland.focusedWorkspace.id)) {
                root.currentScreenActiveWs = Hyprland.focusedWorkspace.id;
            } else if (root._cachedWorkspaceIds.length > 0) {
                root.currentScreenActiveWs = root._cachedWorkspaceIds[0];
            }
        }
    }

    Component.onCompleted: {
        root.updateWorkspaceIds();
        // Inicializar workspace activo para esta pantalla
        let found = false;
        if (Hyprland.monitors && Hyprland.monitors.values) {
            for (let i = 0; i < Hyprland.monitors.values.length; i++) {
                let m = Hyprland.monitors.values[i];
                if (m && m.name === root.monitorName && m.activeWorkspace && m.activeWorkspace.id) {
                    if (root.workspaceIds.includes(m.activeWorkspace.id)) {
                        root.currentScreenActiveWs = m.activeWorkspace.id;
                        found = true;
                        break;
                    }
                }
            }
        }
        if (!found) {
            root.updateActiveWsFromFocus();
        }
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            root.updateActiveWsFromFocus();
        }
        function onRawEvent(event) {
            if (!event) return;
            let n = event.name;
            if (n === "createworkspace" || n === "destroyworkspace" || n === "monitoradded" || n === "monitorremoved" || n === "moveworkspacetomonitor") {
                root.updateWorkspaceIds();
            }
            if (n === "workspace" || n === "focusedmon") {
                root.updateActiveWsFromFocus();
            }
            if (n === "openwindow"
             || n === "closewindow"
             || n === "movewindow"
             || n === "activewindow"
             || n === "activewindowv2"
             || n === "workspace"
             || n === "focusedmon"
             || n === "createworkspace"
             || n === "destroyworkspace"
             || n === "moveworkspacetomonitor"
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

    // Lista de IDs: proviene de la caché estable para evitar reinicializar delegados del Repeater
    readonly property var workspaceIds: root._cachedWorkspaceIds

    Repeater {
        model: root.workspaceIds

        // Contenedor de ancho fijo (cuadrícula rítmica constante donde ningún slot se desplaza)
        Item {
            id: wsButton

            required property int modelData

            readonly property int wsId: modelData
            readonly property bool isDisplayed: root.currentScreenActiveWs === wsId
            readonly property bool hasKeyboardFocus: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId

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

            implicitWidth: root.slotWidth
            implicitHeight: 26
            Layout.preferredWidth: root.slotWidth
            Layout.preferredHeight: 26
            width: root.slotWidth
            height: 26

            // Píldora visual centrada
            Rectangle {
                id: wsPill
                anchors.centerIn: parent

                implicitWidth: wsButton.isDisplayed ? Theme.wsActiveWidth : Theme.wsInactiveWidth
                implicitHeight: Theme.wsHeight
                radius: Theme.wsRadius

                color: {
                    if (wsButton.isUrgent) return Theme.wsUrgentColor;
                    if (wsButton.isDisplayed) {
                        // Si está visible en este monitor y además tiene el foco de teclado: color activo pleno
                        // Si está visible en este monitor pero el teclado está en la otra pantalla: color activo al 65% de presencia
                        if (wsButton.hasKeyboardFocus) {
                            return Theme.wsActiveColor;
                        } else {
                            return Qt.rgba(Theme.wsActiveColor.r, Theme.wsActiveColor.g, Theme.wsActiveColor.b, 0.65);
                        }
                    }
                    if (wsButton.isOccupied) return Theme.wsOccupiedColor;
                    return Theme.wsEmptyColor;
                }

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: Theme.animWorkspaces
                        easing.type: Easing.OutCubic
                    }
                }

                scale: wsMouse.pressed ? 0.78 : (wsMouse.containsMouse && !wsButton.isDisplayed ? 1.25 : 1.0)

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
