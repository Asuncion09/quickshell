import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"

// Fila de dispositivo Bluetooth emparejado/conectado (sección "Paired devices").
Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: 34
    radius: 8

    property var deviceData
    property string icon: ""
    property bool isKeyFocused: false

    color: {
        if (deviceData.connected) {
            return (rowMouse.containsMouse || isKeyFocused) ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.05);
        }
        if (isKeyFocused) return Theme.surfaceKeyFocus;
        return rowMouse.containsMouse ? Theme.surfaceHover : "transparent";
    }
    border.width: isKeyFocused ? 1.5 : (deviceData.connected ? 1 : 0)
    border.color: isKeyFocused ? (deviceData.connected ? Qt.rgba(1, 1, 1, 0.85) : Theme.highlight) : Qt.rgba(1, 1, 1, 0.08)

    scale: rowMouse.pressed ? 0.98 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
    Behavior on border.width { NumberAnimation { duration: 40 } }
    Behavior on border.color { ColorAnimation { duration: 40 } }
    Behavior on color { ColorAnimation { duration: rowMouse.containsMouse ? Theme.animFast : 40 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Text {
            text: root.icon
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: root.deviceData.connected ? Theme.wsActiveColor : (rowMouse.containsMouse ? Theme.text : Theme.textSecondary)
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.deviceData.name || root.deviceData.deviceName || root.deviceData.address || "Device"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: root.deviceData.connected ? Font.DemiBold : Font.Normal
                color: Theme.text
                elide: Text.ElideRight
            }

            // Subtítulo condicional de estado "Conectando..."
            Text {
                Layout.fillWidth: true
                visible: ControlCenterService.connectingMac === root.deviceData.address
                text: "Connecting..."
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.wsActiveColor
            }
        }

        // Indicador de Batería (SOLO SI EL DISPOSITIVO ENVÍA EL NIVEL)
        Item {
            id: batBadge
            readonly property int batLevel: ControlCenterService.getDeviceBattery(root.deviceData.address)
            visible: root.deviceData.connected && batLevel >= 0
            implicitWidth: visible ? batRow.implicitWidth : 0
            implicitHeight: visible ? 18 : 0
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                id: batRow
                anchors.centerIn: parent
                spacing: 3

                Text {
                    text: "󰁹"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: batBadge.batLevel <= 20 ? Theme.critical : (batBadge.batLevel <= 40 ? Theme.warning : Theme.success)
                }

                Text {
                    text: `${batBadge.batLevel}%`
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.textSecondary
                }
            }
        }

        // Estado de conexión (badge con punto esmeralda)
        RowLayout {
            visible: root.deviceData.connected && ControlCenterService.connectingMac !== root.deviceData.address
            spacing: 5
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: Theme.success
            }

            Text {
                text: "Connected"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Theme.textSecondary
            }
        }

        // Botón discreto de "Olvidar / Desvincular"
        Rectangle {
            id: forgetBtn
            implicitWidth: 22
            implicitHeight: 22
            radius: 5
            color: forgetMouse.containsMouse ? Theme.surfaceHover : "transparent"
            visible: rowMouse.containsMouse || forgetMouse.containsMouse
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "󰆴"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: forgetMouse.containsMouse ? Theme.critical : Theme.textMuted
            }

            MouseArea {
                id: forgetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ControlCenterService.removeBluetooth(root.deviceData.address)
            }
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        anchors.rightMargin: forgetBtn.visible ? 24 : 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.deviceData.connected) {
                if (root.deviceData.nativeObj && root.deviceData.nativeObj.disconnect) {
                    root.deviceData.nativeObj.disconnect();
                } else {
                    ControlCenterService.disconnectBluetooth(root.deviceData.address);
                }
            } else {
                ControlCenterService.connectBluetooth(root.deviceData.address);
            }
        }
    }
}
