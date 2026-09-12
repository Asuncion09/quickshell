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
    property bool isFocusedMonitor: true
    property string monitorName: ""
    property int currentView: 0 // 0 = Principal, 1 = Wi-Fi, 2 = Bluetooth, 3 = Sound, 4 = Settings, 5 = Wallpaper
    property int focusedIndex: 0 // 0..11 para los elementos del panel principal
    property bool isKeyNavActive: false // Solo se activa al presionar flechas o teclado

    onCurrentViewChanged: {
        Qt.callLater(() => mainCard.forceActiveFocus());
    }

    implicitWidth: 318 + 8
    implicitHeight: mainCard.implicitHeight + 14
    width: implicitWidth
    height: implicitHeight
    visible: root._isOpen || animContainer.opacity > 0.01

    function triggerSpaceAction(idx) {
        switch (idx) {
            case 0: ControlCenterService.toggleWifi(); break;
            case 1: ControlCenterService.toggleBluetooth(); break;
            case 2: ControlCenterService.toggleMicMute(); break;
            case 3: ControlCenterService.toggleCaffeine(); break;
            case 4: ControlCenterService.pickColor(); break;
            case 5: ControlCenterService.captureRegion(); break;
            case 6: AudioService.toggleMute(); break;
            case 7: break; // No hacer nada en el slider de brillo (solo flechas izquierda/derecha)
            case 8: powerProfiles.stepNext(); break;
            case 9:
                root.currentView = 4;
                Qt.callLater(() => mainCard.forceActiveFocus());
                break;
            case 10: ControlCenterService.lockScreen(); break;
            case 11:
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
            case 2: ControlCenterService.toggleMicMute(); break;
            case 3: ControlCenterService.toggleCaffeine(); break;
            case 4: ControlCenterService.pickColor(); break;
            case 5: ControlCenterService.captureRegion(); break;
            case 6: AudioService.toggleMute(); break;
            case 7: break; // No hacer nada en el slider de brillo (solo flechas izquierda/derecha)
            case 8: powerProfiles.stepNext(); break;
            case 9:
                root.currentView = 4;
                Qt.callLater(() => mainCard.forceActiveFocus());
                break;
            case 10: ControlCenterService.lockScreen(); break;
            case 11:
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
        interval: 150
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

    Timer {
        id: focusRetryTimer
        interval: 40
        onTriggered: {
            if (root._isOpen) {
                mainCard.forceActiveFocus();
            }
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
        mainCard.forceActiveFocus();
        focusRetryTimer.restart();
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
            let target = ControlCenterService.targetMonitor;
            let shouldOpen = (target !== "") ? (target === root.monitorName) : root.isFocusedMonitor;

            if (ControlCenterService.isOpen && !root._isOpen) {
                if (shouldOpen) {
                    root.open();
                }
            } else if (!ControlCenterService.isOpen && root._isOpen) {
                root.close();
            }
        }
        function onHasPasskeyPromptChanged() {
            let target = ControlCenterService.targetMonitor;
            let shouldOpen = (target !== "") ? (target === root.monitorName) : root.isFocusedMonitor;
            if (ControlCenterService.hasPasskeyPrompt && shouldOpen) {
                root.currentView = 2;
                root.open();
            }
        }
        function onRequestedViewChanged() {
            if (ControlCenterService.requestedView > 0) {
                let target = ControlCenterService.targetMonitor;
                let shouldOpen = (target !== "") ? (target === root.monitorName) : root.isFocusedMonitor;
                if (shouldOpen) {
                    root.currentView = ControlCenterService.requestedView;
                    root.open();
                }
                ControlCenterService.requestedView = 0;
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

        // Animación cinemática premium estilo macOS Sonoma / iOS / Material 3:
        // Micro-escala (0.975 -> 1.0) para profundidad 3D limpia sin deformación de fuentes ni efecto 'gelatina'
        scale: root._isOpen ? 1.0 : 0.975
        y: root._isOpen ? 0 : -10
        opacity: root._isOpen ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation {
                duration: root._isOpen ? 210 : 130
                easing.type: root._isOpen ? Easing.OutCubic : Easing.OutQuad
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: root._isOpen ? 210 : 130
                easing.type: root._isOpen ? Easing.OutCubic : Easing.OutQuad
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root._isOpen ? 180 : 120
                easing.type: root._isOpen ? Easing.OutCubic : Easing.OutQuad
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
                if (root.currentView === 3) return audioView.implicitHeight + 22;
                if (root.currentView === 4) return settingsView.implicitHeight + 22;
                if (root.currentView === 5) return wallpaperView.implicitHeight + 22;
                return contentColumn.implicitHeight + 22;
            }

            // Absorbe clics dentro de la tarjeta para que no traspasen a dismissArea
            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: mouse => {
                    mouse.accepted = true;
                    root.isKeyNavActive = false;
                    mainCard.forceActiveFocus();
                }
            }

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            radius: 16
            color: Theme.bgDark
            border.color: "#2e2e2e"
            border.width: 1
            focus: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    if (root.currentView === 1 && wifiView.selectedSsid !== "") {
                        wifiView.cancelPassword();
                    } else if (root.currentView === 3) {
                        root.currentView = 4;
                        Qt.callLater(() => mainCard.forceActiveFocus());
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
                    if (root.currentView === 3) {
                        event.accepted = true;
                        root.currentView = 4;
                        Qt.callLater(() => mainCard.forceActiveFocus());
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

                // --- GESTIÓN DE SUBVISTA AUDIO (currentView === 3) ---
                if (root.currentView === 3) {
                    if (audioView.handleKey(event)) {
                        event.accepted = true;
                        return;
                    }
                    return;
                }

                // --- GESTIÓN DE SUBVISTA CONFIGURACIÓN (currentView === 4) ---
                if (root.currentView === 4) {
                    if (settingsView.handleKey(event)) {
                        event.accepted = true;
                        return;
                    }
                    return;
                }

                // --- GESTIÓN DE SUBVISTA WALLPAPER (currentView === 5) ---
                if (root.currentView === 5) {
                    if (wallpaperView.handleKey(event)) {
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
                        root.focusedIndex = 11;
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
                        root.focusedIndex = 0;      // Selecciona Wi-Fi como primer elemento predeterminado
                        root.isKeyNavActive = true; // Hace visible la selección con estilo hover
                        return;                     // Detiene aquí para que Wi-Fi quede seleccionado en la primera pulsación
                    }
                    // Si se presiona Espacio o Enter sin haber navegado, se ignora completamente para evitar apagar/activar por error
                    if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        event.accepted = true;
                        return;
                    }
                    return;
                }

                if (event.key === Qt.Key_Tab) {
                    event.accepted = true;
                    if (event.modifiers & Qt.ShiftModifier) {
                        root.focusedIndex = (root.focusedIndex + 11) % 12;
                    } else {
                        root.focusedIndex = (root.focusedIndex + 1) % 12;
                    }
                    return;
                }
                if (event.key === Qt.Key_Backtab) {
                    event.accepted = true;
                    root.focusedIndex = (root.focusedIndex + 11) % 12;
                    return;
                }

                // Flecha Derecha (→)
                if (event.key === Qt.Key_Right) {
                    event.accepted = true;
                    if (root.focusedIndex === 6) {
                        sliderVol.stepUp();
                    } else if (root.focusedIndex === 7) {
                        sliderBri.stepUp();
                    } else if (root.focusedIndex === 8) {
                        powerProfiles.stepNext();
                    } else {
                        root.focusedIndex = (root.focusedIndex + 1) % 12;
                    }
                    return;
                }

                // Flecha Izquierda (←)
                if (event.key === Qt.Key_Left) {
                    event.accepted = true;
                    if (root.focusedIndex === 6) {
                        sliderVol.stepDown();
                    } else if (root.focusedIndex === 7) {
                        sliderBri.stepDown();
                    } else if (root.focusedIndex === 8) {
                        powerProfiles.stepPrev();
                    } else {
                        root.focusedIndex = (root.focusedIndex + 11) % 12;
                    }
                    return;
                }

                // Flecha Abajo (↓)
                if (event.key === Qt.Key_Down) {
                    event.accepted = true;
                    if (root.focusedIndex === 0) root.focusedIndex = 2;       // Wi-Fi -> Mic
                    else if (root.focusedIndex === 1) root.focusedIndex = 4;  // BT -> ColorPicker
                    else if (root.focusedIndex >= 2 && root.focusedIndex <= 5) root.focusedIndex = 6; // Quick icons -> Slider Vol
                    else if (root.focusedIndex === 6) root.focusedIndex = 7;  // Slider Vol -> Slider Brillo
                    else if (root.focusedIndex === 7) root.focusedIndex = 8;  // Slider Brillo -> Perfiles
                    else if (root.focusedIndex === 8) root.focusedIndex = 9;  // Perfiles -> Settings
                    else if (root.focusedIndex === 9) root.focusedIndex = 0;  // Settings -> Wi-Fi (wrap)
                    else if (root.focusedIndex === 10) root.focusedIndex = 0; // Lock -> Wi-Fi (wrap)
                    else if (root.focusedIndex === 11) root.focusedIndex = 1; // Power -> BT (wrap)
                    return;
                }

                // Flecha Arriba (↑)
                if (event.key === Qt.Key_Up) {
                    event.accepted = true;
                    if (root.focusedIndex === 0) root.focusedIndex = 9;       // Wi-Fi -> Settings (wrap)
                    else if (root.focusedIndex === 1) root.focusedIndex = 11; // BT -> Power (wrap)
                    else if (root.focusedIndex === 2 || root.focusedIndex === 3) root.focusedIndex = 0; // Mic/Caffeine -> Wi-Fi
                    else if (root.focusedIndex === 4 || root.focusedIndex === 5) root.focusedIndex = 1; // ColorPicker/RegionShot -> BT
                    else if (root.focusedIndex === 6) root.focusedIndex = 2;  // Slider Vol -> Mic
                    else if (root.focusedIndex === 7) root.focusedIndex = 6;  // Slider Brillo -> Slider Vol
                    else if (root.focusedIndex === 8) root.focusedIndex = 7;  // Perfiles -> Slider Brillo
                    else if (root.focusedIndex >= 9 && root.focusedIndex <= 11) root.focusedIndex = 8; // Botones inferiores -> Perfiles
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
                    scale: root.currentView === 0 ? 1.0 : 0.98
                    visible: opacity > 0.01

                    Behavior on opacity {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on x {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }

                    ColumnLayout {
                        id: contentColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 10

                        // 1. Toggles Principales (Wi-Fi y Bluetooth)
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
                                active: NetworkService.isWifiEnabled
                                loading: NetworkService.isWifiEnabled && !NetworkService.isConnected
                                hasSubmenu: true
                                onClicked: ControlCenterService.toggleWifi()
                                onSubmenuClicked: {
                                    root.currentView = 1;
                                    Qt.callLater(() => mainCard.forceActiveFocus());
                                }
                            }

                            // Toggle Bluetooth
                            QuickToggle {
                                id: toggleBt
                                focused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 1
                                icon: BluetoothService.icon
                                title: "Bluetooth"
                                active: BluetoothService.isEnabled
                                hasSubmenu: true
                                onClicked: ControlCenterService.toggleBluetooth()
                                onSubmenuClicked: {
                                    root.currentView = 2;
                                    Qt.callLater(() => mainCard.forceActiveFocus());
                                }
                            }
                        }

                        // 2. Fila de Acciones Rápidas (4 Botones Compactos de Iconos)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            // Micrófono
                            QuickIconButton {
                                id: btnMic
                                icon: ControlCenterService.isMicMuted ? "󰍭" : "󰍬"
                                active: !ControlCenterService.isMicMuted
                                focused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 2
                                onClicked: ControlCenterService.toggleMicMute()
                            }

                            // Caffeine / Desvelo (Inhibir suspensión hypridle)
                            QuickIconButton {
                                id: btnCaffeine
                                icon: ControlCenterService.isCaffeineActive ? "󰅶" : "󰛊"
                                active: ControlCenterService.isCaffeineActive
                                focused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 3
                                onClicked: ControlCenterService.toggleCaffeine()
                            }

                            // Selector de Color / Gotero (hyprpicker)
                            QuickIconButton {
                                id: btnColorPicker
                                icon: "󰈊"
                                active: false
                                focused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 4
                                onClicked: ControlCenterService.pickColor()
                            }

                            // Captura de pantalla de región (hyprshot)
                            QuickIconButton {
                                id: btnRegionShot
                                icon: "󰹑"
                                active: false
                                focused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 5
                                onClicked: ControlCenterService.captureRegion()
                            }
                        }

                        // Línea divisoria fina
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.dividerColor
                        }

                        // 3. Controles Deslizantes (Volumen y Brillo)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            // Slider de Volumen
                            SliderControl {
                                id: sliderVol
                                focused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 6
                                icon: AudioService.icon
                                value: AudioService.currentPercent
                                isMuted: AudioService.isMuted
                                accentColor: Theme.wsActiveColor
                                minValue: 0
                                maxValue: 100
                                step: 5
                                onValueChangedByUser: pct => AudioService.setVolume(pct)
                                onIconClicked: AudioService.toggleMute()
                            }

                            // Slider de Brillo Contextual (regula automáticamente la pantalla donde se encuentra este panel)
                            SliderControl {
                                id: sliderBri
                                focused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 7
                                icon: BrightnessService.getIcon(root.monitorName)
                                value: BrightnessService.getBrightness(root.monitorName)
                                isMuted: false
                                accentColor: Theme.wsActiveColor
                                minValue: 5
                                maxValue: 100
                                step: 5
                                onValueChangedByUser: pct => BrightnessService.setBrightness(pct, root.monitorName)
                                onIconClicked: {
                                    let cur = BrightnessService.getBrightness(root.monitorName);
                                    BrightnessService.setBrightness(cur > 10 ? 10 : 100, root.monitorName);
                                }
                            }
                        }

                        // Línea divisoria fina
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.dividerColor
                        }

                        // 4. Selector Segmentado de Perfiles de Energía
                        PowerProfileSegmentedControl {
                            id: powerProfiles
                            Layout.fillWidth: true
                            focused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 8
                        }

                        // Línea divisoria fina
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.dividerColor
                        }

                        // 5. Fila de Utilidades (Batería compacta, Configuración, Bloqueo y Menú de Apagado)
                        BatteryCard {
                            id: batCard
                            Layout.fillWidth: true
                            settingsFocused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 9
                            lockFocused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 10
                            powerFocused: root.currentView === 0 && root.isKeyNavActive && root.focusedIndex === 11
                            onSettingsClicked: {
                                root.currentView = 4;
                                Qt.callLater(() => mainCard.forceActiveFocus());
                            }
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
                    scale: root.currentView === 1 ? 1.0 : 0.98
                    visible: opacity > 0.01

                    onBackRequested: {
                        root.currentView = 0;
                        Qt.callLater(() => mainCard.forceActiveFocus());
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on x {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
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
                    scale: root.currentView === 2 ? 1.0 : 0.98
                    visible: opacity > 0.01

                    onBackRequested: {
                        root.currentView = 0;
                        Qt.callLater(() => mainCard.forceActiveFocus());
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on x {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                }

                // ==========================================
                // VISTA 3: Detalle de Audio (Salida y Entrada)
                // ==========================================
                AudioDetailView {
                    id: audioView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top

                    opacity: root.currentView === 3 ? 1.0 : 0.0
                    x: root.currentView === 3 ? 0 : 20
                    scale: root.currentView === 3 ? 1.0 : 0.98
                    visible: opacity > 0.01

                    onBackRequested: {
                        root.currentView = 4;
                        Qt.callLater(() => mainCard.forceActiveFocus());
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on x {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                }

                // ==========================================
                // VISTA 4: Hub de Configuración
                // ==========================================
                SettingsView {
                    id: settingsView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top

                    opacity: root.currentView === 4 ? 1.0 : 0.0
                    x: root.currentView === 4 ? 0 : 20
                    scale: root.currentView === 4 ? 1.0 : 0.98
                    visible: opacity > 0.01

                    onBackRequested: {
                        root.currentView = 0;
                        Qt.callLater(() => mainCard.forceActiveFocus());
                    }

                    onSoundRequested: {
                        root.currentView = 3;
                        Qt.callLater(() => mainCard.forceActiveFocus());
                    }

                    onWallpaperRequested: {
                        root.currentView = 5;
                        Qt.callLater(() => mainCard.forceActiveFocus());
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on x {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                }

                // ==========================================
                // VISTA 5: Galería y Selección de Wallpaper
                // ==========================================
                WallpaperDetailView {
                    id: wallpaperView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top

                    opacity: root.currentView === 5 ? 1.0 : 0.0
                    x: root.currentView === 5 ? 0 : 20
                    scale: root.currentView === 5 ? 1.0 : 0.98
                    visible: opacity > 0.01

                    onBackRequested: {
                        root.currentView = 4;
                        Qt.callLater(() => mainCard.forceActiveFocus());
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on x {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
