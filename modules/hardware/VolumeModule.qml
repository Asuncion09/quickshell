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
        text: AudioService.icon
        font.family: Theme.fontFamily
        font.pixelSize: 14
        color: AudioService.isMuted ? Theme.critical : Theme.text
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        Behavior on color {
            ColorAnimation { duration: Theme.animNormal }
        }
    }
}
