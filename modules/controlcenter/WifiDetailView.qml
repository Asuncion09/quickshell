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

    property int navIndex: 0
    property bool isKeyNavActive: false

    HoverHandler {
        onPointChanged: {
            if (root.isKeyNavActive) root.isKeyNavActive = false;
        }
    }

    function scrollToIndex(idx) {
        if (!netScroll || !netScroll.ScrollBar || !netScroll.ScrollBar.vertical) return;
        if (idx < 3) {
            netScroll.ScrollBar.vertical.position = 0;
            return;
        }
        let netIdx = idx - 3;
        let total = root.savedNetworks.length + root.availableNetworks.length;
        if (total <= 1) {
            netScroll.ScrollBar.vertical.position = 0;
            return;
        }
        let targetRatio = Math.max(0, Math.min(1, netIdx / (total - 1)));
        let maxPos = Math.max(0, 1.0 - (netScroll.height / Math.max(1, scrollCol.height)));
        if (maxPos > 0) {
            netScroll.ScrollBar.vertical.position = Math.max(0, Math.min(maxPos, targetRatio * maxPos));
        }
    }

    function triggerCurrentItem() {
        if (root.navIndex === 0) {
            root.cancelPassword();
            root.backRequested();
            return;
        }
        if (root.navIndex === 1) {
            if (root.isScanning) root.stopScan();
            else root.refreshScan();
            return;
        }
        if (root.navIndex === 2) {
            ControlCenterService.toggleWifi();
            return;
        }
        let netIdx = root.navIndex - 3;
        let savedCount = root.savedNetworks.length;
        if (netIdx < savedCount) {
            let net = root.savedNetworks[netIdx];
            if (net) {
                if (net.connected) {
                    ControlCenterService.disconnectWifi(net.name);
                } else {
                    ControlCenterService.connectWifi(net.name);
                }
            }
            return;
        }
        let availIdx = netIdx - savedCount;
        if (availIdx >= 0 && availIdx < root.availableNetworks.length) {
            let net = root.availableNetworks[availIdx];
            if (net) {
                if (root.isConnectingNet(net.name)) return;
                if (net.isProtected) {
                    root.promptPassword(net.name);
                } else {
                    ControlCenterService.connectWifi(net.name);
                }
            }
        }
    }

    function handleKey(event) {
        if (root.selectedSsid !== "") return false;

        let totalNets = (Networking.wifiEnabled || NetworkService.isConnected) ? (root.savedNetworks.length + root.availableNetworks.length) : 0;
        let totalItems = 3 + totalNets;

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
                if (totalNets > 0) root.navIndex = 3;
                else root.navIndex = 0;
            } else {
                root.navIndex = (root.navIndex - 3 + 1) % totalNets + 3;
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
                if (totalNets > 0) {
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
                if (totalNets > 0) root.navIndex = 3;
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

    Component.onCompleted: {
        updateScanner(true);
        ControlCenterService.refreshSavedWifiConnections();
        root.syncKnownSaved();
    }

    onVisibleChanged: {
        root.isKeyNavActive = false;
        root.navIndex = 0;
        if (visible) {
            updateScanner(true);
            refreshScan();
            ControlCenterService.refreshSavedWifiConnections();
            root.syncKnownSaved();
        } else {
            updateScanner(false);
            root.cancelPassword();
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
            ControlCenterService.refreshSavedWifiConnections();
            root.syncKnownSaved();
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
                let sec = parts.length > 3 ? parts[parts.length - 1].trim() : "";
                let sig = parseInt(parts[parts.length > 3 ? parts.length - 2 : 2]) || 50;
                let ssid = parts.length > 3 ? parts.slice(1, parts.length - 2).join(":") : parts[1];

                if (ssid && ssid.trim() !== "") {
                    let key = ssid.trim().toLowerCase();
                    let existing = map.get(key);
                    let isProt = sec !== "" && sec !== "--";
                    let item = {
                        name: ssid,
                        connected: isConn,
                        strength: Math.max(0.0, Math.min(1.0, sig / 100.0)),
                        isProtected: isProt
                    };
                    if (!existing || (!existing.connected && isConn) || (item.strength > existing.strength)) {
                        map.set(key, item);
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

    function stopScan() {
        root.isScanning = false;
        if (scanProc.running) scanProc.running = false;
    }

    // Fusión de fuentes: muestra todas las redes del hardware detectadas por CLI y enriquece con nativas
    readonly property var displayNetworks: {
        let map = new Map();

        // 1. Redes encontradas por escaneo CLI
        for (let i = 0; i < cliNetworks.length; i++) {
            let c = cliNetworks[i];
            if (c && c.name) {
                map.set(c.name.trim().toLowerCase(), c);
            }
        }

        // 2. Redes nativas (agregan o enriquecen con objetos nativos si coinciden)
        for (let i = 0; i < nativeNetworks.length; i++) {
            let n = nativeNetworks[i];
            if (n && n.name) {
                let key = n.name.trim().toLowerCase();
                let existing = map.get(key);
                map.set(key, {
                    name: (existing && existing.name) ? existing.name : n.name,
                    connected: false,
                    strength: n.strength !== undefined ? Math.max(n.strength, existing ? existing.strength : 0) : (existing ? existing.strength : 0.5),
                    isProtected: existing ? existing.isProtected : true,
                    nativeObj: n
                });
            }
        }

        // La red activa proviene con certeza de NetworkService.connectionName
        let activeKey = (NetworkService.connectionName || "").trim().toLowerCase();
        let hasActive = activeKey !== "" && activeKey !== "desconectado" && activeKey !== "wifi" && activeKey !== "ethernet" && activeKey !== "conectado";

        let list = Array.from(map.values()).map(item => {
            let itemKey = item.name.trim().toLowerCase();
            let isConn = false;
            if (hasActive) {
                isConn = (itemKey === activeKey);
            } else {
                isConn = item.connected === true;
            }
            return Object.assign({}, item, { connected: isConn });
        });

        // Si la red activa no estuviera en la lista de escaneo por baja señal, la insertamos
        if (hasActive) {
            let found = list.some(item => item.name.trim().toLowerCase() === activeKey);
            if (!found) {
                list.unshift({
                    name: NetworkService.connectionName,
                    connected: true,
                    strength: 1.0,
                    isProtected: true
                });
            }
        }

        list.sort((a, b) => {
            if (a.connected && !b.connected) return -1;
            if (!a.connected && b.connected) return 1;
            return (b.strength || 0) - (a.strength || 0);
        });
        return list;
    }

    // Registro dinámico de redes guardadas/reconocidas para evitar que salten a "Redes Disponibles"
    property var knownSavedMap: ({})

    function syncKnownSaved() {
        let next = Object.assign({}, knownSavedMap);
        let changed = false;
        let active = (NetworkService.connectionName || "").trim().toLowerCase();
        if (active && active !== "desconectado" && active !== "wifi" && active !== "ethernet" && active !== "conectado") {
            if (!next[active]) { next[active] = true; changed = true; }
        }
        let list = ControlCenterService.savedWifiConnections || [];
        for (let i = 0; i < list.length; i++) {
            let s = (list[i] || "").trim().toLowerCase();
            if (s && !next[s]) { next[s] = true; changed = true; }
        }
        if (changed) knownSavedMap = next;
    }

    function isNetworkSaved(name) {
        if (!name) return false;
        let nTrim = name.trim().toLowerCase();
        if (knownSavedMap[nTrim] === true) return true;
        return ControlCenterService.isWifiSaved(name);
    }

    function markSaved(name) {
        if (!name) return;
        let nTrim = name.trim().toLowerCase();
        if (knownSavedMap[nTrim] === true) return;
        let next = Object.assign({}, knownSavedMap);
        next[nTrim] = true;
        knownSavedMap = next;
    }

    function forgetSaved(name) {
        if (!name) return;
        let nTrim = name.trim().toLowerCase();
        let next = Object.assign({}, knownSavedMap);
        delete next[nTrim];
        knownSavedMap = next;
    }

    function isConnectingNet(netName) {
        if (!netName || !ControlCenterService.connectingWifiSsid) return false;
        let c = ControlCenterService.connectingWifiSsid.trim().toLowerCase();
        let n = netName.trim().toLowerCase();
        return c !== "" && c === n;
    }

    // 1. Mis Redes (Conectada actualmente o guardada en NetworkManager)
    readonly property var savedNetworks: {
        let _s = ControlCenterService.savedWifiConnections;
        let _c = ControlCenterService.connectingWifiSsid;
        let _k = knownSavedMap;
        let list = displayNetworks.filter(n => n && (n.connected || root.isNetworkSaved(n.name)));
        list.sort((a, b) => {
            if (a.connected && !b.connected) return -1;
            if (!a.connected && b.connected) return 1;
            return (b.strength || 0) - (a.strength || 0);
        });
        return list;
    }

    // 2. Redes Disponibles (Cercanas en el aire que no están guardadas)
    readonly property var availableNetworks: {
        let _s = ControlCenterService.savedWifiConnections;
        let _c = ControlCenterService.connectingWifiSsid;
        let _k = knownSavedMap;
        let list = displayNetworks.filter(n => n && !n.connected && !root.isNetworkSaved(n.name));
        list.sort((a, b) => (b.strength || 0) - (a.strength || 0));
        return list;
    }

    function signalIcon(strength) {
        let s = strength !== undefined ? strength : 0.5;
        if (s >= 0.75) return "󰤨";
        if (s >= 0.50) return "󰤢";
        if (s >= 0.25) return "󰤟";
        return "󰤯";
    }

    // --- Manejo de Entrada de Contraseña Inline ---
    property string selectedSsid: ""
    property string passwordText: ""
    property bool showPassword: false

    function promptPassword(ssid) {
        root.selectedSsid = ssid;
        root.passwordText = "";
        root.showPassword = false;
        ControlCenterService.wifiErrorMessage = "";
        Qt.callLater(() => passInput.forceActiveFocus());
    }

    function cancelPassword() {
        root.selectedSsid = "";
        root.passwordText = "";
        root.showPassword = false;
        ControlCenterService.wifiErrorMessage = "";
    }

    function submitPassword() {
        if (!root.selectedSsid || !root.passwordText) return;
        ControlCenterService.connectWifiWithPassword(root.selectedSsid, root.passwordText);
    }

    Connections {
        target: ControlCenterService
        function onSavedWifiConnectionsChanged() {
            root.syncKnownSaved();
        }
        function onWifiConnectionFinished() {
            root.refreshScan();
            root.syncKnownSaved();
            if (!ControlCenterService.wifiErrorMessage) {
                if (root.selectedSsid) root.markSaved(root.selectedSsid);
                root.selectedSsid = "";
                root.passwordText = "";
            }
        }
        function onConnectingWifiSsidChanged() {
            if (!ControlCenterService.connectingWifiSsid) {
                root.refreshScan();
                root.syncKnownSaved();
                if (!ControlCenterService.wifiErrorMessage && root.selectedSsid) {
                    root.selectedSsid = "";
                    root.passwordText = "";
                }
            }
        }
    }

    Connections {
        target: NetworkService
        function onConnectionNameChanged() {
            root.refreshScan();
            root.syncKnownSaved();
        }
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
                color: backMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase
                border.width: (root.isKeyNavActive && root.navIndex === 0) ? 2 : 0
                border.color: Theme.wsActiveColor

                scale: backMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: (backMouse.containsMouse || (root.isKeyNavActive && root.navIndex === 0)) ? Theme.wsActiveColor : Theme.textSecondary

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.cancelPassword();
                        root.backRequested();
                    }
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

            // Botón Recargar / Pausar escaneo (unificado como en Bluetooth)
            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 6
                color: refreshMouse.containsMouse ? Theme.surfaceHover : "transparent"
                border.width: (root.isKeyNavActive && root.navIndex === 1) ? 2 : 0
                border.color: Theme.wsActiveColor

                scale: refreshMouse.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: root.isScanning ? "󰏤" : "󰑐"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: {
                        if (root.isScanning) {
                            return refreshMouse.containsMouse ? Theme.critical : Theme.wsActiveColor;
                        }
                        return (refreshMouse.containsMouse || (root.isKeyNavActive && root.navIndex === 1)) ? Theme.wsActiveColor : Theme.textMuted;
                    }

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.isScanning) {
                            root.stopScan();
                        } else {
                            root.refreshScan();
                        }
                    }
                }
            }

            // Switch compacto de Encendido / Apagado
            Rectangle {
                id: wifiSwitch
                implicitWidth: 38
                implicitHeight: 22
                radius: 11
                color: (Networking.wifiEnabled || NetworkService.isConnected) ? Theme.wsActiveColor : Theme.surfaceBase
                border.width: (root.isKeyNavActive && root.navIndex === 2) ? 2 : 0
                border.color: (Networking.wifiEnabled || NetworkService.isConnected) ? "#ffffff" : Theme.wsActiveColor

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                // Perilla deslizante blanca
                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                    x: (Networking.wifiEnabled || NetworkService.isConnected) ? parent.width - width - 3 : 3

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
        // TARJETA DE CONTRASEÑA WI-FI INLINE
        // ==========================================
        Rectangle {
            id: passwordCard
            Layout.fillWidth: true
            visible: root.selectedSsid !== ""
            implicitHeight: passCol.implicitHeight + 20
            radius: 10
            color: Theme.surfaceBase
            border.width: 0

            onVisibleChanged: {
                if (visible) Qt.callLater(() => passInput.forceActiveFocus());
            }

            ColumnLayout {
                id: passCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "󰌾"
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
                            text: root.selectedSsid
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Theme.text
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Introduce la contraseña de red"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }
                    }
                }

                // Campo de entrada de contraseña
                Rectangle {
                    id: passBox
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 6
                    color: Theme.bgDark
                    border.width: passInput.activeFocus ? 1 : (passBoxMouse.containsMouse ? 1 : 0)
                    border.color: passInput.activeFocus ? Theme.wsActiveColor : Theme.dividerColor

                    MouseArea {
                        id: passBoxMouse
                        anchors.fill: parent
                        anchors.rightMargin: 32
                        hoverEnabled: true
                        cursorShape: Qt.IBeamCursor
                        onClicked: passInput.forceActiveFocus()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 6

                        TextInput {
                            id: passInput
                            Layout.fillWidth: true
                            text: root.passwordText
                            echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.text
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            selectByMouse: true
                            mouseSelectionMode: TextInput.SelectCharacters
                            onTextChanged: root.passwordText = text
                            onAccepted: root.submitPassword()
                            Keys.onEscapePressed: event => {
                                event.accepted = true;
                                root.selectedSsidForPassword = "";
                                root.passwordText = "";
                                root.backRequested();
                            }

                            Text {
                                text: "Contraseña..."
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.textMuted
                                visible: !passInput.text && !passInput.activeFocus
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Botón Mostrar/Ocultar contraseña (Ojo)
                        Rectangle {
                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 4
                            color: "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: root.showPassword ? "󰈉" : "󰈈"
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                color: eyeMouse.containsMouse ? Theme.text : Theme.textMuted
                            }

                            MouseArea {
                                id: eyeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.showPassword = !root.showPassword;
                                    passInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                // Mensaje de error si la conexión falló
                Text {
                    Layout.fillWidth: true
                    visible: ControlCenterService.wifiErrorMessage !== ""
                    text: ControlCenterService.wifiErrorMessage
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.critical
                    wrapMode: Text.Wrap
                }

                // Fila de Botones: Cancelar y Conectar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        id: cancelBtn
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: 6
                        color: cancelMouse.containsMouse ? Theme.surfaceHover : Theme.bgDark
                        border.width: 0

                        Text {
                            anchors.centerIn: parent
                            text: "Cancelar"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.textSecondary
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cancelPassword()
                        }
                    }

                    Rectangle {
                        id: connectBtn
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: 6
                        color: Theme.wsActiveColor
                        border.width: 0
                        opacity: root.passwordText.length > 0 ? 1.0 : 0.5

                        Text {
                            anchors.centerIn: parent
                            text: root.isConnectingNet(root.selectedSsid) ? "Conectando..." : "Conectar"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: "#161616"
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: root.passwordText.length > 0
                            cursorShape: root.passwordText.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (root.passwordText.length > 0) root.submitPassword();
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // CUERPO: Lista de Redes Wi-Fi (Doble Sección Inteligente)
        // ==========================================
        Item {
            Layout.fillWidth: true
            implicitHeight: {
                let enabled = Networking.wifiEnabled || NetworkService.isConnected;
                if (!enabled) return 70;
                if (root.displayNetworks.length === 0) return 70;
                return Math.min(root.selectedSsid !== "" ? 150 : 270, scrollCol.implicitHeight);
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
                    color: Theme.wsActiveColor
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.isScanning ? "Buscando redes..." : "No se encontraron redes"
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
                contentWidth: availableWidth

                ColumnLayout {
                    id: scrollCol
                    width: parent.width
                    spacing: 8

                    // -------------------------------------------------------------
                    // SECCIÓN 1: MIS REDES (Conectada / Guardadas)
                    // -------------------------------------------------------------
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: root.savedNetworks.length > 0

                        Text {
                            text: "MIS REDES"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: Theme.textMuted
                            Layout.leftMargin: 4
                        }

                        Repeater {
                            model: root.savedNetworks

                            delegate: Rectangle {
                                id: savedItem
                                Layout.fillWidth: true
                                implicitHeight: 34
                                radius: 8
                                color: {
                                    if (modelData.connected) return savedRowMouse.containsMouse ? Theme.surfaceActiveHover : Theme.surfaceActive;
                                    return savedRowMouse.containsMouse ? Theme.surfaceHover : "transparent";
                                }
                                border.width: (root.isKeyNavActive && root.navIndex === (3 + index)) ? 2 : 0
                                border.color: Theme.wsActiveColor

                                scale: savedRowMouse.pressed ? 0.98 : 1.0
                                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    // Icono de señal
                                    Text {
                                        text: root.signalIcon(modelData.strength)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                        color: modelData.connected ? Theme.wsActiveColor : (savedRowMouse.containsMouse ? Theme.text : Theme.textSecondary)
                                    }

                                    // Nombre de la red
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.name
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.weight: modelData.connected ? Font.DemiBold : Font.Normal
                                            color: modelData.connected ? Theme.wsActiveColor : Theme.text
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            visible: root.isConnectingNet(modelData.name)
                                            text: "Conectando..."
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            color: Theme.wsActiveColor
                                        }
                                    }

                                    // Estado de conexión
                                    Text {
                                        visible: modelData.connected && !root.isConnectingNet(modelData.name)
                                        text: "Conectado"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        color: Theme.success
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    // Botón para olvidar / borrar red guardada (󰆴)
                                    Rectangle {
                                        id: forgetNetBtn
                                        implicitWidth: 22
                                        implicitHeight: 22
                                        radius: 5
                                        color: forgetNetMouse.containsMouse ? Theme.surfaceHover : "transparent"
                                        visible: savedRowMouse.containsMouse || forgetNetMouse.containsMouse
                                        Layout.alignment: Qt.AlignVCenter

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰆴"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 12
                                            color: forgetNetMouse.containsMouse ? Theme.critical : Theme.textMuted
                                        }

                                        MouseArea {
                                            id: forgetNetMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.forgetSaved(modelData.name);
                                                ControlCenterService.deleteWifiConnection(modelData.name);
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: savedRowMouse
                                    anchors.fill: parent
                                    anchors.rightMargin: forgetNetBtn.visible ? 24 : 0
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.isConnectingNet(modelData.name)) return;
                                        root.markSaved(modelData.name);
                                        if (modelData.connected) {
                                            ControlCenterService.disconnectWifi(modelData.name);
                                        } else {
                                            ControlCenterService.connectWifi(modelData.name);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // -------------------------------------------------------------
                    // SECCIÓN 2: REDES DISPONIBLES (Nuevas en el aire)
                    // -------------------------------------------------------------
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: (Networking.wifiEnabled || NetworkService.isConnected)

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "REDES DISPONIBLES"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: Theme.textMuted
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

                        // Placeholder si no hay redes disponibles
                        Item {
                            visible: root.availableNetworks.length === 0
                            Layout.fillWidth: true
                            implicitHeight: 28

                            Text {
                                anchors.centerIn: parent
                                text: root.isScanning ? "Buscando redes..." : "Sin redes cercanas"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.textSecondary
                            }
                        }

                        Repeater {
                            model: root.availableNetworks

                            delegate: Rectangle {
                                id: availNetItem
                                Layout.fillWidth: true
                                implicitHeight: 34
                                radius: 8
                                color: availNetMouse.containsMouse ? Theme.surfaceHover : "transparent"
                                border.width: (root.isKeyNavActive && root.navIndex === (3 + root.savedNetworks.length + index)) ? 2 : 0
                                border.color: Theme.wsActiveColor

                                scale: availNetMouse.pressed ? 0.98 : 1.0
                                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Text {
                                        text: root.signalIcon(modelData.strength)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                        color: availNetMouse.containsMouse ? Theme.text : Theme.textSecondary
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.name
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            color: Theme.text
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            visible: root.isConnectingNet(modelData.name)
                                            text: "Conectando..."
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            color: Theme.wsActiveColor
                                        }
                                    }

                                    // Candado si está protegida
                                    Text {
                                        visible: modelData.isProtected
                                        text: "󰌾"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        color: Theme.textMuted
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Text {
                                        text: root.isConnectingNet(modelData.name) ? "..." : "Conectar"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        color: Theme.wsActiveColor
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    id: availNetMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.isConnectingNet(modelData.name)) return;
                                        if (modelData.isProtected) {
                                            root.promptPassword(modelData.name);
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
    }
}
