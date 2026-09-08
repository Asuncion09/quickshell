pragma Singleton
import QtQuick
import "."

Item {
    id: root

    property bool isVisible: false
    property string mode: "volume" // "volume" | "brightness" | "mic"
    property int value: 0
    property bool isMuted: false
    property string icon: ""

    Timer {
        id: hideTimer
        interval: 1600
        onTriggered: {
            root.isVisible = false;
        }
    }

    function showOsd(newMode, newValue, newIcon, muted) {
        root.mode = newMode;
        root.value = newValue;
        root.icon = newIcon;
        root.isMuted = muted !== undefined ? muted : false;
        root.isVisible = true;
        hideTimer.restart();
    }

    function hideOsd() {
        hideTimer.stop();
        root.isVisible = false;
    }

    Connections {
        target: AudioService
        function onVolumeChangedTriggered(percent, muted) {
            root.showOsd("volume", percent, AudioService.icon, muted);
        }
        function onMicMutedTriggered(muted) {
            root.showOsd("mic", muted ? 0 : 100, muted ? "󰍭" : "󰍬", muted);
        }
    }

    Connections {
        target: BrightnessService
        function onBrightnessChangedTriggered(percent) {
            root.showOsd("brightness", percent, BrightnessService.icon, false);
        }
    }
}
