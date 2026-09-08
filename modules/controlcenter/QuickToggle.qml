import QtQuick
import QtQuick.Layouts
import "../../theme"

Item {
    id: root

    property string icon: "󰖩"
    property string title: "Toggle"
    property string subtitle: "Estado"
    property bool active: false
    property bool hasSubmenu: false

    signal clicked()
    signal submenuClicked()

    implicitWidth: 135
    implicitHeight: 44
    Layout.fillWidth: true

    property bool focused: false

    // Hover unificado: cualquier zona activa hace que ambas partes reaccionen
    readonly property bool isAnyHovered: leftMouse.containsMouse || rightMouse.containsMouse

    // Animación táctil al presionar (escala leve)
    scale: (leftMouse.pressed || rightMouse.pressed) ? 0.97 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutQuad
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        border.width: 0
        clip: true

        color: root.active
               ? ((root.isAnyHovered || root.focused) ? Qt.lighter(Theme.wsActiveColor, 1.08) : Theme.wsActiveColor)
               : ((root.isAnyHovered || root.focused) ? Theme.surfaceHover : Theme.surfaceBase)

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        // -------------------------------------------------------
        // ZONA IZQUIERDA: Icono + Título (acción: toggle)
        // -------------------------------------------------------
        Item {
            id: leftZone
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            // Si hay submenú, la zona derecha toma 34px; si no, ocupa todo
            anchors.right: root.hasSubmenu ? divider.left : parent.right

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 6
                spacing: 7

                Text {
                    id: iconText
                    text: root.icon
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    color: root.active ? "#161616" : ((root.isAnyHovered || root.focused) ? Theme.text : Theme.textSecondary)
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }

                Text {
                    id: titleText
                    width: parent.width - iconText.width - parent.spacing
                    text: root.title
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: root.active ? "#161616" : Theme.text
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }
            }

            MouseArea {
                id: leftMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clicked()
            }
        }

        // -------------------------------------------------------
        // DIVISOR VERTICAL (solo visible cuando hasSubmenu)
        // -------------------------------------------------------
        Rectangle {
            id: divider
            visible: root.hasSubmenu
            width: 1
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: rightZone.left

            color: root.active
                   ? Qt.rgba(0, 0, 0, 0.18)
                   : Qt.rgba(1, 1, 1, 0.08)

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }

        // -------------------------------------------------------
        // ZONA DERECHA: Flecha › (acción: abrir submenú)
        // -------------------------------------------------------
        Item {
            id: rightZone
            visible: root.hasSubmenu
            width: 34
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Text {
                id: arrowText
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: (rightMouse.containsMouse || root.focused) ? 1.5 : 0
                text: "󰅂"
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.weight: Font.DemiBold

                Behavior on anchors.horizontalCenterOffset {
                    NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad }
                }

                scale: rightMouse.pressed ? 0.88 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: Theme.animFast }
                }

                color: {
                    if (root.active) return "#161616";
                    return (root.isAnyHovered || root.focused) ? Theme.text : Theme.textMuted;
                }
                opacity: root.active ? 0.85 : ((root.isAnyHovered || root.focused) ? 0.90 : 0.45)

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.animFast }
                }
            }

            MouseArea {
                id: rightMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.submenuClicked()
            }
        }
    }
}
