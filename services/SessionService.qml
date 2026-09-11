pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "root:services"

Item {
    id: root

    property bool isOpen: false
    property int focusedIndex: 0 // 0: Bloquear, 1: Suspender, 2: Salir, 3: Reiniciar, 4: Apagar

    readonly property string rawUser: Quickshell.env("USER") || "daniel"
    readonly property string userName: rawUser.length > 0 ? (rawUser.charAt(0).toUpperCase() + rawUser.slice(1)) : "Usuario"
    property string uptimeText: "Iniciando..."

    Process {
        id: uptimeProc
        command: ["cat", "/proc/uptime"]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(" ");
                if (parts.length > 0) {
                    let totalSec = Math.floor(parseFloat(parts[0]));
                    if (!isNaN(totalSec)) {
                        let days = Math.floor(totalSec / 86400);
                        let hours = Math.floor((totalSec % 86400) / 3600);
                        let mins = Math.floor((totalSec % 3600) / 60);
                        let res = "";
                        if (days > 0) res += `${days}d `;
                        if (hours > 0 || days > 0) res += `${hours}h `;
                        res += `${mins}m activo`;
                        root.uptimeText = res;
                    }
                }
            }
        }
    }

    Timer {
        id: uptimeTimer
        interval: 30000
        repeat: true
        running: root.isOpen
        onTriggered: {
            if (!uptimeProc.running) uptimeProc.running = true;
        }
    }

    Process {
        id: sysActionProc
        stderr: SplitParser {
            onRead: data => {
                let text = data.trim();
                if (text) {
                    console.warn("SessionService: sysActionProc error:", text);
                }
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("SessionService: sysActionProc exited with code:", exitCode);
            }
        }
    }

    function runSysCommand(cmd) {
        root.close();
        if (sysActionProc.running) sysActionProc.running = false;
        sysActionProc.command = cmd;
        sysActionProc.running = true;
    }

    function open() {
        if (!uptimeProc.running) uptimeProc.running = true;
        focusedIndex = 0;
        isOpen = true;
    }

    function close() {
        isOpen = false;
    }

    function toggle() {
        if (isOpen) {
            close();
        } else {
            open();
        }
    }

    function next() {
        focusedIndex = (focusedIndex + 1) % 5;
    }

    function prev() {
        focusedIndex = (focusedIndex + 4) % 5;
    }

    function lock() {
        root.close();
        LockService.lock();
    }

    function suspend() {
        runSysCommand(["systemctl", "suspend"]);
    }

    function logout() {
        runSysCommand([
            "sh",
            "-c",
            "if command -v uwsm >/dev/null 2>&1 && uwsm check is-active 2>/dev/null; then " +
            "uwsm stop; " +
            "elif command -v hyprctl >/dev/null 2>&1; then " +
            "hyprctl dispatch 'hl.dsp.exit()' 2>/dev/null || hyprctl dispatch exit; " +
            "elif [ -n \"$XDG_SESSION_ID\" ]; then " +
            "loginctl terminate-session \"$XDG_SESSION_ID\"; " +
            "else " +
            "loginctl terminate-user \"$USER\"; " +
            "fi"
        ]);
    }

    function reboot() {
        runSysCommand(["systemctl", "reboot"]);
    }

    function shutdown() {
        runSysCommand(["systemctl", "poweroff"]);
    }

    function triggerCurrent() {
        switch (focusedIndex) {
            case 0: lock(); break;
            case 1: suspend(); break;
            case 2: logout(); break;
            case 3: reboot(); break;
            case 4: shutdown(); break;
        }
    }

    Component.onCompleted: {
        if (!uptimeProc.running) uptimeProc.running = true;
    }
}
