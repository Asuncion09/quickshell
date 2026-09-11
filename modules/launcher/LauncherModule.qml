import QtQuick
import Quickshell
import "../../theme"
import "../../components"
import "../../services"

BarButton {
    id: root

    text: ""
    pixelSize: Theme.launcherFontSize
    defaultTextColor: LauncherService.isOpen ? Theme.wsActiveColor : Theme.text
    hoverTextColor: Theme.highlight
    hoverBgColor: "transparent"
    tooltipText: "Application launcher (Super + Space)"
    implicitWidth: 22

    onClicked: {
        LauncherService.toggle();
    }
}


