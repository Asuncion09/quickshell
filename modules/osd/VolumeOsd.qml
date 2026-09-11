import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    mask: Region {}

    anchors {
        bottom: true
    }
    margins.bottom: 60

    color: "transparent"

    property real osdOpacity: 0.0
    visible: osdOpacity > 0.001

    Behavior on osdOpacity {
        NumberAnimation {
            duration: root.osdOpacity > 0 ? 50 : 220
            easing.type: root.osdOpacity > 0 ? Easing.OutQuad : Easing.InQuad
        }
    }

    // Modo actual: "volume" o "brightness"
    property string currentMode: "volume"
    property int currentValue: 0
    property string currentIcon: "󰕾"
    property bool isMuted: false

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.osdOpacity = 0.0
    }

    Connections {
        target: AudioService
        function onVolumeChangedTriggered(percent, muted) {
            root.currentMode = "volume";
            root.currentValue = percent;
            root.isMuted = muted;
            root.currentIcon = AudioService.icon;
            root.osdOpacity = 1.0;
            hideTimer.restart();
        }
    }

    Connections {
        target: BrightnessService
        function onBrightnessChangedTriggered(percent) {
            root.currentMode = "brightness";
            root.currentValue = percent;
            root.isMuted = false;
            root.currentIcon = BrightnessService.icon;
            root.osdOpacity = 1.0;
            hideTimer.restart();
        }
    }

    implicitWidth: osdContainer.implicitWidth + 24
    implicitHeight: osdContainer.implicitHeight + 24

    Item {
        anchors.fill: parent
        opacity: root.osdOpacity

        // Sombra suave acelerada por hardware
        Rectangle {
            id: shadowShape
            anchors.fill: osdContainer
            radius: 12
            color: "#000000"
            visible: false
        }

        MultiEffect {
            source: shadowShape
            anchors.fill: shadowShape
            visible: Theme.pillShadowEnabled
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.6
            shadowBlur: 0.5
            shadowVerticalOffset: 4
        }

        // Contenedor principal estilo cápsula oscura
        Rectangle {
            id: osdContainer
            anchors.centerIn: parent

            implicitWidth: 260
            implicitHeight: 46
            width: implicitWidth
            height: implicitHeight

            radius: 12
            color: Theme.bgDark
            border.color: "#393939"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                // Icono dinámico grande
                Text {
                    text: root.currentIcon
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    color: root.isMuted ? Theme.critical : Theme.highlight
                    verticalAlignment: Text.AlignVCenter
                }

                // Barra de nivel horizontal continua
                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: "#262626"
                    clip: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.round(parent.width * (Math.max(0, Math.min(100, root.currentValue)) / 100.0))
                        radius: 3
                        color: root.isMuted ? Theme.critical : Theme.highlight

                        Behavior on width {
                            NumberAnimation {
                                duration: 60
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }

                // Porcentaje numérico o MUTE
                Text {
                    text: root.isMuted ? "MUTE" : root.currentValue + "%"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: root.isMuted ? Theme.critical : Theme.text
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
