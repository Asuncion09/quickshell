pragma Singleton
import QtQuick
import Quickshell.Networking
import Quickshell.Io
import "../theme"

Item {
    id: root

    // Estado del sistema
    property bool _sysConnected: false

    Process {
        command: ["sh", "-c", "LC_ALL=C nmcli -t -f NAME,TYPE connection show --active 2>/dev/null || (for iface in /sys/class/net/*; do b=$(basename \"$iface\"); [ \"$b\" = \"lo\" ] && continue; if [ \"$(cat \"$iface/operstate\" 2>/dev/null)\" = \"up\" ]; then if [ -d \"$iface/wireless\" ] || [ -e \"/sys/class/net/$b/phy80211\" ]; then echo \"$b:802-11-wireless\"; else echo \"$b:802-3-ethernet\"; fi; fi; done)"]
        stdout: SplitParser {
            onRead: data => {
                let lines = data.trim().split("\n");
                let connected = false;
                let isWifi = false;
                let isEth = false;
                let connName = "";

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (!line) continue;
                    let parts = line.split(":");
                    if (parts.length >= 2) {
                        let name = parts[0];
                        let type = parts[1].toLowerCase();
                        if (type.includes("wireless") || type.includes("wifi")) {
                            connected = true;
                            isWifi = true;
                            connName = name;
                            break;
                        } else if (type.includes("ethernet") || type.includes("wired")) {
                            connected = true;
                            isEth = true;
                            if (!connName) connName = name;
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

    function refresh() {
        if (netReader.running) netReader.running = false;
        netReader.running = true;
    }

    readonly property string connectionName: {
        // 1. Respaldo directo y preciso de nmcli / NetworkManager
        if (root._sysConnectionName && root._sysConnectionName !== "") {
            return root._sysConnectionName;
        }

        // 2. Intentar obtener el SSID a través de Quickshell.Networking nativo
        if (Networking.devices && Networking.devices.values) {
            let devs = Networking.devices.values;
            for (let i = 0; i < devs.length; i++) {
                let dev = devs[i];
                if (dev && dev.connected) {
                    if (dev.networks && dev.networks.values) {
                        for (let j = 0; j < dev.networks.values.length; j++) {
                            let net = dev.networks.values[j];
                            if (net && net.connected && net.name) {
                                return net.name;
                            }
                        }
                    }
                    if (dev.network && dev.network.name) {
                        return dev.network.name;
                    }
                }
            }
        }

        if (!isConnected) return "Desconectado";
        if (isWifi) return "WiFi";
        if (isEthernet) return "Ethernet";
        return "Conectado";
    }

    readonly property string tooltipText: {
        if (isWifi) return `WiFi: ${root.connectionName}`;
        if (isEthernet) return `Ethernet: ${root.connectionName}`;
        if (isConnected) return "Red: Conectado";
        return "Red: Desconectado";
    }
}

