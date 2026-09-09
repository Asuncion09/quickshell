//@ pragma UseQApplication
//@ pragma RespectSystemStyle
//@ pragma Env QT_QPA_PLATFORMTHEME = gtk3
//@ pragma Env QT_LOGGING_RULES = qt.qpa.services.warning=false
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "services"
import "modules/bar"
import "modules/osd"
import "modules/switcher"

ShellRoot {
    NotificationServer {
        keepOnReload: false
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true

        onNotification: notif => {
            NotificationService.handleNotification(notif);
        }
    }

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
        function micMute(): void {
            AudioService.toggleMicMute();
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
        target: "media"
        function hover(enabled: bool): void {
            MediaService.forceControls = enabled;
        }
        function playPause(): void {
            MediaService.playPause();
        }
        function next(): void {
            MediaService.next();
        }
        function prev(): void {
            MediaService.previous();
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

    IpcHandler {
        target: "notifications"
        function toggle(): void {
            NotificationService.toggleCenter();
        }
        function open(): void {
            NotificationService.openCenter();
        }
        function close(): void {
            NotificationService.closeCenter();
        }
        function clear(): void {
            NotificationService.clearAll();
        }
        function dnd(): void {
            NotificationService.toggleDnd();
        }
    }

    IpcHandler {
        target: "battery"
        function test(percent: int, charging: bool): void {
            BatteryService.setTestMode(percent, charging);
        }
        function reset(): void {
            BatteryService.clearTestMode();
        }
        function snooze(): void {
            BatteryService.snooze();
        }
    }

    IpcHandler {
        target: "switcher"
        function next(): void {
            SwitcherService.next();
        }
        function prev(): void {
            SwitcherService.prev();
        }
        function open(): void {
            SwitcherService.open();
        }
        function close(): void {
            SwitcherService.close();
        }
        function select(): void {
            SwitcherService.select();
        }
        function cancel(): void {
            SwitcherService.cancel();
        }
        function toggle(): void {
            if (SwitcherService.isOpen) {
                SwitcherService.close();
            } else {
                SwitcherService.open();
            }
        }
        function preview(): void {
            SwitcherService.preview();
        }
    }

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Variants {
        model: Quickshell.screens
        WindowSwitcher {}
    }
}

