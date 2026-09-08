import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../components"
import "../../services"

Item {
    id: root

    property bool isContainerHovered: false
    readonly property bool isHovered: MediaService.forceControls || isContainerHovered || hoverArea.containsMouse || prevMouse.containsMouse || playMouse.containsMouse || nextMouse.containsMouse

    // Progreso único de animación de ancho (0.0 = reposo, 1.0 = expandido en hover)
    property real expandProgress: isHovered ? 1.0 : 0.0
    Behavior on expandProgress {
        NumberAnimation {
            duration: Theme.animNormal
            easing.type: Easing.OutCubic
        }
    }

    // Opacidad sincronizada de controles:
    // Al entrar en hover, aparece suavemente en sincronía con la expansión.
    // Al salir de hover, se desvanece con rapidez (100ms InQuad) antes de que la contracción recorte botones o deje aislada la barra separadora.
    property real controlsOpacity: isHovered ? 1.0 : 0.0
    Behavior on controlsOpacity {
        NumberAnimation {
            duration: root.isHovered ? Theme.animNormal : 100
            easing.type: root.isHovered ? Easing.OutCubic : Easing.InQuad
        }
    }

    implicitWidth: Math.round(contentRow.implicitWidth)
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight

    signal dismissToClockRequested()
    signal wheelRequested()

    // 1. Detección de hover y clics en el fondo (z: 0) extendida a toda la cápsula
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        anchors.leftMargin: -Theme.centerPillPaddingHorizontal
        anchors.rightMargin: -Theme.centerPillPaddingHorizontal
        anchors.topMargin: -2
        anchors.bottomMargin: -2
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
    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6
        z: 1

        // Icono de la Aplicación / Medios (YouTube, Spotify, Firefox, etc.)
        Text {
            id: appIcon
            Layout.alignment: Qt.AlignVCenter
            text: MediaService.appIcon
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: MediaService.isPlaying ? Theme.success : Theme.textSecondary

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }
        }

        // Título de la pista / video con desplazamiento continuo infinito (Ticker Seamless Loop)
        Item {
            id: titleContainer
            Layout.alignment: Qt.AlignVCenter
            readonly property int maxVisibleWidth: 130
            readonly property int textWidth: Math.round(primaryText.implicitWidth)
            readonly property int gap: 38 // Separación limpia entre el final del título y su repetición
            readonly property int cycleWidth: textWidth + gap
            readonly property bool needsScroll: textWidth > maxVisibleWidth

            // Tiempo de reposo en calma cuando el título está en el inicio
            readonly property int initialPauseDuration: 6500

            // Velocidad de desplazamiento en ms por píxel (55ms/px = ritmo pausado y fácil de leer)
            readonly property int msPerPixel: 55

            Layout.preferredWidth: Math.min(textWidth, maxVisibleWidth)
            Layout.preferredHeight: primaryText.implicitHeight
            clip: true

            property real scrollOffset: 0.0

            // Primer texto (título principal)
            Text {
                id: primaryText
                anchors.verticalCenter: parent.verticalCenter
                text: MediaService.title
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Theme.text
                x: -Math.round(titleContainer.scrollOffset)

                // Reiniciar animación al cambiar de canción
                onTextChanged: {
                    marqueeAnim.stop();
                    titleContainer.scrollOffset = 0.0;
                    if (titleContainer.needsScroll && MediaService.isPlaying) {
                        marqueeAnim.restart();
                    }
                }
            }

            // Segundo texto (entra por la derecha de forma continua mientras el primero sale)
            Text {
                id: secondaryText
                anchors.verticalCenter: parent.verticalCenter
                text: MediaService.title
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Theme.text
                visible: titleContainer.needsScroll
                x: Math.round(titleContainer.cycleWidth - titleContainer.scrollOffset)
            }

            SequentialAnimation {
                id: marqueeAnim
                running: titleContainer.needsScroll && MediaService.isPlaying
                loops: Animation.Infinite

                // 1. Pausa prolongada en reposo (6.5s) con el texto alineado al inicio
                PauseAnimation { duration: titleContainer.initialPauseDuration }

                // 2. Desplazamiento continuo a ritmo pausado hasta que la segunda copia llega exactamente a x = 0
                NumberAnimation {
                    target: titleContainer
                    property: "scrollOffset"
                    to: titleContainer.cycleWidth
                    duration: Math.max(2500, Math.round(titleContainer.cycleWidth * titleContainer.msPerPixel))
                    easing.type: Easing.Linear
                }

                // 3. Sincronización instantánea e imperceptible:
                // Como secondaryText estaba en x = 0, reiniciar scrollOffset a 0
                // coloca a primaryText en x = 0 sin que haya ningún salto ni parpadeo visual.
                PropertyAction {
                    target: titleContainer
                    property: "scrollOffset"
                    value: 0.0
                }
            }

            Connections {
                target: MediaService
                function onIsPlayingChanged() {
                    if (MediaService.isPlaying && titleContainer.needsScroll) {
                        marqueeAnim.restart();
                    } else if (!MediaService.isPlaying) {
                        marqueeAnim.stop();
                        titleContainer.scrollOffset = 0.0;
                    }
                }
            }
        }

        // Nombre del Artista / Canal
        Text {
            id: artistLabel
            Layout.alignment: Qt.AlignVCenter
            visible: MediaService.artist !== ""
            text: "•  " + MediaService.artist
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.textSecondary
            elide: Text.ElideRight
            Layout.preferredWidth: Math.min(implicitWidth, 110)
        }

        // Contenedor de Controles interactivos:
        // Layout.leftMargin se contrae a -6 a medida que expandProgress llega a 0,
        // eliminando cualquier salto o separación residual al cerrarse.
        Item {
            id: controlsContainer
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Math.round(controlsRow.implicitWidth * root.expandProgress)
            Layout.preferredHeight: 26
            Layout.leftMargin: Math.round(6 * root.expandProgress) - 6
            clip: true
            opacity: root.controlsOpacity
            visible: root.expandProgress > 0.001

            Row {
                id: controlsRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 9

                // Separador sutil
                Text {
                    text: "|"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.dark6
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Botón Anterior (󰒮)
                Text {
                    text: "󰒮"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    color: prevMouse.containsMouse ? Theme.highlight : Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                    scale: prevMouse.pressed ? 0.80 : (prevMouse.containsMouse ? 1.18 : 1.0)

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

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animFast
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.5
                        }
                    }
                }

                // Botón Play / Pausa (󰐊 / 󰏤)
                Text {
                    text: MediaService.isPlaying ? "󰏤" : "󰐊"
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    color: playMouse.containsMouse ? Theme.highlight : (MediaService.isPlaying ? Theme.success : Theme.text)
                    anchors.verticalCenter: parent.verticalCenter
                    scale: playMouse.pressed ? 0.80 : (playMouse.containsMouse ? 1.18 : 1.0)

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

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animFast
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.5
                        }
                    }
                }

                // Botón Siguiente (󰒭)
                Text {
                    text: "󰒭"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    color: nextMouse.containsMouse ? Theme.highlight : Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                    scale: nextMouse.pressed ? 0.80 : (nextMouse.containsMouse ? 1.18 : 1.0)

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

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animFast
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.5
                        }
                    }
                }
            }
        }
    }
}
