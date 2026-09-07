import QtQuick
import QtQuick.Layouts
import "../../theme"

Item {
    id: root

    property string icon: "󰕾"
    property int value: 50
    property color accentColor: Theme.highlight
    property bool isMuted: false
    property string title: ""

    signal valueChangedByUser(int newValue)
    signal iconClicked()

    implicitWidth: 280
    implicitHeight: 40
    Layout.fillWidth: true

    // Pista de fondo sólida y estática (sin alteración geométrica ni de escala)
    Rectangle {
        id: trackBg
        anchors.fill: parent
        radius: 10
        color: mouseArea.containsMouse ? "#262626" : "#1e1e1e"
        border.width: 0

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        // Relleno de progreso
        Rectangle {
            id: fillRect
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(0, Math.min(trackBg.width, Math.round(trackBg.width * (root.value / 100.0))))
            radius: 9
            color: root.isMuted ? Theme.critical : root.accentColor
            opacity: root.isMuted ? 0.6 : (mouseArea.containsMouse ? 0.95 : 0.85)

            Behavior on width {
                enabled: !mouseArea.pressed
                NumberAnimation {
                    duration: 70
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on color {
                ColorAnimation { duration: Theme.animFast }
            }

            Behavior on opacity {
                NumberAnimation { duration: Theme.animFast }
            }
        }

        // Contenido superpuesto: Icono, Título y Porcentaje
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            // Botón interactivo para el icono
            Item {
                implicitWidth: 24
                implicitHeight: 24
                Layout.alignment: Qt.AlignVCenter

                Text {
                    id: iconText
                    anchors.centerIn: parent
                    text: root.icon
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    color: root.isMuted ? Theme.critical : "#ffffff"

                    scale: iconMouse.pressed ? 0.85 : 1.0
                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animFast
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.2
                        }
                    }
                }

                MouseArea {
                    id: iconMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.iconClicked()
                }
            }

            // Título opcional
            Text {
                text: root.title
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: "#ffffff"
                opacity: 0.9
                visible: root.title !== ""
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Item {
                Layout.fillWidth: true
                visible: root.title === ""
            }

            // Indicador de Porcentaje
            Text {
                text: root.isMuted ? "MUTED" : `${root.value}%`
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: "#ffffff"
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Área de interacción para arrastrar el slider
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            anchors.leftMargin: 36 // Permite al icono recibir sus propios clics
            hoverEnabled: true
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor

            function updateFromMouse(posX) {
                let clampedX = Math.max(0, Math.min(trackBg.width, posX + 36));
                let pct = Math.round((clampedX / trackBg.width) * 100);
                root.valueChangedByUser(Math.max(0, Math.min(100, pct)));
            }

            onPressed: mouse => updateFromMouse(mouse.x)
            onPositionChanged: mouse => {
                if (pressed) updateFromMouse(mouse.x);
            }

            onWheel: wheel => {
                let step = wheel.angleDelta.y > 0 ? 3 : -3;
                let target = Math.max(0, Math.min(100, root.value + step));
                root.valueChangedByUser(target);
            }
        }
    }
}
