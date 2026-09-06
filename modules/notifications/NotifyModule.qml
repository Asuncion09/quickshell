import QtQuick
import Quickshell.Io
import "../../theme"
import "../../components"

BarButton {
    id: root

    text: ""
    pixelSize: Theme.fontSize
    defaultTextColor: Theme.text
    hoverTextColor: Theme.highlight
    hoverBgColor: "transparent"
    tooltipText: "Notificaciones"
    implicitWidth: 24

    Process {
        id: swayncProc
        command: ["swaync-client", "-t", "-sw"]
    }

    onClicked: {
        if (!swayncProc.running) {
            swayncProc.running = true;
        }
    }
}

