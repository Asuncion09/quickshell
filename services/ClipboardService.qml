pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool isOpen: false
    property string searchQuery: ""
    property int selectedIndex: 0

    property var history: []
    readonly property int count: history.length
    readonly property bool hasItems: count > 0

    readonly property var filteredHistory: {
        let q = searchQuery.trim().toLowerCase();
        if (!q) return history;

        let matches = [];
        for (let i = 0; i < history.length; i++) {
            let item = history[i];
            if (!item) continue;
            let text = (item.text || "").toLowerCase();
            let preview = (item.preview || "").toLowerCase();
            let type = (item.type || "").toLowerCase();

            if (text.includes(q) || preview.includes(q) || type.includes(q)) {
                matches.push(item);
            }
        }
        return matches;
    }

    onSearchQueryChanged: {
        selectedIndex = 0;
    }

    onFilteredHistoryChanged: {
        if (selectedIndex >= filteredHistory.length) {
            selectedIndex = Math.max(0, filteredHistory.length - 1);
        }
    }

    function toggle() {
        let otherModalOpen = (typeof LauncherService !== "undefined" && LauncherService && LauncherService.isOpen) ||
                             (typeof NotificationService !== "undefined" && NotificationService && NotificationService.isCenterOpen) ||
                             (typeof ControlCenterService !== "undefined" && ControlCenterService && ControlCenterService.isOpen);
        if (root.isOpen && !otherModalOpen) {
            root.close();
        } else {
            root.open();
        }
    }

    function open() {
        if (typeof LauncherService !== "undefined" && LauncherService && LauncherService.isOpen) {
            LauncherService.close();
        }
        if (typeof NotificationService !== "undefined" && NotificationService) {
            if (NotificationService.isCenterOpen) NotificationService.closeCenter();
            NotificationService.dismissToast();
        }
        if (typeof ControlCenterService !== "undefined" && ControlCenterService && ControlCenterService.isOpen) {
            ControlCenterService.close();
        }
        root.searchQuery = "";
        root.selectedIndex = 0;
        root.isOpen = true;
    }

    function close() {
        root.isOpen = false;
        root.searchQuery = "";
        root.selectedIndex = 0;
    }

    function nextItem() {
        let total = filteredHistory.length;
        if (total <= 0) return;
        selectedIndex = (selectedIndex + 1) % total;
    }

    function prevItem() {
        let total = filteredHistory.length;
        if (total <= 0) return;
        selectedIndex = (selectedIndex - 1 + total) % total;
    }

    function selectIndex(idx) {
        let list = filteredHistory;
        if (idx >= 0 && idx < list.length) {
            let item = list[idx];
            if (item && item.text) {
                sendCmd({ action: "copy", text: item.text });
            }
            root.close();
        }
    }

    function selectCurrent() {
        selectIndex(selectedIndex);
    }

    function deleteItem(itemId) {
        if (!itemId) return;
        sendCmd({ action: "delete", id: itemId });

        // Actualización optimista de UI
        let list = root.history.slice();
        let idx = list.findIndex(h => h.id === itemId);
        if (idx !== -1) {
            list.splice(idx, 1);
            root.history = list;
        }
    }

    function clearAll() {
        sendCmd({ action: "clear" });
        root.history = [];
        root.selectedIndex = 0;
    }

    function sendCmd(cmdObj) {
        try {
            clipDaemonProc.write(JSON.stringify(cmdObj) + "\n");
        } catch (e) {
            console.error("[ClipboardService] Error enviando comando al daemon:", e);
        }
    }

    Timer {
        id: restartTimer
        interval: 1500
        repeat: false
        onTriggered: {
            console.warn("[ClipboardService] Reiniciando daemon de portapapeles...");
            clipDaemonProc.running = true;
        }
    }

    Process {
        id: clipDaemonProc
        command: ["python3", Qt.resolvedUrl("clip_daemon.py").toString().replace(/^file:\/\//, "")]
        stdinEnabled: true
        running: true

        stdout: SplitParser {
            onRead: data => {
                let line = data.trim();
                if (!line) return;
                try {
                    let msg = JSON.parse(line);
                    if (msg.type === "init") {
                        root.history = msg.items || [];
                    } else if (msg.type === "add" && msg.item) {
                        let list = root.history.slice();
                        // Filtrar posible duplicado si ya estaba
                        list = list.filter(h => h.id !== msg.item.id && h.text !== msg.item.text);
                        list.unshift(msg.item);
                        if (list.length > 50) {
                            list = list.slice(0, 50);
                        }
                        root.history = list;
                    } else if (msg.type === "removed" && msg.id) {
                        let list = root.history.slice();
                        root.history = list.filter(h => h.id !== msg.id);
                    } else if (msg.type === "cleared") {
                        root.history = [];
                    }
                } catch (e) {
                    console.error("[ClipboardService] Error parseando mensaje del daemon:", e, line);
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            console.warn("[ClipboardService] clip_daemon.py terminó con código", exitCode, "estado", exitStatus);
            restartTimer.restart();
        }
    }
}
