import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
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

            readonly property bool isInitiallyFocusedScreen: {
                let screensCount = (Hyprland.monitors && Hyprland.monitors.values && Hyprland.monitors.values.length > 0)
                    ? Hyprland.monitors.values.length : (Quickshell.screens ? Quickshell.screens.length : 1);
                if (screensCount <= 1) return true;
                if (!lockSurface.screen) return true;

                if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) {
                    return Hyprland.focusedMonitor.name === lockSurface.screen.name;
                }
                if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.monitor && Hyprland.focusedWorkspace.monitor.name) {
                    return Hyprland.focusedWorkspace.monitor.name === lockSurface.screen.name;
                }
                return lockSurface.screen.name === "eDP-1";
            }

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
                        if (surfaceContent.isInitiallyFocusedScreen) {
                            Qt.callLater(() => pwdInput.forceActiveFocus());
                        }
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
                        if (surfaceContent.isInitiallyFocusedScreen || pwdInput.activeFocus) {
                            Qt.callLater(() => pwdInput.forceActiveFocus());
                        }
                    }
                }
                function onCurrentInputChanged() {
                    if (pwdInput.text !== LockService.currentInput) {
                        pwdInput.text = LockService.currentInput;
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

                    // Estado de bloqueo limpio (sin píldora)
                    RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "󰌾"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: Theme.highlight
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: "Bloqueado"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Theme.textSecondary
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Estado de Red y Batería limpio (sin píldora)
                    RowLayout {
                        spacing: 12
                        Layout.alignment: Qt.AlignVCenter

                        // Icono de Red
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
                            color: Qt.rgba(1, 1, 1, 0.15)
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Estado de Batería
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
                                font.weight: Font.Medium
                                color: Theme.text
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }

                // ----------------------------------------------------------
                // ZONA SUPERIOR (Reloj prominente y Fecha)
                // ----------------------------------------------------------
                ColumnLayout {
                    id: clockBlock
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: Math.round(parent.height * 0.18)
                    spacing: 6

                    // Reloj Estético Prominente (Jerarquía UI/UX)
                    Text {
                        text: Qt.formatDateTime(surfaceContent.timeDate, "hh:mm")
                        font.family: Theme.fontFamily
                        font.pixelSize: 112
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
                        font.pixelSize: 16
                        font.weight: Font.Normal
                        color: "#c0c6d4"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // ----------------------------------------------------------
                // ZONA CENTRAL / AUTENTICACIÓN (Saludo, Contraseña y Feedback)
                // ----------------------------------------------------------
                ColumnLayout {
                    id: authBlock
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: clockBlock.bottom
                    anchors.topMargin: Math.max(64, Math.round(parent.height * 0.08))
                    spacing: 12

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
                        Layout.bottomMargin: 4
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
                            color: Theme.bgDark
                            border.width: 1
                            border.color: LockService.authSucceeded ? Theme.success : (LockService.authFailed ? Theme.critical : (pwdInput.activeFocus ? Theme.highlight : Theme.borderDark))

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
                                anchors.leftMargin: 14
                                anchors.rightMargin: 10
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
                                        focus: surfaceContent.isInitiallyFocusedScreen
                                        clip: true

                                        Keys.onPressed: LockService.checkCapsLock()

                                        onTextEdited: {
                                            LockService.currentInput = pwdInput.text;
                                        }

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

                                // Acción de envío integrada (sin caja anidada ni cambios de color bruscos)
                                Item {
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        text: LockService.authSucceeded ? "󰄬" : (LockService.isAuthenticating ? "󰑐" : "󰅂")
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 15
                                        color: LockService.authSucceeded ? Theme.success : (LockService.authFailed ? Theme.critical : (pwdInput.text.length > 0 ? "#ffffff" : Theme.textMuted))
                                        opacity: pwdInput.text.length > 0 ? (submitMouse.pressed ? 0.6 : 1.0) : 0.4
                                        scale: submitMouse.pressed ? 0.88 : 1.0
                                        rotation: LockService.isAuthenticating ? spinAngle : 0

                                        Behavior on opacity { NumberAnimation { duration: 120 } }
                                        Behavior on scale { NumberAnimation { duration: 80 } }
                                        Behavior on color { ColorAnimation { duration: 120 } }

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
                                        cursorShape: pwdInput.text.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
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

                    // Badge contextual de Bloq Mayús (Caps Lock)
                    Rectangle {
                        id: capsBadge
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: LockService.capsLockActive ? 24 : 0
                        implicitWidth: capsRow.implicitWidth + 20
                        radius: Theme.pillRadius
                        color: Qt.rgba(0.98, 0.70, 0.53, 0.14)
                        border.width: 1
                        border.color: Qt.rgba(0.98, 0.70, 0.53, 0.35)
                        clip: true
                        opacity: LockService.capsLockActive ? 1.0 : 0.0
                        visible: opacity > 0 || Layout.preferredHeight > 0

                        Behavior on opacity { NumberAnimation { duration: 160 } }
                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

                        RowLayout {
                            id: capsRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "󰌎"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: "#fab387"
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: "Bloq Mayús activado"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: "#fab387"
                                Layout.alignment: Qt.AlignVCenter
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

                    // Píldora de acciones de energía segmentada (justo debajo del input / Bloq Mayús)
                    Rectangle {
                        id: powerDock
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 8
                        implicitHeight: 38
                        implicitWidth: 168
                        radius: Theme.pillRadius
                        color: Theme.bgDark
                        border.width: 1
                        border.color: Theme.borderDark
                        clip: true

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 1
                            spacing: 0

                            // Segmento: Suspender
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                topLeftRadius: Theme.pillRadius - 1
                                bottomLeftRadius: Theme.pillRadius - 1
                                topRightRadius: 0
                                bottomRightRadius: 0
                                color: suspMouse.containsMouse ? Theme.surfaceHover : "transparent"

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰤄"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 16
                                    color: suspMouse.containsMouse ? Theme.highlight : Theme.textMuted
                                    scale: suspMouse.pressed ? 0.88 : 1.0
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on scale { NumberAnimation { duration: 80 } }
                                }

                                MouseArea {
                                    id: suspMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SessionService.suspend()
                                }
                            }

                            // Divisor vertical
                            Rectangle {
                                Layout.fillHeight: true
                                implicitWidth: 1
                                color: Theme.dividerColor
                            }

                            // Segmento: Reiniciar
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 0
                                color: rebtMouse.containsMouse ? Theme.surfaceHover : "transparent"

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰑐"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 16
                                    color: rebtMouse.containsMouse ? "#fab387" : Theme.textMuted
                                    scale: rebtMouse.pressed ? 0.88 : 1.0
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on scale { NumberAnimation { duration: 80 } }
                                }

                                MouseArea {
                                    id: rebtMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SessionService.reboot()
                                }
                            }

                            // Divisor vertical
                            Rectangle {
                                Layout.fillHeight: true
                                implicitWidth: 1
                                color: Theme.dividerColor
                            }

                            // Segmento: Apagar
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                topLeftRadius: 0
                                bottomLeftRadius: 0
                                topRightRadius: Theme.pillRadius - 1
                                bottomRightRadius: Theme.pillRadius - 1
                                color: pwrMouse.containsMouse ? Theme.surfaceHover : "transparent"

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰐥"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 16
                                    color: pwrMouse.containsMouse ? Theme.critical : Theme.textMuted
                                    scale: pwrMouse.pressed ? 0.88 : 1.0
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on scale { NumberAnimation { duration: 80 } }
                                }

                                MouseArea {
                                    id: pwrMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SessionService.shutdown()
                                }
                            }
                        }
                    }
                }

                // ----------------------------------------------------------
                // WIDGET MULTIMEDIA INFERIOR (MPRIS)
                // ----------------------------------------------------------
                Rectangle {
                    id: mprisWidget
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 32
                    implicitWidth: 330
                    implicitHeight: 64
                    radius: 16
                    color: Theme.bgDark
                    border.width: 1
                    border.color: Theme.borderDark
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

                            // Reproducir / Pausar
                            Rectangle {
                                implicitWidth: 32
                                implicitHeight: 32
                                radius: 16
                                color: playMouse.containsMouse ? Theme.highlight : Theme.surfaceHover
                                scale: playMouse.pressed ? 0.92 : 1.0
                                Behavior on scale { NumberAnimation { duration: 80 } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
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
