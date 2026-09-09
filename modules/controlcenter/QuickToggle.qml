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
    property bool loading: false

    signal clicked()
    signal submenuClicked()

    implicitWidth: 135
    implicitHeight: 44
    Layout.fillWidth: true

    property bool focused: false

    // Hover unificado: cualquier zona activa hace que ambas partes reaccionen
    readonly property bool isAnyHovered: leftMouse.containsMouse || rightMouse.containsMouse
    property bool wasHovered: false
    onIsAnyHoveredChanged: {
        if (isAnyHovered) wasHovered = true;
        else Qt.callLater(() => { wasHovered = false; });
    }

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
        clip: true

        border.width: root.focused ? 1.5 : 0
        border.color: root.active ? Qt.rgba(1, 1, 1, 0.90) : Theme.highlight

        color: {
            if (root.active) {
                return (root.isAnyHovered || root.focused) ? Qt.lighter(Theme.wsActiveColor, 1.08) : Theme.wsActiveColor;
            }
            if (root.focused) return "#2c2c2c";
            if (root.isAnyHovered) return Theme.surfaceHover;
            return Theme.surfaceBase;
        }

        Behavior on border.width {
            NumberAnimation { duration: 40 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 40 }
        }
        Behavior on color {
            ColorAnimation { duration: (root.isAnyHovered || root.wasHovered) ? Theme.animFast : 40 }
        }

        // -------------------------------------------------------
        // ZONA IZQUIERDA: Icono + Título + Spinner cargando (acción: toggle)
        // -------------------------------------------------------
        Item {
            id: leftZone
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            // Si hay submenú, la zona derecha toma 34px; si no, ocupa todo
            anchors.right: root.hasSubmenu ? divider.left : parent.right

            RowLayout {
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
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on color {
                        ColorAnimation { duration: (root.isAnyHovered || root.wasHovered) ? Theme.animFast : 40 }
                    }
                }

                Text {
                    id: titleText
                    text: root.title
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: root.active ? "#161616" : Theme.text
                    elide: Text.ElideRight
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on color {
                        ColorAnimation { duration: (root.isAnyHovered || root.wasHovered) ? Theme.animFast : 40 }
                    }
                }

                Text {
                    id: loadingIcon
                    visible: root.loading
                    text: "󰑐"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: root.active ? "#161616" : Theme.wsActiveColor
                    Layout.alignment: Qt.AlignVCenter

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: root.loading
                    }
                }

                Item {
                    Layout.fillWidth: true
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
            anchors.topMargin: root.focused ? 1.5 : 0
            anchors.bottomMargin: root.focused ? 1.5 : 0

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
                    NumberAnimation { duration: (root.isAnyHovered || root.wasHovered) ? Theme.animFast : 40; easing.type: Easing.OutQuad }
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
                    ColorAnimation { duration: (root.isAnyHovered || root.wasHovered) ? Theme.animFast : 40 }
                }
                Behavior on opacity {
                    NumberAnimation { duration: (root.isAnyHovered || root.wasHovered) ? Theme.animFast : 40 }
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
