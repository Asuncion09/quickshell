//@ pragma UseQApplication
//@ pragma RespectSystemStyle
//@ pragma Env QT_QPA_PLATFORMTHEME = gtk3
//@ pragma Env QT_LOGGING_RULES = qt.qpa.services.warning=false
import Quickshell
import Quickshell.Io
import "services"
import "modules/bar"
import "modules/osd"

ShellRoot {
    IpcHandler {
        target: "audio"
        function raise(): void {
            AudioService.increaseVolume(5);
        }
        function lower(): void {
            AudioService.decreaseVolume(5);
        }
        function mute(): void {
            AudioService.toggleMute();
        }
    }

    IpcHandler {
        target: "brightness"
        function raise(): void {
            BrightnessService.increase(5);
        }
        function lower(): void {
            BrightnessService.decrease(5);
        }
    }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void {
            ControlCenterService.toggle();
        }
        function open(): void {
            ControlCenterService.open();
        }
        function close(): void {
            ControlCenterService.close();
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            LauncherService.toggle();
        }
        function open(): void {
            LauncherService.open();
        }
        function close(): void {
            LauncherService.close();
        }
        function next(): void {
            LauncherService.nextItem();
        }
        function prev(): void {
            LauncherService.prevItem();
        }
        function launch(): void {
            LauncherService.launchCurrent();
        }
    }

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Variants {
        model: Quickshell.screens
        VolumeOsd {}
    }
}

