import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

Item {
    id: root

    implicitWidth: 280
    implicitHeight: 32
    Layout.fillWidth: true

    // =========================================================================
    // CAPA A: Estado Normal (Batería + Bloqueo + Botón de Energía)
    // =========================================================================
    Item {
        id: normalLayer
        anchors.fill: parent
        visible: opacity > 0.01
        opacity: !ControlCenterService.isPowerMenuOpen ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animFast }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 8

            // Píldora compacta de Batería (32px de alto)
            Rectangle {
                id: batChip
                implicitHeight: 32
                implicitWidth: batLayout.implicitWidth + 18
                radius: 8
                color: batMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase
                border.width: 0

                scale: batMouse.pressed ? 0.95 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: Theme.animFast }
                }
                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }

                RowLayout {
                    id: batLayout
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: BatteryService.icon
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: BatteryService.color

                        scale: BatteryService.isCharging ? 1.1 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: Theme.animNormal }
                        }
                    }

                    Text {
                        text: `${BatteryService.percentage}%`
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Theme.text
                    }
                }

                MouseArea {
                    id: batMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                }
            }

            // Espaciador central
            Item {
                Layout.fillWidth: true
            }

            // Botón de Bloqueo de Pantalla (32x32)
            Rectangle {
                id: lockBtn
                implicitWidth: 32
                implicitHeight: 32
                radius: 8
                color: lockMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase
                border.width: 0

                scale: lockMouse.pressed ? 0.92 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: Theme.animFast }
                }
                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰌾"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: lockMouse.containsMouse ? Theme.highlight : Theme.textSecondary

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }

                MouseArea {
                    id: lockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ControlCenterService.lockScreen()
                }
            }

            // Botón de Menú de Energía (32x32)
            Rectangle {
                id: powerBtn
                implicitWidth: 32
                implicitHeight: 32
                radius: 8
                color: powerMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase
                border.width: 0

                scale: powerMouse.pressed ? 0.92 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: Theme.animFast }
                }
                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰐥"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: powerMouse.containsMouse ? Theme.critical : Theme.textSecondary

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ControlCenterService.togglePowerMenu()
                }
            }
        }
    }

    // =========================================================================
    // CAPA B: Transición In-Place (Reemplazo en los mismos 32px sin cambio de altura)
    // =========================================================================
    Item {
        id: powerLayer
        anchors.fill: parent
        visible: opacity > 0.01
        opacity: ControlCenterService.isPowerMenuOpen ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animFast }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 8

            // Botón Volver (‹)
            Rectangle {
                id: backBtn
                implicitWidth: 32
                implicitHeight: 32
                radius: 8
                color: backMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase
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
                    onClicked: ControlCenterService.togglePowerMenu()
                }
            }

            // Espaciador central con etiqueta indicadora sutil en hover
            Item {
                Layout.fillWidth: true
                implicitHeight: 32

                readonly property string hoveredHint: {
                    if (suspMouse.containsMouse) return "Suspender";
                    if (exitMouse.containsMouse) return "Salir";
                    if (rebootMouse.containsMouse) return "Reiniciar";
                    if (shutMouse.containsMouse) return "Apagar";
                    return "";
                }

                Text {
                    anchors.centerIn: parent
                    text: parent.hoveredHint
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.textSecondary
                    opacity: text !== "" ? 0.9 : 0.0

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animFast }
                    }
                }
            }

            // Fila de 4 botones de acción rápida (32x32px, SOLO ICONOS)
            RowLayout {
                spacing: 6

                // 1. Suspender (󰤄)
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 8
                    color: suspMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase
                    border.width: 0
                    scale: suspMouse.pressed ? 0.92 : 1.0

                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰤄"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: suspMouse.containsMouse ? Theme.highlight : Theme.textSecondary

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    MouseArea {
                        id: suspMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ControlCenterService.suspend()
                    }
                }

                // 2. Cerrar Sesión / Salir (󰍃)
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 8
                    color: exitMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase
                    border.width: 0
                    scale: exitMouse.pressed ? 0.92 : 1.0

                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰍃"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: exitMouse.containsMouse ? Theme.warning : Theme.textSecondary

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    MouseArea {
                        id: exitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ControlCenterService.logout()
                    }
                }

                // 3. Reiniciar (󰑐)
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 8
                    color: rebootMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase
                    border.width: 0
                    scale: rebootMouse.pressed ? 0.92 : 1.0

                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: rebootMouse.containsMouse ? Theme.warning : Theme.textSecondary

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    MouseArea {
                        id: rebootMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ControlCenterService.reboot()
                    }
                }

                // 4. Apagar (󰐥)
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 8
                    color: shutMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase
                    border.width: 0
                    scale: shutMouse.pressed ? 0.92 : 1.0

                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰐥"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: shutMouse.containsMouse ? Theme.critical : Theme.textSecondary

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    MouseArea {
                        id: shutMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ControlCenterService.shutdown()
                    }
                }
            }
        }
    }
}
