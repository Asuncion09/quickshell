import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"

RowLayout {
    id: root
    Layout.fillWidth: true
    spacing: 6
    visible: DisplayService.hasMultipleMonitors

    Repeater {
        model: DisplayService.monitors

        Rectangle {
            id: monPill
            required property var modelData
            required property int index
            readonly property bool isSelected: DisplayService.selectedMonitorIndex === index

            implicitHeight: 32
            Layout.fillWidth: true
            radius: 8
            border.width: 0
            color: isSelected ? Theme.surfaceKeyFocus : (pillMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase)

            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: modelData.name.startsWith("eDP") ? "󰌢" : "󰍹"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: isSelected ? Theme.textBright : Theme.textMuted
                }

                Text {
                    text: modelData.name
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: isSelected ? Font.DemiBold : Font.Normal
                    color: isSelected ? Theme.textBright : Theme.textSecondary
                }
            }

            MouseArea {
                id: pillMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: DisplayService.selectMonitor(index)
            }
        }
    }
}
