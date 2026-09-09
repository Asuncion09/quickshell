import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

Item {
    id: root

    implicitWidth: 280
    implicitHeight: 32
    Layout.fillWidth: true

    property bool lockFocused: false
    property bool powerFocused: false

    property int powerNavIndex: 4 // 0: Volver, 1: Suspender, 2: Salir, 3: Reiniciar, 4: Apagar
    property bool isPowerNavActive: false

    function triggerLock() {
        ControlCenterService.lockScreen();
    }

    function triggerPower() {
        ControlCenterService.togglePowerMenu();
    }

    function nextPowerItem() {
        isPowerNavActive = true;
        powerNavIndex = (powerNavIndex + 1) % 5;
    }

    function prevPowerItem() {
        isPowerNavActive = true;
        powerNavIndex = (powerNavIndex + 4) % 5;
    }

    function triggerPowerCurrent() {
        switch (powerNavIndex) {
            case 0: ControlCenterService.togglePowerMenu(); break;
            case 1: ControlCenterService.suspend(); break;
            case 2: ControlCenterService.logout(); break;
            case 3: ControlCenterService.reboot(); break;
            case 4: ControlCenterService.shutdown(); break;
        }
    }

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
                color: root.lockFocused ? "#2c2c2c" : (lockMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase)
                border.width: root.lockFocused ? 1.5 : 0
                border.color: Theme.highlight

                scale: lockMouse.pressed ? 0.92 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: Theme.animFast }
                }
                Behavior on border.width {
                    NumberAnimation { duration: 40 }
                }
                Behavior on border.color {
                    ColorAnimation { duration: 40 }
                }
                Behavior on color {
                    ColorAnimation { duration: lockMouse.containsMouse ? Theme.animFast : 40 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰌾"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: (lockMouse.containsMouse || root.lockFocused) ? Theme.highlight : Theme.textSecondary

                    Behavior on color {
                        ColorAnimation { duration: lockMouse.containsMouse ? Theme.animFast : 40 }
                    }
                }

                MouseArea {
                    id: lockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.triggerLock()
                }
            }

            // Botón de Menú de Energía (32x32)
            Rectangle {
                id: powerBtn
                implicitWidth: 32
                implicitHeight: 32
                radius: 8
                color: root.powerFocused ? "#2c2c2c" : (powerMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase)
                border.width: root.powerFocused ? 1.5 : 0
                border.color: Theme.critical

                scale: powerMouse.pressed ? 0.92 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: Theme.animFast }
                }
                Behavior on border.width {
                    NumberAnimation { duration: 40 }
                }
                Behavior on border.color {
                    ColorAnimation { duration: 40 }
                }
                Behavior on color {
                    ColorAnimation { duration: powerMouse.containsMouse ? Theme.animFast : 40 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰐥"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: (powerMouse.containsMouse || root.powerFocused) ? Theme.critical : Theme.textSecondary

                    Behavior on color {
                        ColorAnimation { duration: powerMouse.containsMouse ? Theme.animFast : 40 }
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

            // Botón Volver (circular, transparente en reposo, chevron vector)
            Rectangle {
                id: backBtn
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                readonly property bool isKeyFocused: root.isPowerNavActive && root.powerNavIndex === 0
                color: isKeyFocused ? "#2c2c2c" : (backMouse.containsMouse ? Theme.surfaceHover : "transparent")
                border.width: isKeyFocused ? 1.5 : 0
                border.color: Theme.highlight

                scale: backMouse.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on border.width { NumberAnimation { duration: 40 } }
                Behavior on border.color { ColorAnimation { duration: 40 } }
                Behavior on color { ColorAnimation { duration: backMouse.containsMouse ? Theme.animFast : 40 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: (backMouse.containsMouse || backBtn.isKeyFocused) ? Theme.text : Theme.textSecondary

                    Behavior on color { ColorAnimation { duration: backMouse.containsMouse ? Theme.animFast : 40 } }
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ControlCenterService.togglePowerMenu()
                }
            }

            // Espaciador central con etiqueta indicadora sutil en hover o foco de teclado
            Item {
                Layout.fillWidth: true
                implicitHeight: 32

                readonly property string hoveredHint: {
                    if (root.isPowerNavActive) {
                        if (root.powerNavIndex === 0) return "Volver";
                        if (root.powerNavIndex === 1) return "Suspender";
                        if (root.powerNavIndex === 2) return "Salir";
                        if (root.powerNavIndex === 3) return "Reiniciar";
                        if (root.powerNavIndex === 4) return "Apagar";
                    }
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
                    readonly property bool isKeyFocused: root.isPowerNavActive && root.powerNavIndex === 1
                    color: isKeyFocused ? "#2c2c2c" : (suspMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase)
                    border.width: isKeyFocused ? 1.5 : 0
                    border.color: Theme.highlight
                    scale: suspMouse.pressed ? 0.92 : 1.0

                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                    Behavior on border.width { NumberAnimation { duration: 40 } }
                    Behavior on border.color { ColorAnimation { duration: 40 } }
                    Behavior on color { ColorAnimation { duration: suspMouse.containsMouse ? Theme.animFast : 40 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰤄"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: (suspMouse.containsMouse || parent.isKeyFocused) ? Theme.highlight : Theme.textSecondary

                        Behavior on color { ColorAnimation { duration: suspMouse.containsMouse ? Theme.animFast : 40 } }
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
                    readonly property bool isKeyFocused: root.isPowerNavActive && root.powerNavIndex === 2
                    color: isKeyFocused ? "#2c2c2c" : (exitMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase)
                    border.width: isKeyFocused ? 1.5 : 0
                    border.color: Theme.warning
                    scale: exitMouse.pressed ? 0.92 : 1.0

                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                    Behavior on border.width { NumberAnimation { duration: 40 } }
                    Behavior on border.color { ColorAnimation { duration: 40 } }
                    Behavior on color { ColorAnimation { duration: exitMouse.containsMouse ? Theme.animFast : 40 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰍃"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: (exitMouse.containsMouse || parent.isKeyFocused) ? Theme.warning : Theme.textSecondary

                        Behavior on color { ColorAnimation { duration: exitMouse.containsMouse ? Theme.animFast : 40 } }
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
                    readonly property bool isKeyFocused: root.isPowerNavActive && root.powerNavIndex === 3
                    color: isKeyFocused ? "#2c2c2c" : (rebootMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase)
                    border.width: isKeyFocused ? 1.5 : 0
                    border.color: Theme.warning
                    scale: rebootMouse.pressed ? 0.92 : 1.0

                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                    Behavior on border.width { NumberAnimation { duration: 40 } }
                    Behavior on border.color { ColorAnimation { duration: 40 } }
                    Behavior on color { ColorAnimation { duration: rebootMouse.containsMouse ? Theme.animFast : 40 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: (rebootMouse.containsMouse || parent.isKeyFocused) ? Theme.warning : Theme.textSecondary

                        Behavior on color { ColorAnimation { duration: rebootMouse.containsMouse ? Theme.animFast : 40 } }
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
                    readonly property bool isKeyFocused: root.isPowerNavActive && root.powerNavIndex === 4
                    color: isKeyFocused ? "#2c2c2c" : (shutMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase)
                    border.width: isKeyFocused ? 1.5 : 0
                    border.color: Theme.critical
                    scale: shutMouse.pressed ? 0.92 : 1.0

                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                    Behavior on border.width { NumberAnimation { duration: 40 } }
                    Behavior on border.color { ColorAnimation { duration: 40 } }
                    Behavior on color { ColorAnimation { duration: shutMouse.containsMouse ? Theme.animFast : 40 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰐥"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: (shutMouse.containsMouse || parent.isKeyFocused) ? Theme.critical : Theme.textSecondary

                        Behavior on color { ColorAnimation { duration: shutMouse.containsMouse ? Theme.animFast : 40 } }
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
