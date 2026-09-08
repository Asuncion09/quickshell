pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool isOpen: false
    property string searchQuery: ""
    property int selectedIndex: 0

    signal appLaunched()

    // Resuelve todas las aplicaciones instaladas en el sistema (.desktop)
    readonly property var allApplications: {
        if (typeof DesktopEntries === "undefined" || !DesktopEntries || !DesktopEntries.applications || !DesktopEntries.applications.values) {
            return [];
        }
        let raw = DesktopEntries.applications.values;
        let list = [];
        for (let i = 0; i < raw.length; i++) {
            let app = raw[i];
            if (app && !app.noDisplay && app.name && app.name.trim() !== "") {
                list.push(app);
            }
        }
        list.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        return list;
    }

    // Lista filtrada en tiempo real según searchQuery
    readonly property var filteredApplications: {
        let q = searchQuery.trim().toLowerCase();
        if (!q) return allApplications;

        let exactMatches = [];
        let prefixMatches = [];
        let containsMatches = [];

        for (let i = 0; i < allApplications.length; i++) {
            let app = allApplications[i];
            let name = (app.name || "").toLowerCase();
            let generic = (app.genericName || "").toLowerCase();
            let comment = (app.comment || "").toLowerCase();
            let exec = (app.execString || "").toLowerCase();

            if (name === q) {
                exactMatches.push(app);
            } else if (name.startsWith(q)) {
                prefixMatches.push(app);
            } else if (name.includes(q) || generic.includes(q) || comment.includes(q) || exec.includes(q)) {
                containsMatches.push(app);
            }
        }

        return exactMatches.concat(prefixMatches).concat(containsMatches);
    }

    onSearchQueryChanged: {
        selectedIndex = 0;
    }

    function toggle() {
        if (root.isOpen) {
            root.close();
        } else {
            root.open();
        }
    }

    function open() {
        if (ControlCenterService.isOpen) {
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
        let count = filteredApplications.length;
        if (count <= 0) return;
        selectedIndex = (selectedIndex + 1) % count;
    }

    function prevItem() {
        let count = filteredApplications.length;
        if (count <= 0) return;
        selectedIndex = (selectedIndex - 1 + count) % count;
    }

    function launchCurrent() {
        let list = filteredApplications;
        if (list.length > 0 && selectedIndex >= 0 && selectedIndex < list.length) {
            launchApp(list[selectedIndex]);
        }
    }

    readonly property string preferredTerminal: {
        let envTerm = Quickshell.env("TERMINAL");
        if (envTerm && envTerm.trim() !== "") return envTerm.trim();
        return "ghostty";
    }

    Process {
        id: terminalAppProc
    }

    function launchApp(app) {
        if (!app) return;

        // Si la aplicación requiere terminal (Terminal=true en el .desktop, como btop o htop),
        // Quickshell nativamente no provee terminal interactiva, por lo que la ejecutamos en Ghostty.
        if (app.runInTerminal) {
            let cmd = ["setsid", "-f", root.preferredTerminal, "-e"];
            if (app.command && app.command.length > 0) {
                cmd = cmd.concat(app.command);
            } else if (app.execString) {
                let cleanExec = app.execString.replace(/%[a-zA-Z]/g, "").trim();
                cmd = cmd.concat(cleanExec.split(/\s+/));
            } else {
                cmd.push((app.name || "").toLowerCase());
            }

            terminalAppProc.command = cmd;
            if (terminalAppProc.running) terminalAppProc.running = false;
            terminalAppProc.running = true;
            root.appLaunched();
            root.close();
            return;
        }

        // Aplicaciones gráficas (GUI) normales
        if (app.execute) {
            app.execute();
            root.appLaunched();
            root.close();
        }
    }
}
