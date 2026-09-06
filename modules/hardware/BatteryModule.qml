import QtQuick
import "../../theme"
import "../../components"
import "../../services"

Item {
    id: root

    property bool isPinned: false
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property bool isExpanded: isPinned || isHovered || BatteryService.isWarning || BatteryService.isCritical

    // Progreso de animación único y fluido (0.0 -> 1.0)
    property real expandProgress: isExpanded ? 1.0 : 0.0
    Behavior on expandProgress {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutCubic
        }
    }

    // Ancho base del slot: 22px en batería normal, 28px al cargar para alojar el icono compuesto [⚡ 🔋]
    readonly property int collapsedWidth: BatteryService.isCharging ? 28 : 22
    readonly property int expandedWidth: Math.round(collapsedWidth + 4 + textItem.width)

    implicitWidth: Math.round(collapsedWidth + (expandedWidth - collapsedWidth) * expandProgress)
    implicitHeight: 26

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutCubic
        }
    }

    // Color reactivo: verde esmeralda al cargar, warning/crítico al bajar, y highlight en hover sin fondo
    readonly property color activeColor: isHovered ? Theme.highlight : (BatteryService.isCharging ? Theme.success : BatteryService.color)

    // Animación suave de pulsación solo en estado crítico (<15%)
    SequentialAnimation on opacity {
        running: BatteryService.isCritical
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation {
            to: 0.35
            duration: 500
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            to: 1.0
            duration: 500
            easing.type: Easing.InOutQuad
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: Math.round(4 * root.expandProgress)

        // --- ÍCONO COMPUESTO: [ RAYO + BATERÍA HORIZONTAL QML ] ---
        Row {
            id: iconRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2.5

            // Rayo de carga que aparece solo al conectar el cargador
            Item {
                id: boltContainer
                visible: BatteryService.isCharging
                width: 8
                height: 26
                anchors.verticalCenter: parent.verticalCenter
                opacity: BatteryService.isCharging ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animFast }
                }

                Text {
                    id: boltText
                    anchors.centerIn: parent
                    text: "󱐋"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: root.activeColor

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }
            }

            // Batería horizontal 100% en QML con trazo fino y proporción equilibrada
            Item {
                id: horizBattery
                width: 15
                height: 9.5
                anchors.verticalCenter: parent.verticalCenter

                // Cuerpo principal de la batería
                Rectangle {
                    id: batBody
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 13
                    height: 9.5
                    radius: 2
                    color: "transparent"
                    border.width: 1.0
                    border.color: root.activeColor

                    Behavior on border.color {
                        ColorAnimation { duration: Theme.animFast }
                    }

                    // Nivel interior de llenado continuo con margen de aire para conservar la silueta
                    Rectangle {
                        id: batFill
                        anchors.left: parent.left
                        anchors.leftMargin: 1.5
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height - 3
                        // Ancho útil interior: 13 - 3 = 10 px
                        width: Math.max(1, Math.min(Math.round(9.5 * (BatteryService.percentage / 100)), 9.5))
                        radius: 1
                        color: root.activeColor

                        Behavior on width {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutQuad
                            }
                        }
                        Behavior on color {
                            ColorAnimation { duration: Theme.animFast }
                        }
                    }
                }

                // Borne / Polo positivo exterior a la derecha
                Rectangle {
                    anchors.left: batBody.right
                    anchors.leftMargin: 0.8
                    anchors.verticalCenter: batBody.verticalCenter
                    width: 1.2
                    height: 4
                    radius: 0.6
                    color: root.activeColor

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }
            }
        }

        // --- CONTENEDOR DE PORCENTAJE EXPANDIBLE ---
        Item {
            id: textContainer
            width: Math.round(textItem.width * root.expandProgress)
            height: textItem.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            opacity: root.expandProgress

            Text {
                id: textItem
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: BatteryService.percentage + "%"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.SemiBold
                color: root.activeColor
                width: implicitWidth

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                root.isPinned = !root.isPinned;
            }
        }
    }

    BarToolTip {
        id: barTooltip
        targetItem: root
        text: BatteryService.tooltipText
        hovered: mouseArea.containsMouse && !root.isPinned
    }
}
