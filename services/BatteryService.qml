pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Io
import "../theme"

Item {
    id: root

    // Listas de íconos idénticas a config.jsonc de Waybar (11 niveles de 0% a 100%)
    readonly property var defaultIcons: [
        "󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"
    ]

    readonly property var chargingIcons: [
        "󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"
    ]

    // Lectura de sysfs como respaldo garantizado
    property int _sysCapacity: 100
    property string _sysStatus: "Discharging"

    Process {
        id: batReader
        command: ["sh", "-c", "printf '%s:%s\\n' \"$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1)\" \"$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n 1)\""]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(":");
                if (parts.length >= 2) {
                    let cap = parseInt(parts[0]);
                    if (!isNaN(cap)) root._sysCapacity = cap;
                    if (parts[1]) root._sysStatus = parts[1].trim();
                }
            }
        }
    }

    Timer {
        interval: 10000 // Actualiza cada 10 segundos
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!batReader.running) batReader.running = true;
        }
    }

    // Propiedades de simulación/prueba segura para QA
    property int testPercentage: -1
    property int testCharging: -1

    function setTestMode(percent, charging) {
        root._notifiedLow = false;
        root._notifiedFull = false;
        root.isSnoozed = false;
        root.testPercentage = percent;
        root.testCharging = charging ? 1 : 0;
        root.checkBatteryAlerts();
    }

    function clearTestMode() {
        root.testPercentage = -1;
        root.testCharging = -1;
        root.isSnoozed = false;
        root._notifiedLow = false;
        root._notifiedFull = false;
        root.checkBatteryAlerts();
    }

    // Control de posponer / silenciar alerta temporalmente (5 minutos)
    property bool isSnoozed: false

    Timer {
        id: snoozeTimer
        interval: 300000 // 5 minutos
        onTriggered: {
            root.isSnoozed = false;
        }
    }

    function snooze(): void {
        root.isSnoozed = true;
        snoozeTimer.restart();
    }

    function resetSnooze(): void {
        root.isSnoozed = false;
        snoozeTimer.stop();
    }

    // Porcentaje normalizado (0 - 100)
    readonly property int percentage: {
        if (root.testPercentage >= 0) return root.testPercentage;
        if (UPower.displayDevice && UPower.displayDevice.isPresent) {
            let p = UPower.displayDevice.percentage;
            return Math.max(0, Math.min(100, Math.round(p * 100)));
        }
        return root._sysCapacity;
    }

    // Estado de carga
    readonly property bool isCharging: {
        if (root.testCharging >= 0) return root.testCharging === 1;
        if (UPower.displayDevice && UPower.displayDevice.isPresent) {
            return UPower.displayDevice.state === UPowerDeviceState.Charging;
        }
        return root._sysStatus === "Charging";
    }

    // Banderas de estado para evitar spam de notificaciones
    property bool _notifiedLow: false
    property bool _notifiedFull: false

    function checkBatteryAlerts() {
        let p = root.percentage;
        let charging = root.isCharging;

        if (charging) {
            // Si se está cargando, reseteamos la advertencia de batería baja
            root._notifiedLow = false;

            // Caso: Carga Completa (100% o estado Full)
            if ((p >= 100 || root._sysStatus === "Full") && !root._notifiedFull) {
                root._notifiedFull = true;
                if (typeof NotificationService !== "undefined" && NotificationService) {
                    NotificationService.postInternalNotification(
                        "Batería",
                        "⚡ Carga Completa",
                        "La batería está al 100%. Ya puedes desconectar el cargador.",
                        1,
                        Quickshell.iconPath("battery-full-charged") || root.icon,
                        "/usr/share/sounds/freedesktop/stereo/complete.oga"
                    );
                }
            }
        } else {
            // Si se está descargando, reseteamos la bandera de carga completa
            root._notifiedFull = false;

            // Caso: Batería Baja (25% hasta 16%)
            if (p <= 25 && p > 15) {
                if (!root._notifiedLow) {
                    root._notifiedLow = true;
                    if (typeof NotificationService !== "undefined" && NotificationService) {
                        NotificationService.postInternalNotification(
                            "Batería",
                            "⚠️ Batería Baja",
                            `Te queda el ${p}% de energía.`,
                            1,
                            Quickshell.iconPath("battery-low") || root.icon,
                            "/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"
                        );
                    }
                }
            } else if (p > 25) {
                root._notifiedLow = false;
            }
        }
    }

    onPercentageChanged: checkBatteryAlerts()

    onIsChargingChanged: {
        if (isCharging) {
            root.resetSnooze();
        }
        checkBatteryAlerts();
    }

    // Umbrales de batería: Advertencia al 25% (amarillo), Crítica al 15% (rojo/alerta)
    readonly property bool isWarning: percentage <= 25 && !isCharging
    readonly property bool isCritical: percentage <= 15 && !isCharging

    // Condición para mostrar la alerta visual persistente
    readonly property bool shouldAlertCritical: isCritical && !isCharging && !isSnoozed

    // Cálculo del índice de ícono (0 a 10)
    readonly property int iconIndex: Math.min(10, Math.max(0, Math.floor(percentage / 10)))

    // Ícono actual
    readonly property string icon: isCharging ? chargingIcons[iconIndex] : defaultIcons[iconIndex]

    // Color del ícono según las reglas del sistema
    readonly property color color: {
        if (isCharging) return Theme.success;    // #42be65
        if (isCritical) return Theme.critical;   // #ee5396
        if (isWarning) return Theme.warning;     // #f1c40f
        return Theme.text;                       // #dde1e7
    }

    readonly property string tooltipText: {
        if (isCharging) return `Batería: ${percentage}% (Cargando)`;
        if (percentage === 100) return `Batería: ${percentage}% (Completa)`;
        return `Batería: ${percentage}%`;
    }
}

