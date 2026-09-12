import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../../theme"
import "../../components"
import "../../services"
import "../center"

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: -1

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: Theme.barMarginTop
        bottom: 0
        left: 0
        right: 0
    }

    implicitHeight: 60
    color: "transparent"

    // Máscara interactiva y de renderizado:
    // Solo la cápsula del OSD está en la máscara; el resto de la pantalla (99%) es transparente y permeable al ratón
    mask: Region {
        Region {
            item: osdPill
        }
    }

    readonly property string monitorName: root.screen ? root.screen.name : ""
    property bool isFullscreen: false

    function checkFullscreen() {
        let found = false;
        let mon = root.monitorName;
        let screenActiveWsId = -1;

        // 1. Identificar el workspace activo asignado a esta pantalla física
        if (Hyprland.monitors && Hyprland.monitors.values) {
            for (let i = 0; i < Hyprland.monitors.values.length; i++) {
                let m = Hyprland.monitors.values[i];
                if (m && m.name === mon && m.activeWorkspace) {
                    screenActiveWsId = m.activeWorkspace.id;
                    break;
                }
            }
        }

        // Fallback para pantalla única o si m.activeWorkspace aún no se ha poblado
        if (screenActiveWsId === -1) {
            if (mon === "HDMI-A-1") {
                screenActiveWsId = 4;
            } else if (mon === "eDP-1") {
                screenActiveWsId = 1;
            } else if (Hyprland.focusedWorkspace) {
                screenActiveWsId = Hyprland.focusedWorkspace.id;
            } else {
                screenActiveWsId = 1;
            }
        }

        // 2. Revisar si alguna ventana en el workspace activo de esta pantalla está en fullscreen
        if (Hyprland.toplevels && Hyprland.toplevels.values) {
            for (let i = 0; i < Hyprland.toplevels.values.length; i++) {
                let top = Hyprland.toplevels.values[i];
                if (!top) continue;
                let ipc = top.lastIpcObject || {};
                let windowWs = top.workspace ? top.workspace.id : (ipc.workspace ? ipc.workspace.id : -1);

                if (windowWs === screenActiveWsId) {
                    let isFs = (ipc.fullscreen === 1 || ipc.fullscreen === 2 || ipc.fullscreen === true || top.fullscreen === true || top.fullscreen === 1);
                    if (isFs) {
                        found = true;
                        break;
                    }
                }
            }
        }

        // 3. Comprobar si el workspace de esta pantalla reporta hasFullscreen en Hyprland.workspaces
        if (!found && Hyprland.workspaces && Hyprland.workspaces.values) {
            for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                let ws = Hyprland.workspaces.values[i];
                if (ws && ws.id === screenActiveWsId && ws.hasFullscreen) {
                    found = true;
                    break;
                }
            }
        }

        // 4. Comprobar si este monitor es el enfocado y focusedWorkspace reporta hasFullscreen
        if (!found && Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === screenActiveWsId && Hyprland.focusedWorkspace.hasFullscreen) {
            found = true;
        }

        root.isFullscreen = found;

        // 5. Proceso asíncrono con hyprctl y jq como confirmación de respaldo contextualizada por monitor
        if (mon !== "") {
            fsProc.command = [
                "sh",
                "-c",
                "WS=$(hyprctl monitors -j | jq -r --arg M '" + mon + "' '.[] | select(.name==$M) | .activeWorkspace.id'); [ -n \"$WS\" ] && hyprctl workspaces -j | jq -r --argjson W \"$WS\" '.[] | select(.id==$W) | .hasfullscreen'"
            ];
            if (!fsProc.running) {
                fsProc.running = true;
            }
        }
    }

    Process {
        id: fsProc
        stdout: SplitParser {
            onRead: data => {
                let s = data.trim();
                if (s === "true") {
                    root.isFullscreen = true;
                } else if (s === "false") {
                    root.isFullscreen = false;
                }
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event || !OsdService.isVisible) return;
            let n = event.name;
            if (n === "fullscreen" || n === "activewindow" || n === "activewindowv2" || n === "workspace" || n === "focusedmon") {
                root.checkFullscreen();
            }
        }
    }

    Connections {
        target: OsdService
        function onIsVisibleChanged() {
            if (OsdService.isVisible) {
                root.checkFullscreen();
            }
        }
    }

    Component.onCompleted: {
        root.checkFullscreen();
    }

    readonly property bool shouldShow: OsdService.isVisible && root.isFullscreen
    visible: shouldShow || osdPillWrapper.opacity > 0.001

    RowLayout {
        id: osdPillWrapper
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        z: 100

        opacity: root.shouldShow ? 1.0 : 0.0
        scale: opacity > 0.01 ? 1.0 : 0.94
        y: root.shouldShow ? 0 : -8

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutQuad
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutQuad
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutQuad
            }
        }

        Pill {
            id: osdPill
            animateSize: false
            paddingHorizontal: 8
            customBorderColor: (OsdService.mode === "volume" && OsdService.value > 100 && !OsdService.isMuted) ? Qt.rgba(241/255, 196/255, 15/255, 0.45) : null

            OsdIslandView {
                id: osdView
            }
        }
    }
}
