pragma Singleton
import QtQuick
import Quickshell.Io

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
        root.isPowerMenuOpen = false;
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

    // --- Acciones de Sistema y Energía ---
    property bool isPowerMenuOpen: false

    function togglePowerMenu() {
        root.isPowerMenuOpen = !root.isPowerMenuOpen;
    }

    Process {
        id: sysActionProc
    }

    function runSysCommand(cmd) {
        root.close();
        root.isPowerMenuOpen = false;
        if (sysActionProc.running) sysActionProc.running = false;
        sysActionProc.command = cmd;
        sysActionProc.running = true;
    }

    function lockScreen() {
        runSysCommand(["hyprlock"]);
    }

    function suspend() {
        runSysCommand(["systemctl", "suspend"]);
    }

    function reboot() {
        runSysCommand(["systemctl", "reboot"]);
    }

    function shutdown() {
        runSysCommand(["systemctl", "poweroff"]);
    }

    function logout() {
        runSysCommand(["hyprctl", "dispatch", "exit"]);
    }
}

