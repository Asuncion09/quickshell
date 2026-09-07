import QtQuick
import QtQuick.Effects
import Quickshell
import "../theme"

PopupWindow {
    id: root

    property alias text: label.text
    property alias targetItem: root.anchor.item
    property bool hovered: false

    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 8
    color: "transparent"
    visible: showTimer.shouldShow && text !== ""

    implicitWidth: container.implicitWidth + 16
    implicitHeight: container.implicitHeight + 16

    Timer {
        interval: root.delay

        onTriggered: {
            if (root.hovered && root.text !== "") {
                shouldShow = true;
            }
        }
    }

    onHoveredChanged: {
        if (hovered && text !== "") {
            showTimer.restart();
        } else {
            showTimer.stop();
            showTimer.shouldShow = false;
        }
    }

    onTextChanged: {
        if (text === "") {
            showTimer.stop();
            showTimer.shouldShow = false;
        }
    }

    Item {
        anchors.fill: parent

        // Sombra de profundidad acelerada por hardware
        Rectangle {
            id: shadowShape
            anchors.fill: container
            radius: 6
            color: "#000000"
            visible: false
        }

        MultiEffect {
            source: shadowShape
            anchors.fill: shadowShape
            visible: Theme.pillShadowEnabled
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.5
            shadowBlur: 0.4
            shadowVerticalOffset: 2.5
        }

        // Píldora del tooltip integrada con el tema oscuro
        Rectangle {
            id: container
            anchors.centerIn: parent

            implicitWidth: label.implicitWidth + 18
            implicitHeight: label.implicitHeight + 10

            radius: 6
            color: Theme.bgDark
            border.color: "#393939"
            border.width: 1

            opacity: root.visible ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: Theme.animFast }
            }

            Text {
                id: label
                anchors.centerIn: parent
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                color: Theme.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}

