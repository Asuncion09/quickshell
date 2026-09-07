import QtQuick
import "../../theme"
import "../../components"
import "../../services"

Item {
    id: root

    implicitWidth: 20
    implicitHeight: 26
    width: implicitWidth
    height: implicitHeight

    Text {
        id: iconText
        anchors.centerIn: parent
        text: AudioService.icon
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: AudioService.isMuted 
               ? Theme.critical 
               : (mouseArea.containsMouse ? Theme.highlight : Theme.text)

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton || mouse.button === Qt.RightButton) {
                AudioService.toggleMute();
            }
        }

        onWheel: wheel => {
            wheel.accepted = true;
            if (wheel.angleDelta.y > 0) {
                AudioService.increaseVolume(2);
            } else if (wheel.angleDelta.y < 0) {
                AudioService.decreaseVolume(2);
            }
        }
    }

    BarToolTip {
        targetItem: root
        text: AudioService.isMuted 
              ? "Audio: Silenciado" 
              : "Volumen: " + AudioService.currentPercent + "%"
        hovered: mouseArea.containsMouse
    }
}
