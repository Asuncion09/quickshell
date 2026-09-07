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
    property bool clickable: false
    signal clicked(var mouse)

    implicitWidth: pillBackground.implicitWidth
    implicitHeight: pillBackground.implicitHeight

    scale: (root.clickable && pillMouse.pressed) ? 0.95 : ((root.clickable && pillMouse.containsMouse) ? 1.03 : 1.0)
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutBack
            easing.overshoot: 1.3
        }
    }

    // 1. Elemento fuente para la sombra (invisible, define la forma redondeada exacta)
    Rectangle {
        id: shadowSource
        anchors.fill: pillBackground
        radius: Theme.pillRadius
        color: "#000000"
        visible: false
    }

    // 2. Sombra suave por hardware (MultiEffect)
    MultiEffect {
        source: shadowSource
        anchors.fill: shadowSource
        visible: Theme.pillShadowEnabled
        shadowEnabled: true
        shadowColor: Theme.pillShadowColor
        shadowOpacity: Theme.pillShadowOpacity
        shadowBlur: Theme.pillShadowBlur
        shadowVerticalOffset: Theme.pillShadowOffsetY
        shadowHorizontalOffset: 0
    }

    // 3. Cápsula visual principal
    Rectangle {
        id: pillBackground

        anchors.fill: parent
        implicitWidth: contentLayout.implicitWidth + (root.paddingHorizontal * 2)
        implicitHeight: Theme.barHeight

        color: (root.clickable && pillMouse.containsMouse) ? Theme.bgDarkAlt : Theme.bgDark
        border.color: Theme.borderDark
        border.width: Theme.pillBorderWidth
        radius: Theme.pillRadius

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
}
