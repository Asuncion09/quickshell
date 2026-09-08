import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

Item {
    id: root

    implicitHeight: 28
    // Ancho fijo absoluto para evitar jitter o redimensionamiento al pasar de 2 a 3 dígitos (95% -> 100%)
    implicitWidth: 152

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
            color: OsdService.isMuted ? Theme.critical : Theme.highlight
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
            color: "#252525"
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: visible ? 68 : 0
            clip: true

            Rectangle {
                id: barFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(0, Math.min(parent.width, parent.width * (OsdService.value / 100.0)))
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

        // Etiqueta de valor porcentual o estado (ancho reservado fijo de 32px para evitar saltos al pasar a 100% o Mute)
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
            color: OsdService.isMuted ? Theme.critical : Theme.text
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: (OsdService.mode === "mic") ? Text.AlignHCenter : Text.AlignRight
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: (OsdService.mode === "mic") ? implicitWidth : 32

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }
    }
}
