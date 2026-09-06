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

    implicitWidth: pillBackground.implicitWidth
    implicitHeight: pillBackground.implicitHeight

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

        color: Theme.bgDark
        border.color: Theme.borderDark
        border.width: Theme.pillBorderWidth
        radius: Theme.pillRadius

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
}
