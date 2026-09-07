pragma Singleton
import QtQuick
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

    // Porcentaje normalizado (0 - 100)
    readonly property int percentage: {
        if (UPower.displayDevice && UPower.displayDevice.isPresent) {
            let p = UPower.displayDevice.percentage;
            return Math.max(0, Math.min(100, Math.round(p * 100)));
        }
        return root._sysCapacity;
    }

    // Estado de carga
    readonly property bool isCharging: {
        if (UPower.displayDevice && UPower.displayDevice.isPresent) {
            return UPower.displayDevice.state === UPowerDeviceState.Charging;
        }
        return root._sysStatus === "Charging";
    }

    readonly property bool isWarning: percentage <= 30 && !isCharging
    readonly property bool isCritical: percentage <= 15 && !isCharging

    // Cálculo del índice de ícono (0 a 10)
    readonly property int iconIndex: Math.min(10, Math.max(0, Math.floor(percentage / 10)))

    // Ícono actual
    readonly property string icon: isCharging ? chargingIcons[iconIndex] : defaultIcons[iconIndex]

    // Color del ícono según las reglas de style.css
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

