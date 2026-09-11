pragma Singleton
import QtQuick
import Quickshell.Bluetooth
import Quickshell.Io
import "../theme"

Item {
    id: root

    // Respaldo de estado mediante bluetoothctl
    property bool _sysPowered: false
    property bool _sysConnected: false
    property string _sysDeviceName: ""

    Process {
        id: btReader
        command: ["sh", "-c", "powered=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'yes' || echo 'no'); name=$(bluetoothctl devices Connected 2>/dev/null | head -n 1 | cut -d ' ' -f 3- | xargs); echo \"$powered:$name\""]
        stdout: SplitParser {
            onRead: data => {
                let line = data.trim();
                let sep = line.indexOf(":");
                if (sep !== -1) {
                    let powered = line.substring(0, sep) === "yes";
                    let name = line.substring(sep + 1).trim();
                    root._sysPowered = powered;
                    root._sysConnected = powered && name !== "";
                    root._sysDeviceName = root._sysConnected ? name : "";
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!btReader.running) btReader.running = true;
        }
    }

    // Está habilitado / encendido
    readonly property bool isEnabled: {
        if (Bluetooth.defaultAdapter) {
            return Bluetooth.defaultAdapter.enabled;
        }
        return root._sysPowered;
    }

    // Hay algún dispositivo conectado
    readonly property bool isConnected: {
        if (Bluetooth.devices && Bluetooth.devices.values) {
            let devs = Bluetooth.devices.values;
            for (let i = 0; i < devs.length; i++) {
                if (devs[i] && devs[i].connected) return true;
            }
        }
        if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.devices && Bluetooth.defaultAdapter.devices.values) {
            let devs = Bluetooth.defaultAdapter.devices.values;
            for (let i = 0; i < devs.length; i++) {
                if (devs[i] && devs[i].connected) return true;
            }
        }
        return root._sysConnected;
    }

    // Íconos según Waybar config.jsonc:
    // Conectado: ""
    // Encendido: "󰂯"
    // Apagado / Deshabilitado: "󰂲"
    readonly property string icon: {
        if (isConnected) return "󰂱";
        if (isEnabled) return "󰂯";
        return "󰂲";
    }

    readonly property color color: {
        if (isConnected) return Theme.highlight;      // #78a9ff
        if (isEnabled) return Theme.text;             // #dde1e7
        return Theme.textDisabled;                    // 40% opacidad
    }

    readonly property string deviceName: {
        if (!isEnabled) return "Off";
        if (!isConnected) return "Disconnected";
        if (Bluetooth.devices && Bluetooth.devices.values) {
            let devs = Bluetooth.devices.values;
            for (let i = 0; i < devs.length; i++) {
                if (devs[i] && devs[i].connected) return devs[i].name || devs[i].deviceName || "Connected";
            }
        }
        if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.devices && Bluetooth.defaultAdapter.devices.values) {
            let devs = Bluetooth.defaultAdapter.devices.values;
            for (let i = 0; i < devs.length; i++) {
                if (devs[i] && devs[i].connected) return devs[i].name || devs[i].deviceName || "Connected";
            }
        }
        return root._sysDeviceName || "Connected";
    }

    readonly property string tooltipText: {
        if (isConnected) return `Bluetooth: Connected (${root.deviceName})`;
        if (isEnabled) return "Bluetooth: On (not connected)";
        return "Bluetooth: Off";
    }
}

