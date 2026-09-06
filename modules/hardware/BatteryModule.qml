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
    implicitWidth: 18

    // Animación suave de pulsación solo en estado crítico (<15%)
    SequentialAnimation on opacity {
        running: BatteryService.isCritical
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation {
            to: 0.35
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
