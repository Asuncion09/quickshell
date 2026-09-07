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
    implicitHeight: 48
    Layout.fillWidth: true

    readonly property bool isHovered: mouseArea.containsMouse || (root.hasSubmenu && arrowMouse.containsMouse)

    scale: (mouseArea.pressed || (root.hasSubmenu && arrowMouse.pressed)) ? 0.97 : (root.isHovered ? 1.015 : 1.0)
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }

    Rectangle {
        id: cardBg
        anchors.fill: parent
        radius: 10
        border.width: 0

        color: root.active
               ? (root.isHovered ? "#2e333d" : "#252830")
               : (root.isHovered ? "#272727" : "#1e1e1e")

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 6
            spacing: 10

            // Icono limpio directo sobre el fondo (sin caja anidada)
            Text {
                text: root.icon
                font.family: Theme.fontFamily
                font.pixelSize: 18
                color: root.active ? Theme.highlight : Theme.textSecondary
                Layout.alignment: Qt.AlignVCenter

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
            }

            // Etiquetas (Título + Subtítulo)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.text
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.subtitle
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: root.active ? "#9bbdff" : Theme.textMuted
                    elide: Text.ElideRight

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }
            }

            // Botón opcional de submenú (flecha) con micro-cápsula interactiva
            Item {
                id: arrowContainer
                implicitWidth: 26
                implicitHeight: 34
                visible: root.hasSubmenu
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 2

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: arrowMouse.containsMouse ? (root.active ? "#384152" : "#323232") : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    font.family: Theme.fontFamily
                    font.pixelSize: 17
                    font.weight: Font.Bold
                    color: arrowMouse.containsMouse ? Theme.highlight : Theme.textMuted
                    opacity: root.active ? 0.95 : 0.55
                }

                MouseArea {
                    id: arrowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.submenuClicked()
                }
            }
        }

        // Clic general sobre el toggle principal
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            anchors.rightMargin: root.hasSubmenu ? 30 : 0
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
