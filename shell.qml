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
import "modules/wallpaper"
import "modules/lock"
import "modules/session"

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
        function openSettings(): void {
            ControlCenterService.openSettings();
        }
        function openAudio(): void {
            ControlCenterService.openAudio();
        }
        function openWallpaper(): void {
            ControlCenterService.openWallpaper();
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
        target: "clipboard"
        function toggle(): void {
            ClipboardService.toggle();
        }
        function open(): void {
            ClipboardService.open();
        }
        function close(): void {
            ClipboardService.close();
        }
        function clear(): void {
            ClipboardService.clearAll();
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
        function expand(): void {
            NotificationService.expandToast();
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
        target: "power"
        function set(profile: string): void {
            PowerProfileService.setProfile(profile);
        }
        function cycle(): void {
            PowerProfileService.cycleProfile();
        }
        function save(): void {
            PowerProfileService.setProfile("power-save");
        }
        function balanced(): void {
            PowerProfileService.setProfile("balanced");
        }
        function performance(): void {
            PowerProfileService.setProfile("performance");
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

    IpcHandler {
        target: "wallpaper"
        function set(path: string): void {
            WallpaperService.setWallpaper(path);
        }
        function next(): void {
            WallpaperService.next();
        }
        function prev(): void {
            WallpaperService.prev();
        }
        function scan(): void {
            WallpaperService.scanWallpapers();
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void {
            LockService.lock();
        }
        function unlock(): void {
            LockService.triggerUnlockAnimation();
        }
    }

    IpcHandler {
        target: "polkit"
        function submit(password: string): void {
            PolkitService.submit(password);
        }
        function cancel(): void {
            PolkitService.cancel();
        }
    }

    IpcHandler {
        target: "session"
        function toggle(): void {
            SessionService.toggle();
        }
        function open(): void {
            SessionService.open();
        }
        function close(): void {
            SessionService.close();
        }
        function next(): void {
            SessionService.next();
        }
        function prev(): void {
            SessionService.prev();
        }
        function lock(): void {
            SessionService.lock();
        }
        function suspend(): void {
            SessionService.suspend();
        }
        function logout(): void {
            SessionService.logout();
        }
        function reboot(): void {
            SessionService.reboot();
        }
        function shutdown(): void {
            SessionService.shutdown();
        }
    }

    LockWindow {}

    Variants {
        model: Quickshell.screens
        WallpaperWindow {}
    }

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Variants {
        model: Quickshell.screens
        FullscreenIslandOsd {}
    }

    Variants {
        model: Quickshell.screens
        WindowSwitcher {}
    }

    Variants {
        model: Quickshell.screens
        SessionWindow {}
    }
}

