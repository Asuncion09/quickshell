import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"

// Tarjeta de confirmación de clave / passkey (SSP) para emparejamiento Bluetooth.
// Autocontenida: consume el estado y las acciones directamente de ControlCenterService.
Rectangle {
    id: root
    Layout.fillWidth: true
    visible: ControlCenterService.hasPasskeyPrompt
    implicitHeight: passkeyCol.implicitHeight + 20
    radius: 10
    color: Theme.surfaceBase
    border.width: 0

    ColumnLayout {
        id: passkeyCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "󰂱"
                font.family: Theme.fontFamily
                font.pixelSize: 18
                color: Theme.wsActiveColor
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: ControlCenterService.promptDeviceName || "Bluetooth Device"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Theme.text
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: "Pairing Request"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.textMuted
                }
            }
        }

        // Bloque visual de dígitos
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 5

            Repeater {
                model: {
                    let code = ControlCenterService.promptPasskey || "------";
                    return code.split("");
                }

                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 36
                    radius: 6
                    color: Theme.bgDark
                    border.width: 0

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Theme.fontFamily
                        font.pixelSize: 17
                        font.weight: Font.Bold
                        color: Theme.wsActiveColor
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: (ControlCenterService.promptType === "display_pin" || ControlCenterService.promptType === "display_passkey")
                  ? "Enter this code on the device"
                  : "Does it match the code on your screen?"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.textSecondary
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                id: rejectBtn
                Layout.fillWidth: true
                implicitHeight: 32
                radius: 8
                color: rejectMouse.containsMouse ? Theme.surfaceHover : Theme.bgDark
                border.width: 0
                border.color: Theme.critical

                Text {
                    anchors.centerIn: parent
                    text: "Decline"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: rejectMouse.containsMouse ? Theme.critical : Theme.textSecondary
                }

                MouseArea {
                    id: rejectMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ControlCenterService.rejectPasskey()
                }
            }

            Rectangle {
                id: confirmBtn
                Layout.fillWidth: true
                implicitHeight: 32
                radius: 8
                color: Theme.wsActiveColor
                border.width: 0
                border.color: Theme.textBright

                Text {
                    anchors.centerIn: parent
                    text: "Confirm"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Theme.textOnAccent
                }

                MouseArea {
                    id: confirmMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ControlCenterService.confirmPasskey()
                }
            }
        }
    }
}
