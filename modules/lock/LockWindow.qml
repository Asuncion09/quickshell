import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"

WlSessionLock {
    id: root
    locked: LockService.isLocked

    WlSessionLockSurface {
        id: lockSurface

        Item {
            id: surfaceContent
            anchors.fill: parent
            clip: true

            property var timeDate: new Date()

            // Control cinemático de animaciones de interfaz
            property real enterProgress: 0.0
            property real unlockProgress: 0.0

            // Variables reactivas de interfaz (1:1 de escala, sin distorsión)
            readonly property real currentUiOpacity: Math.max(0.0, enterProgress - (unlockProgress * 1.2))
            readonly property real currentUiY: (-16 * (1.0 - enterProgress)) + (-24 * unlockProgress)

            // Animación suave de entrada de los elementos interactivos (300ms)
            NumberAnimation {
                id: lockIntroAnim
                target: surfaceContent
                property: "enterProgress"
                from: 0.0
                to: 1.0
                duration: 300
                easing.type: Easing.OutCubic
            }

            // Animación ágil de salida de la UI al autenticar (220ms)
            NumberAnimation {
                id: unlockOutAnim
                target: surfaceContent
                property: "unlockProgress"
                from: 0.0
                to: 1.0
                duration: 220
                easing.type: Easing.InQuad
            }

            Component.onCompleted: {
                lockIntroAnim.start();
            }

            Timer {
                interval: 1000
                running: root.locked
                repeat: true
                onTriggered: surfaceContent.timeDate = new Date()
            }

            // Gestión de ciclo de vida de bloqueo/desbloqueo y foco
            Connections {
                target: LockService
                function onIsLockedChanged() {
                    if (LockService.isLocked) {
                        unlockOutAnim.stop();
                        surfaceContent.unlockProgress = 0.0;
                        surfaceContent.enterProgress = 0.0;
                        lockIntroAnim.restart();
                        pwdInput.text = "";
                        Qt.callLater(() => pwdInput.forceActiveFocus());
                    }
                }
                function onIsUnlockingChanged() {
                    if (LockService.isUnlocking) {
                        lockIntroAnim.stop();
                        unlockOutAnim.restart();
                    }
                }
                function onAuthFailedChanged() {
                    if (LockService.authFailed) {
                        pwdInput.text = "";
                        Qt.callLater(() => pwdInput.forceActiveFocus());
                    }
                }
            }

            // ==============================================================
            // 1. FONDO CON WALLPAPER Y DESENFOQUE CINEMATOGRÁFICO SIN BORDES
            // ==============================================================
            // Base oscura sólida para evitar cualquier destello
            Rectangle {
                anchors.fill: parent
                color: "#161616"
            }

            Item {
                id: bgContainer
                anchors.fill: parent

                Image {
                    id: lockBgImg
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: WallpaperService.currentWallpaper ? ("file://" + WallpaperService.currentWallpaper) : ""
                    asynchronous: true
                    cache: true
                    visible: false
                }

                MultiEffect {
                    id: blurredBackdrop
                    anchors.fill: lockBgImg
                    source: lockBgImg
                    blurEnabled: true
                    blur: 0.65
                    blurMax: 48
                    autoPaddingEnabled: false
                    brightness: -0.16
                    saturation: -0.05
                }

                // Capa de oscurecimiento uniforme
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.45)
                }
            }

            // Clic en cualquier zona vacía enfoca el campo de contraseña
            MouseArea {
                anchors.fill: parent
                z: 0
                onClicked: pwdInput.forceActiveFocus()
            }

            // ==============================================================
            // 2. CONTENEDOR PRINCIPAL INTERACTIVO
            // ==============================================================
            Item {
                id: mainUI
                z: 1
                anchors.fill: parent

                opacity: surfaceContent.currentUiOpacity
                transform: Translate {
                    y: surfaceContent.currentUiY
                }

                // ----------------------------------------------------------
                // CABECERA SUPERIOR (Icono de candado + Batería & Red)
                // ----------------------------------------------------------
                RowLayout {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 24
                    anchors.leftMargin: 28
                    anchors.rightMargin: 28

                    // Píldora de estado de bloqueo (estilo Quickshell)
                    Rectangle {
                        implicitHeight: 28
                        implicitWidth: lockRow.implicitWidth + 24
                        radius: Theme.pillRadius
                        color: Qt.rgba(0.12, 0.12, 0.12, 0.65)
                        border.width: 1
                        border.color: Theme.dividerColor

                        RowLayout {
                            id: lockRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "󰌾"
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                color: Theme.highlight
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: "Bloqueado"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: Theme.text
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Cápsula de estado: Red y Batería (estilo Quickshell idéntico al Topbar)
                    Rectangle {
                        implicitHeight: 28
                        implicitWidth: statusRow.implicitWidth + 22
                        radius: Theme.pillRadius
                        color: Qt.rgba(0.12, 0.12, 0.12, 0.65)
                        border.width: 1
                        border.color: Theme.dividerColor

                        RowLayout {
                            id: statusRow
                            anchors.centerIn: parent
                            spacing: 10

                            // Icono de Red idéntico al Topbar
                            Text {
                                text: NetworkService.icon
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                color: NetworkService.color
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Divisor ultra-sutil
                            Rectangle {
                                implicitWidth: 1
                                implicitHeight: 12
                                color: Theme.dividerColor
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Estado de batería idéntico al Topbar
                            RowLayout {
                                spacing: 6
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: BatteryService.isCharging ? "󰂄" : BatteryService.icon
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    color: BatteryService.color
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: BatteryService.percentage + "%"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: "#ffffff"
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }
                    }
                }

                // ----------------------------------------------------------
                // ZONA CENTRAL (Reloj grande, Fecha, Saludo y Contraseña)
                // ----------------------------------------------------------
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    // Reloj Estético Minimalista
                    Text {
                        text: Qt.formatDateTime(surfaceContent.timeDate, "hh:mm")
                        font.family: Theme.fontFamily
                        font.pixelSize: 84
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Fecha completa estilizada
                    Text {
                        text: {
                            let d = surfaceContent.timeDate;
                            let formatted = d.toLocaleDateString(Qt.locale("es_ES"), "dddd, d 'de' MMMM");
                            return formatted.charAt(0).toUpperCase() + formatted.slice(1);
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.Normal
                        color: "#c0c6d4"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 16
                    }

                    // Saludo de Usuario (sin avatar circular)
                    Text {
                        text: {
                            let u = Quickshell.env("USER");
                            let name = u ? (u.charAt(0).toUpperCase() + u.slice(1)) : "Usuario";
                            return "Hola, " + name;
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.weight: Font.Medium
                        color: "#ffffff"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 6
                    }

                    // Campo de contraseña estilo Squircle Quickshell con animación de Shake
                    Item {
                        id: pwdWrapper
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 280
                        implicitHeight: 40

                        property real xShake: 0

                        SequentialAnimation {
                            id: shakeAnim
                            running: LockService.authFailed

                            NumberAnimation { target: pwdWrapper; property: "xShake"; to: -14; duration: 45; easing.type: Easing.OutQuad }
                            NumberAnimation { target: pwdWrapper; property: "xShake"; to: 14; duration: 55; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: pwdWrapper; property: "xShake"; to: -10; duration: 55; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: pwdWrapper; property: "xShake"; to: 10; duration: 55; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: pwdWrapper; property: "xShake"; to: -4; duration: 45; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: pwdWrapper; property: "xShake"; to: 0; duration: 45; easing.type: Easing.InOutQuad }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.horizontalCenterOffset: pwdWrapper.xShake
                            radius: Theme.pillRadius
                            color: Qt.rgba(0.12, 0.12, 0.12, 0.85)
                            border.width: 1
                            border.color: LockService.authSucceeded ? Theme.success : (LockService.authFailed ? Theme.critical : (pwdInput.activeFocus ? Theme.highlight : Theme.dividerColor))

                            Behavior on border.color { ColorAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }

                            MouseArea {
                                anchors.fill: parent
                                anchors.rightMargin: 36
                                cursorShape: Qt.IBeamCursor
                                onClicked: pwdInput.forceActiveFocus()
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 6
                                spacing: 8

                                Text {
                                    text: "󰌾"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    color: LockService.authSucceeded ? Theme.success : (LockService.authFailed ? Theme.critical : (pwdInput.activeFocus ? Theme.highlight : Theme.textMuted))
                                    Layout.alignment: Qt.AlignVCenter
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    TextInput {
                                        id: pwdInput
                                        anchors.fill: parent
                                        verticalAlignment: TextInput.AlignVCenter
                                        echoMode: TextInput.Password
                                        passwordCharacter: "•"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                        color: "#ffffff"
                                        selectionColor: "#454545"
                                        selectedTextColor: "#ffffff"
                                        focus: true
                                        clip: true

                                        onTextChanged: {
                                            if (LockService.authFailed && pwdInput.text.length > 0) {
                                                LockService.authFailed = false;
                                                LockService.errorMessage = "";
                                            }
                                        }

                                        onAccepted: {
                                            if (pwdInput.text.length > 0) {
                                                LockService.submitPassword(pwdInput.text);
                                            }
                                        }

                                        Text {
                                            anchors.fill: parent
                                            verticalAlignment: Text.AlignVCenter
                                            text: "Contraseña..."
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 13
                                            color: Theme.textMuted
                                            visible: pwdInput.text.length === 0
                                        }
                                    }
                                }

                                // Botón Squircle de envío Quickshell
                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 6
                                    color: LockService.authSucceeded ? Theme.success : (submitMouse.containsMouse ? Theme.highlight : (pwdInput.text.length > 0 ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.22) : Qt.rgba(1, 1, 1, 0.05)))
                                    border.width: 1
                                    border.color: LockService.authSucceeded ? Theme.success : (pwdInput.text.length > 0 ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.4) : "transparent")
                                    scale: submitMouse.pressed ? 0.92 : 1.0

                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on border.color { ColorAnimation { duration: 120 } }
                                    Behavior on scale { NumberAnimation { duration: 80 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: LockService.authSucceeded ? "󰄬" : (LockService.isAuthenticating ? "󰑐" : "󰅂")
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                        color: (LockService.authSucceeded || submitMouse.containsMouse) ? "#161616" : (pwdInput.text.length > 0 ? Theme.highlight : Theme.textMuted)
                                        rotation: LockService.isAuthenticating ? spinAngle : 0

                                        property real spinAngle: 0
                                        NumberAnimation on spinAngle {
                                            running: LockService.isAuthenticating
                                            from: 0
                                            to: 360
                                            loops: Animation.Infinite
                                            duration: 800
                                        }
                                    }

                                    MouseArea {
                                        id: submitMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (pwdInput.text.length > 0) {
                                                LockService.submitPassword(pwdInput.text);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Mensaje de error de autenticación
                    Text {
                        text: LockService.errorMessage
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Theme.critical
                        Layout.alignment: Qt.AlignHCenter
                        opacity: LockService.authFailed ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                // ----------------------------------------------------------
                // WIDGET MULTIMEDIA INFERIOR (MPRIS)
                // ----------------------------------------------------------
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 34
                    implicitWidth: 330
                    implicitHeight: 64
                    radius: 16
                    color: Qt.rgba(0.12, 0.12, 0.12, 0.80)
                    border.width: 1
                    border.color: Theme.dividerColor
                    visible: MediaService.hasMedia && MediaService.title !== ""

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        // Portada del álbum
                        Rectangle {
                            implicitWidth: 44
                            implicitHeight: 44
                            radius: 8
                            clip: true
                            layer.enabled: true
                            color: "#1e1e1e"

                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: MediaService.artUrl || ""
                                asynchronous: true
                                visible: MediaService.artUrl !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰎆"
                                font.family: Theme.fontFamily
                                font.pixelSize: 20
                                color: Theme.textMuted
                                visible: !MediaService.artUrl || MediaService.artUrl === ""
                            }
                        }

                        // Metadatos (Título y Artista)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: MediaService.title || "Música"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: "#ffffff"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: MediaService.artist || "Artista"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Controles de transporte
                        RowLayout {
                            spacing: 6

                            // Anterior
                            Rectangle {
                                implicitWidth: 28
                                implicitHeight: 28
                                radius: 14
                                color: prevMouse.containsMouse ? Theme.surfaceHover : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒮"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    color: prevMouse.containsMouse ? "#ffffff" : Theme.textMuted
                                }
                                MouseArea {
                                    id: prevMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MediaService.previous()
                                }
                            }

                            // Play / Pause
                            Rectangle {
                                implicitWidth: 32
                                implicitHeight: 32
                                radius: 16
                                color: playMouse.containsMouse ? Theme.highlight : Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.20)
                                Text {
                                    anchors.centerIn: parent
                                    text: MediaService.isPlaying ? "󰏤" : "󰐊"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 16
                                    color: playMouse.containsMouse ? "#161616" : Theme.highlight
                                }
                                MouseArea {
                                    id: playMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MediaService.playPause()
                                }
                            }

                            // Siguiente
                            Rectangle {
                                implicitWidth: 28
                                implicitHeight: 28
                                radius: 14
                                color: nextMouse.containsMouse ? Theme.surfaceHover : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒭"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    color: nextMouse.containsMouse ? "#ffffff" : Theme.textMuted
                                }
                                MouseArea {
                                    id: nextMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MediaService.next()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
