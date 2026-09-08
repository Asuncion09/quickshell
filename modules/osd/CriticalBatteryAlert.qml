import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../theme"
import "../../services"

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    anchors {
        top: true
        right: true
    }
    margins.top: 42
    margins.right: 14

    implicitWidth: 330
    implicitHeight: 114

    color: "transparent"

    // Solo capturar clics dentro de la tarjeta de alerta cuando está visible; 100% permeable al escritorio en el resto
    mask: Region {
        Region {
            item: alertCard
        }
    }

    // Estado interno de visualización
    property bool displayed: false
    property bool isPluggedNotice: false

    // Control de animación de pulso crítico en el borde
    property real pulseAlpha: 0.4
    SequentialAnimation {
        running: root.displayed && !root.isPluggedNotice
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "pulseAlpha"
            to: 1.0
            duration: 800
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: root
            property: "pulseAlpha"
            to: 0.4
            duration: 800
            easing.type: Easing.InOutQuad
        }
    }

    // Reproductor de sonido de advertencia crítica
    Process {
        id: soundAlert
        command: ["paplay", "/usr/share/sounds/freedesktop/stereo/dialog-error.oga"]
    }

    // Temporizador para desvanecer la alerta al conectar el cargador
    Timer {
        id: plugNoticeTimer
        interval: 1800
        onTriggered: {
            root.displayed = false;
            root.isPluggedNotice = false;
        }
    }

    // Reacción reactiva a cambios de estado de batería
    Connections {
        target: BatteryService

        function onShouldAlertCriticalChanged() {
            if (BatteryService.shouldAlertCritical) {
                root.isPluggedNotice = false;
                root.displayed = true;
                if (!soundAlert.running) {
                    soundAlert.running = true;
                }
            } else if (!BatteryService.isCritical) {
                root.displayed = false;
                root.isPluggedNotice = false;
            }
        }

        function onIsChargingChanged() {
            if (BatteryService.isCharging && root.displayed) {
                // Notificación visual de éxito al conectar el cargador
                root.isPluggedNotice = true;
                plugNoticeTimer.restart();
            }
        }
    }

    Component.onCompleted: {
        if (BatteryService.shouldAlertCritical) {
            root.displayed = true;
            if (!soundAlert.running) soundAlert.running = true;
        }
    }

    visible: cardContainer.opacity > 0.001

    Item {
        id: cardContainer
        anchors.fill: parent
        opacity: root.displayed ? 1.0 : 0.0
        scale: root.displayed ? 1.0 : 0.94
        transformOrigin: Item.TopRight

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
        }

        // Sombra suave multicapa
        Rectangle {
            id: shadowShape
            anchors.fill: alertCard
            radius: 10
            color: "#000000"
            visible: false
        }

        MultiEffect {
            source: shadowShape
            anchors.fill: shadowShape
            visible: Theme.pillShadowEnabled
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.65
            shadowBlur: 0.6
            shadowVerticalOffset: 4
        }

        // Tarjeta principal de alerta
        Rectangle {
            id: alertCard
            anchors.fill: parent
            radius: 10
            color: Theme.bgDark
            border.width: 1.5
            border.color: {
                if (root.isPluggedNotice) return Theme.success;
                return Qt.rgba(238 / 255, 83 / 255, 150 / 255, root.pulseAlpha);
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                // Fila de encabezado: Icono + Título + Botón Cerrar/Posponer
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Icono animado
                    Text {
                        text: root.isPluggedNotice ? "󰂄" : "󰂃"
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        color: root.isPluggedNotice ? Theme.success : Theme.critical
                        Layout.alignment: Qt.AlignVCenter

                        scale: (root.displayed && !root.isPluggedNotice) ? (1.0 + (root.pulseAlpha - 0.4) * 0.25) : 1.0
                    }

                    // Título
                    Text {
                        Layout.fillWidth: true
                        text: root.isPluggedNotice ? "Cargador Conectado" : `Batería Crítica — ${BatteryService.percentage}%`
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: root.isPluggedNotice ? Theme.success : "#ffffff"
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Botón de descarte / posponer rápido en la esquina
                    Rectangle {
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 10
                        color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: closeMouse.containsMouse ? "#ffffff" : Theme.textMuted
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                BatteryService.snooze();
                            }
                        }
                    }
                }

                // Subtítulo informativo
                Text {
                    Layout.fillWidth: true
                    text: root.isPluggedNotice ? "Cargando el equipo normalmente." : "Conecta el cargador de inmediato para evitar que el equipo se apague."
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Normal
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                }

                // Fila inferior: Mini barra de nivel + Chip de posponer
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Layout.topMargin: 2

                    // Barra de progreso de la batería
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 4
                        radius: 2
                        color: Qt.rgba(1, 1, 1, 0.10)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(6, Math.round((parent.width * Math.max(0, Math.min(100, BatteryService.percentage))) / 100))
                            radius: 2
                            color: root.isPluggedNotice ? Theme.success : Theme.critical

                            Behavior on width {
                                NumberAnimation { duration: Theme.animNormal }
                            }
                        }
                    }

                    // Botón explícito para posponer 5 minutos
                    Rectangle {
                        implicitWidth: snoozeRow.implicitWidth + 16
                        implicitHeight: 22
                        radius: 4
                        color: snoozeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.07)
                        border.width: 1
                        border.color: snoozeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.10)
                        visible: !root.isPluggedNotice

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        RowLayout {
                            id: snoozeRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: "󰏤"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.textSecondary
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                id: snoozeBtnLabel
                                text: "Posponer 5 min"
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.Medium
                                color: Theme.text
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: snoozeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                BatteryService.snooze();
                            }
                        }
                    }
                }
            }
        }
    }
}
