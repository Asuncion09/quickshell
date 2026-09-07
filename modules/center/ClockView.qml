import QtQuick
import Quickshell.Io
import "../../theme"
import "../../components"

Item {
    id: root

    property date currentDate: new Date()
    property bool showDate: false
    readonly property bool isHovered: mouseArea.containsMouse

    readonly property string timeString: Qt.formatDateTime(currentDate, "hh:mm AP")
    readonly property string dateString: Qt.formatDateTime(currentDate, "ddd, dd MMM")

    readonly property string activeText: showDate ? dateString : timeString

    implicitWidth: textLabel.implicitWidth
    implicitHeight: 26
    width: implicitWidth
    height: implicitHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutCubic
        }
    }

    // Proceso para abrir/cerrar el panel de SwayNC (Notificaciones + Calendario)
    Process {
        id: swayncProc
        command: ["swaync-client", "-t", "-sw"]
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

        Text {
            id: textLabel
            anchors.centerIn: parent

            text: root.activeText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Font.ExtraBold

            color: Theme.highlight
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter

            scale: mouseArea.pressed ? 0.96 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.animFast
                    easing.type: Easing.OutQuad
                }
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
            if (mouse.button === Qt.LeftButton) {
                // Clic izquierdo: Abre/cierra el Centro de Notificaciones y Calendario
                if (swayncProc.running) {
                    swayncProc.running = false;
                }
                swayncProc.running = true;
            } else if (mouse.button === Qt.RightButton) {
                // Clic derecho: Alterna rápidamente entre hora y fecha en la barra
                root.showDate = !root.showDate;
            } else if (mouse.button === Qt.MiddleButton) {
                // Clic central (rueda ratón / toque 3 dedos): Despierta la música pausada
                root.wakeMediaRequested();
            }
        }

        onWheel: wheel => {
            wheel.accepted = true;
            root.wheelRequested();
        }
    }
}
