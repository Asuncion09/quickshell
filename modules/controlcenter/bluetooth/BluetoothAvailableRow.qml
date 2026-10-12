import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"

// Fila de dispositivo Bluetooth descubierto y disponible (sección "Available devices").
Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: 34
    radius: 8

    property var deviceData
    property string icon: ""
    property bool isKeyFocused: false

    color: isKeyFocused ? Theme.surfaceKeyFocus : (availMouse.containsMouse ? Theme.surfaceHover : "transparent")
    border.width: isKeyFocused ? 1.5 : 0
    border.color: Theme.highlight

    scale: availMouse.pressed ? 0.98 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
    Behavior on border.width { NumberAnimation { duration: 40 } }
    Behavior on border.color { ColorAnimation { duration: 40 } }
    Behavior on color { ColorAnimation { duration: availMouse.containsMouse ? Theme.animFast : 40 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Text {
            text: root.icon
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: availMouse.containsMouse ? Theme.text : Theme.textSecondary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.deviceData.name || root.deviceData.deviceName || root.deviceData.address || "Device"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: Theme.text
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: ControlCenterService.connectingMac === root.deviceData.address
                text: "Pairing..."
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.wsActiveColor
            }
        }

        Text {
            text: ControlCenterService.connectingMac === root.deviceData.address ? "..." : "Pair"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            color: availMouse.containsMouse ? Theme.wsActiveColor : Theme.textMuted
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: availMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            ControlCenterService.pairAndTrustBluetooth(root.deviceData.address);
        }
    }
}
