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
        text: NetworkService.icon
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: NetworkService.color
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        Behavior on color {
            ColorAnimation { duration: Theme.animNormal }
        }
    }
}
