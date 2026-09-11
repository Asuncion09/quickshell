pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root

    property int laptopBrightness: 50
    property int externalBrightness: 50

    property bool hasExternalMonitor: false
    property string externalMonitorName: ""
    property bool hasDdcutil: false

    // Detección reactiva de qué monitor tiene el foco de teclado/cursor actualmente
    readonly property string currentFocusedMonitor: {
        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) {
            return Hyprland.focusedMonitor.name;
        }
        if (Hyprland.monitors && Hyprland.monitors.values) {
            for (let i = 0; i < Hyprland.monitors.values.length; i++) {
                let m = Hyprland.monitors.values[i];
                if (m && m.focused && m.name) return m.name;
            }
        }
        return "eDP-1";
    }

    function isExternal(monName) {
        let name = (monName !== undefined && monName !== "") ? monName : root.currentFocusedMonitor;
        return root.hasExternalMonitor && (name !== "eDP-1");
    }

    function getBrightness(monName) {
        return isExternal(monName) ? root.externalBrightness : root.laptopBrightness;
    }

    function getIcon(monName) {
        let val = getBrightness(monName);
        if (val < 33) return "󰃞";
        if (val < 66) return "󰃟";
        return "󰃠";
    }

    // Valor reactivo expuesto para el monitor con foco activo actual
    readonly property int brightnessPercent: getBrightness(root.currentFocusedMonitor)
    readonly property string icon: getIcon(root.currentFocusedMonitor)

    signal brightnessChangedTriggered(int percent)

    property bool _readyForOsd: false
    property int _lastReportedPercent: -1

    onBrightnessPercentChanged: {
        if (root._readyForOsd) {
            if (root.brightnessPercent !== root._lastReportedPercent) {
                root._lastReportedPercent = root.brightnessPercent;
                root.brightnessChangedTriggered(root.brightnessPercent);
            }
        }
    }

    Timer {
        id: initTimer
        interval: 1200
        running: true
        onTriggered: {
            root._readyForOsd = true;
            root._lastReportedPercent = root.brightnessPercent;
            root.checkMonitors();
        }
    }

    // 1. Detección de monitores conectados en Hyprland / Quickshell
    function checkMonitors() {
        let extFound = false;
        let extName = "";
        if (Hyprland.monitors && Hyprland.monitors.values) {
            for (let i = 0; i < Hyprland.monitors.values.length; i++) {
                let m = Hyprland.monitors.values[i];
                if (m && m.name && m.name !== "eDP-1") {
                    extFound = true;
                    extName = m.name;
                    break;
                }
            }
        } else if (Quickshell.screens && Quickshell.screens.length > 1) {
            extFound = true;
            extName = "HDMI-A-1";
        }
        root.hasExternalMonitor = extFound;
        root.externalMonitorName = extName;

        if (!whichDdcProc.running) {
            whichDdcProc.running = true;
        }
    }

    // 2. Detección de disponibilidad de ddcutil en el sistema
    Process {
        id: whichDdcProc
        command: ["which", "ddcutil"]
        onExited: exitCode => {
            let found = (exitCode === 0);
            if (root.hasDdcutil !== found) {
                root.hasDdcutil = found;
                console.log("[BrightnessService] ddcutil disponible:", found);
            }
            if (root.hasDdcutil && root.hasExternalMonitor) {
                root.readDdcBrightness();
            }
        }
    }

    // 3. Lectura de brillo interno de Laptop con brightnessctl
    Process {
        id: readProc
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: data => {
                let text = data.trim();
                if (text === "") return;
                let parts = text.split(",");
                if (parts.length >= 4) {
                    let pctStr = parts[3].replace("%", "").trim();
                    let val = parseInt(pctStr);
                    if (!isNaN(val)) {
                        root.laptopBrightness = val;
                    }
                }
            }
        }
    }

    // Proceso de aplicación instantánea para la laptop
    Process {
        id: setProc
        command: ["brightnessctl", "set", "50%"]
    }

    function setLaptopBrightness(pct) {
        let val = Math.max(5, Math.min(100, pct));
        root.laptopBrightness = val;
        if (setProc.running) setProc.running = false;
        setProc.command = ["brightnessctl", "set", val + "%"];
        setProc.running = true;
    }

    // 4. Lectura de brillo de Monitor Externo con ddcutil (VCP code 10 = Brillo)
    Process {
        id: ddcReadProc
        command: ["sh", "-c", "ddcutil getvcp 10 --brief 2>&1"]
        stdout: SplitParser {
            onRead: data => {
                let text = data.trim();
                if (text.indexOf("VCP 10") >= 0) {
                    let parts = text.split(/\s+/);
                    if (parts.length >= 4) {
                        let val = parseInt(parts[3]);
                        if (!isNaN(val) && val >= 0 && val <= 100) {
                            root.externalBrightness = val;
                        }
                    }
                } else if (text.indexOf("Permission denied") >= 0 || text.indexOf("EACCES") >= 0) {
                    console.log("[BrightnessService] DDC/CI permiso denegado en /dev/i2c-*:", text);
                }
            }
        }
    }

    function readDdcBrightness() {
        if (!root.hasDdcutil || !root.hasExternalMonitor) return;
        if (!ddcReadProc.running) ddcReadProc.running = true;
    }

    // 5. Aplicación con Throttling / Debouncing para ddcutil (evita saturar el bus I2C)
    property int _pendingDdcBrightness: -1

    Timer {
        id: ddcDebounceTimer
        interval: 180
        repeat: false
        onTriggered: {
            if (root._pendingDdcBrightness >= 0 && root.hasDdcutil) {
                root._executeDdcSet(root._pendingDdcBrightness);
            }
        }
    }

    Process {
        id: setDdcProc
        stderr: SplitParser {
            onRead: data => {
                let err = data.trim();
                if (err !== "") {
                    console.log("[BrightnessService ddcutil error]:", err);
                }
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.log("[BrightnessService] setvcp finalizó con código:", exitCode);
            }
            if (root._pendingDdcBrightness >= 0 && root._pendingDdcBrightness !== root.externalBrightness) {
                ddcDebounceTimer.restart();
            }
        }
    }

    function _executeDdcSet(val) {
        if (setDdcProc.running) return;
        setDdcProc.command = ["sh", "-c", "ddcutil setvcp 10 " + val + " --noverify"];
        setDdcProc.running = true;
    }

    function setExternalBrightness(pct) {
        let val = Math.max(0, Math.min(100, pct));
        root.externalBrightness = val;
        root._pendingDdcBrightness = val;
        ddcDebounceTimer.restart();
    }

    // 6. Conmutador y Despacho unificado contextual por monitor
    function setBrightness(pct, monName) {
        let val = Math.max(5, Math.min(100, pct));
        let targetExternal = isExternal(monName);

        if (targetExternal) {
            setExternalBrightness(val);
        } else {
            setLaptopBrightness(val);
        }

        root._lastReportedPercent = val;
        if (root._readyForOsd) {
            root.brightnessChangedTriggered(val);
        }
    }

    function increase(step, monName) {
        let s = step || 5;
        let current = getBrightness(monName);
        let next = Math.min(100, Math.floor(current / s) * s + s);
        setBrightness(next, monName);
    }

    function decrease(step, monName) {
        let s = step || 5;
        let current = getBrightness(monName);
        let prev = Math.max(5, Math.ceil(current / s) * s - s);
        setBrightness(prev, monName);
    }

    function refresh() {
        if (readProc.running) readProc.running = false;
        readProc.running = true;
    }

    // 7. Monitoreo reactivo de cambios de hardware y temporizador de actualización periódica
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event) return;
            let n = event.name;
            if (n === "monitoradded" || n === "monitorremoved") {
                root.checkMonitors();
            }
        }
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.hasDdcutil && !whichDdcProc.running) {
                whichDdcProc.running = true;
            }
            root.refresh();
            if (root.hasDdcutil && root.hasExternalMonitor && root.selectedDisplay === "external") {
                root.readDdcBrightness();
            }
        }
    }
}
