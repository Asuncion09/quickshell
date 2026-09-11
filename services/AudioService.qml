pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire
import Quickshell.Io

Item {
    id: root

    // PwObjectTracker enlaza (bind) los nodos para habilitar sincronización y control de volumen en tiempo real
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    readonly property PwNode defaultSink: Pipewire.defaultAudioSink
    readonly property real volume: (defaultSink && defaultSink.audio) ? defaultSink.audio.volume : 0.0
    readonly property int volumePercent: Math.round(volume * 100)
    readonly property bool isMuted: (defaultSink && defaultSink.audio) ? defaultSink.audio.muted : false
    readonly property string sinkName: defaultSink ? (defaultSink.description || defaultSink.name || "Speaker") : "No output"

    // Icono general de volumen
    readonly property string icon: {
        if (isMuted || volumePercent === 0) return "󰝟";
        return "󰕾";
    }

    // Icono contextual de salida (según el tipo de dispositivo activo)
    readonly property string outputIcon: {
        if (isMuted || volumePercent === 0) return "󰝟";
        for (let i = 0; i < sinks.length; i++) {
            if (sinks[i].isDefault && sinks[i].icon) {
                return sinks[i].icon;
            }
        }
        let lower = sinkName.toLowerCase();
        if (lower.includes("blue") || lower.includes("airpod") || lower.includes("buds")) return "󰂯";
        if (lower.includes("headphone") || lower.includes("headset") || lower.includes("auricular") || lower.includes("jack")) return "󰋋";
        if (lower.includes("hdmi") || lower.includes("displayport") || lower.includes("dp")) return "󰡁";
        return "󰕾";
    }

    signal volumeChangedTriggered(int percent, bool muted)
    signal micMutedTriggered(bool muted)

    // Evitar que el OSD aparezca durante la carga inicial
    property bool _readyForOsd: false
    Timer {
        id: initTimer
        interval: 1500
        running: true
        onTriggered: root._readyForOsd = true
    }

    property int currentPercent: 50
    property int _lastReportedPercent: -1
    property bool _lastReportedMuted: false

    onVolumePercentChanged: {
        root.currentPercent = root.volumePercent;
    }

    onVolumeChanged: {
        if (root._readyForOsd) {
            let pct = root.volumePercent;
            if (pct !== root._lastReportedPercent) {
                root._lastReportedPercent = pct;
                root.volumeChangedTriggered(pct, root.isMuted);
            }
        }
    }

    onIsMutedChanged: {
        if (root._readyForOsd) {
            if (root.isMuted !== root._lastReportedMuted) {
                root._lastReportedMuted = root.isMuted;
                root.volumeChangedTriggered(root.currentPercent, root.isMuted);
            }
        }
    }

    Process {
        id: wpctlProc
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "0.5"]
    }

    function setVolume(pct) {
        let clamped = Math.max(0, Math.min(150, pct));
        let normalized = clamped / 100.0;
        root.currentPercent = clamped;
        root._lastReportedPercent = clamped;

        if (defaultSink && defaultSink.audio) {
            defaultSink.audio.volume = normalized;
        }
        if (wpctlProc.running) wpctlProc.running = false;
        wpctlProc.command = ["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", normalized.toFixed(2)];
        wpctlProc.running = true;

        if (root._readyForOsd) {
            root.volumeChangedTriggered(clamped, root.isMuted);
        }
    }

    function increaseVolume(step) {
        if (root.isMuted) {
            if (root._readyForOsd) {
                root.volumeChangedTriggered(root.currentPercent, true);
            }
            return;
        }
        let s = step || 5;
        let next = Math.min(150, Math.floor(currentPercent / s) * s + s);
        setVolume(next);
    }

    function decreaseVolume(step) {
        if (root.isMuted) {
            if (root._readyForOsd) {
                root.volumeChangedTriggered(root.currentPercent, true);
            }
            return;
        }
        let s = step || 5;
        let prev = Math.max(0, Math.ceil(currentPercent / s) * s - s);
        setVolume(prev);
    }

    function toggleMute() {
        let newMute = !root.isMuted;
        root._lastReportedMuted = newMute;
        if (defaultSink && defaultSink.audio) {
            defaultSink.audio.muted = newMute;
        } else {
            if (wpctlProc.running) wpctlProc.running = false;
            wpctlProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", newMute ? "1" : "0"];
            wpctlProc.running = true;
        }
        if (root._readyForOsd) {
            root.volumeChangedTriggered(root.currentPercent, newMute);
        }
    }

    // --- Control de Micrófono (Input) ---
    readonly property PwNode defaultSource: Pipewire.defaultAudioSource
    readonly property bool isMicMuted: (defaultSource && defaultSource.audio) ? defaultSource.audio.muted : false
    readonly property real micVolume: (defaultSource && defaultSource.audio) ? defaultSource.audio.volume : 1.0
    readonly property int micVolumePercent: Math.round(micVolume * 100)
    readonly property string inputIcon: isMicMuted ? "󰍭" : "󰍬"

    Process {
        id: micWpctlProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
    }

    Process {
        id: micVolProc
    }

    function toggleMicMute() {
        let newMute = !root.isMicMuted;
        if (defaultSource && defaultSource.audio) {
            defaultSource.audio.muted = newMute;
        } else {
            if (micWpctlProc.running) micWpctlProc.running = false;
            micWpctlProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", newMute ? "1" : "0"];
            micWpctlProc.running = true;
        }
        if (root._readyForOsd) {
            root.micMutedTriggered(newMute);
        }
        Qt.callLater(() => refreshDevicesTimer.restart());
    }

    function setMicVolume(pct) {
        let clamped = Math.max(0, Math.min(150, pct));
        let norm = (clamped / 100.0).toFixed(2);
        if (defaultSource && defaultSource.audio) {
            defaultSource.audio.volume = clamped / 100.0;
        }
        if (micVolProc.running) micVolProc.running = false;
        micVolProc.command = ["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SOURCE@", norm];
        micVolProc.running = true;
    }

    // =================================================================
    // GESTIÓN DE DISPOSITIVOS DE AUDIO (SINKS Y SOURCES VIA WPCTL)
    // =================================================================
    property var sinks: []
    property var sources: []
    readonly property bool isRefreshing: statusProc.running
    property var _accumulatedStatusLines: []

    Process {
        id: statusProc
        command: ["wpctl", "status"]
        onStarted: root._accumulatedStatusLines = []
        stdout: SplitParser {
            onRead: data => {
                let text = data.trim();
                if (text) {
                    let lines = text.split("\n");
                    for (let i = 0; i < lines.length; i++) {
                        let s = lines[i];
                        if (s !== undefined && s !== null) root._accumulatedStatusLines.push(s);
                    }
                }
            }
        }
        onExited: {
            root.parseWpctlStatus(root._accumulatedStatusLines);
        }
    }

    function parseWpctlStatus(lines) {
        let currentSection = null;
        let newSinks = [];
        let newSources = [];

        for (let i = 0; i < lines.length; i++) {
            let line = lines[i];
            let stripped = line.trim();

            if (stripped.indexOf("Sinks:") !== -1) {
                currentSection = "sinks";
                continue;
            } else if (stripped.indexOf("Sources:") !== -1) {
                currentSection = "sources";
                continue;
            } else if (stripped.indexOf("Filters:") !== -1 || stripped.indexOf("Streams:") !== -1 || stripped.indexOf("Devices:") !== -1 || stripped.indexOf("Video") !== -1 || stripped.indexOf("Settings") !== -1) {
                currentSection = null;
                continue;
            }

            if (currentSection === "sinks" || currentSection === "sources") {
                let cleaned = line.replace(/│/g, "").replace(/├/g, "").replace(/└/g, "").replace(/─/g, "").trim();
                if (!cleaned) continue;

                let isDefault = cleaned.startsWith("*");
                if (isDefault) {
                    cleaned = cleaned.substring(1).trim();
                }

                // Formato: "45. Ryzen HD Audio Controller Analog Stereo [vol: 1.50] [MUTED]"
                let m = cleaned.match(/^(\d+)\.\s+(.*?)(?:\s+\[vol:\s*([\d\.]+)\])?(?:\s+\[MUTED\])?$/);
                if (m) {
                    let nodeId = parseInt(m[1]);
                    let name = m[2].trim();
                    let vol = m[3] ? parseFloat(m[3]) : 1.0;
                    let isMuted = cleaned.indexOf("[MUTED]") !== -1;

                    let lower = name.toLowerCase();
                    let devType = "speaker";
                    let iconGlyph = "󰓃";

                    if (currentSection === "sinks") {
                        if (lower.includes("blue") || lower.includes("airpod") || lower.includes("freebud") || lower.includes("wh-") || lower.includes("wf-") || lower.includes("buds")) {
                            devType = "bluetooth";
                            iconGlyph = "󰂯";
                        } else if (lower.includes("headphone") || lower.includes("headset") || lower.includes("auricular") || lower.includes("jack")) {
                            devType = "headphones";
                            iconGlyph = "󰋋";
                        } else if (lower.includes("hdmi") || lower.includes("displayport") || lower.includes("dp")) {
                            devType = "hdmi";
                            iconGlyph = "󰡁";
                        } else if (lower.includes("usb")) {
                            devType = "usb";
                            iconGlyph = "󰓃";
                        } else {
                            devType = "speaker";
                            iconGlyph = "󰓃";
                        }
                    } else {
                        // Entrada / Micrófono
                        if (lower.includes("blue") || lower.includes("airpod") || lower.includes("headset")) {
                            devType = "bluetooth_mic";
                            iconGlyph = "󰂯";
                        } else if (lower.includes("camera") || lower.includes("camara")) {
                            devType = "webcam";
                            iconGlyph = "󰄀";
                        } else if (lower.includes("headset") || lower.includes("auricular")) {
                            devType = "headset_mic";
                            iconGlyph = "󰋋";
                        } else {
                            devType = "mic";
                            iconGlyph = "󰍬";
                        }
                    }

                    let devObj = {
                        id: nodeId,
                        name: name,
                        isDefault: isDefault,
                        volume: vol,
                        volumePercent: Math.round(vol * 100),
                        isMuted: isMuted,
                        type: devType,
                        icon: iconGlyph
                    };

                    if (currentSection === "sinks") {
                        newSinks.push(devObj);
                    } else {
                        newSources.push(devObj);
                    }
                }
            }
        }

        root.sinks = newSinks;
        root.sources = newSources;
    }

    function refreshDevices() {
        if (statusProc.running) statusProc.running = false;
        statusProc.running = true;
    }

    Process {
        id: switchSinkProc
    }

    Process {
        id: switchSourceProc
    }

    function setDefaultSink(nodeId) {
        if (!nodeId) return;
        switchSinkProc.command = ["wpctl", "set-default", nodeId.toString()];
        if (switchSinkProc.running) switchSinkProc.running = false;
        switchSinkProc.running = true;
        refreshDevicesTimer.restart();
    }

    function setDefaultSource(nodeId) {
        if (!nodeId) return;
        switchSourceProc.command = ["wpctl", "set-default", nodeId.toString()];
        if (switchSourceProc.running) switchSourceProc.running = false;
        switchSourceProc.running = true;
        refreshDevicesTimer.restart();
    }

    Timer {
        id: refreshDevicesTimer
        interval: 200
        repeat: false
        onTriggered: root.refreshDevices()
    }

    Timer {
        id: autoPollDevicesTimer
        interval: 4000
        repeat: true
        running: true
        onTriggered: root.refreshDevices()
    }

    Component.onCompleted: {
        root.refreshDevices();
    }
}
