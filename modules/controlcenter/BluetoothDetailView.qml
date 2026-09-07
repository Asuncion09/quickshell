import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Bluetooth
import Quickshell.Io
import "../../theme"
import "../../services"

Item {
    id: root

    implicitWidth: 280
    implicitHeight: contentCol.implicitHeight
    height: implicitHeight
    Layout.fillWidth: true

    signal backRequested()
    signal openAdvancedRequested()

    // 1. Dispositivos resueltos nativamente por Quickshell.Bluetooth
    readonly property var nativeDevices: {
        let raw = [];
        if (Bluetooth.devices && Bluetooth.devices.values) {
            raw = Bluetooth.devices.values.slice();
        } else if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.devices && Bluetooth.defaultAdapter.devices.values) {
            raw = Bluetooth.defaultAdapter.devices.values.slice();
        }

        let list = raw.filter(d => d && (d.paired || d.connected || (d.name && d.name.trim() !== "")));

        list.sort((a, b) => {
            if (a.connected && !b.connected) return -1;
            if (!a.connected && b.connected) return 1;
            let nameA = (a.name || a.deviceName || "").toLowerCase();
            let nameB = (b.name || b.deviceName || "").toLowerCase();
            return nameA.localeCompare(nameB);
        });

        return list;
    }

    // 2. Respaldo CLI directo por bluetoothctl con acumulador de líneas
    property var cliDevices: []
    property var _accumulatedLines: []
    property bool isScanning: false

    Process {
        id: btScanProc
        command: ["sh", "-c", "conn=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}'); bluetoothctl devices 2>/dev/null | while read -r tag mac name; do [ \"$tag\" = \"Device\" ] || continue; is_conn=$(echo \"$conn\" | grep -Fq \"$mac\" && echo 'yes' || echo 'no'); echo \"$is_conn:$mac:$name\"; done"]
        onStarted: {
            root._accumulatedLines = [];
        }
        stdout: SplitParser {
            onRead: data => {
                let text = data.trim();
                if (text) {
                    let lines = text.split("\n");
                    for (let i = 0; i < lines.length; i++) {
                        let l = lines[i].trim();
                        if (l) root._accumulatedLines.push(l);
                    }
                }
            }
        }
        onExited: {
            root.isScanning = false;
            root.parseCliLines(root._accumulatedLines);
        }
    }

    function parseCliLines(lines) {
        let list = [];
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i];
            if (!line) continue;
            let parts = line.split(":");
            if (parts.length >= 3) {
                let isConn = parts[0] === "yes";
                let mac = parts[1];
                let name = parts.slice(2).join(":");
                list.push({
                    name: name,
                    deviceName: name,
                    address: mac,
                    connected: isConn,
                    paired: true
                });
            }
        }
        list.sort((a, b) => {
            if (a.connected && !b.connected) return -1;
            if (!a.connected && b.connected) return 1;
            return a.name.localeCompare(b.name);
        });
        root.cliDevices = list;
    }

    function refreshBtScan() {
        root.isScanning = true;
        if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) {
            Bluetooth.defaultAdapter.discovering = true;
        }
        if (btScanProc.running) btScanProc.running = false;
        btScanProc.running = true;
    }

    Component.onCompleted: refreshBtScan()

    onVisibleChanged: {
        if (visible) {
            refreshBtScan();
            if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) {
                Bluetooth.defaultAdapter.discoverable = true;
                Bluetooth.defaultAdapter.discovering = true;
            }
        } else {
            if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) {
                Bluetooth.defaultAdapter.discoverable = false;
                Bluetooth.defaultAdapter.discovering = false;
            }
        }
    }

    // Fusión de dispositivos de ambas fuentes
    readonly property var displayDevices: {
        let map = new Map();

        // 1. Dispositivos CLI
        for (let i = 0; i < cliDevices.length; i++) {
            let c = cliDevices[i];
            if (c && (c.name || c.address)) {
                map.set(c.address || c.name, c);
            }
        }

        // 2. Dispositivos nativos (enriquecen y dan control nativo)
        for (let i = 0; i < nativeDevices.length; i++) {
            let n = nativeDevices[i];
            if (n && (n.name || n.address)) {
                map.set(n.address || n.name, n);
            }
        }

        let list = Array.from(map.values());
        list.sort((a, b) => {
            if (a.connected && !b.connected) return -1;
            if (!a.connected && b.connected) return 1;
            let nameA = (a.name || a.deviceName || "").toLowerCase();
            let nameB = (b.name || b.deviceName || "").toLowerCase();
            return nameA.localeCompare(nameB);
        });
        return list;
    }

    function deviceIcon(dev) {
        let name = (dev.name || dev.deviceName || "").toLowerCase();
        if (name.includes("headphone") || name.includes("auricular") || name.includes("wh-") || name.includes("airpod") || name.includes("buds") || name.includes("earphone")) return "󰋋";
        if (name.includes("speaker") || name.includes("parlante") || name.includes("sound") || name.includes("boom") || name.includes("jbl")) return "󰓃";
        if (name.includes("mouse") || name.includes("ratón") || name.includes("trackball")) return "󰍽";
        if (name.includes("keyboard") || name.includes("teclado")) return "󰌌";
        if (name.includes("phone") || name.includes("móvil") || name.includes("galaxy") || name.includes("iphone") || name.includes("pixel") || name.includes("redmi")) return "󰏲";
        if (name.includes("gamepad") || name.includes("controller") || name.includes("joystick") || name.includes("xbox") || name.includes("dualshock")) return "󰊴";
        return "󰂱";
    }

    ColumnLayout {
        id: contentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 8

        // ==========================================
        // CABECERA (32px): Volver + Título + Recargar + Switch ON/OFF
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 32
            spacing: 8

            // Botón Volver (‹)
            Rectangle {
                id: backBtn
                implicitWidth: 32
                implicitHeight: 32
                radius: 8
                color: backMouse.containsMouse ? "#262626" : "#1e1e1e"
                border.width: 0

                scale: backMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: backMouse.containsMouse ? Theme.highlight : Theme.textSecondary

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

            // Título de la vista
            Text {
                text: "Bluetooth"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.text
                Layout.alignment: Qt.AlignVCenter
            }

            // Espaciador
            Item {
                Layout.fillWidth: true
            }

            // Botón Recargar / Re-escanear
            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 6
                color: refreshMouse.containsMouse ? "#2a2a2a" : "transparent"
                border.width: 0

                scale: refreshMouse.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: refreshMouse.containsMouse ? Theme.highlight : Theme.textMuted
                    rotation: root.isScanning ? 360 : 0

                    Behavior on rotation {
                        NumberAnimation { duration: 600; easing.type: Easing.Linear }
                    }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.refreshBtScan()
                }
            }

            // Switch compacto de Encendido / Apagado
            Rectangle {
                id: btSwitch
                implicitWidth: 38
                implicitHeight: 22
                radius: 11
                color: BluetoothService.isEnabled ? Theme.highlight : "#2e2e2e"
                border.width: 0

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                // Perilla deslizante blanca
                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                    x: BluetoothService.isEnabled ? parent.width - width - 3 : 3

                    Behavior on x {
                        NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ControlCenterService.toggleBluetooth()
                }
            }
        }

        // Separador fino
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.dividerColor
        }

        // ==========================================
        // TARJETA DE CONFIRMACIÓN DE CLAVE / PASSKEY (SSP)
        // ==========================================
        Rectangle {
            id: passkeyCard
            Layout.fillWidth: true
            visible: ControlCenterService.hasPasskeyPrompt
            implicitHeight: passkeyCol.implicitHeight + 20
            radius: 10
            color: "#1e1e1e"
            border.width: 0

            ColumnLayout {
                id: passkeyCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                // Cabecera: Icono directo + Nombre del Dispositivo + Subtítulo
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "󰂱"
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        color: Theme.highlight
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: ControlCenterService.promptDeviceName || "Dispositivo Bluetooth"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Theme.text
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Solicitud de vinculación"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }
                    }
                }

                // Bloque visual de 6 dígitos estilo PIN/OTP
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 5

                    Repeater {
                        model: {
                            let code = ControlCenterService.promptPasskey || "------";
                            return code.split("");
                        }

                        Rectangle {
                            implicitWidth: 32
                            implicitHeight: 36
                            radius: 6
                            color: "#161616"
                            border.width: 0

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme.fontFamily
                                font.pixelSize: 17
                                font.weight: Font.Bold
                                color: Theme.highlight
                            }
                        }
                    }
                }

                // Texto orientativo sutil
                Text {
                    Layout.fillWidth: true
                    text: (ControlCenterService.promptType === "display_pin" || ControlCenterService.promptType === "display_passkey")
                          ? "Introduce este código en el dispositivo"
                          : "¿Coincide con el código en tu pantalla?"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                }

                // Botones de acción (32px de alto, estándar del sistema)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Botón Rechazar
                    Rectangle {
                        id: rejectBtn
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: 8
                        color: rejectMouse.containsMouse ? "#262626" : "#161616"
                        border.width: 0

                        scale: rejectMouse.pressed ? 0.94 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "Rechazar"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: rejectMouse.containsMouse ? Theme.critical : Theme.textSecondary

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }

                        MouseArea {
                            id: rejectMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ControlCenterService.rejectPasskey()
                        }
                    }

                    // Botón Confirmar
                    Rectangle {
                        id: confirmBtn
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: 8
                        color: confirmMouse.containsMouse ? Qt.lighter(Theme.highlight, 1.08) : Theme.highlight
                        border.width: 0

                        scale: confirmMouse.pressed ? 0.94 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "Confirmar"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: "#161616"
                        }

                        MouseArea {
                            id: confirmMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ControlCenterService.confirmPasskey()
                        }
                    }
                }
            }
        }

        // ==========================================
        // CUERPO: Lista de Dispositivos o Estados Vacíos
        // ==========================================
        Item {
            Layout.fillWidth: true
            implicitHeight: {
                if (!BluetoothService.isEnabled) return 70;
                if (root.displayDevices.length === 0) return 70;
                return Math.min(ControlCenterService.hasPasskeyPrompt ? 110 : 220, devRepeater.contentHeight);
            }
            clip: true

            // Estado 1: Bluetooth Apagado
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                visible: !BluetoothService.isEnabled

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰂲"
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                    color: Theme.textMuted
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Bluetooth desactivado"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textSecondary
                }
            }

            // Estado 2: Sin dispositivos vinculados
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                visible: BluetoothService.isEnabled && root.displayDevices.length === 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰂯"
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                    color: Theme.highlight
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.isScanning ? "Buscando dispositivos..." : "Sin dispositivos vinculados"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textSecondary
                }
            }

            // Estado 3: Lista interactiva de dispositivos
            ScrollView {
                id: devScroll
                anchors.fill: parent
                visible: BluetoothService.isEnabled && root.displayDevices.length > 0
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                contentWidth: availableWidth

                ColumnLayout {
                    id: devRepeater
                    width: parent.width
                    spacing: 3
                    property real contentHeight: implicitHeight

                    Repeater {
                        model: root.displayDevices

                        delegate: Rectangle {
                            id: devItem
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: 8
                            color: {
                                if (modelData.connected) return rowMouse.containsMouse ? "#2d3545" : "#242a38";
                                return rowMouse.containsMouse ? "#282828" : "transparent";
                            }
                            border.width: 0

                            scale: rowMouse.pressed ? 0.98 : 1.0
                            Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                // Icono del dispositivo
                                Text {
                                    text: root.deviceIcon(modelData)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    color: modelData.connected ? Theme.highlight : (rowMouse.containsMouse ? Theme.text : Theme.textSecondary)

                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                }

                                // Nombre del dispositivo
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name || modelData.deviceName || modelData.address || "Dispositivo"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: modelData.connected ? Font.DemiBold : Font.Normal
                                    color: modelData.connected ? Theme.highlight : Theme.text
                                    elide: Text.ElideRight
                                }

                                // Estado de conexión (solo visible si está conectado)
                                Text {
                                    text: modelData.connected ? "Conectado" : ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    color: Theme.success
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.connected) {
                                        if (modelData.disconnect) {
                                            modelData.disconnect();
                                        } else if (modelData.address) {
                                            ControlCenterService.disconnectBluetooth(modelData.address);
                                        }
                                    } else {
                                        if (modelData.connect) {
                                            modelData.connect();
                                        } else if (modelData.address) {
                                            ControlCenterService.connectBluetooth(modelData.address);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Separador fino
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.dividerColor
        }

        // ==========================================
        // PIE: Enlace a Configuración Avanzada / Bluetui
        // ==========================================
        Rectangle {
            id: advBtn
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 6
            color: advMouse.containsMouse ? "#262626" : "transparent"
            border.width: 0

            scale: advMouse.pressed ? 0.97 : 1.0
            Behavior on scale { NumberAnimation { duration: Theme.animFast } }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "󰂯"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: advMouse.containsMouse ? Theme.highlight : Theme.textMuted

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                Text {
                    text: "Emparejar nuevo dispositivo (Bluetui)..."
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: advMouse.containsMouse ? Theme.text : Theme.textSecondary

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
            }

            MouseArea {
                id: advMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openAdvancedRequested()
            }
        }
    }
}

