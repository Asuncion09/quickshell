import QtQuick
import "../../theme"
import "../../services"

Item {
    id: root

    implicitWidth: 16
    implicitHeight: 26

    Text {
        id: iconLabel
        anchors.centerIn: parent
        text: PowerProfileService.icon
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
        color: PowerProfileService.accentColor
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        Behavior on color {
            ColorAnimation { duration: Theme.animNormal }
        }
    }
}
