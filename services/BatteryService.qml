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

    // Lectura de sysfs como respaldo y acelerador de eventos instantáneos
    property int _sysCapacity: 100
    property string _sysStatus: "Discharging"
    property bool _sysAcOnline: false
    property bool _pendingRead: false

    function requestImmediateRead() {
        if (!batReader.running) {
            batReader.running = true;
        } else {
            root._pendingRead = true;
        }
    }

    Process {
        id: batReader
        command: ["sh", "-c", "printf '%s:%s:%s\\n' \"$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1)\" \"$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n 1)\" \"$(cat /sys/class/power_supply/{AC,ACAD,ADP,A}*/online 2>/dev/null | head -n 1)\""]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(":");
                if (parts.length >= 2) {
                    let cap = parseInt(parts[0]);
                    if (!isNaN(cap)) root._sysCapacity = cap;
                    if (parts[1]) root._sysStatus = parts[1].trim();
                }
                if (parts.length >= 3) {
                    let online = parts[2].trim();
                    root._sysAcOnline = (online === "1");
                }
            }
        }
        onExited: {
            if (root._pendingRead) {
                root._pendingRead = false;
                batReader.running = true;
            }
        }
    }

    // Monitor en tiempo real de eventos del kernel (udev) para detección en <10ms al enchufar/desenchufar
    Process {
        id: udevProc
        command: ["udevadm", "monitor", "--kernel", "--subsystem-match=power_supply"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.requestImmediateRead();
            }
        }
    }

    // Reacción inmediata ante cambios del demonio UPower
    Connections {
        target: UPower
        function onOnBatteryChanged() {
            root.requestImmediateRead();
        }
    }

    // Temporizador de respaldo periódico (30s)
    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.requestImmediateRead();
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

    // Estado de carga / conexión a corriente (reactivo e instantáneo)
    readonly property bool isCharging: {
        if (root.testCharging >= 0) return root.testCharging === 1;
        // Prioridad 1: Detección por hardware a nivel de kernel/sysfs (/sys/class/power_supply/ACAD/online)
        if (root._sysAcOnline) return true;
        // Prioridad 2: Estado del demonio UPower (!OnBattery = conectado a corriente)
        if (UPower.onBattery !== undefined && !UPower.onBattery) return true;
        // Prioridad 3: Estado específico de la batería reportado por UPower
        if (UPower.displayDevice && UPower.displayDevice.isPresent) {
            let s = UPower.displayDevice.state;
            if (s === UPowerDeviceState.Charging || s === UPowerDeviceState.FullyCharged) {
                return true;
            }
        }
        // Prioridad 4: Respaldo de texto directo de sysfs
        return root._sysStatus === "Charging" || root._sysStatus === "Full";
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
                        "⚡ Carga completa",
                        "Batería al 100%. Puedes desconectar el cargador.",
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
                            `⚠️ Batería baja (${p}%)`,
                            "Conecta el cargador pronto.",
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

    // --- Retroalimentación sonora centralizada y global (Singleton) ---
    // Al ser un servicio singleton, garantiza que el sonido suene exactamente una vez,
    // independientemente del número de monitores conectados (1, 2 o más pantallas).
    property bool _audioInitialized: false
    Timer {
        id: audioInitTimer
        interval: 1200
        running: true
        onTriggered: root._audioInitialized = true
    }

    Timer {
        id: soundDebounceTimer
        interval: 800
        repeat: false
    }

    Process {
        id: soundPlugged
        command: ["canberra-gtk-play", "-f", "/usr/share/sounds/freedesktop/stereo/device-added.oga"]
    }

    Process {
        id: soundUnplugged
        command: ["canberra-gtk-play", "-f", "/usr/share/sounds/freedesktop/stereo/device-removed.oga"]
    }

    Process {
        id: soundAlert
        command: ["canberra-gtk-play", "-f", "/usr/share/sounds/freedesktop/stereo/dialog-error.oga"]
    }

    function playPluggedSound() {
        if (!root._audioInitialized || soundDebounceTimer.running) return;
        soundDebounceTimer.restart();
        if (!soundPlugged.running) soundPlugged.running = true;
    }

    function playUnpluggedSound() {
        if (!root._audioInitialized || soundDebounceTimer.running) return;
        soundDebounceTimer.restart();
        if (!soundUnplugged.running) soundUnplugged.running = true;
    }

    function playCriticalAlertSound() {
        if (!root._audioInitialized || soundDebounceTimer.running) return;
        soundDebounceTimer.restart();
        if (!soundAlert.running) soundAlert.running = true;
    }

    onPercentageChanged: checkBatteryAlerts()

    onIsChargingChanged: {
        if (isCharging) {
            root.resetSnooze();
            root.playPluggedSound();
            // Si la batería ya está al 100% al momento de conectar, marcar como ya notificado
            // para evitar solapar el sonido de conexión con el de carga completa
            if (root.percentage >= 100 || root._sysStatus === "Full") {
                root._notifiedFull = true;
            }
        } else {
            root._notifiedFull = false;
            if (!root.isCritical) {
                root.playUnpluggedSound();
            }
        }
        checkBatteryAlerts();
    }

    onShouldAlertCriticalChanged: {
        if (shouldAlertCritical) {
            root.playCriticalAlertSound();
        }
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

