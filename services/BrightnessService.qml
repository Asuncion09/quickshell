pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root

    property int brightnessPercent: 50
    readonly property string icon: {
        if (brightnessPercent < 33) return "󰃞";
        if (brightnessPercent < 66) return "󰃟";
        return "󰃠";
    }

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
        interval: 1500
        running: true
        onTriggered: {
            root._readyForOsd = true;
            root._lastReportedPercent = root.brightnessPercent;
        }
    }

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
                        root.brightnessPercent = val;
                    }
                }
            }
        }
    }

    Process {
        id: setProc
        command: ["brightnessctl", "set", "50%"]
    }

    function refresh() {
        if (readProc.running) readProc.running = false;
        readProc.running = true;
    }

    function setBrightness(pct) {
        let val = Math.max(5, Math.min(100, pct));
        root.brightnessPercent = val;
        root._lastReportedPercent = val;
        if (root._readyForOsd) {
            root.brightnessChangedTriggered(val);
        }
        if (setProc.running) setProc.running = false;
        setProc.command = ["brightnessctl", "set", val + "%"];
        setProc.running = true;
    }

    function increase(step) {
        let s = step || 5;
        let next = Math.min(100, Math.floor(brightnessPercent / s) * s + s);
        setBrightness(next);
    }

    function decrease(step) {
        let s = step || 5;
        let prev = Math.max(5, Math.ceil(brightnessPercent / s) * s - s);
        setBrightness(prev);
    }

    // Sincronización de fondo ocasional para cambios externos sin disparar OSD innecesario
    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
