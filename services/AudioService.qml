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
    readonly property string sinkName: defaultSink ? (defaultSink.description || defaultSink.name || "Altavoz") : "Sin salida"

    // Icono estable según el estado de silencio.
    // Usamos el glifo completo de altavoz con ondas (󰕾) para garantizar simetría y peso visual estable en la barra y sliders
    readonly property string icon: {
        if (isMuted || volumePercent === 0) return "󰝟";
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
        } else {
            if (wpctlProc.running) wpctlProc.running = false;
            wpctlProc.command = ["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", normalized.toFixed(2)];
            wpctlProc.running = true;
        }
        if (root._readyForOsd) {
            root.volumeChangedTriggered(clamped, root.isMuted);
        }
    }

    function increaseVolume(step) {
        if (root.isMuted) {
            // Si está en silencio, preservar el volumen anterior y solo mostrar el aviso OSD en Mute
            if (root._readyForOsd) {
                root.volumeChangedTriggered(root.currentPercent, true);
            }
            return;
        }
        let s = step || 5;
        let next = Math.min(100, Math.floor(currentPercent / s) * s + s);
        setVolume(next);
    }

    function decreaseVolume(step) {
        if (root.isMuted) {
            // Si está en silencio, preservar el volumen anterior y solo mostrar el aviso OSD en Mute
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

    // --- Control de Micrófono ---
    readonly property PwNode defaultSource: Pipewire.defaultAudioSource
    readonly property bool isMicMuted: (defaultSource && defaultSource.audio) ? defaultSource.audio.muted : false

    Process {
        id: micWpctlProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
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
    }
}
