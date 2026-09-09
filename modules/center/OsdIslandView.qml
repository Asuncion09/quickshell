import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

Item {
    id: root

    implicitHeight: 28
    // Ancho fijo calibrado para evitar jitter o saltos visuales (0% hasta 150% o Mute)
    implicitWidth: 156

    readonly property bool isOver100: OsdService.mode === "volume" && OsdService.value > 100 && !OsdService.isMuted
    readonly property real maxRange: (OsdService.mode === "volume") ? 150.0 : 100.0

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
            color: OsdService.isMuted ? Theme.critical : (root.isOver100 ? Theme.warning : Theme.highlight)
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 16

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }

        // Barra de progreso (activa para volumen y brillo)
        Rectangle {
            id: barBg
            visible: OsdService.mode !== "mic"
            implicitWidth: 68
            implicitHeight: 5
            radius: 3
            color: root.isOver100 ? Qt.rgba(241/255, 196/255, 15/255, 0.22) : "#252525"
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: visible ? 68 : 0
            clip: true

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }

            // Marca indicadora del 100% nominal (a 45px de 68px en escala de 150%)
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                x: Math.round(parent.width * (100.0 / 150.0))
                width: 1
                color: root.isOver100 ? Qt.rgba(241/255, 196/255, 15/255, 0.50) : Qt.rgba(1, 1, 1, 0.20)
                visible: OsdService.mode === "volume"
                z: 2
            }

            Rectangle {
                id: barFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(0, Math.min(parent.width, parent.width * (OsdService.value / root.maxRange)))
                radius: 3
                color: OsdService.isMuted ? Theme.critical : (root.isOver100 ? Theme.warning : Theme.highlight)

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

        // Etiqueta de valor porcentual o estado (ancho reservado fijo de 36px para evitar saltos al pasar a 100%, 150% o Mute)
        Text {
            text: {
                if (OsdService.mode === "mic") {
                    return OsdService.isMuted ? "Silenciado" : "Activo";
                }
                if (OsdService.isMuted) return "Mute";
                return OsdService.value + "%";
            }
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: OsdService.isMuted ? Theme.critical : (root.isOver100 ? Theme.warning : Theme.text)
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: (OsdService.mode === "mic") ? Text.AlignHCenter : Text.AlignRight
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: (OsdService.mode === "mic") ? implicitWidth : 36

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }
    }
}
