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

    Process {
        id: wifiConnProc
    }

    function toggleWifi() {
        if (wifiToggleProc.running) wifiToggleProc.running = false;
        wifiToggleProc.running = true;
    }

    function connectWifi(ssid) {
        if (wifiConnProc.running) wifiConnProc.running = false;
        wifiConnProc.command = ["nmcli", "device", "wifi", "connect", ssid];
        wifiConnProc.running = true;
    }

    function disconnectWifi(ssid) {
        if (wifiConnProc.running) wifiConnProc.running = false;
        wifiConnProc.command = ["nmcli", "connection", "down", ssid];
        wifiConnProc.running = true;
    }

    // --- Control de Bluetooth ---
    property string connectingMac: ""
    Timer {
        id: connectingTimer
        interval: 10000
        repeat: false
        onTriggered: root.connectingMac = ""
    }

    Process {
        id: btToggleProc
        command: ["sh", "-c", "if bluetoothctl show | grep -q 'Powered: yes'; then bluetoothctl power off; else bluetoothctl power on; fi"]
    }

    Process {
        id: btConnProc
        onExited: {
            root.connectingMac = "";
            root.refreshBluetoothBatteries();
        }
    }

    Process {
        id: btRemoveProc
    }

    property var deviceBatteries: ({})

    Timer {
        id: btBatteryTimer
        interval: 12000
        running: root.isOpen && BluetoothService.isEnabled && BluetoothService.isConnected
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshBluetoothBatteries()
    }

    Connections {
        target: BluetoothService
        function onIsConnectedChanged() {
            if (BluetoothService.isConnected) {
                root.refreshBluetoothBatteries();
            } else {
                root.deviceBatteries = {};
            }
        }
    }

    Process {
        id: btBatteryProc
        command: ["sh", "-c", "for mac in $(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}'); do bat=$(bluetoothctl info \"$mac\" 2>/dev/null | awk '/[Bb]attery [Pp]ercentage/ { if (match($0, /\\([0-9]+\\)/)) print substr($0, RSTART+1, RLENGTH-2); else if (match($0, /[0-9]+%/)) print substr($0, RSTART, RLENGTH-1); else if (match($0, /[0-9]+/)) print substr($0, RSTART, RLENGTH) }' | head -n 1); [ -n \"$bat\" ] && echo \"$mac|$bat\"; done"]
        stdout: SplitParser {
            onRead: data => {
                let text = data.trim();
                if (!text) {
                    root.deviceBatteries = {};
                    return;
                }
                let lines = text.split("\n");
                let updated = {};
                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].trim().split("|");
                    if (parts.length === 2) {
                        let mac = parts[0].trim().toLowerCase();
                        let pct = parseInt(parts[1].trim(), 10);
                        if (!isNaN(pct) && pct >= 0 && pct <= 100) {
                            updated[mac] = pct;
                        }
                    }
                }
                root.deviceBatteries = updated;
            }
        }
    }

    function toggleBluetooth() {
        if (btToggleProc.running) btToggleProc.running = false;
        btToggleProc.running = true;
    }

    function connectBluetooth(mac) {
        root.connectingMac = mac;
        connectingTimer.restart();
        if (btConnProc.running) btConnProc.running = false;
        btConnProc.command = ["sh", "-c", `bluetoothctl trust ${mac} && bluetoothctl connect ${mac}`];
        btConnProc.running = true;
    }

    function pairAndTrustBluetooth(mac) {
        root.connectingMac = mac;
        connectingTimer.restart();
        if (btConnProc.running) btConnProc.running = false;
        btConnProc.command = ["sh", "-c", `bluetoothctl pair ${mac} && bluetoothctl trust ${mac} && bluetoothctl connect ${mac}`];
        btConnProc.running = true;
    }

    function disconnectBluetooth(mac) {
        if (root.connectingMac === mac) root.connectingMac = "";
        if (btConnProc.running) btConnProc.running = false;
        btConnProc.command = ["bluetoothctl", "disconnect", mac];
        btConnProc.running = true;
    }

    function removeBluetooth(mac) {
        if (root.connectingMac === mac) root.connectingMac = "";
        if (btRemoveProc.running) btRemoveProc.running = false;
        btRemoveProc.command = ["bluetoothctl", "remove", mac];
        btRemoveProc.running = true;
    }

    function refreshBluetoothBatteries() {
        if (!btBatteryProc.running) btBatteryProc.running = true;
    }

    function getDeviceBattery(mac) {
        if (!mac) return -1;
        let key = mac.toLowerCase();
        if (root.deviceBatteries && root.deviceBatteries[key] !== undefined) {
            return root.deviceBatteries[key];
        }
        return -1;
    }

    // --- Agente BlueZ para Emparejamiento / Passkey ---
    property bool hasPasskeyPrompt: false
    property string promptDeviceName: ""
    property string promptMac: ""
    property string promptPasskey: ""
    property string promptType: "" // "confirmation", "display_passkey", "display_pin"

    Process {
        id: btAgentProc
        command: ["python3", Qt.resolvedUrl("bt_agent.py").toString().replace(/^file:\/\//, "")]
        stdinEnabled: true
        running: true

        stdout: SplitParser {
            onRead: data => {
                let line = data.trim();
                if (!line) return;
                try {
                    let msg = JSON.parse(line);
                    if (msg.type === "request_confirmation") {
                        root.promptDeviceName = msg.device || "Dispositivo";
                        root.promptMac = msg.mac || "";
                        root.promptPasskey = msg.passkey || "";
                        root.promptType = "confirmation";
                        root.hasPasskeyPrompt = true;
                        root.open();
                    } else if (msg.type === "display_passkey" || msg.type === "display_pin") {
                        root.promptDeviceName = msg.device || "Dispositivo";
                        root.promptMac = msg.mac || "";
                        root.promptPasskey = msg.passkey || msg.pincode || "";
                        root.promptType = msg.type;
                        root.hasPasskeyPrompt = true;
                        root.open();
                    } else if (msg.type === "cancel" || msg.type === "confirmed" || msg.type === "rejected") {
                        root.hasPasskeyPrompt = false;
                        root.promptDeviceName = "";
                        root.promptMac = "";
                        root.promptPasskey = "";
                        root.promptType = "";
                    }
                } catch (e) {}
            }
        }

        onExited: (exitCode, exitStatus) => {
            btAgentRestartTimer.restart();
        }
    }

    Timer {
        id: btAgentRestartTimer
        interval: 2500
        repeat: false
        onTriggered: {
            if (!btAgentProc.running) {
                btAgentProc.running = true;
            }
        }
    }

    function confirmPasskey() {
        if (btAgentProc.running) {
            btAgentProc.write("confirm\n");
        }
        root.hasPasskeyPrompt = false;
    }

    function rejectPasskey() {
        if (btAgentProc.running) {
            btAgentProc.write("reject\n");
        }
        root.hasPasskeyPrompt = false;
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

