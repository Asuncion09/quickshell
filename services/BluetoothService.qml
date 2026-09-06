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
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'POWERED_ON' || echo 'POWERED_OFF'; bluetoothctl info 2>/dev/null | grep 'Name:' | head -n 1 | cut -d ':' -f 2"]
        stdout: SplitParser {
            onRead: data => {
                let lines = data.trim().split("\n");
                if (lines.length >= 1) {
                    root._sysPowered = lines[0].includes("POWERED_ON");
                }
                if (lines.length >= 2 && lines[1].trim() !== "") {
                    root._sysConnected = true;
                    root._sysDeviceName = lines[1].trim();
                } else {
                    root._sysConnected = false;
                    root._sysDeviceName = "";
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
        if (isConnected) return "";
        if (isEnabled) return "󰂯";
        return "󰂲";
    }

    readonly property color color: {
        if (isConnected) return Theme.highlight;      // #78a9ff
        if (isEnabled) return Theme.text;             // #dde1e7
        return Theme.textDisabled;                    // 40% opacidad
    }

    readonly property string tooltipText: {
        if (isConnected) return `Bluetooth: Conectado (${root._sysDeviceName || "Dispositivo"})`;
        if (isEnabled) return "Bluetooth: Encendido (sin conexión)";
        return "Bluetooth: Apagado";
    }
}

