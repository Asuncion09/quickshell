import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: SessionService.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: -1

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: 0
        bottom: 0
        left: 0
        right: 0
    }

    implicitWidth: modelData ? modelData.width : 1920
    implicitHeight: modelData ? modelData.height : 1080

    color: "transparent"
    visible: SessionService.isOpen || cardWrapper.opacity > 0.01

    // Telón de fondo oscurecido y cinemático
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.50)
        opacity: SessionService.isOpen ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutQuad
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: SessionService.close()
        }
    }

    // Receptor de eventos de teclado
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: SessionService.isOpen

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                SessionService.close();
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                event.accepted = true;
                SessionService.next();
            } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                event.accepted = true;
                SessionService.prev();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                event.accepted = true;
                SessionService.triggerCurrent();
            } else if (event.key === Qt.Key_L) {
                event.accepted = true;
                SessionService.lock();
            } else if (event.key === Qt.Key_S) {
                event.accepted = true;
                SessionService.suspend();
            } else if (event.key === Qt.Key_E) {
                event.accepted = true;
                SessionService.logout();
            } else if (event.key === Qt.Key_R) {
                event.accepted = true;
                SessionService.reboot();
            } else if (event.key === Qt.Key_P) {
                event.accepted = true;
                SessionService.shutdown();
            }
        }
    }

    // Contenedor animado con elevación y sombra
    Item {
        id: cardWrapper
        anchors.centerIn: parent
        width: 480
        height: 94

        scale: SessionService.isOpen ? 1.0 : 0.94
        opacity: SessionService.isOpen ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation { duration: 140; easing.type: Easing.OutQuad }
        }
        Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
        }

        // Sombra suave volumétrica por hardware (coherente con WindowSwitcher y Centro de Control)
        Rectangle {
            id: shadowShape
            anchors.fill: mainCard
            radius: mainCard.radius
            color: "#000000"
            visible: false
        }

        MultiEffect {
            source: shadowShape
            anchors.fill: shadowShape
            visible: Theme.pillShadowEnabled
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.60
            shadowBlur: 0.55
            shadowVerticalOffset: 4
            z: 0
        }

        // Tarjeta principal (estilo nativo de Quickshell)
        Rectangle {
            id: mainCard
            anchors.fill: parent
            radius: 16
            color: Theme.bgDark
            border.color: "#2e2e2e"
            border.width: 1
            z: 1

            // Previene que clics dentro de la tarjeta cierren el menú
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                readonly property var actions: [
                    { name: "Bloquear",  icon: "󰌾", accent: Theme.highlight, callback: () => SessionService.lock() },
                    { name: "Suspender", icon: "󰤄", accent: Theme.highlight, callback: () => SessionService.suspend() },
                    { name: "Salir",     icon: "󰍃", accent: Theme.warning,   callback: () => SessionService.logout() },
                    { name: "Reiniciar", icon: "󰑐", accent: Theme.warning,   callback: () => SessionService.reboot() },
                    { name: "Apagar",    icon: "󰐥", accent: Theme.critical,  callback: () => SessionService.shutdown() }
                ]

                Repeater {
                    model: parent.actions

                    Rectangle {
                        id: itemBtn
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.pillRadius

                        readonly property bool isCurrent: SessionService.focusedIndex === index
                        readonly property bool isHovered: itemMouse.containsMouse
                        readonly property color actionAccent: modelData.accent

                        scale: itemMouse.pressed ? 0.94 : ((isHovered || isCurrent) ? 1.03 : 1.0)
                        color: isCurrent
                               ? "#2c2c2c"
                               : (isHovered ? Theme.surfaceHover : Theme.surfaceBase)

                        border.color: isCurrent
                                      ? (index === 4 ? Theme.critical : (index >= 2 ? Theme.warning : Theme.highlight))
                                      : (isHovered ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
                        border.width: isCurrent ? 1.5 : 1

                        Behavior on scale {
                            NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 110 }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: 110 }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.icon
                                font.family: Theme.fontFamily
                                font.pixelSize: 20
                                color: itemBtn.isCurrent
                                       ? itemBtn.border.color
                                       : (itemBtn.isHovered ? Theme.text : Theme.textSecondary)

                                Behavior on color {
                                    ColorAnimation { duration: 110 }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.name
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: itemBtn.isCurrent ? Font.DemiBold : Font.Normal
                                color: (itemBtn.isCurrent || itemBtn.isHovered) ? Theme.text : Theme.textSecondary

                                Behavior on color {
                                    ColorAnimation { duration: 110 }
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: SessionService.focusedIndex = index
                            onClicked: modelData.callback()
                        }
                    }
                }
            }
        }
    }
}
