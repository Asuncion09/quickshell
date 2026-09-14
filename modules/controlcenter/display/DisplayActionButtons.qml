import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 8

    property bool hasPendingChanges: false
    property bool isKeyFocused: false

    signal applyClicked()

    // ==========================================
    // Posicionamiento Relativo (Multimonitor)
    // ==========================================
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 5
        visible: DisplayService.hasMultipleMonitors

        Text {
            text: "ARRANGEMENT"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Theme.textMuted
            Layout.leftMargin: 4
        }

        RowLayout {
            id: relPosRow
            Layout.fillWidth: true
            spacing: 4

            readonly property string otherMonitorName: {
                let mons = DisplayService.monitors;
                if (!mons || mons.length < 2) return "";
                let curIdx = DisplayService.selectedMonitorIndex;
                let otherIdx = (curIdx === 0) ? 1 : 0;
                return mons[otherIdx].name;
            }

            Repeater {
                model: [
                    { id: "left", label: "󰁍 Left" },
                    { id: "right", label: "Right 󰁔" },
                    { id: "up", label: "󰁝 Top" },
                    { id: "down", label: "Bottom 󰁅" },
                    { id: "mirror", label: "󰍺 Mirror" }
                ]

                Rectangle {
                    id: posBtn
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 8
                    color: posMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase
                    border.width: 0

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: posMouse.containsMouse ? Theme.textBright : Theme.textSecondary
                    }

                    MouseArea {
                        id: posMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let curMon = DisplayService.selectedMonitor;
                            if (curMon && relPosRow.otherMonitorName !== "") {
                                DisplayService.setRelativePosition(curMon.name, relPosRow.otherMonitorName, modelData.id);
                            }
                        }
                    }
                }
            }
        }
    }

    // Feedback / Mensaje de estado tras aplicar
    RowLayout {
        Layout.fillWidth: true
        visible: DisplayService.statusMessage !== ""
        spacing: 6
        Layout.alignment: Qt.AlignHCenter

        Text {
            text: "󰄬"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            color: Theme.success
        }

        Text {
            text: DisplayService.statusMessage
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.success
            font.weight: Font.Medium
        }
    }

    // ==========================================
    // Botón de Acción: Aplicar (Reactivo)
    // ==========================================
    Rectangle {
        id: applyBtn
        Layout.fillWidth: true
        Layout.topMargin: 4
        implicitHeight: 40
        radius: 10
        readonly property bool canApply: root.hasPendingChanges

        color: {
            if (canApply) {
                return root.isKeyFocused ? Qt.lighter(Theme.highlight, 1.15) : (applyMouse.containsMouse ? Qt.lighter(Theme.highlight, 1.08) : Theme.highlight);
            } else {
                return root.isKeyFocused ? Theme.surfaceKeyFocus : (applyMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase);
            }
        }

        border.width: root.isKeyFocused ? 1.5 : (canApply ? 0 : 1)
        border.color: root.isKeyFocused ? Theme.highlight : Theme.borderDark
        opacity: canApply ? 1.0 : 0.65

        scale: (canApply && applyMouse.pressed) ? 0.98 : 1.0
        Behavior on scale { NumberAnimation { duration: Theme.animFast } }
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "󰄬"
                font.family: Theme.fontFamily
                font.pixelSize: 14
                color: applyBtn.canApply ? Theme.textOnAccent : Theme.textMuted
            }

            Text {
                text: applyBtn.canApply ? "Apply Display Settings" : "Display Settings Up to Date"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: applyBtn.canApply ? Font.Bold : Font.Medium
                color: applyBtn.canApply ? Theme.textOnAccent : Theme.textMuted
            }
        }

        MouseArea {
            id: applyMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: applyBtn.canApply ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (applyBtn.canApply) {
                    root.applyClicked();
                }
            }
        }
    }
}
