pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Networking
import "."

Item {
    id: root

    property bool isOpen: false

    function toggle() {
        let otherModalOpen = (typeof LauncherService !== "undefined" && LauncherService && LauncherService.isOpen) ||
                             (typeof ClipboardService !== "undefined" && ClipboardService && ClipboardService.isOpen) ||
                             (typeof NotificationService !== "undefined" && NotificationService && NotificationService.isCenterOpen);
        if (root.isOpen && !otherModalOpen) {
            root.close();
        } else {
            root.open();
        }
    }

    function open() {
        if (typeof LauncherService !== "undefined" && LauncherService && LauncherService.isOpen) {
            LauncherService.close();
        }
        if (typeof ClipboardService !== "undefined" && ClipboardService && ClipboardService.isOpen) {
            ClipboardService.close();
        }
        if (typeof NotificationService !== "undefined" && NotificationService && NotificationService.isCenterOpen) {
            NotificationService.closeCenter();
        }
        root.isOpen = true;
    }

    property int requestedView: 0

    function openSettings() {
        root.requestedView = 4;
        root.open();
    }

    function openAudio() {
        root.requestedView = 3;
        root.open();
    }

    function openWallpaper() {
        root.requestedView = 5;
        root.open();
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
    property string connectingWifiSsid: ""
    property string wifiErrorMessage: ""
    property var savedWifiConnections: []

    Timer {
        id: connectingWifiTimer
        interval: 15000
        repeat: false
        onTriggered: {
            if (root.connectingWifiSsid !== "") {
                root.connectingWifiSsid = "";
            }
        }
    }

    Process {
        id: wifiToggleProc
        command: ["sh", "-c", "if nmcli radio wifi | grep -q 'enabled'; then nmcli radio wifi off; else nmcli radio wifi on; fi"]
        onExited: {
            NetworkService.refresh();
        }
    }

    Component.onCompleted: {
        root.refreshSavedWifiConnections();
        root.checkCaffeine();
    }

    onIsOpenChanged: {
        if (root.isOpen) {
            root.refreshSavedWifiConnections();
            root.checkCaffeine();
        }
    }

    property var _accumulatedSavedLines: []

    Process {
        id: wifiSavedProc
        command: ["sh", "-c", "LC_ALL=C nmcli -t -f NAME,TYPE connection show 2>/dev/null | while IFS=: read -r name type; do [ \"$type\" = \"802-11-wireless\" ] || continue; echo \"$name\"; ssid=$(nmcli -s -g 802-11-wireless.ssid connection show \"$name\" 2>/dev/null); [ -n \"$ssid\" ] && echo \"$ssid\"; done | sort -u"]
        onStarted: root._accumulatedSavedLines = []
        stdout: SplitParser {
            onRead: data => {
                let text = data.trim();
                if (text) {
                    let lines = text.split("\n");
                    for (let i = 0; i < lines.length; i++) {
                        let s = lines[i].trim();
                        if (s) root._accumulatedSavedLines.push(s);
                    }
                }
            }
        }
        onExited: {
            let list = [];
            for (let i = 0; i < root._accumulatedSavedLines.length; i++) {
                let item = root._accumulatedSavedLines[i];
                if (item && !list.includes(item)) list.push(item);
            }
            root.savedWifiConnections = list;
        }
    }

    Process {
        id: wifiConnProc
        stdout: SplitParser {
            onRead: data => {
                let text = data.trim();
                if (text.toLowerCase().includes("error") || text.toLowerCase().includes("failed")) {
                    root.wifiErrorMessage = text;
                }
            }
        }
        stderr: SplitParser {
            onRead: data => {
                let text = data.trim();
                if (text) {
                    root.wifiErrorMessage = text;
                }
            }
        }
        onExited: exitCode => {
            root.connectingWifiSsid = "";
            NetworkService.refresh();
            if (exitCode === 0) {
                root.wifiErrorMessage = "";
                root.refreshSavedWifiConnections();
            } else if (!root.wifiErrorMessage) {
                root.wifiErrorMessage = "Failed to connect to network.";
            }
            root.wifiConnectionFinished();
        }
    }

    signal wifiConnectionFinished()

    Process {
        id: wifiDeleteProc
        onExited: root.refreshSavedWifiConnections()
    }


    function refreshSavedWifiConnections() {
        if (wifiSavedProc.running) wifiSavedProc.running = false;
        wifiSavedProc.running = true;
    }

    function isWifiSaved(ssid) {
        if (!ssid) return false;
        let s = ssid.toLowerCase();
        let sTrim = s.trim();
        for (let i = 0; i < root.savedWifiConnections.length; i++) {
            let saved = (root.savedWifiConnections[i] || "").toLowerCase();
            if (saved === s || saved.trim() === sTrim) return true;
        }
        return false;
    }

    function toggleWifi() {
        let turnOn = !NetworkService.isWifiEnabled;
        if (typeof Networking !== "undefined" && Networking.wifiEnabled !== undefined) {
            Networking.wifiEnabled = turnOn;
        }
        if (wifiToggleProc.running) return;
        wifiToggleProc.command = ["nmcli", "radio", "wifi", turnOn ? "on" : "off"];
        wifiToggleProc.running = true;
        NetworkService.refresh();
    }

    function connectWifi(ssid) {
        root.connectingWifiSsid = ssid;
        root.wifiErrorMessage = "";
        connectingWifiTimer.restart();
        if (wifiConnProc.running) wifiConnProc.running = false;
        wifiConnProc.command = [
            "sh", "-c",
            'target="$1"; ' +
            'conn=$(LC_ALL=C nmcli -t -f NAME,TYPE connection show 2>/dev/null | while IFS=: read -r name type; do [ "$type" = "802-11-wireless" ] || continue; trimmed=$(echo "$name" | xargs); if [ "$name" = "$target" ] || [ "$trimmed" = "$target" ] || [ "$trimmed" = "$(echo "$target" | xargs)" ]; then echo "$name"; break; fi; done); ' +
            'if [ -n "$conn" ]; then nmcli connection up id "$conn" && exit 0; fi; ' +
            'nmcli device wifi connect "$target" 2>/dev/null && exit 0; ' +
            'air=$(LC_ALL=C nmcli -t -f SSID device wifi list 2>/dev/null | while read -r s; do trimmed=$(echo "$s" | xargs); if [ "$s" = "$target" ] || [ "$trimmed" = "$target" ] || [ "$trimmed" = "$(echo "$target" | xargs)" ]; then echo "$s"; break; fi; done); ' +
            'if [ -n "$air" ]; then nmcli device wifi connect "$air" && exit 0; fi; ' +
            'exit 1',
            "sh", ssid
        ];
        wifiConnProc.running = true;
    }

    function connectWifiWithPassword(ssid, password) {
        root.connectingWifiSsid = ssid;
        root.wifiErrorMessage = "";
        connectingWifiTimer.restart();
        if (wifiConnProc.running) wifiConnProc.running = false;
        wifiConnProc.command = [
            "sh", "-c",
            'target="$1"; pass="$2"; ' +
            'nmcli device wifi connect "$target" password "$pass" 2>/dev/null && exit 0; ' +
            'air=$(LC_ALL=C nmcli -t -f SSID device wifi list 2>/dev/null | while read -r s; do trimmed=$(echo "$s" | xargs); if [ "$s" = "$target" ] || [ "$trimmed" = "$target" ] || [ "$trimmed" = "$(echo "$target" | xargs)" ]; then echo "$s"; break; fi; done); ' +
            'if [ -n "$air" ]; then nmcli device wifi connect "$air" password "$pass" && exit 0; fi; ' +
            'exit 1',
            "sh", ssid, password
        ];
        wifiConnProc.running = true;
    }

    function disconnectWifi(ssid) {
        if (root.connectingWifiSsid === ssid) root.connectingWifiSsid = "";
        if (wifiConnProc.running) wifiConnProc.running = false;
        wifiConnProc.command = [
            "sh", "-c",
            'target="$1"; ' +
            'conn=$(LC_ALL=C nmcli -t -f NAME,TYPE connection show 2>/dev/null | while IFS=: read -r name type; do [ "$type" = "802-11-wireless" ] || continue; trimmed=$(echo "$name" | xargs); if [ "$name" = "$target" ] || [ "$trimmed" = "$target" ] || [ "$trimmed" = "$(echo "$target" | xargs)" ]; then echo "$name"; break; fi; done); ' +
            'if [ -n "$conn" ]; then nmcli connection down id "$conn"; else nmcli connection down id "$target"; fi',
            "sh", ssid
        ];
        wifiConnProc.running = true;
    }

    function deleteWifiConnection(ssid) {
        if (wifiDeleteProc.running) wifiDeleteProc.running = false;
        wifiDeleteProc.command = [
            "sh", "-c",
            'target="$1"; ' +
            'conn=$(LC_ALL=C nmcli -t -f NAME,TYPE connection show 2>/dev/null | while IFS=: read -r name type; do [ "$type" = "802-11-wireless" ] || continue; trimmed=$(echo "$name" | xargs); if [ "$name" = "$target" ] || [ "$trimmed" = "$target" ] || [ "$trimmed" = "$(echo "$target" | xargs)" ]; then echo "$name"; break; fi; done); ' +
            'if [ -n "$conn" ]; then nmcli connection delete id "$conn"; else nmcli connection delete id "$target"; fi',
            "sh", ssid
        ];
        wifiDeleteProc.running = true;
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
                        root.promptDeviceName = msg.device || "Device";
                        root.promptMac = msg.mac || "";
                        root.promptPasskey = msg.passkey || "";
                        root.promptType = "confirmation";
                        root.hasPasskeyPrompt = true;
                        root.open();
                    } else if (msg.type === "display_passkey" || msg.type === "display_pin") {
                        root.promptDeviceName = msg.device || "Device";
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

    // --- Control de No Molestar (DND sincronizado con NotificationService) ---
    readonly property bool isDnd: NotificationService.dnd

    function toggleDnd() {
        NotificationService.toggleDnd();
    }

    // --- Control de Caffeine (Anti-reposo / Inhibidor de suspensión de pantalla) ---
    property bool isCaffeineActive: false

    Process {
        id: caffeineCheckProc
        command: ["sh", "-c", "pid=$(pgrep hypridle | head -n 1); if [ -n \"$pid\" ] && grep -q 'State:.*T (stopped)' /proc/$pid/status 2>/dev/null; then echo 'active'; else echo 'inactive'; fi"]
        stdout: SplitParser {
            onRead: data => {
                root.isCaffeineActive = (data.trim() === "active");
            }
        }
    }

    function checkCaffeine() {
        if (!caffeineCheckProc.running) caffeineCheckProc.running = true;
    }

    Process {
        id: caffeineToggleProc
    }

    function toggleCaffeine() {
        if (root.isCaffeineActive) {
            root.isCaffeineActive = false;
            if (caffeineToggleProc.running) caffeineToggleProc.running = false;
            caffeineToggleProc.command = ["sh", "-c", "pkill -CONT hypridle 2>/dev/null"];
            caffeineToggleProc.running = true;
        } else {
            root.isCaffeineActive = true;
            if (caffeineToggleProc.running) caffeineToggleProc.running = false;
            caffeineToggleProc.command = ["sh", "-c", "pkill -STOP hypridle 2>/dev/null"];
            caffeineToggleProc.running = true;
        }
    }

    // --- Herramienta de Gotero (Color Picker con hyprpicker) ---
    Process {
        id: colorPickerProc
    }

    function pickColor() {
        root.close();
        if (colorPickerProc.running) colorPickerProc.running = false;
        colorPickerProc.command = ["sh", "-c", "sleep 0.2 && hyprpicker -a -n"];
        colorPickerProc.running = true;
    }

    // --- Herramienta de Recorte Rápido de Región (Hyprshot) ---
    Process {
        id: quickShotProc
    }

    function captureRegion() {
        root.close();
        if (quickShotProc.running) quickShotProc.running = false;
        quickShotProc.command = ["sh", "-c", "sleep 0.2 && hyprshot -m region"];
        quickShotProc.running = true;
    }

    // --- Acciones de Sistema y Energía ---
    property bool isPowerMenuOpen: SessionService.isOpen

    function togglePowerMenu() {
        root.close();
        SessionService.toggle();
    }

    function closePowerMenu() {
        SessionService.close();
    }

    function lockScreen() {
        root.close();
        SessionService.lock();
    }

    function suspend() {
        SessionService.suspend();
    }

    function reboot() {
        SessionService.reboot();
    }

    function shutdown() {
        SessionService.shutdown();
    }

    function logout() {
        SessionService.logout();
    }
}

