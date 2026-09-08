import QtQuick
import QtQuick.Layouts
import "../../theme"

Item {
    id: root

    property string icon: "󰕾"
    property int value: 50
    property color accentColor: Theme.highlight
    property bool isMuted: false
    property int minValue: 0
    property int maxValue: 100
    property int step: 5


    property bool focused: false

    function stepUp() {
        let next = Math.min(root.maxValue, Math.floor(root.value / root.step) * root.step + root.step);
        root.valueChangedByUser(next);
    }

    function stepDown() {
        let next = Math.max(root.minValue, Math.ceil(root.value / root.step) * root.step - root.step);
        root.valueChangedByUser(next);
    }

    implicitWidth: 280
    implicitHeight: 40
    Layout.fillWidth: true

    // Pista de fondo con bordes redondeados armónicos (radius: 12)
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: (mouseArea.containsMouse || root.focused) ? Theme.surfaceHover : Theme.surfaceBase
        border.width: root.focused ? 2 : 0
        border.color: Theme.wsActiveColor
        clip: true

        Behavior on border.width { NumberAnimation { duration: Theme.animFast } }

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }

        // Relleno de progreso visual limpio sin texto encima
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(0, Math.min(trackBg.width, Math.round(trackBg.width * (root.value / 100.0))))
            radius: 12
            color: root.isMuted ? Theme.critical : root.accentColor
            opacity: root.isMuted ? 0.65 : 1.0

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

        // Elementos superpuestos: Solo Icono interactivo a la izquierda e Indicador a la derecha
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 12
            spacing: 0

            // Botón interactivo para el icono
            Item {
                implicitWidth: 32
                implicitHeight: 40
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    color: {
                        if (root.isMuted) {
                            return root.value > 12 ? "#161616" : Theme.critical;
                        }
                        return root.value > 12 ? "#161616" : Theme.textSecondary;
                    }

                    Behavior on color {
                        ColorAnimation { duration: Theme.animFast }
                    }

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
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.iconClicked()
                }
            }

            // Espaciador central limpio: la barra de progreso fluye sin interferencias
            Item {
                Layout.fillWidth: true
            }

            // Indicador de Porcentaje nítido a la derecha
            Text {
                text: root.isMuted ? "MUTED" : `${root.value}%`
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: {
                    if (root.isMuted) {
                        return root.value >= 88 ? "#161616" : Theme.critical;
                    }
                    return root.value >= 88 ? "#161616" : Theme.text;
                }
                verticalAlignment: Text.AlignVCenter
                opacity: 0.95

                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
            }
        }

        // Área de interacción para arrastrar el slider
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            anchors.leftMargin: 40 // Permite al icono recibir sus propios clics sin conflicto
            hoverEnabled: true
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                if (mouseArea.width <= 0) return;
                let clamped = Math.max(0, Math.min(mouseArea.width, posX));
                let rawPct = (clamped / mouseArea.width) * 100;
                let stepped = Math.round(rawPct / root.step) * root.step;
                let finalVal = Math.max(root.minValue, Math.min(root.maxValue, stepped));
                root.valueChangedByUser(finalVal);
            }

            onPressed: mouse => updateFromMouse(mouse.x)
            onPositionChanged: mouse => {
                if (pressed) updateFromMouse(mouse.x);
            }

            onWheel: wheel => {
                if (wheel.angleDelta.y > 0) {
                    root.stepUp();
                } else if (wheel.angleDelta.y < 0) {
                    root.stepDown();
                }
            }
        }
    }
}
