import QtQuick
import Quickshell.Io
import "../../theme"
import "../../components"
import "../../services"

BarButton {
    id: root

    text: BluetoothService.icon
    pixelSize: Theme.fontSize
    defaultTextColor: BluetoothService.color
    hoverTextColor: Theme.highlight
    hoverBgColor: "transparent"
    tooltipText: BluetoothService.tooltipText
    implicitWidth: 22

    Process {
        id: btProc
        command: ["ghostty", "--class=com.floating.medium", "-e", "bluetui"]
    }

    onClicked: {
        if (!btProc.running) {
            btProc.running = true;
        }
    }
}

