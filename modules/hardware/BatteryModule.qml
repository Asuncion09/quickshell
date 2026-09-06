import QtQuick
import "../../theme"
import "../../components"
import "../../services"

BarButton {
    id: root

    text: BatteryService.icon
    pixelSize: Theme.fontSize
    defaultTextColor: BatteryService.color
    hoverTextColor: Theme.highlight
    hoverBgColor: "transparent"
    tooltipText: BatteryService.tooltipText
    implicitWidth: 22

    // Animación de parpadeo idéntica a @keyframes blink de Waybar cuando la batería está crítica (<15%)
    SequentialAnimation on opacity {
        running: BatteryService.isCritical
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation {
            to: 0.25
            duration: 500
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            to: 1.0
            duration: 500
            easing.type: Easing.InOutQuad
        }
    }
}

