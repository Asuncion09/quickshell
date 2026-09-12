import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../theme"
import "../../components"
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
        left: 0
        right: 0
    }

    // Altura del lienzo fija a 460px:
    // Al ser constante, Wayland jamás reconfigura el buffer, eliminando cualquier parpadeo
    // y manteniendo el exclusiveZone intacto (las ventanas de Hyprland JAMÁS se mueven).
    implicitHeight: root.screen ? root.screen.height : 1080
    color: "transparent"

    readonly property bool isFocusedMonitor: {
        let screensCount = (Hyprland.monitors && Hyprland.monitors.values && Hyprland.monitors.values.length > 0)
            ? Hyprland.monitors.values.length : (Quickshell.screens ? Quickshell.screens.length : 1);
        if (screensCount <= 1) return true;
        if (!root.screen) return true;

        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) {
            return Hyprland.focusedMonitor.name === root.screen.name;
        }

        if (Hyprland.monitors && Hyprland.monitors.values) {
            for (let i = 0; i < Hyprland.monitors.values.length; i++) {
                let m = Hyprland.monitors.values[i];
                if (m && m.focused && m.name) {
                    return m.name === root.screen.name;
                }
            }
        }

        if (Hyprland.focusedWorkspace) {
            if (Hyprland.focusedWorkspace.monitor && Hyprland.focusedWorkspace.monitor.name) {
                return Hyprland.focusedWorkspace.monitor.name === root.screen.name;
            }
            let wsId = Hyprland.focusedWorkspace.id;
            if (root.screen.name === "HDMI-A-1" && (wsId === 4 || wsId === 5)) return true;
            if (root.screen.name === "eDP-1" && (wsId >= 1 && wsId <= 3)) return true;
        }

        return false;
    }

    // Modal abierto específicamente en este monitor:
    readonly property bool isControlCenterTarget: {
        if (!ControlCenterService.isOpen) return false;
        let target = ControlCenterService.targetMonitor;
        return (target !== "") ? (target === (root.screen ? root.screen.name : "")) : root.isFocusedMonitor;
    }

    readonly property bool isToastTarget: {
        if (!NotificationService.isToastActive) return false;
        let target = NotificationService.targetMonitor;
        return (target !== "") ? (target === (root.screen ? root.screen.name : "")) : root.isFocusedMonitor;
    }

    readonly property bool isIslandModalActive: root.isFocusedMonitor && (PolkitService.isActive || ClipboardService.isOpen || LauncherService.isOpen || NotificationService.isCenterOpen)

    readonly property bool isModalOpen: root.isIslandModalActive || root.isControlCenterTarget

    readonly property bool isDismissActive: root.isModalOpen || (root.isToastTarget && NotificationService.isToastExpanded && !OsdService.isVisible)

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: Theme.barHeight
    WlrLayershell.keyboardFocus: root.isModalOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Máscara de clics por hardware:
    // Cerrado: Solo las 5 cápsulas físicas reciben clics (100% permeable al escritorio).
    // Abierto: Se expande a pantalla completa únicamente en el monitor enfocado para capturar clics exteriores sin bloquear la otra pantalla.
    mask: Region {
        Region {
            x: 0
            y: 0
            width: root.isDismissActive ? (root.screen ? root.screen.width : 1920) : 0
            height: root.isDismissActive ? (root.screen ? root.screen.height : 1080) : 0
        }
        Region { item: leftPill }
        Region { item: taskbarPill }
        Region { item: centerPill }
        Region { item: trayPill }
        Region { item: hardwarePill }
    }

    // Cierra automáticamente el lanzador, centro de control o centro de notificaciones si el usuario cambia de ventana activa, workspace o monitor enfocado
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event) return;
            let n = event.name;
            if (n === "activewindow" || n === "activewindowv2" || n === "workspace") {
                if (ClipboardService.isOpen) ClipboardService.close();
                if (LauncherService.isOpen) LauncherService.close();
                if (ControlCenterService.isOpen) ControlCenterService.close();
                if (NotificationService.isCenterOpen) NotificationService.closeCenter();
                if (NotificationService.isToastExpanded) NotificationService.dismissToast();
            } else if (n === "focusedmon") {
                if (ClipboardService.isOpen) ClipboardService.close();
                if (LauncherService.isOpen) LauncherService.close();
                // No cerramos ControlCenterService aquí para que cruzar el ratón al monitor adyacente no lo cierre accidentalmente
                if (NotificationService.isCenterOpen) NotificationService.closeCenter();
                if (NotificationService.isToastExpanded) NotificationService.dismissToast();
            }
        }
    }

    // Contenedor horizontal que alinea Izquierda, Centro y Derecha
    Item {
        anchors.fill: parent

        // Área de captura exterior invisible a pantalla completa (activa solo con lanzador, centro de control o notificaciones abierto en este monitor)
        // z: 90 cubre el fondo y las cápsulas laterales (z: 1), pero queda debajo de centerPill y controlCenter (z: 100).
        MouseArea {
            id: dismissArea
            anchors.fill: parent
            visible: root.isDismissActive
            enabled: root.isDismissActive
            z: 90
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: {
                if (PolkitService.isActive) {
                    console.log("[Bar] Clic exterior detectado -> cancelando solicitud Polkit");
                    PolkitService.cancel();
                    return;
                }
                if (ClipboardService.isOpen) {
                    console.log("[Bar] Clic exterior detectado -> cerrando portapapeles");
                    ClipboardService.close();
                }
                if (LauncherService.isOpen) {
                    console.log("[Bar] Clic exterior detectado -> cerrando lanzador");
                    LauncherService.close();
                }
                if (ControlCenterService.isOpen) {
                    console.log("[Bar] Clic exterior detectado -> cerrando centro de control");
                    ControlCenterService.close();
                }
                if (NotificationService.isCenterOpen) {
                    console.log("[Bar] Clic exterior detectado -> cerrando centro de notificaciones");
                    NotificationService.closeCenter();
                }
                if (NotificationService.isToastExpanded) {
                    console.log("[Bar] Clic exterior detectado -> cerrando notificación expandida");
                    NotificationService.dismissToast();
                }
            }
        }

        // SECCIÓN IZQUIERDA: .modules-left (Launcher + Workspaces)
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: Theme.barMarginLeft
            anchors.top: parent.top
            spacing: 8
            z: 1

            Pill {
                id: leftPill
                animateSize: false

                WorkspacesModule {
                    id: workspaces
                    monitorName: root.screen ? root.screen.name : ""
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

        // SECCIÓN CENTRAL: .modules-center (Isla Dinámica: Reloj / Reproductor Multimedia / Lanzador / Notificaciones)
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            z: 100

            Pill {
                id: centerPill
                animateSize: false
                paddingHorizontal: (root.isIslandModalActive || (root.isToastTarget && NotificationService.isToastExpanded && !OsdService.isVisible)) ? 6 : ((root.isToastTarget || OsdService.isVisible) ? (centerIsland.isBatteryToast ? 12 : 8) : (centerIsland.isBatteryAlertActive ? 13 : Theme.centerPillPaddingHorizontal))
                customBorderColor: {
                    if (root.isFocusedMonitor && PolkitService.isActive) return PolkitService.isSuccess ? Theme.success : (PolkitService.authFailed ? Theme.critical : Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.4));
                    if (centerIsland.isBatteryToast && root.isToastTarget && !OsdService.isVisible) return Theme.warning;
                    if (centerIsland.isBatteryAlertActive && !OsdService.isVisible) return centerIsland.batteryBorderColor;
                    if (OsdService.isVisible && OsdService.mode === "volume" && OsdService.value > 100 && !OsdService.isMuted) return Qt.rgba(241/255, 196/255, 15/255, 0.45);
                    return null;
                }
                customColor: {
                    if (centerIsland.isBatteryToast && root.isToastTarget && !NotificationService.isToastExpanded && !OsdService.isVisible) return Theme.warning;
                    if (centerIsland.isBatteryAlertDisplaying) return centerIsland.batteryBgColor;
                    return null;
                }
                customBorderWidth: {
                    if (centerIsland.isBatteryToast && root.isToastTarget && !OsdService.isVisible) return 1.0;
                    if (centerIsland.isBatteryAlertActive && !OsdService.isVisible) return centerIsland.batteryBorderWidth;
                    return null;
                }

                CenterIslandModule {
                    id: centerIsland
                    isPillHovered: centerPill.containsMouse
                    isFocusedMonitor: root.isFocusedMonitor
                    monitorName: root.screen ? root.screen.name : ""
                    isToastTarget: root.isToastTarget
                }
            }
        }

        // SECCIÓN DERECHA: .modules-right (Tray + Sistema/Hardware)
        RowLayout {
            id: rightLayout
            anchors.right: parent.right
            anchors.rightMargin: Theme.barMarginRight
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
                onClicked: {
                    ControlCenterService.targetMonitor = root.screen ? root.screen.name : "";
                    controlCenter.toggle();
                }

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

                PowerProfileModule {
                    id: powerProfile
                }
            }
        }

        // Centro de Control Flotante integrado en la misma superficie
        ControlCenter {
            id: controlCenter
            anchors.top: rightLayout.bottom
            anchors.topMargin: 3
            anchors.right: parent.right
            anchors.rightMargin: 4
            z: 100
            isFocusedMonitor: root.isFocusedMonitor
            monitorName: root.screen ? root.screen.name : ""
        }
    }
}
