import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"

// Tarjeta de contraseña Wi-Fi inline (prompt de conexión a red protegida).
// Autocontenida: gestiona su propio passwordText/showPassword y emite señales
// de submit/cancel/back. El SSID y el estado de conexión se inyectan como propiedades.
Rectangle {
    id: root
    Layout.fillWidth: true
    visible: root.ssid !== ""
    implicitHeight: passCol.implicitHeight + 20
    radius: 10
    color: Theme.surfaceBase
    border.width: 0

    property string ssid: ""
    property bool connecting: false
    property string passwordText: ""
    property bool showPassword: false

    signal submitRequested(string password)
    signal cancelRequested()
    signal backRequested()

    onVisibleChanged: {
        root.passwordText = "";
        root.showPassword = false;
        if (visible) Qt.callLater(() => passInput.forceActiveFocus());
    }

    ColumnLayout {
        id: passCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "󰌾"
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
                    text: root.ssid
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Theme.text
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: "Enter network password"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.textMuted
                }
            }
        }

        // Campo de entrada de contraseña
        Rectangle {
            id: passBox
            Layout.fillWidth: true
            implicitHeight: 34
            radius: 6
            color: Theme.bgDark
            border.width: passInput.activeFocus ? 1 : (passBoxMouse.containsMouse ? 1 : 0)
            border.color: passInput.activeFocus ? Theme.wsActiveColor : Theme.dividerColor

            MouseArea {
                id: passBoxMouse
                anchors.fill: parent
                anchors.rightMargin: 32
                hoverEnabled: true
                cursorShape: Qt.IBeamCursor
                onClicked: passInput.forceActiveFocus()
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 6

                TextInput {
                    id: passInput
                    Layout.fillWidth: true
                    text: root.passwordText
                    echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.text
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    selectByMouse: true
                    mouseSelectionMode: TextInput.SelectCharacters
                    onTextChanged: root.passwordText = text
                    onAccepted: root.submitRequested(root.passwordText)
                    Keys.onEscapePressed: event => {
                        event.accepted = true;
                        root.backRequested();
                    }

                    Text {
                        text: "Password..."
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.textMuted
                        visible: !passInput.text && !passInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Botón Mostrar/Ocultar contraseña (Ojo)
                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 4
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: root.showPassword ? "󰈉" : "󰈈"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: eyeMouse.containsMouse ? Theme.text : Theme.textMuted
                    }

                    MouseArea {
                        id: eyeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.showPassword = !root.showPassword;
                            passInput.forceActiveFocus();
                        }
                    }
                }
            }
        }

        // Mensaje de error si la conexión falló
        Text {
            Layout.fillWidth: true
            visible: ControlCenterService.wifiErrorMessage !== ""
            text: ControlCenterService.wifiErrorMessage
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.critical
            wrapMode: Text.Wrap
        }

        // Fila de Botones: Cancelar y Conectar
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                id: cancelBtn
                Layout.fillWidth: true
                implicitHeight: 30
                radius: 6
                color: cancelMouse.containsMouse ? Theme.surfaceHover : Theme.bgDark
                border.width: 0

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }

                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cancelRequested()
                }
            }

            Rectangle {
                id: connectBtn
                Layout.fillWidth: true
                implicitHeight: 30
                radius: 6
                color: Theme.wsActiveColor
                border.width: 0
                opacity: root.passwordText.length > 0 ? 1.0 : 0.5

                Text {
                    anchors.centerIn: parent
                    text: root.connecting ? "Connecting..." : "Connect"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Theme.textOnAccent
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: root.passwordText.length > 0
                    cursorShape: root.passwordText.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (root.passwordText.length > 0) root.submitRequested(root.passwordText);
                    }
                }
            }
        }
    }
}
