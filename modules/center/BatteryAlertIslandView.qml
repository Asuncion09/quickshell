import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../theme"
import "../../services"

Item {
    id: root

    property bool isHovered: false
    property bool isPluggedNotice: false
    property bool isUnpluggedNotice: false
    readonly property bool isCriticalAlert: BatteryService.shouldAlertCritical
    readonly property bool isActive: isCriticalAlert || isPluggedNotice || isUnpluggedNotice

    implicitHeight: 28
    implicitWidth: contentRow.implicitWidth

    // Evitar disparar aviso de desconexión durante la carga inicial de Quickshell
    property bool _initialized: false
    Timer {
        id: initTimer
        interval: 600
        running: true
        onTriggered: root._initialized = true
    }

    // Color del tema según el estado
    readonly property color alertColor: {
        if (root.isPluggedNotice) return Theme.success;
        if (root.isCriticalAlert) return Theme.critical;
        if (root.isUnpluggedNotice) {
            if (BatteryService.isWarning) return Theme.warning;
            return Theme.bgDark;
        }
        return Theme.bgDark;
    }

    // Borde de la cápsula
    readonly property real alertBorderWidth: Theme.pillBorderWidth
    readonly property color alertBorderColor: {
        if (root.isPluggedNotice) return Theme.success;
        if (root.isCriticalAlert) return Theme.critical;
        if (root.isUnpluggedNotice) {
            if (BatteryService.isWarning) return Theme.warning;
            return Qt.rgba(1, 1, 1, 0.20);
        }
        return "transparent";
    }

    // Fondo de la cápsula
    readonly property color alertBgColor: {
        if (root.isPluggedNotice) return Theme.success;
        if (root.isCriticalAlert) return Theme.critical;
        if (root.isUnpluggedNotice) {
            if (BatteryService.isWarning) return Theme.warning;
            return Theme.bgDark;
        }
        return Theme.bgDark;
    }

    // Color de texto e ícono
    readonly property color contentColor: {
        if (root.isUnpluggedNotice && BatteryService.isWarning) {
            return "#161616"; // Máximo contraste sobre fondo amarillo #f1c40f
        }
        return "#ffffff";
    }

    // Micro-animación de latido sutil en el ícono de batería crítica
    property real iconPulseScale: 1.0
    SequentialAnimation {
        running: root.isCriticalAlert && !root.isPluggedNotice && !root.isUnpluggedNotice
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "iconPulseScale"
            to: 1.16
            duration: 650
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "iconPulseScale"
            to: 1.0
            duration: 650
            easing.type: Easing.InOutSine
        }
    }

    // Procesos de audio para retroalimentación sonora
    Process {
        id: soundAlert
        command: ["canberra-gtk-play", "-f", "/usr/share/sounds/freedesktop/stereo/dialog-error.oga"]
    }

    Process {
        id: soundPlugged
        command: ["canberra-gtk-play", "-f", "/usr/share/sounds/freedesktop/stereo/device-added.oga"]
    }

    Process {
        id: soundUnplugged
        command: ["canberra-gtk-play", "-f", "/usr/share/sounds/freedesktop/stereo/device-removed.oga"]
    }

    // Temporizador de 2.5 segundos para la confirmación de cargador conectado
    Timer {
        id: pluggedTimer
        interval: 2500
        onTriggered: {
            root.isPluggedNotice = false;
        }
    }

    // Temporizador de 2.0 segundos para la confirmación de cargador desconectado
    Timer {
        id: unpluggedTimer
        interval: 2000
        onTriggered: {
            root.isUnpluggedNotice = false;
        }
    }

    Connections {
        target: BatteryService

        function onShouldAlertCriticalChanged() {
            if (BatteryService.shouldAlertCritical) {
                root.isPluggedNotice = false;
                root.isUnpluggedNotice = false;
                pluggedTimer.stop();
                unpluggedTimer.stop();
                if (!soundAlert.running) {
                    soundAlert.running = true;
                }
            }
        }

        function onIsChargingChanged() {
            if (!root._initialized) return;

            if (BatteryService.isCharging) {
                // Al enchufar el cargador
                root.isUnpluggedNotice = false;
                unpluggedTimer.stop();
                root.isPluggedNotice = true;
                pluggedTimer.restart();
                if (!soundPlugged.running) {
                    soundPlugged.running = true;
                }
            } else {
                // Al desenchufar el cargador
                root.isPluggedNotice = false;
                pluggedTimer.stop();
                if (!root.isCriticalAlert) {
                    root.isUnpluggedNotice = true;
                    unpluggedTimer.restart();
                    if (!soundUnplugged.running) {
                        soundUnplugged.running = true;
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (BatteryService.shouldAlertCritical) {
            if (!soundAlert.running) soundAlert.running = true;
        }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 7

        Text {
            text: {
                if (root.isPluggedNotice) return "󰂄";
                if (root.isUnpluggedNotice) return BatteryService.icon;
                return "󰂃";
            }
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: root.contentColor
            Layout.alignment: Qt.AlignVCenter
            scale: (root.isCriticalAlert && !root.isPluggedNotice && !root.isUnpluggedNotice) ? root.iconPulseScale : 1.0
        }

        Text {
            text: {
                if (root.isPluggedNotice) return `Cargador conectado · ${BatteryService.percentage}%`;
                if (root.isUnpluggedNotice) return `Cargador desconectado · ${BatteryService.percentage}%`;
                return `Conectar cargador · ${BatteryService.percentage}%`;
            }
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: root.contentColor
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
