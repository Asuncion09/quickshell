import QtQuick
import QtQuick.Layouts
import "../../theme"

// Cabecera estándar de las vistas de detalle del Centro de Control:
// botón "Volver" (navIndex 0) + título + contenido opcional a la derecha.
RowLayout {
    id: root
    Layout.fillWidth: true
    implicitHeight: 32
    spacing: 8

    property string title: ""
    property bool backFocused: false
    signal backRequested()

    // Permite inyectar controles a la derecha (recargar, switch, contadores, etc.)
    default property alias rightContent: rightSlot.data

    // Botón Volver (circular, transparente en reposo, chevron vector)
    Rectangle {
        id: backBtn
        implicitWidth: 28
        implicitHeight: 28
        radius: 14
        readonly property bool isKeyFocused: root.backFocused
        color: isKeyFocused ? Theme.surfaceKeyFocus : (backMouse.containsMouse ? Theme.surfaceHover : "transparent")
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
            onClicked: root.backRequested()
        }
    }

    // Título de la vista
    Text {
        text: root.title
        font.family: Theme.fontFamily
        font.pixelSize: 14
        font.weight: Font.DemiBold
        color: Theme.text
        Layout.alignment: Qt.AlignVCenter
    }

    // Espaciador flexible
    Item { Layout.fillWidth: true }

    // Contenedor del contenido derecho (inyectado por cada vista)
    RowLayout {
        id: rightSlot
        spacing: 8
        Layout.alignment: Qt.AlignVCenter
    }
}
