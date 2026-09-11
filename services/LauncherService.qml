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

    // Lista filtrada de aplicaciones según searchQuery
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

    // Evaluador matemático seguro y preciso
    function evaluateMath(str) {
        if (!str) return null;
        let s = str.trim();
        if (s.startsWith("=")) {
            s = s.substring(1).trim();
        }
        if (!s) return null;

        // Debe contener al menos un dígito o constantes matemáticas (pi, e)
        if (!/[0-9]/.test(s) && !/(?:pi|e)\b/i.test(s)) return null;

        // Verificar que no contenga palabras ajenas a matemáticas
        let testStr = s.toLowerCase()
                       .replace(/\b(?:sqrt|abs|sin|cos|tan|log|ln|pi|e|of)\b/g, "")
                       .replace(/[\d\s+\-*\/%^().,x]/g, "");
        if (testStr.length > 0) return null;

        // Debe contener algún operador, función matemática o haber iniciado con '='
        let hasOp = /[\+\-\*\/\%\^x]|(?:sqrt|abs|sin|cos|tan|log|ln|of)\b/i.test(s) || str.trim().startsWith("=");
        if (!hasOp) return null;

        try {
            let clean = s.toLowerCase();
            clean = clean.replace(/(\d+(?:\.\d+)?)\s*%\s*of\s*(\d+(?:\.\d+)?)/g, "($1/100)*$2");
            clean = clean.replace(/(\d+(?:\.\d+)?)\s*%/g, "($1/100)");
            clean = clean.replace(/(\d|\))\s*[xX]\s*(\d|\()/g, "$1 * $2");
            clean = clean.replace(/\^/g, "**");
            clean = clean.replace(/\bpi\b/g, "Math.PI");
            clean = clean.replace(/\be\b/g, "Math.E");
            clean = clean.replace(/\bsqrt\b/g, "Math.sqrt");
            clean = clean.replace(/\babs\b/g, "Math.abs");
            clean = clean.replace(/\bsin\b/g, "Math.sin");
            clean = clean.replace(/\bcos\b/g, "Math.cos");
            clean = clean.replace(/\btan\b/g, "Math.tan");
            clean = clean.replace(/\blog\b/g, "Math.log10");
            clean = clean.replace(/\bln\b/g, "Math.log");

            if (!/^[0-9\s+\-*\/().,MathPIEsqrtabscostanlogn]+$/.test(clean)) return null;

            let fn = new Function("\"use strict\"; return (" + clean + ")");
            let val = fn();
            if (typeof val !== "number" || !isFinite(val) || isNaN(val)) return null;

            let strVal = Number.isInteger(val) ? val.toLocaleString("en-US") : parseFloat(val.toFixed(8)).toString();
            let copyVal = Number.isInteger(val) ? val.toString() : parseFloat(val.toFixed(8)).toString();
            return { resultStr: strVal, copyStr: copyVal, expression: s };
        } catch (e) {
            return null;
        }
    }

    // Lista Maestra Spotlight: Combina Cálculos, Comandos directos, Búsqueda Web y Apps
    readonly property var filteredItems: {
        let q = searchQuery.trim();
        let qLower = q.toLowerCase();
        let items = [];

        // 1. Detección de operaciones matemáticas
        let mathRes = evaluateMath(q);
        if (mathRes) {
            items.push({
                isSpecial: true,
                specialType: "calc",
                name: "= " + mathRes.resultStr,
                comment: "Calculator • Press Enter to copy (" + mathRes.expression + ")",
                iconGlyph: "󰃬",
                copyValue: mathRes.copyStr,
                badge: "↵ Copy"
            });
        }

        // 2. Comandos directos de terminal (> o :)
        if (q.startsWith(">") || q.startsWith(":")) {
            let cmd = q.substring(1).trim();
            if (cmd.length > 0) {
                items.push({
                    isSpecial: true,
                    specialType: "cmd",
                    name: "Run: " + cmd,
                    comment: "Execute in terminal (" + preferredTerminal + ")",
                    iconGlyph: "󰆍",
                    commandValue: cmd,
                    badge: "↵ Run"
                });
            }
            return items;
        }

        // 3. Búsqueda web explícita (? o g o web o d / ddg)
        if (q.startsWith("?") || qLower.startsWith("g ") || qLower.startsWith("web ") || qLower.startsWith("d ") || qLower.startsWith("ddg ")) {
            let query = "";
            let isDdg = qLower.startsWith("d ") || qLower.startsWith("ddg ");
            if (q.startsWith("?")) query = q.substring(1).trim();
            else if (qLower.startsWith("g ")) query = q.substring(2).trim();
            else if (qLower.startsWith("d ")) query = q.substring(2).trim();
            else if (qLower.startsWith("ddg ")) query = q.substring(4).trim();
            else query = q.substring(4).trim(); // "web "

            if (query.length > 0) {
                let targetUrl = isDdg
                    ? ("https://duckduckgo.com/?q=" + encodeURIComponent(query))
                    : ("https://www.google.com/search?q=" + encodeURIComponent(query));
                items.push({
                    isSpecial: true,
                    specialType: "web",
                    name: "Search: \"" + query + "\"",
                    comment: isDdg ? "Search DuckDuckGo in default browser" : "Search Google in default browser",
                    iconGlyph: "󰇧",
                    urlValue: targetUrl,
                    badge: "↵ Search"
                });
            }
            return items;
        }

        // 4. Aplicaciones coincidentes
        let apps = filteredApplications;
        for (let i = 0; i < apps.length; i++) {
            items.push(apps[i]);
        }

        // 5. Opciones de rescate si no hay aplicaciones y la consulta tiene al menos 2 caracteres
        if (apps.length === 0 && q.length >= 2 && !mathRes) {
            items.push({
                isSpecial: true,
                specialType: "web",
                name: "Search Google for \"" + q + "\"",
                comment: "Open Google in default browser",
                iconGlyph: "󰇧",
                urlValue: "https://www.google.com/search?q=" + encodeURIComponent(q),
                badge: "↵ Search"
            });
            items.push({
                isSpecial: true,
                specialType: "cmd",
                name: "Run \"" + q + "\" in terminal",
                comment: "Execute in " + preferredTerminal,
                iconGlyph: "󰆍",
                commandValue: q,
                badge: "↵ Run"
            });
        }

        return items;
    }

    onSearchQueryChanged: {
        selectedIndex = 0;
    }

    onFilteredItemsChanged: {
        if (selectedIndex >= filteredItems.length) {
            selectedIndex = Math.max(0, filteredItems.length - 1);
        }
    }

    function toggle() {
        let otherModalOpen = (typeof ClipboardService !== "undefined" && ClipboardService && ClipboardService.isOpen) ||
                             (typeof NotificationService !== "undefined" && NotificationService && NotificationService.isCenterOpen) ||
                             (typeof ControlCenterService !== "undefined" && ControlCenterService && ControlCenterService.isOpen);
        if (root.isOpen && !otherModalOpen) {
            root.close();
        } else {
            root.open();
        }
    }

    function open() {
        if (typeof ClipboardService !== "undefined" && ClipboardService && ClipboardService.isOpen) {
            ClipboardService.close();
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
        let count = filteredItems.length;
        if (count <= 0) return;
        selectedIndex = (selectedIndex + 1) % count;
    }

    function prevItem() {
        let count = filteredItems.length;
        if (count <= 0) return;
        selectedIndex = (selectedIndex - 1 + count) % count;
    }

    function launchCurrent() {
        let list = filteredItems;
        if (list.length > 0 && selectedIndex >= 0 && selectedIndex < list.length) {
            launchItem(list[selectedIndex]);
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

    Process {
        id: copyProc
    }

    Process {
        id: xdgOpenProc
    }

    function launchItem(item) {
        if (!item) return;

        if (item.isSpecial) {
            if (item.specialType === "calc") {
                copyProc.command = ["wl-copy", "--", item.copyValue.toString()];
                if (copyProc.running) copyProc.running = false;
                copyProc.running = true;
                root.appLaunched();
                root.close();
                return;
            } else if (item.specialType === "cmd") {
                let c = (item.commandValue || "").trim();
                let firstWord = c.split(/\s+/)[0].toLowerCase();
                if (firstWord.includes("/")) {
                    firstWord = firstWord.substring(firstWord.lastIndexOf("/") + 1);
                }

                // Programas TUI interactivos que ya gestionan su propio ciclo de vida a pantalla completa
                let interactiveTuis = [
                    "btop", "htop", "top", "nvtop", "ranger", "yazi", "mc", 
                    "nvim", "vim", "vi", "nano", "micro", "lazygit", "ncdu", "cmatrix"
                ];

                let fullCmd;
                if (interactiveTuis.indexOf(firstWord) !== -1) {
                    fullCmd = ["setsid", "-f", root.preferredTerminal, "-e", "bash", "-c", c];
                } else {
                    // Para comandos con salida de texto (ej. nvidia-smi, fastfetch, sensors, ls, ping):
                    // Muestra el resultado, permite leerlo con calma y presionar cualquier tecla para salir o Enter para quedarse en una shell interactiva
                    let pauseScript = c + "; echo; echo -e '\\e[90m──────────────────────────────────────────────\\e[0m'; echo -e '\\e[36mPress any key to close, or [Enter] for a shell...\\e[0m'; IFS= read -r -s -n 1 k; if [[ \"$k\" == $'\\n' || \"$k\" == $'\\r' || -z \"$k\" ]]; then echo; exec bash; fi";
                    fullCmd = ["setsid", "-f", root.preferredTerminal, "-e", "bash", "-c", pauseScript];
                }

                terminalAppProc.command = fullCmd;
                if (terminalAppProc.running) terminalAppProc.running = false;
                terminalAppProc.running = true;
                root.appLaunched();
                root.close();
                return;
            } else if (item.specialType === "web") {
                xdgOpenProc.command = ["xdg-open", item.urlValue];
                if (xdgOpenProc.running) xdgOpenProc.running = false;
                xdgOpenProc.running = true;
                root.appLaunched();
                root.close();
                return;
            }
        }

        // Aplicación normal
        launchApp(item);
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
