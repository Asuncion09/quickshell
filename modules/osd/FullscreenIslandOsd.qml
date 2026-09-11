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

    property bool isFullscreen: false

    function checkFullscreen() {
        let found = false;
        let reason = "none";
        let activeWsId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1;

        // 1. Revisar si alguna ventana en el workspace activo está en fullscreen
        if (Hyprland.toplevels && Hyprland.toplevels.values) {
            for (let i = 0; i < Hyprland.toplevels.values.length; i++) {
                let top = Hyprland.toplevels.values[i];
                if (!top) continue;
                let ipc = top.lastIpcObject || {};
                let windowWs = top.workspace ? top.workspace.id : (ipc.workspace ? ipc.workspace.id : -1);

                if (windowWs === activeWsId && (ipc.fullscreen === 1 || ipc.fullscreen === 2 || ipc.fullscreen === true)) {
                    found = true;
                    reason = "toplevel on active ws:" + (ipc.title || top.title || ipc.class);
                    break;
                }
            }
        }

        // 2. Comprobar si el workspace enfocado reporta hasFullscreen
        if (!found && Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.hasFullscreen) {
            found = true;
            reason = "focusedWorkspace.hasFullscreen";
        }

        root.isFullscreen = found;

        // 3. Proceso asíncrono con hyprctl y jq como confirmación de respaldo
        if (!fsProc.running) {
            fsProc.running = true;
        }
    }

    Process {
        id: fsProc
        command: ["sh", "-c", "hyprctl activeworkspace -j | jq -r .hasfullscreen"]
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
            if (!event) return;
            let n = event.name;
            if (n === "fullscreen") {
                let val = (event.data || "").trim();
                root.isFullscreen = (val === "1" || val === "true");
            } else if (n === "activewindow" || n === "activewindowv2" || n === "workspace") {
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
