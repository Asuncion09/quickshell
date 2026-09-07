import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

Item {
    id: root

    implicitWidth: 280
    implicitHeight: 32
    Layout.fillWidth: true

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Píldora compacta de Batería (misma altura de 32px que el botón de bloqueo)
        Rectangle {
            id: batChip
            implicitHeight: 32
            implicitWidth: batLayout.implicitWidth + 18
            radius: 8
            color: batMouse.containsMouse ? "#262626" : "#1e1e1e"
            border.width: 0

            scale: batMouse.pressed ? 0.95 : 1.0
            Behavior on scale {
                NumberAnimation { duration: Theme.animFast }
            }
            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }

            RowLayout {
                id: batLayout
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: BatteryService.icon
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: BatteryService.color

                    scale: BatteryService.isCharging ? 1.1 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: Theme.animNormal }
                    }
                }

                Text {
                    text: `${BatteryService.percentage}%`
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.text
                }
            }

            MouseArea {
                id: batMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
            }
        }

        // Espaciador central
        Item {
            Layout.fillWidth: true
        }

        // Botón de Bloqueo de Pantalla (32x32)
        Rectangle {
            id: lockBtn
            implicitWidth: 32
            implicitHeight: 32
            radius: 8
            color: lockMouse.containsMouse ? "#2e3440" : "#1e1e1e"
            border.width: 0

            scale: lockMouse.pressed ? 0.92 : 1.0
            Behavior on scale {
                NumberAnimation { duration: Theme.animFast }
            }
            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }

            Text {
                anchors.centerIn: parent
                text: "󰌾"
                font.family: Theme.fontFamily
                font.pixelSize: 14
                color: lockMouse.containsMouse ? Theme.highlight : Theme.textSecondary

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
            }

            MouseArea {
                id: lockMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ControlCenterService.lockScreen()
            }
        }
    }
}
