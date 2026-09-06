import QtQuick
import Quickshell.Io
import "../../theme"
import "../../components"
import "../../services"

BarButton {
    id: root

    text: NetworkService.icon
    pixelSize: Theme.fontSize
    defaultTextColor: NetworkService.color
    hoverTextColor: Theme.highlight
    hoverBgColor: "transparent"
    tooltipText: NetworkService.tooltipText
    implicitWidth: 18

    Process {
        id: netProc
        command: ["nmrs-gui"]
    }

    onClicked: {
        if (!netProc.running) {
            netProc.running = true;
        }
    }
}
