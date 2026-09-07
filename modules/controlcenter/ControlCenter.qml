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
    color: "transparent"
    visible: false
    grabFocus: true

    function toggle() {
        root.visible = !root.visible;
    }

    function open() {
        root.visible = true;
    }

    function close() {
        root.visible = false;
    }

    onVisibleChanged: {
        if (!visible && ControlCenterService.isOpen) {
            ControlCenterService.close();
        } else if (visible && !ControlCenterService.isOpen) {
            ControlCenterService.open();
        }
    }

    Connections {
        target: ControlCenterService
        function onIsOpenChanged() {
            if (root.visible !== ControlCenterService.isOpen) {
                root.visible = ControlCenterService.isOpen;
            }
        }
    }

    // Dimensiones totales incluyendo margen para el difuminado de sombra
    implicitWidth: 300 + 16
    implicitHeight: mainCard.implicitHeight + 14

    // Procesos auxiliares para submenús
    Process {
        id: netGuiProc
        command: ["nmrs-gui"]
    }

    Process {
        id: btGuiProc
        command: ["ghostty", "--class=com.floating.medium", "-e", "bluetui"]
    }

    Item {
        id: animContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 2
        anchors.topMargin: 4
        anchors.bottomMargin: 10
        transformOrigin: Item.TopRight

        scale: root.visible ? 1.0 : 0.94
        opacity: root.visible ? 1.0 : 0.0

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
            radius: 14
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
            implicitHeight: contentColumn.implicitHeight + 22

            radius: 14
            color: Theme.bgDark
            border.color: "#383838"
            border.width: 1

            ColumnLayout {
                id: contentColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 11
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
                        onSubmenuClicked: {
                            if (!netGuiProc.running) netGuiProc.running = true;
                        }
                    }

                    // Toggle Bluetooth
                    QuickToggle {
                        icon: BluetoothService.icon
                        title: "Bluetooth"
                        subtitle: BluetoothService.deviceName
                        active: BluetoothService.isEnabled
                        hasSubmenu: true
                        onClicked: ControlCenterService.toggleBluetooth()
                        onSubmenuClicked: {
                            if (!btGuiProc.running) btGuiProc.running = true;
                        }
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
                    color: "#282828"
                }

                // 2. Controles Deslizantes (Volumen y Brillo)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Slider de Volumen
                    SliderControl {
                        icon: AudioService.icon
                        value: AudioService.currentPercent
                        title: "Volumen"
                        isMuted: AudioService.isMuted
                        accentColor: Theme.highlight
                        onValueChangedByUser: pct => AudioService.setVolume(pct)
                        onIconClicked: AudioService.toggleMute()
                    }

                    // Slider de Brillo
                    SliderControl {
                        icon: BrightnessService.icon
                        value: BrightnessService.brightnessPercent
                        title: "Brillo"
                        isMuted: false
                        accentColor: Theme.warning
                        onValueChangedByUser: pct => BrightnessService.setBrightness(pct)
                        onIconClicked: BrightnessService.setBrightness(BrightnessService.brightnessPercent > 10 ? 10 : 100)
                    }
                }

                // Línea divisoria fina
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#282828"
                }

                // 3. Fila de Utilidades (Batería compacta y Bloqueo de 32px)
                BatteryCard {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
