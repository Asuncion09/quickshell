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

    readonly property bool isHovered: mainMouse.containsMouse

    // Solo animación táctil al hacer click (presionar), sin elevarse ni saltar en hover
    scale: mainMouse.pressed ? 0.97 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutQuad
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
                    color: root.active ? "#414d61" : "#353535"
                    opacity: mainMouse.isOverArrow ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animFast }
                    }
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
                    color: mainMouse.isOverArrow ? Theme.highlight : (root.active ? "#9bbdff" : Theme.textMuted)
                    opacity: root.active ? 0.95 : 0.55

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }
            }
        }

        // MouseArea unificado para todo el botón (con desvanecimiento seguro al salir)
        MouseArea {
            id: mainMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            // Solo es true SI contiene el ratón Y además está sobre las coordenadas de la flecha
            readonly property bool isOverArrow: root.hasSubmenu && mainMouse.containsMouse && (mouseX >= (cardBg.width - 34))

            onClicked: mouse => {
                if (isOverArrow) {
                    root.submenuClicked();
                } else {
                    root.clicked();
                }
            }
        }
    }
}
