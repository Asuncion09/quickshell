import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"

// Fila de red Wi-Fi descubierta y disponible (sección "Available networks").
Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: 34
    radius: 8

    property var networkData
    property string icon: ""
    property bool isKeyFocused: false
    property bool isConnecting: false

    signal passwordRequested(string name)

    color: isKeyFocused ? Theme.surfaceKeyFocus : (availNetMouse.containsMouse ? Theme.surfaceHover : "transparent")
    border.width: isKeyFocused ? 1.5 : 0
    border.color: Theme.highlight

    scale: availNetMouse.pressed ? 0.98 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
    Behavior on border.width { NumberAnimation { duration: 40 } }
    Behavior on border.color { ColorAnimation { duration: 40 } }
    Behavior on color { ColorAnimation { duration: availNetMouse.containsMouse ? Theme.animFast : 40 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Text {
            text: root.icon
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: availNetMouse.containsMouse ? Theme.text : Theme.textSecondary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.networkData.name
                font.family: Theme.fontFamily
                font.pixelSize: 13
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

        // Candado si está protegida
        Text {
            visible: root.networkData.isProtected
            text: "󰌾"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.textMuted
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.isConnecting ? "..." : "Connect"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            color: availNetMouse.containsMouse ? Theme.wsActiveColor : Theme.textMuted
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: availNetMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.isConnecting) return;
            if (root.networkData.isProtected) {
                root.passwordRequested(root.networkData.name);
            } else {
                ControlCenterService.connectWifi(root.networkData.name);
            }
        }
    }
}
