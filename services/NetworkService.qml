pragma Singleton
import QtQuick
import Quickshell.Networking
import Quickshell.Io
import "../theme"

Item {
    id: root

    // Estado del sistema
    property bool _sysConnected: false
    property bool _sysIsWifi: false
    property bool _sysIsEthernet: false
    property string _sysConnectionName: ""

    Process {
        id: netReader
        command: ["sh", "-c", "if ! nmcli -t -f TYPE,STATE,CONNECTION dev 2>/dev/null; then for iface in /sys/class/net/*; do b=$(basename \"$iface\"); [ \"$b\" = \"lo\" ] && continue; if [ \"$(cat \"$iface/operstate\" 2>/dev/null)\" = \"up\" ]; then if [ -d \"$iface/wireless\" ] || [ -e \"/sys/class/net/$b/phy80211\" ]; then echo \"wifi:connected:$b\"; else echo \"ethernet:connected:$b\"; fi; fi; done; fi"]
        stdout: SplitParser {
            onRead: data => {
                let lines = data.trim().split("\n");
                let connected = false;
                let isWifi = false;
                let isEth = false;
                let connName = "";

                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].split(":");
                    if (parts.length >= 3 && parts[1] === "connected") {
                        connected = true;
                        if (parts[0] === "wifi") {
                            isWifi = true;
                            connName = parts[2];
                            break; // Priorizar wifi o ethernet
                        } else if (parts[0] === "ethernet") {
                            isEth = true;
                            connName = parts[2];
                        }
                    }
                }

                root._sysConnected = connected;
                root._sysIsWifi = isWifi;
                root._sysIsEthernet = isEth;
                root._sysConnectionName = connName;
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!netReader.running) netReader.running = true;
        }
    }

    // Comprobación de estado
    readonly property bool isConnected: {
        if (Networking.devices && Networking.devices.values) {
            let devs = Networking.devices.values;
            for (let i = 0; i < devs.length; i++) {
                if (devs[i] && devs[i].connected) return true;
            }
        }
        return root._sysConnected;
    }

    readonly property bool isWifi: {
        if (Networking.devices && Networking.devices.values) {
            let devs = Networking.devices.values;
            for (let i = 0; i < devs.length; i++) {
                if (devs[i] && devs[i].connected && devs[i].type === DeviceType.Wifi) return true;
            }
        }
        return root._sysIsWifi;
    }

    readonly property bool isEthernet: {
        if (Networking.devices && Networking.devices.values) {
            let devs = Networking.devices.values;
            for (let i = 0; i < devs.length; i++) {
                if (devs[i] && devs[i].connected && devs[i].type === DeviceType.Wired) return true;
            }
        }
        return root._sysIsEthernet;
    }

    // Íconos según Waybar config.jsonc:
    // WiFi: "󰖩"
    // Ethernet: ""
    // Desconectado: "󰖪"
    readonly property string icon: {
        if (isEthernet) return "";
        if (isWifi) return "󰖩";
        if (isConnected) return "󰖩";
        return "󰖪";
    }

    readonly property color color: {
        if (!isConnected) return Theme.critical; // #ee5396 cuando está desconectado
        return Theme.text;                       // #dde1e7
    }

    readonly property string tooltipText: {
        if (isWifi) return `WiFi: ${root._sysConnectionName || "Conectado"}`;
        if (isEthernet) return `Ethernet: ${root._sysConnectionName || "Conectado"}`;
        if (isConnected) return "Red: Conectado";
        return "Red: Desconectado";
    }
}

