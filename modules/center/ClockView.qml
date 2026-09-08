import QtQuick
import "../../theme"
import "../../components"
import "../../services"

Item {
    id: root

    property date currentDate: new Date()
    readonly property bool isHovered: mouseArea.containsMouse

    readonly property string timeString: Qt.formatDateTime(currentDate, "hh:mm AP")
    readonly property string dateString: Qt.formatDateTime(currentDate, "ddd, dd MMM")

    implicitWidth: contentRow.implicitWidth
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.currentDate = new Date();
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 8

            scale: mouseArea.pressed ? 0.96 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.animFast
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                id: dateLabel
                anchors.verticalCenter: parent.verticalCenter
                text: root.dateString
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
                color: Theme.textSecondary
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: separator
                anchors.verticalCenter: parent.verticalCenter
                text: "•"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                font.weight: Font.Normal
                color: Theme.textMuted
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: timeLabel
                anchors.verticalCenter: parent.verticalCenter
                text: root.timeString
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.ExtraBold
                color: Theme.highlight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    signal wakeMediaRequested()
    signal wheelRequested()

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton || mouse.button === Qt.RightButton) {
                // Alterna el Centro de Notificaciones nativo de Quickshell
                NotificationService.toggleCenter();
            } else if (mouse.button === Qt.MiddleButton) {
                // Clic central (rueda del ratón): Despierta el reproductor multimedia si hay música en pausa
                root.wakeMediaRequested();
            }
        }

        onWheel: wheel => {
            wheel.accepted = true;
            root.wheelRequested();
        }
    }
}

