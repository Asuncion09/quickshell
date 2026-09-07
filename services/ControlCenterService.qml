pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: root

    property bool isOpen: false

    function toggle() {
        root.isOpen = !root.isOpen;
    }

    function open() {
        root.isOpen = true;
    }

    function close() {
        root.isOpen = false;
    }

    // --- Control de Micrófono con Pipewire (enlazado a AudioService) ---
    readonly property bool isMicMuted: AudioService.isMicMuted

    function toggleMicMute() {
        AudioService.toggleMicMute();
    }

    // --- Control de Wi-Fi ---
    Process {
        id: wifiToggleProc
        command: ["sh", "-c", "if nmcli radio wifi | grep -q 'enabled'; then nmcli radio wifi off; else nmcli radio wifi on; fi"]
    }

    function toggleWifi() {
        if (wifiToggleProc.running) wifiToggleProc.running = false;
        wifiToggleProc.running = true;
    }

    // --- Control de Bluetooth ---
    Process {
        id: btToggleProc
        command: ["sh", "-c", "if bluetoothctl show | grep -q 'Powered: yes'; then bluetoothctl power off; else bluetoothctl power on; fi"]
    }

    function toggleBluetooth() {
        if (btToggleProc.running) btToggleProc.running = false;
        btToggleProc.running = true;
    }

    // --- Control de No Molestar (DND) ---
    property bool isDnd: false

    Process {
        id: dndCheckProc
        command: ["swaync-client", "-D"]
        stdout: SplitParser {
            onRead: data => {
                let val = data.trim();
                root.isDnd = (val === "true");
            }
        }
    }

    Process {
        id: dndToggleProc
        command: ["swaync-client", "-d", "-sw"]
        onExited: {
            dndCheckProc.running = true;
        }
    }

    function toggleDnd() {
        root.isDnd = !root.isDnd;
        if (dndToggleProc.running) dndToggleProc.running = false;
        dndToggleProc.running = true;
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!dndCheckProc.running) dndCheckProc.running = true;
        }
    }

    // --- Acciones de Sistema ---
    Process {
        id: lockProc
        command: ["hyprlock"]
    }

    function lockScreen() {
        root.close();
        if (!lockProc.running) lockProc.running = true;
    }
}

