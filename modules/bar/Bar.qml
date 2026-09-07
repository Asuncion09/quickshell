import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../theme"
import "../../components"
import "../launcher"
import "../workspaces"
import "../center"
import "../tray"
import "../hardware"
import "../taskbar"
import "../controlcenter"
import "../../services"

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    // Anclaje al borde superior completo (fijo y constante: no cambia nunca)
    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: Theme.barMarginTop
        bottom: Theme.barMarginBottom
        left: Theme.barMarginLeft
        right: Theme.barMarginRight
    }

    // Altura del lienzo fija a 460px:
    // Al ser constante, Wayland jamás reconfigura el buffer, eliminando cualquier parpadeo
    // y manteniendo el exclusiveZone intacto (las ventanas de Hyprland JAMÁS se mueven).
    implicitHeight: root.screen ? root.screen.height : 1080
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: Theme.barHeight
    WlrLayershell.keyboardFocus: (LauncherService.isOpen || ControlCenterService.isOpen) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Máscara de clics por hardware:
    // Cerrado: Solo las 5 cápsulas físicas reciben clics (100% permeable al escritorio).
    // Abierto: Se expande a pantalla completa para capturar cualquier clic exterior y cerrar el lanzador o el centro de control.
    mask: Region {
        Region {
            x: 0
            y: 0
            width: (LauncherService.isOpen || ControlCenterService.isOpen) ? (root.screen ? root.screen.width : 1920) : 0
            height: (LauncherService.isOpen || ControlCenterService.isOpen) ? (root.screen ? root.screen.height : 1080) : 0
        }
        Region { item: leftPill }
        Region { item: taskbarPill }
        Region { item: centerPill }
        Region { item: trayPill }
        Region { item: hardwarePill }
    }

    // Cierra automáticamente el lanzador o centro de control si el usuario cambia de ventana activa o de workspace en Hyprland
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event) return;
            let n = event.name;
            if (n === "activewindow" || n === "activewindowv2" || n === "workspace") {
                if (LauncherService.isOpen) LauncherService.close();
                if (ControlCenterService.isOpen) ControlCenterService.close();
            }
        }
    }

    // Contenedor horizontal que alinea Izquierda, Centro y Derecha
    Item {
        anchors.fill: parent

        // Área de captura exterior invisible a pantalla completa (activa solo con lanzador o centro de control abierto)
        // z: 90 cubre el fondo y las cápsulas laterales (z: 1), pero queda debajo de centerPill y controlCenter (z: 100).
        MouseArea {
            id: dismissArea
            anchors.fill: parent
            visible: LauncherService.isOpen || ControlCenterService.isOpen
            enabled: LauncherService.isOpen || ControlCenterService.isOpen
            z: 90
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: {
                if (LauncherService.isOpen) {
                    console.log("[Bar] Clic exterior detectado -> cerrando lanzador");
                    LauncherService.close();
                }
                if (ControlCenterService.isOpen) {
                    console.log("[Bar] Clic exterior detectado -> cerrando centro de control");
                    ControlCenterService.close();
                }
            }
        }

        // SECCIÓN IZQUIERDA: .modules-left (Launcher + Workspaces)
        RowLayout {
            anchors.left: parent.left
            anchors.top: parent.top
            spacing: 8
            z: 1

            Pill {
                id: leftPill
                spacing: 6

                LauncherModule {
                    id: launcher
                }

                WorkspacesModule {
                    id: workspaces
                }
            }

            // Cápsula #taskbar (Dock de Ventanas Abiertas con salto a Workspace)
            Pill {
                id: taskbarPill
                visible: taskbar.hasWindows
                paddingHorizontal: 6

                TaskbarModule {
                    id: taskbar
                }
            }
        }

        // SECCIÓN CENTRAL: .modules-center (Isla Dinámica: Reloj / Reproductor Multimedia / Lanzador Metamorfoseado)
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            z: 100

            Pill {
                id: centerPill
                paddingHorizontal: LauncherService.isOpen ? 6 : Theme.centerPillPaddingHorizontal

                CenterIslandModule {
                    id: centerIsland
                }
            }
        }

        // SECCIÓN DERECHA: .modules-right (Tray + Sistema/Hardware)
        RowLayout {
            id: rightLayout
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 8
            z: 1

            // Cápsula #tray (Solo iconos de la bandeja del sistema)
            // Se auto-oculta limpiamente si no hay aplicaciones activas en la bandeja
            Pill {
                id: trayPill
                visible: tray.hasItems
                spacing: 8

                TrayModule {
                    id: tray
                }
            }

            // Cápsula #hardware (Bluetooth + Red + Batería)
            Pill {
                id: hardwarePill
                spacing: 6
                paddingHorizontal: 8
                clickable: true
                tooltipText: "Centro de Control"
                onClicked: controlCenter.toggle()

                BluetoothModule {
                    id: bluetooth
                }

                NetworkModule {
                    id: network
                }

                VolumeModule {
                    id: volume
                }

                BatteryModule {
                    id: battery
                }
            }
        }

        // Centro de Control Flotante integrado en la misma superficie
        ControlCenter {
            id: controlCenter
            anchors.top: rightLayout.bottom
            anchors.topMargin: 4
            anchors.right: parent.right
            anchors.rightMargin: 0
            z: 100
        }
    }
}
