import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

Item {
    id: root

    implicitHeight: 28
    // Ancho calibrado según el modo para evitar jitter o saltos visuales
    implicitWidth: (OsdService.mode === "power") ? 130 : 156

    readonly property real maxRange: 100.0

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 8

        // Icono dinámico OSD
        Text {
            text: OsdService.icon
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            color: OsdService.isMuted ? Theme.critical : (OsdService.mode === "power" ? PowerProfileService.accentColor : Theme.highlight)
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 16

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }

        // Barra de progreso (activa solo para volumen y brillo)
        Rectangle {
            id: barBg
            visible: OsdService.mode !== "mic" && OsdService.mode !== "power"
            implicitWidth: 68
            implicitHeight: 5
            radius: 3
            color: "#252525"
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: visible ? 68 : 0
            clip: true

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }

            Rectangle {
                id: barFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(0, Math.min(parent.width, parent.width * (OsdService.value / root.maxRange)))
                radius: 3
                color: OsdService.isMuted ? Theme.critical : Theme.highlight

                Behavior on width {
                    NumberAnimation {
                        duration: 80
                        easing.type: Easing.OutQuad
                    }
                }
                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
            }
        }

        // Etiqueta de valor porcentual o estado
        Text {
            text: {
                if (OsdService.mode === "power") {
                    return PowerProfileService.label;
                }
                if (OsdService.mode === "mic") {
                    return OsdService.isMuted ? "Muted" : "Active";
                }
                if (OsdService.isMuted) return "Mute";
                return OsdService.value + "%";
            }
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: OsdService.isMuted ? Theme.critical : (OsdService.mode === "power" ? PowerProfileService.accentColor : Theme.text)
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: (OsdService.mode === "mic" || OsdService.mode === "power") ? Text.AlignHCenter : Text.AlignRight
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: (OsdService.mode === "mic" || OsdService.mode === "power") ? implicitWidth : 36

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }
    }
}
