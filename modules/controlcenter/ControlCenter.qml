import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../services"

Item {
    id: root

    property bool _isOpen: false
    property int currentView: 0 // 0 = Principal, 1 = Wi-Fi, 2 = Bluetooth
    property int focusedIndex: 0 // 0..7 para los elementos del panel principal
    property bool isKeyNavActive: false // Solo se activa al presionar flechas o teclado

    implicitWidth: 300 + 8
    implicitHeight: mainCard.implicitHeight + 14
    width: implicitWidth
    height: implicitHeight
    visible: root._isOpen || animContainer.opacity > 0.01

    function triggerSpaceAction(idx) {
        switch (idx) {
            case 0: ControlCenterService.toggleWifi(); break;
            case 1: ControlCenterService.toggleBluetooth(); break;
            case 2: NotificationService.toggleDnd(); break;
            case 3: ControlCenterService.toggleMicMute(); break;
            case 4: AudioService.toggleMute(); break;
            case 5: BrightnessService.setBrightness(BrightnessService.brightnessPercent > 10 ? 10 : 100); break;
            case 6: ControlCenterService.lockScreen(); break;
            case 7:
                ControlCenterService.togglePowerMenu();
                if (ControlCenterService.isPowerMenuOpen) {
                    batCard.powerNavIndex = 4;
                    batCard.isPowerNavActive = true;
                }
                break;
        }
    }

    function triggerEnterAction(idx) {
        switch (idx) {
            case 0: root.currentView = 1; break;
            case 1: root.currentView = 2; break;
            case 2: NotificationService.toggleDnd(); break;
            case 3: ControlCenterService.toggleMicMute(); break;
            case 4: AudioService.toggleMute(); break;
            case 5: BrightnessService.setBrightness(BrightnessService.brightnessPercent > 10 ? 10 : 100); break;
            case 6: ControlCenterService.lockScreen(); break;
            case 7:
                ControlCenterService.togglePowerMenu();
                if (ControlCenterService.isPowerMenuOpen) {
                    batCard.powerNavIndex = 4;
                    batCard.isPowerNavActive = true;
                }
                break;
        }
    }

    Timer {
        id: closeTimer
        interval: 220
        onTriggered: {
            if (!root._isOpen) {
                root.currentView = 0;
            }
        }
    }

    function toggle() {
        if (root._isOpen) {
            root.close();
        } else {
            root.open();
        }
    }

    function open() {
        closeTimer.stop();
        root._isOpen = true;
        root.focusedIndex = 0;
        root.isKeyNavActive = false;
        if (!ControlCenterService.isOpen) {
            ControlCenterService.open();
        }
        Qt.callLater(() => mainCard.forceActiveFocus());
    }

    function close() {
        root._isOpen = false;
        root.isKeyNavActive = false;
        closeTimer.restart();
        if (ControlCenterService.isOpen) {
            ControlCenterService.close();
        }
    }

    Connections {
        target: ControlCenterService
        function onIsOpenChanged() {
            if (ControlCenterService.isOpen && !root._isOpen) {
                root.open();
            } else if (!ControlCenterService.isOpen && root._isOpen) {
                root.close();
            }
        }
        function onHasPasskeyPromptChanged() {
            if (ControlCenterService.hasPasskeyPrompt) {
                root.currentView = 2;
                root.open();
            }
        }
    }

    Item {
        id: animContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8
        anchors.rightMargin: 0
        anchors.topMargin: 2
        anchors.bottomMargin: 10
        transformOrigin: Item.TopRight

        // Animaciones dinámicas de despliegue: escala elástica, traslación vertical y desvanecimiento
        scale: root._isOpen ? 1.0 : 0.90
        y: root._isOpen ? 0 : -16
        opacity: root._isOpen ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation {
                duration: root._isOpen ? 240 : 180
                easing.type: root._isOpen ? Easing.OutBack : Easing.InCubic
                easing.overshoot: root._isOpen ? 1.08 : 1.0
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: root._isOpen ? 240 : 180
                easing.type: root._isOpen ? Easing.OutCubic : Easing.InCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root._isOpen ? 200 : 160
                easing.type: root._isOpen ? Easing.OutQuad : Easing.InQuad
            }
        }

        // Sombra volumétrica por hardware
        Rectangle {
            id: shadowShape
            anchors.fill: mainCard
            radius: 16
            color: "#000000"
            visible: false
        }

        MultiEffect {
            source: shadowShape
            anchors.fill: shadowShape
            visible: Theme.pillShadowEnabled
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.65
            shadowBlur: 0.55
            shadowVerticalOffset: 4
        }

        // Tarjeta principal del Centro de Control
        Rectangle {
            id: mainCard
            anchors.fill: parent
            implicitHeight: {
                if (root.currentView === 1) return wifiView.implicitHeight + 22;
                if (root.currentView === 2) return btView.implicitHeight + 22;
                return contentColumn.implicitHeight + 22;
            }

            // Absorbe clics dentro de la tarjeta para que no traspasen a dismissArea
            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: mouse => mouse.accepted = true
            }

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Theme.animNormal
                    easing.type: Easing.OutCubic
                }
            }

            radius: 16
            color: Theme.bgDark
            border.color: "#2e2e2e"
            border.width: 1
            focus: true

            HoverHandler {
                onPointChanged: {
                    if (root.isKeyNavActive) {
                        root.isKeyNavActive = false;
                        root.focusedIndex = 0;
                    }
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    if (root.currentView === 1 && wifiView.selectedSsid !== "") {
                        wifiView.cancelPassword();
                    } else if (root.currentView !== 0) {
                        root.currentView = 0;
                        Qt.callLater(() => mainCard.forceActiveFocus());
                    } else if (ControlCenterService.isPowerMenuOpen) {
                        ControlCenterService.closePowerMenu();
                    } else {
                        root.close();
                    }
                    return;
                }

                if (event.key === Qt.Key_Back || event.key === Qt.Key_Backspace) {
                    if (root.currentView === 1 && wifiView.selectedSsid !== "") {
                        return;
                    }
                    if (root.currentView !== 0) {
                        event.accepted = true;
                        root.currentView = 0;
                        Qt.callLater(() => mainCard.forceActiveFocus());
                        return;
                    }
                    if (ControlCenterService.isPowerMenuOpen) {
                        event.accepted = true;
                        ControlCenterService.closePowerMenu();
                        return;
                    }
                }

                // --- GESTIÓN DE SUBVISTA WI-FI (currentView === 1) ---
                if (root.currentView === 1) {
                    if (wifiView.handleKey(event)) {
                        event.accepted = true;
                        return;
                    }
                    return;
                }

                // --- GESTIÓN DE SUBVISTA BLUETOOTH (currentView === 2) ---
                if (root.currentView === 2) {
                    if (btView.handleKey(event)) {
                        event.accepted = true;
                        return;
                    }
                    return;
                }

                // --- GESTIÓN DE MENÚ DE APAGADO (isPowerMenuOpen) ---
                if (ControlCenterService.isPowerMenuOpen) {
                    if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                        event.accepted = true;
                        batCard.nextPowerItem();
                        return;
                    }
                    if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                        event.accepted = true;
                        batCard.prevPowerItem();
                        return;
                    }
                    if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        event.accepted = true;
                        batCard.triggerPowerCurrent();
                        return;
                    }
                    if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                        event.accepted = true;
                        ControlCenterService.closePowerMenu();
                        root.focusedIndex = 7;
                        return;
                    }
                    return;
                }

                // --- VISTA PRINCIPAL (currentView === 0) ---
                let isNavKey = (event.key === Qt.Key_Right ||
                                event.key === Qt.Key_Left  ||
                                event.key === Qt.Key_Down  ||
                                event.key === Qt.Key_Up    ||
                                event.key === Qt.Key_Tab   ||
                                event.key === Qt.Key_Backtab);

                // Si la navegación por teclado aún no está activa:
                if (!root.isKeyNavActive) {
                    if (isNavKey) {
                        event.accepted = true;
                        root.focusedIndex = 0;
                        root.isKeyNavActive = true;
                        return;
                    }
                    // Si se presiona Espacio o Enter sin haber seleccionado un elemento con las flechas, ignorar para evitar acciones accidentales (como apagar el Wi-Fi)
                    if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        event.accepted = true;
                        return;
                    }
                    return;
                }

                if (event.key === Qt.Key_Tab) {
                    event.accepted = true;
                    if (event.modifiers & Qt.ShiftModifier) {
                        root.focusedIndex = (root.focusedIndex + 7) % 8;
                    } else {
                        root.focusedIndex = (root.focusedIndex + 1) % 8;
                    }
                    return;
                }
                if (event.key === Qt.Key_Backtab) {
                    event.accepted = true;
                    root.focusedIndex = (root.focusedIndex + 7) % 8;
                    return;
                }

                // Flecha Derecha (→)
                if (event.key === Qt.Key_Right) {
                    event.accepted = true;
                    if (root.focusedIndex === 4) {
                        sliderVol.stepUp();
                    } else if (root.focusedIndex === 5) {
                        sliderBri.stepUp();
                    } else {
                        // Flujo continuo: Wi-Fi(0) -> BT(1) -> DND(2) -> Mic(3) -> Vol(4), etc.
                        root.focusedIndex = (root.focusedIndex + 1) % 8;
                    }
                    return;
                }

                // Flecha Izquierda (←)
                if (event.key === Qt.Key_Left) {
                    event.accepted = true;
                    if (root.focusedIndex === 4) {
                        sliderVol.stepDown();
                    } else if (root.focusedIndex === 5) {
                        sliderBri.stepDown();
                    } else {
                        // Flujo continuo hacia atrás
                        root.focusedIndex = (root.focusedIndex + 7) % 8;
                    }
                    return;
                }

                // Flecha Abajo (↓)
                if (event.key === Qt.Key_Down) {
                    event.accepted = true;
                    if (root.focusedIndex === 0) root.focusedIndex = 2;       // Wi-Fi -> DND
                    else if (root.focusedIndex === 1) root.focusedIndex = 3;  // BT -> Mic
                    else if (root.focusedIndex === 2 || root.focusedIndex === 3) root.focusedIndex = 4; // DND/Mic -> Slider Vol
                    else if (root.focusedIndex === 4) root.focusedIndex = 5;  // Slider Vol -> Slider Brillo
                    else if (root.focusedIndex === 5) root.focusedIndex = 6;  // Slider Brillo -> Lock
                    else if (root.focusedIndex === 6) root.focusedIndex = 0;  // Lock -> Wi-Fi (wrap)
                    else if (root.focusedIndex === 7) root.focusedIndex = 1;  // Power -> BT (wrap)
                    return;
                }

                // Flecha Arriba (↑)
                if (event.key === Qt.Key_Up) {
                    event.accepted = true;
                    if (root.focusedIndex === 0) root.focusedIndex = 6;       // Wi-Fi -> Lock (wrap)
                    else if (root.focusedIndex === 1) root.focusedIndex = 7;  // BT -> Power (wrap)
                    else if (root.focusedIndex === 2) root.focusedIndex = 0;  // DND -> Wi-Fi
                    else if (root.focusedIndex === 3) root.focusedIndex = 1;  // Mic -> BT
                    else if (root.focusedIndex === 4) root.focusedIndex = 2;  // Slider Vol -> DND
                    else if (root.focusedIndex === 5) root.focusedIndex = 4;  // Slider Brillo -> Slider Vol
                    else if (root.focusedIndex === 6) root.focusedIndex = 5;  // Lock -> Slider Brillo
                    else if (root.focusedIndex === 7) root.focusedIndex = 5;  // Power -> Slider Brillo
                    return;
                }

                // Espacio (Space): conmuta el toggle o estado
                if (event.key === Qt.Key_Space) {
                    event.accepted = true;
                    root.triggerSpaceAction(root.focusedIndex);
                    return;
                }

                // Intro / Return: abre submenú si existe, o activa acción
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true;
                    root.triggerEnterAction(root.focusedIndex);
                    return;
                }
            }

            Item {
                id: viewsContainer
                anchors.fill: parent
                anchors.margins: 11
                clip: true

                // ==========================================
                // VISTA 0: Panel Principal (Toggles 2x2, Sliders, Batería)
                // ==========================================
                Item {
                    id: mainView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    implicitHeight: contentColumn.implicitHeight
                    height: implicitHeight

                    opacity: root.currentView === 0 ? 1.0 : 0.0
                    x: root.currentView === 0 ? 0 : -20
                    visible: opacity > 0.01

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animFast }
                    }
                    Behavior on x {
                        NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
                    }

                    ColumnLayout {
                        id: contentColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 10

                        // 1. Cuadrícula de Toggles 2x2
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 8
                            rowSpacing: 8

                            // Toggle Wi-Fi
                            QuickToggle {
                                id: toggleWifi
                                focused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 0
                                icon: NetworkService.icon
                                title: "Wi-Fi"
                                subtitle: NetworkService.connectionName
                                active: NetworkService.isConnected
                                hasSubmenu: true
                                onClicked: ControlCenterService.toggleWifi()
                                onSubmenuClicked: root.currentView = 1
                            }

                            // Toggle Bluetooth
                            QuickToggle {
                                id: toggleBt
                                focused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 1
                                icon: BluetoothService.icon
                                title: "Bluetooth"
                                subtitle: BluetoothService.deviceName
                                active: BluetoothService.isEnabled
                                hasSubmenu: true
                                onClicked: ControlCenterService.toggleBluetooth()
                                onSubmenuClicked: root.currentView = 2
                            }

                            // Toggle No Molestar (DND)
                            QuickToggle {
                                id: toggleDnd
                                focused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 2
                                icon: NotificationService.dnd ? "󰂛" : "󰂚"
                                title: "No Molestar"
                                subtitle: NotificationService.dnd ? "Silenciado" : "Desactivado"
                                active: NotificationService.dnd
                                hasSubmenu: false
                                onClicked: NotificationService.toggleDnd()
                            }

                            // Toggle Micrófono
                            QuickToggle {
                                id: toggleMic
                                focused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 3
                                icon: ControlCenterService.isMicMuted ? "󰍭" : "󰍬"
                                title: "Micrófono"
                                subtitle: ControlCenterService.isMicMuted ? "Silenciado" : "Activo"
                                active: !ControlCenterService.isMicMuted
                                hasSubmenu: false
                                onClicked: ControlCenterService.toggleMicMute()
                            }
                        }

                        // Línea divisoria fina
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.dividerColor
                        }

                        // 2. Controles Deslizantes (Volumen y Brillo)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            // Slider de Volumen
                            SliderControl {
                                id: sliderVol
                                focused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 4
                                icon: AudioService.icon
                                value: AudioService.currentPercent
                                isMuted: AudioService.isMuted
                                accentColor: Theme.wsActiveColor
                                onValueChangedByUser: pct => AudioService.setVolume(pct)
                                onIconClicked: AudioService.toggleMute()
                            }

                            // Slider de Brillo
                            SliderControl {
                                id: sliderBri
                                focused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 5
                                icon: BrightnessService.icon
                                value: BrightnessService.brightnessPercent
                                isMuted: false
                                accentColor: Theme.wsActiveColor
                                onValueChangedByUser: pct => BrightnessService.setBrightness(pct)
                                onIconClicked: BrightnessService.setBrightness(BrightnessService.brightnessPercent > 10 ? 10 : 100)
                            }
                        }

                        // Línea divisoria fina
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.dividerColor
                        }

                        // 3. Fila de Utilidades (Batería compacta y Bloqueo de 32px)
                        BatteryCard {
                            id: batCard
                            Layout.fillWidth: true
                            lockFocused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 6
                            powerFocused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 7
                        }
                    }
                }

                // ==========================================
                // VISTA 1: Detalle de Wi-Fi
                // ==========================================
                WifiDetailView {
                    id: wifiView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top

                    opacity: root.currentView === 1 ? 1.0 : 0.0
                    x: root.currentView === 1 ? 0 : 20
                    visible: opacity > 0.01

                    onBackRequested: {
                        root.currentView = 0;
                        Qt.callLater(() => mainCard.forceActiveFocus());
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animFast }
                    }
                    Behavior on x {
                        NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
                    }
                }

                // ==========================================
                // VISTA 2: Detalle de Bluetooth
                // ==========================================
                BluetoothDetailView {
                    id: btView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top

                    opacity: root.currentView === 2 ? 1.0 : 0.0
                    x: root.currentView === 2 ? 0 : 20
                    visible: opacity > 0.01

                    onBackRequested: {
                        root.currentView = 0;
                        Qt.callLater(() => mainCard.forceActiveFocus());
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animFast }
                    }
                    Behavior on x {
                        NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
