import QtQuick
import "../../theme"
import "../../services"

Item {
    id: root

    implicitWidth: 20
    implicitHeight: 26

    Text {
        id: iconLabel
        anchors.centerIn: parent
        text: BatteryService.icon
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: BatteryService.color
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        Behavior on color {
            ColorAnimation { duration: Theme.animNormal }
        }
    }

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
