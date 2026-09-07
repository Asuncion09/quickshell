import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../services"

PopupWindow {
    id: root

    property alias targetItem: root.anchor.item

    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 2
    anchor.margins.right: -6
    color: "transparent"
    visible: false
    grabFocus: true

    property bool _isOpen: false

    property int currentView: 0 // 0 = Principal, 1 = Wi-Fi, 2 = Bluetooth

    Timer {
        id: closeTimer
        interval: Theme.animNormal
        onTriggered: {
            if (!root._isOpen) {
                root.visible = false;
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
        root.visible = true;
        root._isOpen = true;
    }

    function close() {
        root._isOpen = false;
        closeTimer.restart();
        if (ControlCenterService.isOpen) ControlCenterService.close();
    }

    onVisibleChanged: {
        if (!visible) {
            root._isOpen = false;
            root.currentView = 0;
            if (ControlCenterService.isOpen) ControlCenterService.close();
        } else {
            root._isOpen = true;
            if (ControlCenterService.hasPasskeyPrompt) {
                root.currentView = 2;
            }
            if (!ControlCenterService.isOpen) {
                ControlCenterService.open();
            }
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

    // Dimensiones totales incluyendo margen para el difuminado de sombra
    implicitWidth: 300 + 8
    implicitHeight: mainCard.implicitHeight + 14

    Item {
        id: animContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8
        anchors.rightMargin: 0
        anchors.topMargin: 4
        anchors.bottomMargin: 10
        transformOrigin: Item.TopRight

        scale: root._isOpen ? 1.0 : 0.94
        opacity: root._isOpen ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
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
                                icon: ControlCenterService.isDnd ? "󰂛" : "󰂚"
                                title: "No Molestar"
                                subtitle: ControlCenterService.isDnd ? "Silenciado" : "Desactivado"
                                active: ControlCenterService.isDnd
                                hasSubmenu: false
                                onClicked: ControlCenterService.toggleDnd()
                            }

                            // Toggle Micrófono
                            QuickToggle {
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
                                icon: AudioService.icon
                                value: AudioService.currentPercent
                                isMuted: AudioService.isMuted
                                accentColor: Theme.wsActiveColor
                                onValueChangedByUser: pct => AudioService.setVolume(pct)
                                onIconClicked: AudioService.toggleMute()
                            }

                            // Slider de Brillo
                            SliderControl {
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
                            Layout.fillWidth: true
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

                    onBackRequested: root.currentView = 0

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

                    onBackRequested: root.currentView = 0

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
