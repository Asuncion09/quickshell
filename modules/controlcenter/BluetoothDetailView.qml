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

    property int navIndex: 0
    property bool isKeyNavActive: false
    property int passkeyNavIndex: 1 // 0: Rechazar, 1: Confirmar

    HoverHandler {
        onPointChanged: {
            if (root.isKeyNavActive) root.isKeyNavActive = false;
        }
    }

    function scrollToIndex(idx) {
        if (!devScroll || !devScroll.ScrollBar || !devScroll.ScrollBar.vertical) return;
        if (idx < 3) {
            devScroll.ScrollBar.vertical.position = 0;
            return;
        }
        let devIdx = idx - 3;
        let total = root.pairedDevices.length + root.availableDevices.length;
        if (total <= 1) {
            devScroll.ScrollBar.vertical.position = 0;
            return;
        }
        let targetRatio = Math.max(0, Math.min(1, devIdx / (total - 1)));
        let maxPos = Math.max(0, 1.0 - (devScroll.height / Math.max(1, scrollCol.height)));
        if (maxPos > 0) {
            devScroll.ScrollBar.vertical.position = Math.max(0, Math.min(maxPos, targetRatio * maxPos));
        }
    }

    function triggerCurrentItem() {
        if (ControlCenterService.hasPasskeyPrompt) {
            if (root.passkeyNavIndex === 0) ControlCenterService.rejectPasskey();
            else ControlCenterService.confirmPasskey();
            return;
        }

        if (root.navIndex === 0) {
            root.backRequested();
            return;
        }
        if (root.navIndex === 1) {
            if (root.isScanning) {
                root.stopBtScan();
            } else {
                root.hasCompletedScan = false;
                root.refreshBtScan();
            }
            return;
        }
        if (root.navIndex === 2) {
            let willTurnOn = !BluetoothService.isEnabled;
            ControlCenterService.toggleBluetooth();
            if (willTurnOn) {
                root.hasCompletedScan = false;
                root.isScanning = true;
                enableScanTimer.restart();
            } else {
                root.stopBtScan();
                root.hasCompletedScan = false;
            }
            return;
        }
        let devIdx = root.navIndex - 3;
        let pairedCount = root.pairedDevices.length;
        if (devIdx < pairedCount) {
            let dev = root.pairedDevices[devIdx];
            if (dev) {
                if (dev.connected) {
                    if (dev.nativeObj && dev.nativeObj.disconnect) dev.nativeObj.disconnect();
                    else ControlCenterService.disconnectBluetooth(dev.address);
                } else {
                    ControlCenterService.connectBluetooth(dev.address);
                }
            }
            return;
        }
        let availIdx = devIdx - pairedCount;
        if (availIdx >= 0 && availIdx < root.availableDevices.length) {
            let dev = root.availableDevices[availIdx];
            if (dev) {
                ControlCenterService.pairAndTrustBluetooth(dev.address);
            }
        }
    }

    function handleKey(event) {
        if (ControlCenterService.hasPasskeyPrompt) {
            root.isKeyNavActive = true;
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                root.passkeyNavIndex = root.passkeyNavIndex === 0 ? 1 : 0;
                return true;
            }
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.passkeyNavIndex === 0) ControlCenterService.rejectPasskey();
                else ControlCenterService.confirmPasskey();
                return true;
            }
            return false;
        }

        let totalDevs = BluetoothService.isEnabled ? (root.pairedDevices.length + root.availableDevices.length) : 0;
        let totalItems = 3 + totalDevs;

        if (!root.isKeyNavActive) {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Up || event.key === Qt.Key_Right || event.key === Qt.Key_Left || event.key === Qt.Key_Tab) {
                root.isKeyNavActive = true;
                root.navIndex = 0;
                return true;
            }
        }

        if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
            root.isKeyNavActive = true;
            if (root.navIndex < 3) {
                if (totalDevs > 0) root.navIndex = 3;
                else root.navIndex = 0;
            } else {
                root.navIndex = (root.navIndex - 3 + 1) % totalDevs + 3;
            }
            root.scrollToIndex(root.navIndex);
            return true;
        }

        if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
            root.isKeyNavActive = true;
            if (root.navIndex === 3) {
                root.navIndex = 0;
                root.scrollToIndex(0);
            } else if (root.navIndex > 3) {
                root.navIndex--;
                root.scrollToIndex(root.navIndex);
            } else {
                if (totalDevs > 0) {
                    root.navIndex = totalItems - 1;
                    root.scrollToIndex(root.navIndex);
                }
            }
            return true;
        }

        if (event.key === Qt.Key_Right) {
            root.isKeyNavActive = true;
            if (root.navIndex === 0) root.navIndex = 1;
            else if (root.navIndex === 1) root.navIndex = 2;
            else if (root.navIndex === 2) {
                if (totalDevs > 0) root.navIndex = 3;
                else root.navIndex = 0;
            }
            root.scrollToIndex(root.navIndex);
            return true;
        }

        if (event.key === Qt.Key_Left) {
            root.isKeyNavActive = true;
            if (root.navIndex === 2) root.navIndex = 1;
            else if (root.navIndex === 1) root.navIndex = 0;
            else if (root.navIndex === 0) {
                root.backRequested();
            } else if (root.navIndex >= 3) {
                root.navIndex = 0;
                root.scrollToIndex(0);
            }
            return true;
        }

        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.triggerCurrentItem();
            return true;
        }

        return false;
    }

    // 1. Dispositivos resueltos nativamente por Quickshell.Bluetooth
    readonly property var nativeDevices: {
        let raw = [];
        if (Bluetooth.devices && Bluetooth.devices.values) {
            raw = Bluetooth.devices.values.slice();
        } else if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.devices && Bluetooth.defaultAdapter.devices.values) {
            raw = Bluetooth.defaultAdapter.devices.values.slice();
        }

        let list = raw.filter(d => d && (d.paired || d.connected || (d.name && d.name.trim() !== "")));
        return list;
    }

    // 2. Respaldo CLI directo por bluetoothctl con acumulador de líneas
    property var cliDevices: []
    property var _accumulatedLines: []
    property bool isScanning: false
    property bool hasCompletedScan: false

    Timer {
        id: enableScanTimer
        interval: 650
        repeat: false
        onTriggered: {
            if (BluetoothService.isEnabled && root.visible) {
                root.refreshBtScan();
            }
        }
    }

    Timer {
        id: scanPollTimer
        interval: 2500
        repeat: true
        running: root.visible && root.isScanning && BluetoothService.isEnabled
        onTriggered: {
            if (!btScanProc.running) {
                btScanProc.running = true;
            }
        }
    }

    Timer {
        id: scanTimeoutTimer
        interval: 10000
        repeat: false
        onTriggered: {
            root.isScanning = false;
            root.hasCompletedScan = true;
            if (scanCtlProc.running) scanCtlProc.running = false;
        }
    }

    Timer {
        id: autoScanTimer
        interval: 16000
        running: root.visible && BluetoothService.isEnabled
        repeat: true
        onTriggered: {
            if (!root.isScanning) {
                root.refreshBtScan();
            }
        }
    }

    Connections {
        target: BluetoothService
        function onIsEnabledChanged() {
            if (BluetoothService.isEnabled) {
                if (root.visible) {
                    root.hasCompletedScan = false;
                    root.isScanning = true;
                    enableScanTimer.restart();
                }
            } else {
                root.stopBtScan();
                root.hasCompletedScan = false;
            }
        }
    }

    // Proceso para activar escaneo en vivo de nuevos dispositivos (Discovery)
    Process {
        id: scanCtlProc
        command: ["bluetoothctl", "--timeout", "10", "scan", "on"]
        onStarted: root.isScanning = true
        onExited: {
            root.isScanning = false;
            root.hasCompletedScan = true;
            if (btScanProc.running) btScanProc.running = false;
            btScanProc.running = true;
        }
    }

    // Proceso de inspección de dispositivos (Conectados, Emparejados y Disponibles)
    Process {
        id: btScanProc
        command: ["sh", "-c", "conn=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}'); paired=$(bluetoothctl devices Paired 2>/dev/null | awk '{print $2}'); (bluetoothctl devices Paired 2>/dev/null; bluetoothctl devices 2>/dev/null) | awk '!seen[$2]++' | while read -r tag mac name; do [ \"$tag\" = \"Device\" ] || continue; is_conn=$(echo \"$conn\" | grep -Fq \"$mac\" && echo 'yes' || echo 'no'); is_paired=$(echo \"$paired\" | grep -Fq \"$mac\" && echo 'yes' || echo 'no'); echo \"$is_conn|$is_paired|$mac|$name\"; done"]
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
            root.parseCliLines(root._accumulatedLines);
            ControlCenterService.refreshBluetoothBatteries();
        }
    }

    function isMacAddress(str) {
        if (!str) return false;
        let s = str.trim();
        return /^([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$/.test(s) || /^[0-9a-fA-F]{12}$/.test(s);
    }

    function parseCliLines(lines) {
        let list = [];
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i];
            if (!line) continue;
            let parts = line.split("|");
            if (parts.length >= 4) {
                let isConn = parts[0] === "yes";
                let isPaired = parts[1] === "yes";
                let mac = parts[2].trim();
                let name = parts.slice(3).join("|").trim();
                if (mac) {
                    list.push({
                        name: name || mac,
                        deviceName: name || mac,
                        address: mac,
                        connected: isConn,
                        paired: isPaired
                    });
                }
            }
        }
        root.cliDevices = list;
    }

    function refreshBtScan() {
        if (!BluetoothService.isEnabled) return;
        root.isScanning = true;
        scanTimeoutTimer.restart();

        if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) {
            Bluetooth.defaultAdapter.discovering = true;
        }
        if (scanCtlProc.running) scanCtlProc.running = false;
        scanCtlProc.running = true;

        if (btScanProc.running) btScanProc.running = false;
        btScanProc.running = true;
    }

    function stopBtScan() {
        root.isScanning = false;
        root.hasCompletedScan = true;
        scanTimeoutTimer.stop();
        if (scanCtlProc.running) scanCtlProc.running = false;
        if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled && Bluetooth.defaultAdapter.discovering) {
            Bluetooth.defaultAdapter.discovering = false;
        }
    }

    Component.onCompleted: {
        if (BluetoothService.isEnabled) {
            root.hasCompletedScan = false;
            root.isScanning = true;
            enableScanTimer.restart();
        }
    }

    onVisibleChanged: {
        root.isKeyNavActive = false;
        root.navIndex = 0;
        root.passkeyNavIndex = 1;
        if (visible) {
            ControlCenterService.refreshBluetoothBatteries();
            if (BluetoothService.isEnabled) {
                root.hasCompletedScan = false;
                root.isScanning = true;
                enableScanTimer.restart();
            } else {
                root.hasCompletedScan = false;
                root.isScanning = false;
            }
            if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) {
                Bluetooth.defaultAdapter.discoverable = true;
            }
        } else {
            root.stopBtScan();
            enableScanTimer.stop();
            if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) {
                Bluetooth.defaultAdapter.discoverable = false;
            }
        }
    }

    // Fusión de dispositivos de ambas fuentes
    readonly property var allDevices: {
        let map = new Map();

        // 1. Dispositivos CLI
        for (let i = 0; i < cliDevices.length; i++) {
            let c = cliDevices[i];
            if (c && (c.name || c.address)) {
                let key = (c.address || c.name).toLowerCase();
                map.set(key, c);
            }
        }

        // 2. Dispositivos nativos (enriquecen)
        for (let i = 0; i < nativeDevices.length; i++) {
            let n = nativeDevices[i];
            if (n && (n.name || n.address)) {
                let key = (n.address || n.name).toLowerCase();
                let existing = map.get(key);
                map.set(key, {
                    name: n.name || (existing ? existing.name : "") || n.deviceName || n.address,
                    deviceName: n.deviceName || n.name || (existing ? existing.deviceName : ""),
                    address: n.address || (existing ? existing.address : ""),
                    connected: n.connected !== undefined ? (n.connected || (existing ? existing.connected : false)) : (existing ? existing.connected : false),
                    paired: n.paired !== undefined ? (n.paired || (existing ? existing.paired : false)) : (existing ? existing.paired : false),
                    nativeObj: n
                });
            }
        }

        return Array.from(map.values());
    }

    // 1. Mis Dispositivos (Emparejados previamente o actualmente conectados)
    readonly property var pairedDevices: {
        let list = allDevices.filter(d => d && (d.paired || d.connected));
        list.sort((a, b) => {
            if (a.connected && !b.connected) return -1;
            if (!a.connected && b.connected) return 1;
            let nameA = (a.name || a.deviceName || "").toLowerCase();
            let nameB = (b.name || b.deviceName || "").toLowerCase();
            return nameA.localeCompare(nameB);
        });
        return list;
    }

    // 2. Dispositivos Disponibles (Descubiertos en el aire sin emparejar ni conectar)
    readonly property var availableDevices: {
        let list = allDevices.filter(d => {
            if (!d || d.paired || d.connected) return false;
            let name = (d.name || d.deviceName || "").trim();
            if (name === "" || root.isMacAddress(name)) return false;
            if (name.toLowerCase() === (d.address || "").toLowerCase()) return false;
            return true;
        });
        list.sort((a, b) => {
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
        if (name.includes("phone") || name.includes("móvil") || name.includes("galaxy") || name.includes("iphone") || name.includes("pixel") || name.includes("redmi") || name.includes("poco")) return "󰏲";
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

            // Botón Volver (circular, transparente en reposo, chevron vector)
            Rectangle {
                id: backBtn
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === 0
                color: isKeyFocused ? "#2c2c2c" : (backMouse.containsMouse ? Theme.surfaceHover : "transparent")
                border.width: isKeyFocused ? 1.5 : 0
                border.color: Theme.highlight

                scale: backMouse.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on border.width { NumberAnimation { duration: 40 } }
                Behavior on border.color { ColorAnimation { duration: 40 } }
                Behavior on color { ColorAnimation { duration: backMouse.containsMouse ? Theme.animFast : 40 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: (backMouse.containsMouse || backBtn.isKeyFocused) ? Theme.text : Theme.textSecondary

                    Behavior on color { ColorAnimation { duration: backMouse.containsMouse ? Theme.animFast : 40 } }
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

            // Botón Recargar / Pausar escaneo (circular, sin borde agresivo en teclado)
            Rectangle {
                id: refreshBtn
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === 1
                color: isKeyFocused ? "#2c2c2c" : (refreshMouse.containsMouse ? Theme.surfaceHover : "transparent")
                border.width: isKeyFocused ? 1.5 : 0
                border.color: Theme.highlight

                scale: refreshMouse.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on border.width { NumberAnimation { duration: 40 } }
                Behavior on border.color { ColorAnimation { duration: 40 } }
                Behavior on color { ColorAnimation { duration: refreshMouse.containsMouse ? Theme.animFast : 40 } }

                Text {
                    anchors.centerIn: parent
                    text: root.isScanning ? "󰏤" : "󰑐"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: {
                        if (root.isScanning) {
                            return refreshMouse.containsMouse ? Theme.critical : Theme.wsActiveColor;
                        }
                        return (refreshMouse.containsMouse || refreshBtn.isKeyFocused) ? Theme.wsActiveColor : Theme.textMuted;
                    }

                    Behavior on color { ColorAnimation { duration: refreshMouse.containsMouse ? Theme.animFast : 40 } }
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.isScanning) {
                            root.stopBtScan();
                        } else {
                            root.hasCompletedScan = false;
                            root.refreshBtScan();
                        }
                    }
                }
            }

            // Switch compacto de Encendido / Apagado
            Rectangle {
                id: btSwitch
                implicitWidth: 38
                implicitHeight: 22
                radius: 11
                readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === 2
                color: BluetoothService.isEnabled ? Theme.wsActiveColor : Theme.surfaceBase
                border.width: isKeyFocused ? 1.5 : 0
                border.color: BluetoothService.isEnabled ? "#ffffff" : Theme.highlight

                Behavior on border.width { NumberAnimation { duration: 40 } }
                Behavior on border.color { ColorAnimation { duration: 40 } }
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
                    onClicked: {
                        let willTurnOn = !BluetoothService.isEnabled;
                        ControlCenterService.toggleBluetooth();
                        if (willTurnOn) {
                            root.hasCompletedScan = false;
                            root.isScanning = true;
                            enableScanTimer.restart();
                        } else {
                            root.stopBtScan();
                            root.hasCompletedScan = false;
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
        // TARJETA DE CONFIRMACIÓN DE CLAVE / PASSKEY (SSP)
        // ==========================================
        Rectangle {
            id: passkeyCard
            Layout.fillWidth: true
            visible: ControlCenterService.hasPasskeyPrompt
            implicitHeight: passkeyCol.implicitHeight + 20
            radius: 10
            color: Theme.surfaceBase
            border.width: 0

            ColumnLayout {
                id: passkeyCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "󰂱"
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        color: Theme.wsActiveColor
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

                // Bloque visual de dígitos
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
                            color: Theme.bgDark
                            border.width: 0

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme.fontFamily
                                font.pixelSize: 17
                                font.weight: Font.Bold
                                color: Theme.wsActiveColor
                            }
                        }
                    }
                }

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

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        id: rejectBtn
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: 8
                        color: rejectMouse.containsMouse ? Theme.surfaceHover : Theme.bgDark
                        border.width: 0
                        border.color: Theme.critical

                        Text {
                            anchors.centerIn: parent
                            text: "Rechazar"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: rejectMouse.containsMouse ? Theme.critical : Theme.textSecondary
                        }

                        MouseArea {
                            id: rejectMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ControlCenterService.rejectPasskey()
                        }
                    }

                    Rectangle {
                        id: confirmBtn
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: 8
                        color: Theme.wsActiveColor
                        border.width: 0
                        border.color: "#ffffff"

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
        // CUERPO: Lista de Dispositivos (Doble Sección)
        // ==========================================
        Item {
            Layout.fillWidth: true
            implicitHeight: {
                if (!BluetoothService.isEnabled) return 70;
                if (root.pairedDevices.length === 0 && root.availableDevices.length === 0) return 70;
                return Math.min(ControlCenterService.hasPasskeyPrompt ? 140 : 270, scrollCol.implicitHeight);
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

            // Estado 2: Buscando Dispositivos / Sin Dispositivos
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6
                visible: BluetoothService.isEnabled && root.pairedDevices.length === 0 && root.availableDevices.length === 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: (!root.hasCompletedScan || root.isScanning) ? "󰑐" : "󰂲"
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                    color: (!root.hasCompletedScan || root.isScanning) ? Theme.wsActiveColor : Theme.textMuted

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 1200
                        loops: Animation.Infinite
                        running: (!root.hasCompletedScan || root.isScanning)
                    }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: (!root.hasCompletedScan || root.isScanning) ? "Buscando dispositivos..." : "No se encontraron dispositivos"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textSecondary
                }
            }

            // Estado 3: Lista interactiva de dispositivos
            ScrollView {
                id: devScroll
                anchors.fill: parent
                visible: BluetoothService.isEnabled && (root.pairedDevices.length > 0 || root.availableDevices.length > 0)
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                contentWidth: availableWidth

                ColumnLayout {
                    id: scrollCol
                    width: parent.width
                    spacing: 8

                    // -------------------------------------------------------------
                    // SECCIÓN 1: MIS DISPOSITIVOS (Vinculados)
                    // -------------------------------------------------------------
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: root.pairedDevices.length > 0

                        Text {
                            text: "Mis dispositivos"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: Theme.textSecondary
                            Layout.leftMargin: 4
                        }

                        Repeater {
                            model: root.pairedDevices

                            delegate: Rectangle {
                                id: devItem
                                Layout.fillWidth: true
                                implicitHeight: 34
                                radius: 8
                                readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === (3 + index)
                                color: {
                                    if (modelData.connected) {
                                        return (rowMouse.containsMouse || isKeyFocused) ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.05);
                                    }
                                    if (isKeyFocused) return "#2c2c2c";
                                    return rowMouse.containsMouse ? Theme.surfaceHover : "transparent";
                                }
                                border.width: isKeyFocused ? 1.5 : (modelData.connected ? 1 : 0)
                                border.color: isKeyFocused ? (modelData.connected ? Qt.rgba(1, 1, 1, 0.85) : Theme.highlight) : Qt.rgba(1, 1, 1, 0.08)

                                scale: rowMouse.pressed ? 0.98 : 1.0
                                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                                Behavior on border.width { NumberAnimation { duration: 40 } }
                                Behavior on border.color { ColorAnimation { duration: 40 } }
                                Behavior on color { ColorAnimation { duration: rowMouse.containsMouse ? Theme.animFast : 40 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Text {
                                        text: root.deviceIcon(modelData)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                        color: modelData.connected ? Theme.wsActiveColor : (rowMouse.containsMouse ? Theme.text : Theme.textSecondary)
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.name || modelData.deviceName || modelData.address || "Dispositivo"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.weight: modelData.connected ? Font.DemiBold : Font.Normal
                                            color: Theme.text
                                            elide: Text.ElideRight
                                        }

                                        // Subtítulo condicional de estado "Conectando..."
                                        Text {
                                            Layout.fillWidth: true
                                            visible: ControlCenterService.connectingMac === modelData.address
                                            text: "Conectando..."
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            color: Theme.wsActiveColor
                                        }
                                    }

                                    // Indicador de Batería (SOLO SI EL DISPOSITIVO ENVÍA EL NIVEL)
                                    Item {
                                        id: batBadge
                                        readonly property int batLevel: ControlCenterService.getDeviceBattery(modelData.address)
                                        visible: modelData.connected && batLevel >= 0
                                        implicitWidth: visible ? batRow.implicitWidth : 0
                                        implicitHeight: visible ? 18 : 0
                                        Layout.alignment: Qt.AlignVCenter

                                        RowLayout {
                                            id: batRow
                                            anchors.centerIn: parent
                                            spacing: 3

                                            Text {
                                                text: "󰁹"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                color: batBadge.batLevel <= 20 ? Theme.critical : (batBadge.batLevel <= 40 ? Theme.warning : Theme.success)
                                            }

                                            Text {
                                                text: `${batBadge.batLevel}%`
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                                font.weight: Font.DemiBold
                                                color: Theme.textSecondary
                                            }
                                        }
                                    }

                                    // Estado de conexión (badge con punto esmeralda)
                                    RowLayout {
                                        visible: modelData.connected && ControlCenterService.connectingMac !== modelData.address
                                        spacing: 5
                                        Layout.alignment: Qt.AlignVCenter

                                        Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: Theme.success
                                        }

                                        Text {
                                            text: "Conectado"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: Font.Medium
                                            color: Theme.textSecondary
                                        }
                                    }

                                    // Botón discreto de "Olvidar / Desvincular"
                                    Rectangle {
                                        id: forgetBtn
                                        implicitWidth: 22
                                        implicitHeight: 22
                                        radius: 5
                                        color: forgetMouse.containsMouse ? Theme.surfaceHover : "transparent"
                                        visible: rowMouse.containsMouse || forgetMouse.containsMouse
                                        Layout.alignment: Qt.AlignVCenter

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰆴"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 12
                                            color: forgetMouse.containsMouse ? Theme.critical : Theme.textMuted
                                        }

                                        MouseArea {
                                            id: forgetMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: ControlCenterService.removeBluetooth(modelData.address)
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    anchors.rightMargin: forgetBtn.visible ? 24 : 0
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.connected) {
                                            if (modelData.nativeObj && modelData.nativeObj.disconnect) {
                                                modelData.nativeObj.disconnect();
                                            } else {
                                                ControlCenterService.disconnectBluetooth(modelData.address);
                                            }
                                        } else {
                                            ControlCenterService.connectBluetooth(modelData.address);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // -------------------------------------------------------------
                    // SECCIÓN 2: DISPOSITIVOS DISPONIBLES (Cercanos en el aire)
                    // -------------------------------------------------------------
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: BluetoothService.isEnabled

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Dispositivos disponibles"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.textSecondary
                                Layout.leftMargin: 4
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                visible: root.isScanning
                                text: "Buscando..."
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                color: Theme.wsActiveColor
                                Layout.rightMargin: 4
                            }
                        }

                        // Placeholder si no hay dispositivos disponibles
                        Item {
                            visible: root.availableDevices.length === 0
                            Layout.fillWidth: true
                            implicitHeight: 28

                            Text {
                                anchors.centerIn: parent
                                text: (!root.hasCompletedScan || root.isScanning) ? "Buscando dispositivos..." : "Sin dispositivos cerca"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.textSecondary
                            }
                        }

                        Repeater {
                            model: root.availableDevices

                            delegate: Rectangle {
                                id: availItem
                                Layout.fillWidth: true
                                implicitHeight: 34
                                radius: 8
                                readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === (3 + root.pairedDevices.length + index)
                                color: isKeyFocused ? "#2c2c2c" : (availMouse.containsMouse ? Theme.surfaceHover : "transparent")
                                border.width: isKeyFocused ? 1.5 : 0
                                border.color: Theme.highlight

                                scale: availMouse.pressed ? 0.98 : 1.0
                                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                                Behavior on border.width { NumberAnimation { duration: 40 } }
                                Behavior on border.color { ColorAnimation { duration: 40 } }
                                Behavior on color { ColorAnimation { duration: availMouse.containsMouse ? Theme.animFast : 40 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Text {
                                        text: root.deviceIcon(modelData)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                        color: availMouse.containsMouse ? Theme.text : Theme.textSecondary
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.name || modelData.deviceName || modelData.address || "Dispositivo"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            color: Theme.text
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            visible: ControlCenterService.connectingMac === modelData.address
                                            text: "Vinculando..."
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            color: Theme.wsActiveColor
                                        }
                                    }

                                    Text {
                                        text: ControlCenterService.connectingMac === modelData.address ? "..." : "Vincular"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                        color: availMouse.containsMouse ? Theme.wsActiveColor : Theme.textMuted
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    id: availMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        ControlCenterService.pairAndTrustBluetooth(modelData.address);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

    }
}
