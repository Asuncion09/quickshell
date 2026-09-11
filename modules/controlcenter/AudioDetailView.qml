import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../../services"

Item {
    id: root

    implicitWidth: 280
    implicitHeight: contentCol.implicitHeight
    height: implicitHeight
    Layout.fillWidth: true

    signal backRequested()

    property int navIndex: 0
    property bool isKeyNavActive: false

    onVisibleChanged: {
        root.isKeyNavActive = false;
        root.navIndex = 0;
        if (visible) {
            AudioService.refreshDevices();
        }
    }

    function triggerCurrentItem() {
        if (root.navIndex === 0) {
            root.backRequested();
            return;
        }

        let sinkCount = AudioService.sinks.length;
        let sourceCount = AudioService.sources.length;

        // navIndex 1 .. (1 + sinkCount - 1): Output Sinks
        let sinkIdx = root.navIndex - 1;
        if (sinkIdx >= 0 && sinkIdx < sinkCount) {
            let s = AudioService.sinks[sinkIdx];
            if (s) AudioService.setDefaultSink(s.id);
            return;
        }

        // navIndex 1 + sinkCount: Output Volume Slider -> Conmuta silencio
        if (root.navIndex === 1 + sinkCount) {
            AudioService.toggleMute();
            return;
        }

        // navIndex (2 + sinkCount) .. (2 + sinkCount + sourceCount - 1): Input Sources
        let srcIdx = root.navIndex - (2 + sinkCount);
        if (srcIdx >= 0 && srcIdx < sourceCount) {
            let src = AudioService.sources[srcIdx];
            if (src) AudioService.setDefaultSource(src.id);
            return;
        }

        // navIndex 2 + sinkCount + sourceCount: Mic Gain Slider -> Conmuta silencio de micro
        if (root.navIndex === 2 + sinkCount + sourceCount) {
            AudioService.toggleMicMute();
            return;
        }
    }

    function handleKey(event) {
        let sinkCount = AudioService.sinks.length;
        let sourceCount = AudioService.sources.length;
        // Total: Volver (0) + Sinks + Slider Salida (1) + Sources + Slider Micro (1)
        let totalItems = 1 + sinkCount + 1 + sourceCount + 1;

        if (!root.isKeyNavActive) {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Up || event.key === Qt.Key_Right || event.key === Qt.Key_Left || event.key === Qt.Key_Tab) {
                root.isKeyNavActive = true;
                root.navIndex = 0;
                return true;
            }
        }

        if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
            root.isKeyNavActive = true;
            root.navIndex = (root.navIndex + 1) % totalItems;
            return true;
        }

        if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
            root.isKeyNavActive = true;
            root.navIndex = (root.navIndex - 1 + totalItems) % totalItems;
            return true;
        }

        // Flecha Izquierda: ajustes en sliders o volver en la cabecera
        if (event.key === Qt.Key_Left) {
            root.isKeyNavActive = true;
            if (root.navIndex === 0) {
                root.backRequested();
                return true;
            }
            // Slider volumen salida
            if (root.navIndex === 1 + sinkCount) {
                outSlider.stepDown();
                return true;
            }
            // Slider volumen micro
            if (root.navIndex === 2 + sinkCount + sourceCount) {
                inSlider.stepDown();
                return true;
            }
            // Desde cualquier otro elemento, volver al inicio (botón atrás)
            root.navIndex = 0;
            return true;
        }

        // Flecha Derecha: cabecera o incremento en sliders
        if (event.key === Qt.Key_Right) {
            root.isKeyNavActive = true;
            if (root.navIndex === 0) {
                if (totalItems > 1) root.navIndex = 1;
                return true;
            }
            if (root.navIndex === 1 + sinkCount) {
                outSlider.stepUp();
                return true;
            }
            if (root.navIndex === 2 + sinkCount + sourceCount) {
                inSlider.stepUp();
                return true;
            }
            return true;
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.triggerCurrentItem();
            return true;
        }

        if (event.key === Qt.Key_Escape) {
            root.backRequested();
            return true;
        }

        return false;
    }

    ColumnLayout {
        id: contentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 8

        // ==========================================
        // 1. CABECERA: Volver + Título
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 32
            spacing: 8

            // Botón Volver (circular 28px, idéntico a WifiDetailView y BluetoothDetailView)
            Rectangle {
                id: backBtn
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === 0
                color: isKeyFocused ? "#2c2c2c" : (backMouse.containsMouse ? Theme.surfaceHover : "transparent")
                border.width: isKeyFocused ? 1.5 : 0
                border.color: Theme.highlight

                scale: backMouse.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on border.width { NumberAnimation { duration: 40 } }
                Behavior on border.color { ColorAnimation { duration: 40 } }
                Behavior on color { ColorAnimation { duration: backMouse.containsMouse ? Theme.animFast : 40 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: (backMouse.containsMouse || backBtn.isKeyFocused) ? Theme.text : Theme.textSecondary
                    Behavior on color { ColorAnimation { duration: backMouse.containsMouse ? Theme.animFast : 40 } }
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

            // Título de la vista
            Text {
                text: "Sound"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.text
                Layout.alignment: Qt.AlignVCenter
            }

            // Espaciador flexible
            Item { Layout.fillWidth: true }
        }

        // Línea divisoria fina
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.dividerColor
        }

        // ==========================================
        // 2. SECCIÓN: OUTPUT (Salida de Audio)
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            // Encabezado de sección con contador
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                spacing: 6

                Text {
                    text: "Output devices"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.textSecondary
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: AudioService.sinks.length + (AudioService.sinks.length === 1 ? " device" : " devices")
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.textMuted
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Lista de Dispositivos de Salida (Sinks)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                // Estado vacío si no hay dispositivos
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: 8
                    color: Theme.surfaceBase
                    visible: AudioService.sinks.length === 0

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "󰓄"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: Theme.textMuted
                        }
                        Text {
                            text: "No output devices found"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.textSecondary
                        }
                    }
                }

                Repeater {
                    model: AudioService.sinks

                    delegate: Rectangle {
                        id: sinkItem
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 8

                        readonly property int itemNavIdx: 1 + index
                        readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === itemNavIdx

                        color: {
                            if (modelData.isDefault) {
                                return (sinkMouse.containsMouse || isKeyFocused) ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.05);
                            }
                            if (isKeyFocused) return "#2c2c2c";
                            return sinkMouse.containsMouse ? Theme.surfaceHover : "transparent";
                        }
                        border.width: isKeyFocused ? 1.5 : (modelData.isDefault ? 1 : 0)
                        border.color: isKeyFocused ? (modelData.isDefault ? Qt.rgba(1, 1, 1, 0.85) : Theme.highlight) : Qt.rgba(1, 1, 1, 0.08)

                        scale: sinkMouse.pressed ? 0.98 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                        Behavior on border.width { NumberAnimation { duration: 40 } }
                        Behavior on border.color { ColorAnimation { duration: 40 } }
                        Behavior on color { ColorAnimation { duration: sinkMouse.containsMouse ? Theme.animFast : 40 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            // Icono contextual del dispositivo
                            Text {
                                text: modelData.icon || "󰓃"
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                color: modelData.isDefault ? Theme.wsActiveColor : (sinkMouse.containsMouse ? Theme.text : Theme.textSecondary)
                                Layout.alignment: Qt.AlignVCenter
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }

                            // Nombre limpio del dispositivo (único texto, centrado verticalmente)
                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: modelData.name || "Output Device"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: modelData.isDefault ? Font.DemiBold : Font.Normal
                                color: modelData.isDefault ? "#ffffff" : (sinkMouse.containsMouse ? Theme.text : Theme.textSecondary)
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }

                            // Indicador de selección activa
                            Text {
                                text: modelData.isDefault ? "󰄴" : "󰄱"
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                color: modelData.isDefault ? Theme.wsActiveColor : Qt.rgba(1, 1, 1, 0.18)
                                Layout.alignment: Qt.AlignVCenter
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }
                        }

                        MouseArea {
                            id: sinkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AudioService.setDefaultSink(modelData.id)
                        }
                    }
                }
            }

            // Slider de Volumen de Salida
            SliderControl {
                id: outSlider
                Layout.fillWidth: true
                focused: root.isKeyNavActive && root.navIndex === (1 + AudioService.sinks.length)
                icon: AudioService.outputIcon
                value: AudioService.currentPercent
                isMuted: AudioService.isMuted
                accentColor: (AudioService.currentPercent > 100 && !AudioService.isMuted) ? Theme.warning : Theme.wsActiveColor
                minValue: 0
                maxValue: 150
                step: 5
                onValueChangedByUser: pct => AudioService.setVolume(pct)
                onIconClicked: AudioService.toggleMute()
            }
        }

        // Línea divisoria fina entre Salida y Entrada
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.dividerColor
        }

        // ==========================================
        // 3. SECCIÓN: INPUT (Micrófono / Entrada)
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            // Encabezado de sección con contador
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                spacing: 6

                Text {
                    text: "Input devices"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.textSecondary
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: AudioService.sources.length + (AudioService.sources.length === 1 ? " device" : " devices")
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.textMuted
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Lista de Dispositivos de Entrada (Sources)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                // Estado vacío si no hay micrófonos
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: 8
                    color: Theme.surfaceBase
                    visible: AudioService.sources.length === 0

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "󰍭"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: Theme.textMuted
                        }
                        Text {
                            text: "No input devices found"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.textSecondary
                        }
                    }
                }

                Repeater {
                    model: AudioService.sources

                    delegate: Rectangle {
                        id: srcItem
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 8

                        readonly property int itemNavIdx: 2 + AudioService.sinks.length + index
                        readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === itemNavIdx

                        color: {
                            if (modelData.isDefault) {
                                return (srcMouse.containsMouse || isKeyFocused) ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.05);
                            }
                            if (isKeyFocused) return "#2c2c2c";
                            return srcMouse.containsMouse ? Theme.surfaceHover : "transparent";
                        }
                        border.width: isKeyFocused ? 1.5 : (modelData.isDefault ? 1 : 0)
                        border.color: isKeyFocused ? (modelData.isDefault ? Qt.rgba(1, 1, 1, 0.85) : Theme.highlight) : Qt.rgba(1, 1, 1, 0.08)

                        scale: srcMouse.pressed ? 0.98 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                        Behavior on border.width { NumberAnimation { duration: 40 } }
                        Behavior on border.color { ColorAnimation { duration: 40 } }
                        Behavior on color { ColorAnimation { duration: srcMouse.containsMouse ? Theme.animFast : 40 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            // Icono contextual de entrada
                            Text {
                                text: modelData.icon || "󰍬"
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                color: modelData.isDefault ? Theme.wsActiveColor : (srcMouse.containsMouse ? Theme.text : Theme.textSecondary)
                                Layout.alignment: Qt.AlignVCenter
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }

                            // Nombre limpio del dispositivo (único texto, centrado verticalmente)
                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: modelData.name || "Microphone"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: modelData.isDefault ? Font.DemiBold : Font.Normal
                                color: modelData.isDefault ? "#ffffff" : (srcMouse.containsMouse ? Theme.text : Theme.textSecondary)
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }

                            // Indicador de selección activa
                            Text {
                                text: modelData.isDefault ? "󰄴" : "󰄱"
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                color: modelData.isDefault ? Theme.wsActiveColor : Qt.rgba(1, 1, 1, 0.18)
                                Layout.alignment: Qt.AlignVCenter
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }
                        }

                        MouseArea {
                            id: srcMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AudioService.setDefaultSource(modelData.id)
                        }
                    }
                }
            }

            // Slider de Ganancia / Volumen del Micrófono
            SliderControl {
                id: inSlider
                Layout.fillWidth: true
                focused: root.isKeyNavActive && root.navIndex === (2 + AudioService.sinks.length + AudioService.sources.length)
                icon: AudioService.inputIcon
                value: AudioService.micVolumePercent
                isMuted: AudioService.isMicMuted
                accentColor: Theme.wsActiveColor
                minValue: 0
                maxValue: 150
                step: 5
                onValueChangedByUser: pct => AudioService.setMicVolume(pct)
                onIconClicked: AudioService.toggleMicMute()
            }
        }
    }
}
