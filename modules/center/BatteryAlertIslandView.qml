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
        if (root.isPluggedNotice) return Qt.rgba(66/255, 190/255, 101/255, 0.40);
        if (root.isCriticalAlert) return Qt.rgba(238/255, 83/255, 150/255, 0.50);
        if (root.isUnpluggedNotice) {
            if (BatteryService.isWarning) return Qt.rgba(241/255, 196/255, 15/255, 0.40);
            return Qt.rgba(1, 1, 1, 0.16);
        }
        return "transparent";
    }

    // Fondo de la cápsula: se conserva el fondo oscuro elegante de la isla dinámica
    readonly property color alertBgColor: Theme.bgDark

    // Color del ícono según el estado semántico
    readonly property color iconColor: {
        if (root.isPluggedNotice) return Theme.success;
        if (root.isCriticalAlert) return Theme.critical;
        if (root.isUnpluggedNotice && BatteryService.isWarning) return Theme.warning;
        return Theme.textSecondary;
    }

    // Color de texto
    readonly property color contentColor: Theme.text

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
            } else {
                // Al desenchufar el cargador
                root.isPluggedNotice = false;
                pluggedTimer.stop();
                if (!root.isCriticalAlert) {
                    root.isUnpluggedNotice = true;
                    unpluggedTimer.restart();
                }
            }
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
            color: root.iconColor
            Layout.alignment: Qt.AlignVCenter
            scale: (root.isCriticalAlert && !root.isPluggedNotice && !root.isUnpluggedNotice) ? root.iconPulseScale : 1.0
        }

        Text {
            text: {
                if (root.isPluggedNotice) return `Cargador conectado · ${BatteryService.percentage}%`;
                if (root.isUnpluggedNotice) return `Cargador desconectado · ${BatteryService.percentage}%`;
                return `Batería baja · ${BatteryService.percentage}%`;
            }
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: root.contentColor
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
