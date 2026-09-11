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

    signal valueChangedByUser(int newValue)
    signal iconClicked()

    property bool focused: false

    readonly property bool isHovered: mouseArea.containsMouse
    property bool wasHovered: false
    onIsHoveredChanged: {
        if (isHovered) wasHovered = true;
        else Qt.callLater(() => { wasHovered = false; });
    }

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
        id: trackBg
        anchors.fill: parent
        radius: 12
        color: root.focused ? "#2c2c2c" : (root.isHovered ? Theme.surfaceHover : Theme.surfaceBase)
        border.width: 0
        clip: true

        Behavior on color {
            ColorAnimation { duration: (root.isHovered || root.wasHovered) ? Theme.animFast : 40 }
        }

        // Anillo de foco nítido para navegación por teclado (z: 5 para situarse sobre fillRect)
        Rectangle {
            id: focusRing
            anchors.fill: parent
            radius: 12
            color: "transparent"
            border.width: root.focused ? 1.5 : 0
            border.color: Theme.highlight
            z: 5

            Behavior on border.width {
                NumberAnimation { duration: 40 }
            }
            Behavior on border.color {
                ColorAnimation { duration: 40 }
            }
        }

        // Relleno de progreso visual limpio sin texto encima
        Rectangle {
            id: fillRect
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(0, Math.min(trackBg.width, Math.round(trackBg.width * ((root.value - root.minValue) / Math.max(1, root.maxValue - root.minValue)))))
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
                    id: iconText
                    anchors.centerIn: parent
                    text: root.icon
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    color: {
                        if (root.isMuted) {
                            return root.value > 12 ? "#161616" : Theme.critical;
                        }
                        return root.value > 12 ? "#161616" : (root.focused ? Theme.text : Theme.textSecondary);
                    }

                    Behavior on color {
                        ColorAnimation { duration: (root.isHovered || root.wasHovered) ? Theme.animFast : 40 }
                    }

                    scale: (mouseArea.pressed && mouseArea.pressX <= 40 && !mouseArea.isDragging) ? 0.85 : 1.0
                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animFast
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.2
                        }
                    }
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
                    let isCovered = (root.value - root.minValue) >= ((root.maxValue - root.minValue) * 0.88);
                    if (root.isMuted) {
                        return isCovered ? "#161616" : Theme.critical;
                    }
                    if (root.focused) {
                        return isCovered ? "#161616" : Theme.highlight;
                    }
                    return isCovered ? "#161616" : Theme.text;
                }
                verticalAlignment: Text.AlignVCenter
                opacity: 0.95

                Behavior on color {
                    ColorAnimation { duration: (root.isHovered || root.wasHovered) ? Theme.animFast : 40 }
                }
            }
        }

        // Área de interacción para arrastrar el slider por el 100% de la pista visual
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor

            property real pressX: 0
            property bool isDragging: false

            function updateFromMouse(posX) {
                if (trackBg.width <= 0) return;
                let clamped = Math.max(0, Math.min(trackBg.width, posX));
                let rawPct = root.minValue + (clamped / trackBg.width) * (root.maxValue - root.minValue);
                let finalVal = Math.max(root.minValue, Math.min(root.maxValue, Math.round(rawPct)));
                if (finalVal !== root.value) {
                    root.valueChangedByUser(finalVal);
                }
            }

            onPressed: mouse => {
                pressX = mouse.x;
                isDragging = false;
                // Si el clic es en la pista activa (> 40px), posicionar el valor inmediatamente
                if (mouse.x > 40) {
                    updateFromMouse(mouse.x);
                }
            }

            onPositionChanged: mouse => {
                if (pressed) {
                    // Si se desplaza más de 4px, entra en modo arrastre
                    if (!isDragging && Math.abs(mouse.x - pressX) > 4) {
                        isDragging = true;
                    }
                    if (isDragging || mouse.x > 40) {
                        updateFromMouse(mouse.x);
                    }
                }
            }

            onReleased: mouse => {
                // Clic deliberado sobre el icono sin arrastrar activa su acción (ej. silenciar)
                if (!isDragging && pressX <= 40 && mouse.x <= 40) {
                    root.iconClicked();
                } else if (isDragging || mouse.x > 40) {
                    updateFromMouse(mouse.x);
                }
                isDragging = false;
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
