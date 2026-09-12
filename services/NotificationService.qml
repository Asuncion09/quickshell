pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Hyprland

Item {
    id: root

    Component.onCompleted: {
        console.log("[NotificationService] Singleton INICIALIZADO correctamente");
    }

    // --- Configuración de Sonidos de Notificación ---
    property bool soundEnabled: true
    property string defaultSoundPath: "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"

    // Procesos alternados para evitar colisiones o bloqueos cuando llegan notificaciones continuas
    property int _soundProcTurn: 0
    Process {
        id: soundProc1
    }
    Process {
        id: soundProc2
    }

    function playSound(customPath) {
        if (!root.soundEnabled) return;
        let file = (customPath && customPath !== "") ? customPath : root.defaultSoundPath;

        let proc = (root._soundProcTurn === 0) ? soundProc1 : soundProc2;
        root._soundProcTurn = (root._soundProcTurn + 1) % 2;

        if (proc.running) proc.running = false;
        // Reproducir como flujo de evento (media.role=event) para que se mezcle con la música sin cortes
        if (customPath && customPath !== "") {
            proc.command = ["sh", "-c", "canberra-gtk-play -f \"" + file + "\" 2>/dev/null || paplay --property=media.role=event \"" + file + "\""];
        } else {
            proc.command = ["sh", "-c", "canberra-gtk-play -i message-new-instant 2>/dev/null || paplay --property=media.role=event \"" + root.defaultSoundPath + "\""];
        }
        proc.running = true;
    }

    // Estado de la interfaz
    property bool isCenterOpen: false
    property bool dnd: false

    // Notificación actual para la Dynamic Island (Toast efímero)
    property var currentToast: null
    property bool isToastExpanded: false
    property string targetMonitor: ""
    readonly property bool isToastActive: currentToast !== null && !isCenterOpen && !isLauncherOpen && !isClipboardOpen

    function updateTargetMonitor() {
        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) {
            root.targetMonitor = Hyprland.focusedMonitor.name;
            return;
        }
        if (Hyprland.monitors && Hyprland.monitors.values) {
            for (let i = 0; i < Hyprland.monitors.values.length; i++) {
                let m = Hyprland.monitors.values[i];
                if (m && m.focused && m.name) {
                    root.targetMonitor = m.name;
                    return;
                }
            }
        }
        root.targetMonitor = "";
    }

    // Comprobación segura de estado de Launcher y Clipboard
    readonly property bool isLauncherOpen: {
        return (typeof LauncherService !== "undefined" && LauncherService && LauncherService.isOpen);
    }
    readonly property bool isClipboardOpen: {
        return (typeof ClipboardService !== "undefined" && ClipboardService && ClipboardService.isOpen);
    }

    // Lista de notificaciones activas (más recientes al principio)
    property var notifications: []
    readonly property int count: notifications.length
    readonly property bool hasNotifications: count > 0

    // Temporizador para actualizar los tiempos relativos cada 30 segundos
    property int _ticker: 0
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root._ticker++
    }

    // Temporizador de cortesía de 4 segundos para el toast emergente
    Timer {
        id: toastTimer
        interval: 4000
        onTriggered: {
            root.isToastExpanded = false;
            root.currentToast = null;
            root.targetMonitor = "";
        }
    }

    function pauseToast() {
        toastTimer.stop();
    }

    function resumeToast() {
        if (root.currentToast && !root.isToastExpanded) {
            toastTimer.interval = 3500;
            toastTimer.restart();
        } else if (root.currentToast && root.isToastExpanded) {
            toastTimer.interval = 6000;
            toastTimer.restart();
        }
    }

    Connections {
        target: OsdService
        function onIsVisibleChanged() {
            if (OsdService.isVisible) {
                root.pauseToast();
            } else {
                root.resumeToast();
            }
        }
    }

    function expandToast() {
        if (!root.currentToast) return;
        root.isToastExpanded = true;
        root.pauseToast();
    }

    function collapseToast() {
        root.isToastExpanded = false;
        root.resumeToast();
    }

    function dismissToast() {
        toastTimer.stop();
        root.isToastExpanded = false;
        root.currentToast = null;
        root.targetMonitor = "";
    }

    function toggleDnd() {
        root.dnd = !root.dnd;
    }

    function resolveAppIcon(iconName, desktopEntry, appName) {
        if (iconName && iconName !== "") {
            if (iconName.startsWith("/") || iconName.startsWith("file://")) return iconName;
            if (Quickshell.hasThemeIcon(iconName)) return Quickshell.iconPath(iconName);
            let lower = iconName.toLowerCase();
            if (Quickshell.hasThemeIcon(lower)) return Quickshell.iconPath(lower);
        }
        if (desktopEntry && desktopEntry !== "") {
            if (Quickshell.hasThemeIcon(desktopEntry)) return Quickshell.iconPath(desktopEntry);
            let dLower = desktopEntry.toLowerCase();
            if (Quickshell.hasThemeIcon(dLower)) return Quickshell.iconPath(dLower);
        }
        if (appName && appName !== "") {
            let aLower = appName.toLowerCase();
            if (Quickshell.hasThemeIcon(aLower)) return Quickshell.iconPath(aLower);

            // Detección para Antigravity IDE, VS Code y editores de código
            if (aLower.includes("antigravity") || aLower.includes("code") || aLower.includes("vscode")) {
                if (Quickshell.hasThemeIcon("com.visualstudio.code")) return Quickshell.iconPath("com.visualstudio.code");
                if (Quickshell.hasThemeIcon("visual-studio-code")) return Quickshell.iconPath("visual-studio-code");
                if (Quickshell.hasThemeIcon("vscode")) return Quickshell.iconPath("vscode");
                if (Quickshell.hasThemeIcon("com.visualstudio.code-oss")) return Quickshell.iconPath("com.visualstudio.code-oss");
                return "/home/daniel/Downloads/Antigravity IDE/resources/app/resources/linux/code.png";
            }
            if (aLower.includes("term") || aLower.includes("bash") || aLower.includes("shell") || aLower.includes("kitty") || aLower.includes("alacritty")) {
                if (Quickshell.hasThemeIcon("utilities-terminal")) return Quickshell.iconPath("utilities-terminal");
            }
        }
        if (Quickshell.hasThemeIcon("dialog-information")) return Quickshell.iconPath("dialog-information");
        if (Quickshell.hasThemeIcon("preferences-desktop-notification")) return Quickshell.iconPath("preferences-desktop-notification");
        if (Quickshell.hasThemeIcon("notification-symbolic")) return Quickshell.iconPath("notification-symbolic");
        return "";
    }

    function handleNotification(notif) {
        if (!notif) return;
        console.warn("[NotificationService] Recibida notificación:", notif.id, notif.appName, notif.summary);

        // Mantener la notificación viva en el servidor hasta que se descarte
        notif.tracked = true;

        let lowerApp = (notif.appName || "").toLowerCase();
        let lowerSum = (notif.summary || "").toLowerCase();
        let lowerBody = (notif.body || "").toLowerCase();

        let isScreenshot = false;
        if (lowerApp.includes("hyprshot") || lowerApp.includes("grimblast") || lowerApp.includes("screenshot") ||
            lowerSum.includes("screenshot") || lowerSum.includes("captura") ||
            lowerBody.includes("image saved") || lowerBody.includes("imagen guardada")) {
            isScreenshot = true;
        }

        let screenshotPath = "";
        if (notif.appIcon && (notif.appIcon.startsWith("/") || notif.appIcon.startsWith("file://"))) {
            let cleanIcon = notif.appIcon.replace(/^file:\/\//, "");
            if (cleanIcon.match(/\.(png|jpg|jpeg|webp)$/i)) {
                screenshotPath = cleanIcon;
            }
        }
        if (!screenshotPath && notif.image && (notif.image.startsWith("/") || notif.image.startsWith("file://"))) {
            screenshotPath = notif.image.replace(/^file:\/\//, "");
        }
        if (!screenshotPath && notif.body) {
            let m = notif.body.match(/<i>(.*?)<\/i>/);
            if (m && m[1] && (m[1].startsWith("/") || m[1].startsWith("file://"))) {
                screenshotPath = m[1].replace(/^file:\/\//, "");
            } else {
                let m2 = notif.body.match(/(\/[^\s<"']+\.(png|jpg|jpeg|webp))/i);
                if (m2 && m2[1]) {
                    screenshotPath = m2[1];
                }
            }
        }

        if (screenshotPath !== "") {
            isScreenshot = true;
        }

        // Detección de Selector de Color (hyprpicker / color picker)
        let isColorPicker = false;
        let pickedColor = "";

        if (lowerApp.includes("hyprpicker") || lowerApp.includes("color picker") || lowerApp.includes("colorpicker") ||
            lowerSum.includes("color picker") || lowerSum.includes("colorpicker") || lowerSum.includes("hyprpicker") ||
            lowerSum.includes("gotero") || lowerSum.includes("selector de color") ||
            lowerBody.includes("color picker") || lowerBody.includes("hyprpicker")) {
            isColorPicker = true;
        }

        let hexMatch = (notif.body || "").match(/#([0-9a-fA-F]{6}|[0-9a-fA-F]{8}|[0-9a-fA-F]{3})\b/) ||
                       (notif.summary || "").match(/#([0-9a-fA-F]{6}|[0-9a-fA-F]{8}|[0-9a-fA-F]{3})\b/);
        if (hexMatch) {
            pickedColor = hexMatch[0].toUpperCase();
            isColorPicker = true;
        } else if (isColorPicker) {
            let bodyTrimmed = (notif.body || "").trim();
            if (bodyTrimmed.startsWith("#") || bodyTrimmed.startsWith("rgb")) {
                pickedColor = bodyTrimmed;
            } else {
                let sumTrimmed = (notif.summary || "").trim();
                if (sumTrimmed.startsWith("#") || sumTrimmed.startsWith("rgb")) {
                    pickedColor = sumTrimmed;
                }
            }
        }

        let pickedRgb = root.hexToRgb(pickedColor);

        let icon = isScreenshot ? "󰹑" : (isColorPicker ? "󰈊" : resolveAppIcon(notif.appIcon, notif.desktopEntry, notif.appName));
        let item = {
            id: notif.id,
            ref: notif,
            appName: isScreenshot ? "Hyprshot" : (isColorPicker ? "Color Picker" : (notif.appName && notif.appName !== "" ? notif.appName : "Sistema")),
            appIcon: icon,
            summary: isColorPicker ? (pickedColor !== "" ? pickedColor : "Color copiado") : (notif.summary || ""),
            body: notif.body || "",
            urgency: notif.urgency, // 0: Low, 1: Normal, 2: Critical
            image: notif.image || "",
            actions: isColorPicker ? [] : (notif.actions || []),
            timestamp: Date.now(),
            isScreenshot: isScreenshot,
            screenshotPath: screenshotPath,
            isColorPicker: isColorPicker,
            pickedColor: pickedColor,
            pickedRgb: pickedRgb
        };

        // Escuchar si la aplicación emisora cierra la notificación externamente
        try {
            notif.closed.connect(function() {
                root.removeNotification(notif.id);
            });
        } catch (e) {
            // Ignorar si la señal ya estaba conectada
        }

        // Si ya existe en la lista (reemplazo/actualización), sustituirlo
        let list = root.notifications.slice();
        let existingIdx = list.findIndex(n => n.id === notif.id);
        if (existingIdx !== -1) {
            list[existingIdx] = item;
        } else {
            list.unshift(item);
        }
        root.notifications = list;

        // Mostrar Toast si no está en modo DND (No Molestar) o si es urgente/crítica
        // También omitir si el centro de notificaciones ya está abierto
        if (!root.isCenterOpen && (!root.dnd || notif.urgency === 2)) {
            root.updateTargetMonitor();
            if (isScreenshot && screenshotPath !== "") {
                root.isToastExpanded = true;
                root.currentToast = item;
                toastTimer.interval = 8000;
                toastTimer.restart();
            } else if (isScreenshot && screenshotPath === "") {
                // Captura directa al portapapeles (--clipboard-only): píldora compacta de confirmación
                root.isToastExpanded = false;
                root.currentToast = item;
                toastTimer.interval = 3500;
                toastTimer.restart();
            } else {
                root.isToastExpanded = false;
                root.currentToast = item;
                toastTimer.interval = 4000;
                toastTimer.restart();
            }
        }

        // Reproducir sonido si está habilitado y no está en DND (o si es urgente/crítica)
        // Omitir sonido en avisos de cambio de pista musical de Spotify/reproductores para no interrumpir la música
        let isMusicPlayer = notif.appName && (notif.appName.toLowerCase() === "spotify" || notif.appName.toLowerCase() === "playerctl");
        if (root.soundEnabled && (!root.dnd || notif.urgency === 2) && !isMusicPlayer) {
            root.playSound();
        }
    }

    // Permite que servicios internos del sistema (como la batería) emitan notificaciones limpias
    function postInternalNotification(appName, summary, body, urgency, icon, customSound) {
        let notifId = Math.floor(Math.random() * 100000) + 900000;
        let item = {
            id: notifId,
            ref: null,
            appName: appName || "System",
            appIcon: icon || resolveAppIcon("", "", appName),
            summary: summary || "",
            body: body || "",
            urgency: urgency !== undefined ? urgency : 1,
            image: "",
            actions: [],
            timestamp: Date.now()
        };

        let list = root.notifications.slice();
        list.unshift(item);
        root.notifications = list;

        if (!root.isCenterOpen && (!root.dnd || urgency === 2)) {
            root.updateTargetMonitor();
            root.isToastExpanded = false;
            root.currentToast = item;
            toastTimer.restart();
        }

        if (root.soundEnabled && (!root.dnd || urgency === 2)) {
            root.playSound(customSound);
        }
    }

    function removeNotification(id) {
        let list = root.notifications.slice();
        let idx = list.findIndex(n => n.id === id);
        if (idx !== -1) {
            list.splice(idx, 1);
            root.notifications = list;
        }
        if (root.currentToast && root.currentToast.id === id) {
            root.dismissToast();
        }
    }

    function dismiss(id) {
        let list = root.notifications.slice();
        let idx = list.findIndex(n => n.id === id);
        if (idx !== -1) {
            let item = list[idx];
            try {
                if (item.ref && typeof item.ref.dismiss === "function") {
                    item.ref.dismiss();
                }
            } catch (e) {
                console.log("[NotificationService] Error en dismiss:", e);
            }
            list.splice(idx, 1);
            root.notifications = list;
        }
        if (root.currentToast && root.currentToast.id === id) {
            root.dismissToast();
        }
    }

    function clearAll() {
        let list = root.notifications.slice();
        for (let i = 0; i < list.length; i++) {
            try {
                if (list[i].ref && typeof list[i].ref.dismiss === "function") {
                    list[i].ref.dismiss();
                }
            } catch (e) {
                console.log("[NotificationService] Error al limpiar:", e);
            }
        }
        root.notifications = [];
        root.dismissToast();
    }

    Process {
        id: screenshotProc
    }

    function openScreenshot(path) {
        if (!path) return;
        let p = path.replace(/^file:\/\//, "");
        if (screenshotProc.running) screenshotProc.running = false;
        screenshotProc.command = ["sh", "-c", "xdg-open \"" + p + "\" 2>/dev/null || loupe \"" + p + "\""];
        screenshotProc.running = true;
        root.dismissToast();
    }

    function copyScreenshotImage(path) {
        if (!path) return;
        let p = path.replace(/^file:\/\//, "");
        if (screenshotProc.running) screenshotProc.running = false;
        screenshotProc.command = ["sh", "-c", "wl-copy --type image/png < \"" + p + "\""];
        screenshotProc.running = true;
    }

    function deleteScreenshot(id, path) {
        if (path) {
            let p = path.replace(/^file:\/\//, "");
            if (screenshotProc.running) screenshotProc.running = false;
            screenshotProc.command = ["sh", "-c", "rm -f \"" + p + "\""];
            screenshotProc.running = true;
        }
        root.dismiss(id);
    }

    function hexToRgb(hex) {
        if (!hex || typeof hex !== "string") return "";
        let clean = hex.trim().replace(/^#/, "");
        if (clean.length === 3) {
            clean = clean[0] + clean[0] + clean[1] + clean[1] + clean[2] + clean[2];
        }
        if (clean.length >= 6) {
            let r = parseInt(clean.substring(0, 2), 16);
            let g = parseInt(clean.substring(2, 4), 16);
            let b = parseInt(clean.substring(4, 6), 16);
            if (!isNaN(r) && !isNaN(g) && !isNaN(b)) {
                return "rgb(" + r + ", " + g + ", " + b + ")";
            }
        }
        return "";
    }

    Process {
        id: clipCopyProc
    }

    function copyText(text) {
        if (!text) return;
        if (clipCopyProc.running) clipCopyProc.running = false;
        clipCopyProc.command = ["wl-copy", text];
        clipCopyProc.running = true;
    }

    Process {
        id: hyprFocusProc
        stdout: SplitParser {
            onRead: data => console.warn("[NotificationService] hyprFocusProc stdout:", data.trim())
        }
        stderr: SplitParser {
            onRead: data => console.warn("[NotificationService] hyprFocusProc stderr:", data.trim())
        }
    }

    function focusAppWindow(appName, desktopEntry, summary) {
        let targetApp = (appName || "").toLowerCase();
        let targetEntry = (desktopEntry || "").toLowerCase();
        let targetSummary = (summary || "").toLowerCase();

        console.warn("[NotificationService] focusAppWindow buscando ventana para:", appName, "| desktopEntry:", desktopEntry, "| summary:", summary);

        let foundAddr = "";
        let foundTop = null;
        let foundWs = 0;

        if (Hyprland.toplevels && Hyprland.toplevels.values) {
            let toplevels = Hyprland.toplevels.values;

            // FASE 1: Coincidencia por clase o appId
            for (let i = 0; i < toplevels.length; i++) {
                let top = toplevels[i];
                let ipc = top.lastIpcObject || {};
                let cls = (ipc.class || (top.wayland ? top.wayland.appId : "") || "").toLowerCase();
                let initialCls = (ipc.initialClass || "").toLowerCase();

                let cleanCls = cls.replace(/[^a-z0-9]/g, "");
                let cleanInitCls = initialCls.replace(/[^a-z0-9]/g, "");
                let cleanApp = targetApp.replace(/[^a-z0-9]/g, "");
                let cleanEntry = targetEntry.replace(/[^a-z0-9]/g, "");

                let match = false;
                if (cleanEntry !== "") {
                    if (cleanCls === cleanEntry || cleanInitCls === cleanEntry || cleanCls.includes(cleanEntry) || cleanEntry.includes(cleanCls)) {
                        match = true;
                    }
                }

                if (!match && cleanApp !== "") {
                    if (cleanApp.includes("antigravity") && (cleanCls.includes("antigravity") || cleanInitCls.includes("antigravity"))) match = true;
                    else if ((cleanApp.includes("code") || cleanApp.includes("vscode")) && (cleanCls.includes("code") || cleanInitCls.includes("code"))) match = true;
                    else if (cleanApp.includes("ghostty") && (cleanCls.includes("ghostty") || cleanInitCls.includes("ghostty"))) match = true;
                    else if (cleanApp.includes("spotify") && (cleanCls.includes("spotify") || cleanInitCls.includes("spotify"))) match = true;
                    else if (cleanApp.includes("zen") && (cleanCls.includes("zen") || cleanInitCls.includes("zen"))) match = true;
                    else if (cleanApp.includes("firefox") && (cleanCls.includes("firefox") || cleanInitCls.includes("firefox"))) match = true;
                    else if (cleanApp.includes("steam") && (cleanCls.includes("steam") || cleanInitCls.includes("steam"))) match = true;
                    else if (cleanApp.includes("telegram") && (cleanCls.includes("telegram") || cleanInitCls.includes("telegram"))) match = true;
                    else if (cleanApp.includes("discord") && (cleanCls.includes("discord") || cleanCls.includes("vesktop") || cleanInitCls.includes("discord"))) match = true;
                    else if ((cleanApp.includes("nautilus") || cleanApp.includes("files") || cleanApp.includes("archivo")) && (cleanCls.includes("nautilus") || cleanCls.includes("files"))) match = true;
                    else if ((cleanApp.includes("chrome") || cleanApp.includes("chromium")) && (cleanCls.includes("chrome") || cleanCls.includes("chromium"))) match = true;
                    else if (cleanCls === cleanApp || cleanInitCls === cleanApp || cleanCls.includes(cleanApp) || (cleanApp.length >= 4 && cleanApp.includes(cleanCls))) match = true;
                }

                // Fallback para notificaciones de script/notify-send usando el summary
                if (!match && (cleanApp.includes("notifysend") || cleanApp.includes("sistema") || cleanApp.includes("system") || cleanApp === "")) {
                    let cleanSum = targetSummary.replace(/[^a-z0-9]/g, "");
                    if (cleanSum.length >= 3) {
                        if (cleanSum.includes("antigravity") && (cleanCls.includes("antigravity") || cleanInitCls.includes("antigravity"))) match = true;
                        else if ((cleanSum.includes("code") || cleanSum.includes("vscode")) && (cleanCls.includes("code") || cleanInitCls.includes("code"))) match = true;
                        else if (cleanSum.includes("ghostty") && (cleanCls.includes("ghostty") || cleanInitCls.includes("ghostty"))) match = true;
                        else if (cleanCls.includes(cleanSum) || cleanInitCls.includes(cleanSum)) match = true;
                    }
                }

                if (match) {
                    foundAddr = top.address || "";
                    foundTop = top;
                    foundWs = (top.workspace && top.workspace.id) ? top.workspace.id : (ipc.workspace ? (ipc.workspace.id || ipc.workspace) : 0);
                    break;
                }
            }

            // FASE 2: Coincidencia por título si la clase no coincidió (excluyendo emuladores de terminal)
            if (!foundTop) {
                for (let i = 0; i < toplevels.length; i++) {
                    let top = toplevels[i];
                    let ipc = top.lastIpcObject || {};
                    let cls = (ipc.class || (top.wayland ? top.wayland.appId : "") || "").toLowerCase();
                    let title = (top.title || ipc.title || "").toLowerCase();

                    let isTerminal = cls.includes("ghostty") || cls.includes("kitty") || cls.includes("alacritty") || cls.includes("foot") || cls.includes("terminal");
                    if (isTerminal && !targetApp.includes("ghostty") && !targetApp.includes("term") && !targetApp.includes("kitty")) {
                        continue;
                    }

                    if (targetApp !== "" && !targetApp.includes("notifysend") && title.includes(targetApp)) {
                        foundAddr = top.address || "";
                        foundTop = top;
                        foundWs = (top.workspace && top.workspace.id) ? top.workspace.id : (ipc.workspace ? (ipc.workspace.id || ipc.workspace) : 0);
                        break;
                    }
                }
            }
        }

        if (foundAddr !== "") {
            console.warn("[NotificationService] Ventana encontrada:", foundAddr, "| en workspace:", foundWs);
        } else {
            console.warn("[NotificationService] No se encontró ventana activa para:", appName, "| desktopEntry:", desktopEntry, "| summary:", summary);
        }

        // 1. Activar vía protocolo Wayland si está soportado
        if (foundTop && foundTop.wayland && typeof foundTop.wayland.activate === "function") {
            foundTop.wayland.activate();
        }

        // 2. Enfocar ventana y cambiar al workspace correspondiente vía Hyprland Lua
        if (foundAddr !== "") {
            let cleanAddr = foundAddr.startsWith("0x") ? foundAddr : ("0x" + foundAddr);
            let ws = (foundWs && foundWs > 0) ? foundWs : 0;

            let luaCmd = "local ws = " + ws + "; "
                       + "local addr = \"" + cleanAddr + "\"; "
                       + "if ws > 0 then hl.dispatch(hl.dsp.focus({ workspace = ws })) end; "
                       + "hl.dispatch(hl.dsp.focus({ window = \"address:\" .. addr })); "
                       + "for _, w in ipairs(hl.get_windows()) do "
                       + "  if w.address:lower() == addr:lower() and w.at and w.size then "
                       + "    local cx = math.floor(w.at.x + w.size.x / 2); "
                       + "    local cy = math.floor(w.at.y + w.size.y / 2); "
                       + "    hl.dispatch(hl.dsp.cursor.move({ x = cx, y = cy })); "
                       + "    break; "
                       + "  end; "
                       + "end;";

            if (hyprFocusProc.running) hyprFocusProc.running = false;
            hyprFocusProc.command = ["hyprctl", "repl", luaCmd];
            hyprFocusProc.running = true;
            return true;
        }

        return false;
    }

    function activateNotification(id) {
        let notif = root.notifications.find(n => n.id == id) || (root.currentToast && root.currentToast.id == id ? root.currentToast : null);
        if (!notif) {
            console.warn("[NotificationService] activateNotification: no se encontró notificación con id:", id);
            return;
        }

        if (notif.isScreenshot && notif.screenshotPath) {
            root.openScreenshot(notif.screenshotPath);
            return;
        }

        let appName = notif.appName || "";
        let desktopEntry = (notif.ref && notif.ref.desktopEntry) ? notif.ref.desktopEntry : (notif.desktopEntry || "");
        let summary = notif.summary || "";

        // 1. Invocar la acción predeterminada ("default") si la app la registró
        try {
            if (notif.ref && typeof notif.ref.invokeAction === "function") {
                notif.ref.invokeAction("default");
            }
        } catch (e) {
            console.warn("[NotificationService] Error al invocar acción default:", e);
        }

        // 2. Cerrar el centro de notificaciones y la cápsula
        if (root.isCenterOpen) {
            root.closeCenter();
        }
        root.dismissToast();

        // 3. Enfocar la ventana de la app en Hyprland y cambiar a su workspace
        if (appName !== "" || desktopEntry !== "" || summary !== "") {
            root.focusAppWindow(appName, desktopEntry, summary);
        }

        // 4. Descartar la notificación del registro
        root.dismiss(id);
    }

    function invokeAction(id, action) {
        let notif = root.notifications.find(n => n.id == id) || (root.currentToast && root.currentToast.id == id ? root.currentToast : null);
        if (!notif) {
            console.warn("[NotificationService] invokeAction: no se encontró notificación con id:", id);
            return;
        }

        let appName = notif.appName || "";
        let desktopEntry = (notif.ref && notif.ref.desktopEntry) ? notif.ref.desktopEntry : (notif.desktopEntry || "");
        let summary = notif.summary || "";

        try {
            if (action && typeof action.invoke === "function") {
                action.invoke();
            } else {
                let actionId = (action && typeof action === "object" && action.id) ? action.id : action;
                if (notif && notif.ref && typeof notif.ref.invokeAction === "function") {
                    notif.ref.invokeAction(actionId);
                }
            }
        } catch (e) {
            console.warn("[NotificationService] Error al invocar acción:", e);
        }

        // Cerrar el centro de notificaciones y el toast
        if (root.isCenterOpen) {
            root.closeCenter();
        }
        root.dismissToast();

        // Enfocar la ventana de la aplicación que emitió la notificación
        if (appName !== "" || desktopEntry !== "" || summary !== "") {
            root.focusAppWindow(appName, desktopEntry, summary);
        }

        root.dismiss(id);
    }

    function toggleCenter() {
        let otherModalOpen = (typeof LauncherService !== "undefined" && LauncherService && LauncherService.isOpen) ||
                             (typeof ClipboardService !== "undefined" && ClipboardService && ClipboardService.isOpen) ||
                             (typeof ControlCenterService !== "undefined" && ControlCenterService && ControlCenterService.isOpen);
        if (root.isCenterOpen && !otherModalOpen) {
            root.closeCenter();
        } else {
            root.openCenter();
        }
    }

    function openCenter() {
        if (typeof LauncherService !== "undefined" && LauncherService && LauncherService.isOpen) {
            LauncherService.close();
        }
        if (typeof ClipboardService !== "undefined" && ClipboardService && ClipboardService.isOpen) {
            ClipboardService.close();
        }
        if (typeof ControlCenterService !== "undefined" && ControlCenterService && ControlCenterService.isOpen) {
            ControlCenterService.close();
        }
        root.dismissToast();
        root.isCenterOpen = true;
    }

    function closeCenter() {
        root.isCenterOpen = false;
    }

    function formatRelativeTime(timestamp) {
        // Usa root._ticker para forzar reactividad
        let _ = root._ticker;
        let diff = Math.floor((Date.now() - timestamp) / 1000);
        if (diff < 30) return "now";
        if (diff < 60) return diff + "s ago";
        let mins = Math.floor(diff / 60);
        if (mins < 60) return mins + "m ago";
        let hours = Math.floor(mins / 60);
        if (hours < 24) return hours + "h ago";
        let days = Math.floor(hours / 24);
        return days + "d ago";
    }
}
