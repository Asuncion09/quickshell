import QtQuick
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
        command: ["/home/daniel/.config/rofi/launcher.sh"]
    }

    onClicked: {
        if (!launcherProc.running) {
            launcherProc.running = true;
        }
    }
}

