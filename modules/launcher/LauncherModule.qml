import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"

BarButton {
    id: root

    text: ""
    pixelSize: Theme.launcherFontSize
    defaultTextColor: Theme.text
    hoverTextColor: Theme.highlight
    hoverBgColor: "transparent"
    tooltipText: "Lanzador de aplicaciones"
    implicitWidth: 22

    Process {
        id: launcherProc
        command: [Quickshell.env("HOME") + "/.config/rofi/launcher.sh"]
    }

    onClicked: {
        if (!launcherProc.running) {
            launcherProc.running = true;
        }
    }
}

