import QtQuick
import "../../theme"
import "../../components"
import "../../services"

Item {
    id: root

    readonly property bool isHovered: hoverArea.containsMouse || prevMouse.containsMouse || playMouse.containsMouse || nextMouse.containsMouse

    // Progreso único de animación (0.0 = reposo, 1.0 = expandido en hover)
    // Sincroniza al 100% la cápsula exterior y los controles interiores sin ningún lag
    property real expandProgress: isHovered ? 1.0 : 0.0
    Behavior on expandProgress {
        NumberAnimation {
            duration: Theme.animNormal
            easing.type: Easing.OutCubic
        }
    }

    implicitWidth: Math.round(contentRow.implicitWidth)
    implicitHeight: 26
    width: implicitWidth
    height: implicitHeight

    signal dismissToClockRequested()
    signal wheelRequested()

    // 1. Detección de hover y clics en el fondo (z: 0)
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        z: 0

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                // Clic izquierdo: Play / Pausa
                MediaService.playPause();
            } else if (mouse.button === Qt.RightButton) {
                // Clic derecho: Regresa al reloj inmediatamente
                root.dismissToClockRequested();
            }
        }

        onWheel: wheel => {
            wheel.accepted = true;
            root.wheelRequested();
        }
    }

    // 2. Fila de contenido sincronizada (z: 1)
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6
        z: 1

        // Icono de la Aplicación / Medios (YouTube, Spotify, Firefox, etc.)
        Text {
            id: appIcon
            anchors.verticalCenter: parent.verticalCenter
            text: MediaService.appIcon
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: MediaService.isPlaying ? Theme.success : Theme.textSecondary

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }

        // Título de la pista / video
        Text {
            id: titleLabel
            anchors.verticalCenter: parent.verticalCenter
            text: MediaService.title
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Theme.text
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 130)
        }

        // Nombre del Artista / Canal
        Text {
            id: artistLabel
            anchors.verticalCenter: parent.verticalCenter
            visible: MediaService.artist !== ""
            text: "•  " + MediaService.artist
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.textSecondary
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 110)
        }

        // Contenedor de Controles interactivos:
        // Su ancho y opacidad están ligados directamente a expandProgress,
        // garantizando que la cápsula y los controles se muevan exactamente al mismo tiempo
        Item {
            id: controlsContainer
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round((controlsRow.implicitWidth + 4) * root.expandProgress)
            height: 26
            clip: true
            opacity: root.expandProgress
            visible: root.expandProgress > 0.01

            Row {
                id: controlsRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                spacing: 9

                // Separador sutil
                Text {
                    text: "|"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.pixelSize: 11
                    color: Theme.dark6
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Botón Anterior (󰒮)
                Text {
                    text: "󰒮"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.pixelSize: 15
                    color: prevMouse.containsMouse ? Theme.highlight : Theme.text
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaService.previous()
                    }

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }

                // Botón Play / Pausa (󰐊 / 󰏤)
                Text {
                    text: MediaService.isPlaying ? "󰏤" : "󰐊"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.pixelSize: 16
                    color: playMouse.containsMouse ? Theme.highlight : (MediaService.isPlaying ? Theme.success : Theme.text)
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaService.playPause()
                    }

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }

                // Botón Siguiente (󰒭)
                Text {
                    text: "󰒭"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.pixelSize: 15
                    color: nextMouse.containsMouse ? Theme.highlight : Theme.text
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaService.next()
                    }

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }
                }
            }
        }
    }
}
