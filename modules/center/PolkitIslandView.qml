import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../../components"
import "../../services"

Item {
    id: root

    implicitWidth: 368
    implicitHeight: mainLayout.implicitHeight + 28

    property bool showPassword: false

    // Absorbe clics para evitar que se propaguen a áreas subyacentes
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: mouse => {
            mouse.accepted = true;
            passInput.forceActiveFocus();
        }
    }

    Connections {
        target: PolkitService
        function onIsActiveChanged() {
            if (PolkitService.isActive) {
                passInput.text = "";
                root.showPassword = false;
                Qt.callLater(() => {
                    passInput.forceActiveFocus();
                });
            }
        }
        function onAuthFailedChanged() {
            if (PolkitService.authFailed) {
                passInput.selectAll();
                Qt.callLater(() => passInput.forceActiveFocus());
            }
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // 1. Cabecera (Icono de Escudo, Título y Botón Cancelar)
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Badge de icono
            Rectangle {
                implicitWidth: 34
                implicitHeight: 34
                radius: 8
                color: Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.15)
                border.width: 1
                border.color: Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.35)

                Text {
                    anchors.centerIn: parent
                    text: "󰌾"
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    color: Theme.highlight
                }
            }

            // Títulos y Contexto
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Autenticación Requerida"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                    Layout.fillWidth: true
                }

                Text {
                    text: PolkitService.actionId ? PolkitService.actionId : "system-privilege"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.textMuted
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }

            // Botón rápido de descarte (Cancelar)
            Rectangle {
                implicitWidth: 26
                implicitHeight: 26
                radius: 6
                color: closeMouse.containsMouse ? Theme.surfaceHover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: closeMouse.containsMouse ? "#ffffff" : Theme.textMuted
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PolkitService.cancel()
                }
            }
        }

        // Línea divisoria muy sutil
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.dividerColor
        }

        // 2. Mensaje descriptivo de la solicitud
        Text {
            Layout.fillWidth: true
            text: PolkitService.message
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.text
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            lineHeight: 1.15
        }

        // 3. Campo de Contraseña con diseño Squircle Quickshell y animación de Shake
        Item {
            id: passBoxWrapper
            Layout.fillWidth: true
            implicitHeight: 38

            property real xShake: 0

            SequentialAnimation {
                id: shakeAnim
                running: PolkitService.authFailed

                NumberAnimation { target: passBoxWrapper; property: "xShake"; to: -12; duration: 45; easing.type: Easing.OutQuad }
                NumberAnimation { target: passBoxWrapper; property: "xShake"; to: 12; duration: 55; easing.type: Easing.InOutQuad }
                NumberAnimation { target: passBoxWrapper; property: "xShake"; to: -8; duration: 55; easing.type: Easing.InOutQuad }
                NumberAnimation { target: passBoxWrapper; property: "xShake"; to: 8; duration: 55; easing.type: Easing.InOutQuad }
                NumberAnimation { target: passBoxWrapper; property: "xShake"; to: -3; duration: 45; easing.type: Easing.InOutQuad }
                NumberAnimation { target: passBoxWrapper; property: "xShake"; to: 0; duration: 45; easing.type: Easing.InOutQuad }
            }

            Rectangle {
                anchors.fill: parent
                anchors.horizontalCenterOffset: passBoxWrapper.xShake
                radius: Theme.pillRadius
                color: Qt.rgba(0.12, 0.12, 0.12, 0.85)
                border.width: 1
                border.color: PolkitService.isSuccess ? Theme.success : (PolkitService.authFailed ? Theme.critical : (passInput.activeFocus ? Theme.highlight : Theme.dividerColor))

                Behavior on border.color { ColorAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: 36
                    cursorShape: Qt.IBeamCursor
                    onClicked: passInput.forceActiveFocus()
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: "󰌾"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: PolkitService.isSuccess ? Theme.success : (PolkitService.authFailed ? Theme.critical : (passInput.activeFocus ? Theme.highlight : Theme.textMuted))
                        Layout.alignment: Qt.AlignVCenter
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        TextInput {
                            id: passInput
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: (root.showPassword || PolkitService.responseVisible) ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "•"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: "#ffffff"
                            selectionColor: "#454545"
                            selectedTextColor: "#ffffff"
                            focus: true
                            clip: true

                            onTextChanged: {
                                if (passInput.text.length > 0 && PolkitService._manualFailed) {
                                    PolkitService._manualFailed = false;
                                    PolkitService._manualErrorMessage = "";
                                }
                            }

                            onAccepted: {
                                if (passInput.text.length > 0) {
                                    PolkitService.submit(passInput.text);
                                }
                            }

                            Keys.onEscapePressed: event => {
                                event.accepted = true;
                                PolkitService.cancel();
                            }

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Contraseña..."
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: Theme.textMuted
                                visible: passInput.text.length === 0
                            }
                        }
                    }

                    // Botón para alternar visibilidad de contraseña (Ojo)
                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 5
                        color: eyeMouse.containsMouse ? Theme.surfaceHover : "transparent"

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
                            onClicked: root.showPassword = !root.showPassword
                        }
                    }
                }
            }
        }

        // Mensaje de error si la autenticación falló
        Text {
            Layout.fillWidth: true
            text: PolkitService.errorMessage
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Theme.critical
            visible: PolkitService.authFailed && PolkitService.errorMessage !== ""
            wrapMode: Text.WordWrap
        }

        // 4. Botones de Acción (Cancelar / Autenticar)
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Botón Cancelar
            Rectangle {
                Layout.preferredWidth: 100
                implicitHeight: 32
                radius: 7
                color: cancelMouse.containsMouse ? Theme.surfaceHover : Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: Theme.dividerColor
                scale: cancelMouse.pressed ? 0.95 : 1.0

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on scale { NumberAnimation { duration: 60 } }

                Text {
                    anchors.centerIn: parent
                    text: "Cancelar"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: cancelMouse.containsMouse ? "#ffffff" : Theme.textSecondary
                }

                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PolkitService.cancel()
                }
            }

            // Botón Autenticar
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: 7
                color: {
                    if (PolkitService.isSuccess) return Theme.success;
                    if (authMouse.containsMouse) return Theme.highlight;
                    if (passInput.text.length > 0) return Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.85);
                    return Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.35);
                }
                scale: authMouse.pressed ? 0.96 : 1.0

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on scale { NumberAnimation { duration: 60 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: PolkitService.isSuccess ? "󰄬" : "󰌾"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: (PolkitService.isSuccess || passInput.text.length > 0 || authMouse.containsMouse) ? "#161616" : Theme.textDisabled
                    }

                    Text {
                        text: PolkitService.isSuccess ? "Autorizado" : "Autenticar"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: (PolkitService.isSuccess || passInput.text.length > 0 || authMouse.containsMouse) ? "#161616" : Theme.textDisabled
                    }
                }

                MouseArea {
                    id: authMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: (passInput.text.length > 0 || PolkitService.isSuccess) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (passInput.text.length > 0) {
                            PolkitService.submit(passInput.text);
                        }
                    }
                }
            }
        }
    }
}
