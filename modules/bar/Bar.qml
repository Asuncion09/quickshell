import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../components"
import "../launcher"
import "../workspaces"
import "../center"
import "../tray"
import "../hardware"
import "../taskbar"

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    // Anclaje al borde superior completo
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

    // Altura ampliada ligeramente para dar espacio transparente al difuminado de la sombra sin recortarlo
    implicitHeight: Theme.barHeight + 8
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: Theme.barHeight

    // Contenedor horizontal que alinea Izquierda, Centro y Derecha
    Item {
        anchors.fill: parent

        // SECCIÓN IZQUIERDA: .modules-left (Launcher + Workspaces)
        RowLayout {
            anchors.left: parent.left
            anchors.top: parent.top
            spacing: 8

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

            // Cápsula #taskbar (Dock de Apps Abiertas en el Workspace Activo)
            Pill {
                id: taskbarPill
                visible: taskbar.hasWindows
                paddingHorizontal: 6

                TaskbarModule {
                    id: taskbar
                }
            }
        }

        // SECCIÓN CENTRAL: .modules-center (Isla Dinámica: Reloj / Reproductor Multimedia)
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

            Pill {
                id: centerPill
                paddingHorizontal: Theme.centerPillPaddingHorizontal

                CenterIslandModule {
                    id: centerIsland
                }
            }
        }

        // SECCIÓN DERECHA: .modules-right (Tray + Sistema/Hardware)
        RowLayout {
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 8

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
                spacing: 4

                BluetoothModule {
                    id: bluetooth
                }

                NetworkModule {
                    id: network
                }

                BatteryModule {
                    id: battery
                }
            }
        }
    }
}
