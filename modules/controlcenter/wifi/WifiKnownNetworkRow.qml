import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"

// Fila de red Wi-Fi guardada/conectada (sección "Known networks").
Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: 34
    radius: 8

    property var networkData
    property string icon: ""
    property bool isKeyFocused: false
    property bool isConnecting: false

    signal forgetRequested(string name)
    signal markSavedRequested(string name)

    color: {
        if (networkData.connected) {
            return (savedRowMouse.containsMouse || isKeyFocused) ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.05);
        }
        if (isKeyFocused) return Theme.surfaceKeyFocus;
        return savedRowMouse.containsMouse ? Theme.surfaceHover : "transparent";
    }
    border.width: isKeyFocused ? 1.5 : (networkData.connected ? 1 : 0)
    border.color: isKeyFocused ? (networkData.connected ? Qt.rgba(1, 1, 1, 0.85) : Theme.highlight) : Qt.rgba(1, 1, 1, 0.08)

    scale: savedRowMouse.pressed ? 0.98 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
    Behavior on border.width { NumberAnimation { duration: 40 } }
    Behavior on border.color { ColorAnimation { duration: 40 } }
    Behavior on color { ColorAnimation { duration: savedRowMouse.containsMouse ? Theme.animFast : 40 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        // Icono de señal
        Text {
            text: root.icon
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: root.networkData.connected ? Theme.wsActiveColor : (savedRowMouse.containsMouse ? Theme.text : Theme.textSecondary)
        }

        // Nombre de la red
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.networkData.name
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: root.networkData.connected ? Font.DemiBold : Font.Normal
                color: Theme.text
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.isConnecting
                text: "Connecting..."
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.wsActiveColor
            }
        }

        // Estado de conexión (badge con punto esmeralda sutil)
        RowLayout {
            visible: root.networkData.connected && !root.isConnecting
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

        // Botón para olvidar / borrar red guardada
        Rectangle {
            id: forgetNetBtn
            implicitWidth: 22
            implicitHeight: 22
            radius: 5
            color: forgetNetMouse.containsMouse ? Theme.surfaceHover : "transparent"
            visible: savedRowMouse.containsMouse || forgetNetMouse.containsMouse
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "󰆴"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: forgetNetMouse.containsMouse ? Theme.critical : Theme.textMuted
            }

            MouseArea {
                id: forgetNetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.forgetRequested(root.networkData.name);
                    ControlCenterService.deleteWifiConnection(root.networkData.name);
                }
            }
        }
    }

    MouseArea {
        id: savedRowMouse
        anchors.fill: parent
        anchors.rightMargin: forgetNetBtn.visible ? 24 : 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.isConnecting) return;
            root.markSavedRequested(root.networkData.name);
            if (root.networkData.connected) {
                ControlCenterService.disconnectWifi(root.networkData.name);
            } else {
                ControlCenterService.connectWifi(root.networkData.name);
            }
        }
    }
}
