import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../theme"

Item {
    id: root

    // Permite declarar elementos hijos directamente dentro del Pill
    default property alias content: contentLayout.data
    property alias spacing: contentLayout.spacing
    property int paddingHorizontal: Theme.pillPaddingHorizontal
    property int paddingVertical: Theme.pillPaddingVertical
    property alias borderColor: pillBackground.border.color
    property alias borderWidth: pillBackground.border.width
    property int radius: Theme.pillRadius
    property bool clickable: false
    property string tooltipText: ""
    readonly property bool isHovered: root.clickable && pillMouse.containsMouse
    signal clicked(var mouse)

    property bool animateSize: true

    Behavior on paddingHorizontal {
        NumberAnimation {
            duration: Theme.animNormal
            easing.type: Easing.OutCubic
        }
    }

    implicitWidth: pillBackground.implicitWidth
    implicitHeight: pillBackground.implicitHeight

    // Solo animación táctil al hacer click (presionar), sin alterar el tamaño en hover
    scale: (root.clickable && pillMouse.pressed) ? 0.96 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutQuad
        }
    }

    // Detección de elevación para isla expandida (Centro de Notificaciones o Lanzador)
    readonly property bool isExpanded: pillBackground.height > 60

    // 1. Elemento fuente para la sombra (invisible, define la forma redondeada exacta)
    Rectangle {
        id: shadowSource
        anchors.fill: pillBackground
        radius: root.radius
        color: "#000000"
        visible: false
    }

    // 2. Sombra volumétrica por hardware con elevación dinámica (MultiEffect)
    MultiEffect {
        source: shadowSource
        anchors.fill: shadowSource
        visible: Theme.pillShadowEnabled
        shadowEnabled: true
        shadowColor: Theme.pillShadowColor
        shadowOpacity: root.isExpanded ? 0.85 : Theme.pillShadowOpacity
        shadowBlur: root.isExpanded ? 0.70 : Theme.pillShadowBlur
        shadowVerticalOffset: root.isExpanded ? 8.0 : Theme.pillShadowOffsetY
        shadowHorizontalOffset: 0

        Behavior on shadowOpacity {
            NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutQuad }
        }
        Behavior on shadowBlur {
            NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutQuad }
        }
        Behavior on shadowVerticalOffset {
            NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutQuad }
        }
    }

    // 3. Cápsula visual principal
    Rectangle {
        id: pillBackground

        anchors.fill: parent
        implicitWidth: contentLayout.implicitWidth + (root.paddingHorizontal * 2)
        implicitHeight: Math.max(Theme.barHeight, contentLayout.implicitHeight + (root.paddingVertical * 2))
        clip: true

        // En hover solo cambia suavemente de color sin cambiar de tamaño
        color: (root.clickable && pillMouse.containsMouse) ? Theme.bgDarkAlt : Theme.bgDark
        border.color: root.isExpanded ? Qt.rgba(1, 1, 1, 0.12) : Theme.borderDark
        border.width: Theme.pillBorderWidth
        radius: root.radius

        Behavior on implicitWidth {
            enabled: root.animateSize
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on implicitHeight {
            enabled: root.animateSize
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        Behavior on border.color {
            ColorAnimation { duration: Theme.animFast }
        }

        RowLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.leftMargin: root.paddingHorizontal
            anchors.rightMargin: root.paddingHorizontal
            anchors.topMargin: root.paddingVertical
            anchors.bottomMargin: root.paddingVertical
            spacing: 4
        }
    }

    // Detección universal de hover sobre el 100% de la cápsula física (incluye padding)
    HoverHandler {
        id: pillHoverHandler
    }
    readonly property bool containsMouse: pillHoverHandler.hovered

    // Área interactiva de nivel superior para Pills clickables (sin alterar RowLayout)
    MouseArea {
        id: pillMouse
        anchors.fill: parent
        enabled: root.clickable
        visible: root.clickable
        hoverEnabled: true
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton
        z: 10
        onClicked: mouse => root.clicked(mouse)
    }

    BarToolTip {
        targetItem: root
        text: root.tooltipText
        hovered: root.isHovered && root.tooltipText !== ""
    }
}
