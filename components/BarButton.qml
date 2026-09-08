import QtQuick
import "../theme"

Rectangle {
    id: root

    signal clicked()
    signal rightClicked()

    property alias text: label.text
    property alias textColor: label.color
    property alias font: label.font
    property alias pixelSize: label.font.pixelSize
    property alias fontWeight: label.font.weight

    property color defaultTextColor: Theme.text
    property color hoverTextColor: Theme.highlight
    property color defaultBgColor: "transparent"
    property color hoverBgColor: Theme.hoverBg

    property string tooltipText: ""
    property bool isHovered: mouseArea.containsMouse

    implicitWidth: label.implicitWidth + 12
    implicitHeight: 26
    radius: 6

    color: mouseArea.containsMouse ? hoverBgColor : defaultBgColor
    Behavior on color {
        ColorAnimation { duration: Theme.animNormal }
    }

    scale: mouseArea.pressed ? 0.88 : (mouseArea.containsMouse ? 1.05 : 1.0)
    opacity: mouseArea.pressed ? 0.82 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutBack
            easing.overshoot: 1.4
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: Theme.animFast }
    }

    Text {
        id: label
        anchors.centerIn: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: mouseArea.containsMouse ? root.hoverTextColor : root.defaultTextColor
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        Behavior on color {
            ColorAnimation { duration: Theme.animNormal }
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
                root.clicked();
            } else if (mouse.button === Qt.RightButton) {
                root.rightClicked();
            }
        }
    }

    // Tooltip integrado en QML con el tema de Quickshell
    BarToolTip {
        id: barTooltip
        targetItem: root
        text: root.tooltipText
        hovered: mouseArea.containsMouse
    }
}

