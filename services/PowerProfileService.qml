pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    // Perfiles disponibles: "power-save" | "balanced" | "performance"
    property string currentProfile: "balanced"
    property string label: "Balance"
    property string icon: "󰾆"
    property color accentColor: Theme.text

    readonly property string stateFilePath: Quickshell.env("HOME") + "/.config/quickshell/state/power_profile.txt"
    readonly property string applyScriptPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/ryzenadj/apply-profile.sh"

    function updateMetadata(profile) {
        root.currentProfile = profile;
        if (profile === "power-save") {
            root.label = "Eco";
            root.icon = "󰌪";
            root.accentColor = Theme.success;
        } else if (profile === "performance") {
            root.label = "Turbo";
            root.icon = "󰓅";
            root.accentColor = Theme.warning;
        } else {
            root.currentProfile = "balanced";
            root.label = "Balance";
            root.icon = "󰾆";
            root.accentColor = Theme.text;
        }
    }

    // Proceso asíncrono para aplicar el perfil a nivel de hardware y kernel
    Process {
        id: applyProc
    }

    function applyHardwareLimits(profile) {
        if (!profile) return;
        if (applyProc.running) applyProc.running = false;
        applyProc.command = ["sh", root.applyScriptPath, profile];
        applyProc.running = true;
    }

    // Proceso para leer el perfil actual de powerprofilesctl al inicio si no hay archivo de estado
    Process {
        id: readPpdProc
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: data => {
                let p = data.trim();
                let prof = "balanced";
                if (p === "power-saver" || p === "power-save") prof = "power-save";
                else if (p === "performance") prof = "performance";
                root.updateMetadata(prof);
                root.applyHardwareLimits(prof);
            }
        }
    }

    // Guardar estado persistente
    Process {
        id: saveStateProc
    }

    function setProfile(profile) {
        if (!profile) return;
        let p = profile.trim();
        if (p === "power-saver") p = "power-save";
        if (p === "gaming") p = "performance";

        root.updateMetadata(p);

        // 1. Ejecutar script unificado (PPD + RyzenAdj)
        root.applyHardwareLimits(p);

        // 2. Guardar estado para persistencia entre reinicios
        if (saveStateProc.running) saveStateProc.running = false;
        saveStateProc.command = ["sh", "-c", "mkdir -p $(dirname " + root.stateFilePath + ") && echo " + p + " > " + root.stateFilePath];
        saveStateProc.running = true;

        // 3. Mostrar confirmación en la Dynamic Island (OSD)
        OsdService.showOsd("power", 0, root.icon, false);
    }

    function cycleProfile() {
        if (root.currentProfile === "power-save") {
            root.setProfile("balanced");
        } else if (root.currentProfile === "balanced") {
            root.setProfile("performance");
        } else {
            root.setProfile("power-save");
        }
    }

    // Proceso para leer estado guardado al iniciar sesión
    Process {
        id: readStateProc
        command: ["sh", "-c", "cat " + root.stateFilePath + " 2>/dev/null || true"]
        stdout: SplitParser {
            onRead: data => {
                let saved = data.trim();
                if (saved === "power-save" || saved === "balanced" || saved === "performance") {
                    root.updateMetadata(saved);
                    // Re-aplicar silenciosamente a nivel de hardware al iniciar la sesión
                    root.applyHardwareLimits(saved);
                } else {
                    readPpdProc.running = true;
                }
            }
        }
    }

    // Proceso permanente para detectar cuando el sistema despierta de suspensión (systemd / login1)
    Process {
        id: sleepMonitorProc
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1"]
        stdout: SplitParser {
            onRead: data => {
                // Cuando PrepareForSleep pasa a false, el sistema ha vuelto de suspensión
                if (data.includes("PrepareForSleep") && data.includes("false")) {
                    console.log("[PowerProfileService] Sistema reanudado de suspensión. Re-aplicando perfil de hardware:", root.currentProfile);
                    root.applyHardwareLimits(root.currentProfile);
                }
            }
        }
        onExited: {
            sleepReconnectTimer.start();
        }
    }

    Timer {
        id: sleepReconnectTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if (!sleepMonitorProc.running) sleepMonitorProc.running = true;
        }
    }

    Component.onCompleted: {
        readStateProc.running = true;
        sleepMonitorProc.running = true;
    }
}
