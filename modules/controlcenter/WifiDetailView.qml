import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Networking
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

    // Resuelve el dispositivo Wi-Fi nativo en Quickshell
    readonly property var wifiDevice: {
        if (!Networking.devices || !Networking.devices.values) return null;
        let devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++) {
            let dev = devs[i];
            if (dev && (dev.type === DeviceType.Wifi || dev.networks !== undefined || dev.scannerEnabled !== undefined)) {
                return dev;
            }
        }
        return null;
    }

    // Activar escáner nativo al montar o hacerse visible
    function updateScanner(enable) {
        if (wifiDevice && wifiDevice.scannerEnabled !== undefined) {
            wifiDevice.scannerEnabled = enable;
        }
    }

    Component.onCompleted: updateScanner(true)

    onVisibleChanged: {
        if (visible) {
            updateScanner(true);
            refreshScan();
        } else {
            updateScanner(false);
        }
    }

    // 1. Redes detectadas nativamente por Quickshell.Networking
    readonly property var nativeNetworks: {
        if (!wifiDevice || !wifiDevice.networks || !wifiDevice.networks.values) return [];
        let raw = wifiDevice.networks.values;
        let map = new Map();

        for (let i = 0; i < raw.length; i++) {
            let net = raw[i];
            if (net && net.name && net.name.trim() !== "") {
                let existing = map.get(net.name);
                if (!existing || (!existing.connected && net.connected) || (net.strength > existing.strength)) {
                    map.set(net.name, net);
                }
            }
        }

        let list = Array.from(map.values());
        list.sort((a, b) => {
            if (a.connected && !b.connected) return -1;
            if (!a.connected && b.connected) return 1;
            return (b.strength || 0) - (a.strength || 0);
        });
        return list;
    }

    // 2. Respaldo directo de nmcli por CLI
    property var cliNetworks: []
    property var _accumulatedNetLines: []
    property bool isScanning: false

    Process {
        id: scanProc
        command: ["sh", "-c", "LC_ALL=C nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null"]
        onStarted: {
            root._accumulatedNetLines = [];
        }
        stdout: SplitParser {
            onRead: data => {
                let text = data.trim();
                if (text) {
                    let lines = text.split("\n");
                    for (let i = 0; i < lines.length; i++) {
                        let l = lines[i].trim();
                        if (l) root._accumulatedNetLines.push(l);
                    }
                }
            }
        }
        onExited: {
            root.isScanning = false;
            root.parseCliLines(root._accumulatedNetLines);
        }
    }

    function parseCliLines(lines) {
        let map = new Map();

        for (let i = 0; i < lines.length; i++) {
            let line = lines[i];
            if (!line) continue;
            let parts = line.split(":");
            if (parts.length >= 3) {
                let isConn = parts[0].trim() === "*";
                let ssid = parts[1].trim();
                let sig = parseInt(parts[2]) || 50;
                let sec = parts.length > 3 ? parts[3].trim() : "";

                if (ssid !== "") {
                    let existing = map.get(ssid);
                    let item = {
                        name: ssid,
                        connected: isConn,
                        strength: Math.max(0.0, Math.min(1.0, sig / 100.0)),
                        known: isConn || sec === "",
                        isProtected: sec !== "" && sec !== "--"
                    };
                    if (!existing || (!existing.connected && isConn) || (item.strength > existing.strength)) {
                        map.set(ssid, item);
                    }
                }
            }
        }

        let list = Array.from(map.values());
        list.sort((a, b) => {
            if (a.connected && !b.connected) return -1;
            if (!a.connected && b.connected) return 1;
            return (b.strength || 0) - (a.strength || 0);
        });
        root.cliNetworks = list;
    }

    function refreshScan() {
        root.isScanning = true;
        if (scanProc.running) scanProc.running = false;
        scanProc.running = true;
    }

    // Fusión de fuentes: muestra todas las redes del hardware detectadas por CLI y enriquece con nativas
    readonly property var displayNetworks: {
        let map = new Map();

        // 1. Redes encontradas por escaneo CLI
        for (let i = 0; i < cliNetworks.length; i++) {
            let c = cliNetworks[i];
            if (c && c.name) {
                map.set(c.name, c);
            }
        }

        // 2. Redes nativas (agregan o enriquecen con objetos nativos si coinciden)
        for (let i = 0; i < nativeNetworks.length; i++) {
            let n = nativeNetworks[i];
            if (n && n.name) {
                map.set(n.name, n);
            }
        }

        let list = Array.from(map.values());
        list.sort((a, b) => {
            if (a.connected && !b.connected) return -1;
            if (!a.connected && b.connected) return 1;
            return (b.strength || 0) - (a.strength || 0);
        });
        return list;
    }

    function signalIcon(strength) {
        let s = strength !== undefined ? strength : 0.5;
        if (s >= 0.75) return "󰤨";
        if (s >= 0.50) return "󰤢";
        if (s >= 0.25) return "󰤟";
        return "󰤯";
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
                color: backMouse.containsMouse ? "#2e3440" : "#1e1e1e"
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
                text: "Wi-Fi"
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

            // Botón de Recargar / Re-escanear
            Rectangle {
                implicitWidth: 26
                implicitHeight: 26
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
                    onClicked: root.refreshScan()
                }
            }

            // Switch compacto de Encendido / Apagado
            Rectangle {
                id: wifiSwitch
                implicitWidth: 38
                implicitHeight: 22
                radius: 11
                color: NetworkService.isConnected || Networking.wifiEnabled ? Theme.highlight : "#2e2e2e"
                border.width: 0

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                // Perilla deslizante blanca
                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                    x: (NetworkService.isConnected || Networking.wifiEnabled) ? parent.width - width - 3 : 3

                    Behavior on x {
                        NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ControlCenterService.toggleWifi()
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
        // CUERPO: Lista de Redes o Estados Vacíos
        // ==========================================
        Item {
            Layout.fillWidth: true
            implicitHeight: {
                if (!Networking.wifiEnabled && !NetworkService.isConnected) return 70;
                if (root.displayNetworks.length === 0) return 70;
                return Math.min(180, netRepeater.contentHeight);
            }
            clip: true

            // Estado 1: Wi-Fi Apagado
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                visible: !Networking.wifiEnabled && !NetworkService.isConnected

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰖪"
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                    color: Theme.textMuted
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Wi-Fi desactivado"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textSecondary
                }
            }

            // Estado 2: Buscando Redes
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                visible: (Networking.wifiEnabled || NetworkService.isConnected) && root.displayNetworks.length === 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰖩"
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                    color: Theme.highlight
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.isScanning ? "Buscando redes disponibles..." : "No se encontraron redes cercanas"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textSecondary
                }
            }

            // Estado 3: Lista interactiva de redes
            ScrollView {
                id: netScroll
                anchors.fill: parent
                visible: (Networking.wifiEnabled || NetworkService.isConnected) && root.displayNetworks.length > 0
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    id: netRepeater
                    width: parent.width
                    spacing: 3
                    property real contentHeight: implicitHeight

                    Repeater {
                        model: root.displayNetworks

                        delegate: Rectangle {
                            id: netItem
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

                                // Icono de señal Wi-Fi
                                Text {
                                    text: root.signalIcon(modelData.strength)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    color: modelData.connected ? Theme.highlight : (rowMouse.containsMouse ? Theme.text : Theme.textSecondary)

                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                }

                                // Nombre de la red (SSID)
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: modelData.connected ? Font.Bold : Font.Normal
                                    color: modelData.connected ? "#ffffff" : Theme.text
                                    elide: Text.ElideRight
                                }

                                // Indicador de Conectado o Candado si requiere clave
                                Text {
                                    text: modelData.connected ? "Conectado" : (modelData.isProtected !== undefined ? (modelData.isProtected ? "󰌾" : "") : (modelData.known ? "" : "󰌾"))
                                    font.family: Theme.fontFamily
                                    font.pixelSize: modelData.connected ? 10 : 12
                                    font.weight: modelData.connected ? Font.DemiBold : Font.Normal
                                    color: modelData.connected ? Theme.success : Theme.textMuted
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
                                        } else {
                                            ControlCenterService.disconnectWifi(modelData.name);
                                        }
                                    } else {
                                        if (modelData.connect) {
                                            modelData.connect();
                                        } else {
                                            ControlCenterService.connectWifi(modelData.name);
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
        // PIE: Enlace a Configuración Avanzada
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
                    text: "󰒓"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: advMouse.containsMouse ? Theme.highlight : Theme.textMuted

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                Text {
                    text: "Configuración avanzada de red..."
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
