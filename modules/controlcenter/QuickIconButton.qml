import QtQuick
import QtQuick.Layouts
import "../../theme"

Item {
    id: root

    property string icon: "󰍬"
    property string tooltipText: ""
    property bool active: false
    property bool focused: false
    property color customActiveColor: Theme.wsActiveColor
    property color customActiveTextColor: "#161616"

    signal clicked()

    implicitWidth: 68
    implicitHeight: 38
    Layout.fillWidth: true

    readonly property bool isHovered: mouseArea.containsMouse

    scale: mouseArea.pressed ? 0.93 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Easing.OutQuad
        }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: 10
        clip: true

        border.width: root.focused ? 1.5 : 0
        border.color: root.active ? Qt.rgba(1, 1, 1, 0.90) : Theme.highlight

        color: {
            if (root.active) {
                return (root.isHovered || root.focused) ? Qt.lighter(root.customActiveColor, 1.1) : root.customActiveColor;
            }
            if (root.focused) return "#2c2c2c";
            if (root.isHovered) return Theme.surfaceHover;
            return Theme.surfaceBase;
        }

        Behavior on border.width { NumberAnimation { duration: 40 } }
        Behavior on border.color { ColorAnimation { duration: 40 } }
        Behavior on color { ColorAnimation { duration: root.isHovered ? Theme.animFast : 40 } }

        Text {
            anchors.centerIn: parent
            text: root.icon
            font.family: Theme.fontFamily
            font.pixelSize: 16
            font.weight: Font.DemiBold
            color: {
                if (root.active) return root.customActiveTextColor;
                if (root.isHovered || root.focused) return "#ffffff";
                return Theme.textSecondary;
            }

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
