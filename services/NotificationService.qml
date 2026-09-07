pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Item {
    id: root

    Component.onCompleted: {
        console.log("[NotificationService] Singleton INICIALIZADO correctamente");
    }

    // --- Configuración de Sonidos de Notificación ---

    Process {
        command: ["paplay", root.defaultSoundPath]
    }

        if (!root.soundEnabled) return;
        let file = (customPath && customPath !== "") ? customPath : root.defaultSoundPath;
        if (soundProc.running) soundProc.running = false;
        soundProc.command = ["paplay", file];
        soundProc.running = true;
    }

    // Estado de la interfaz
    property bool isCenterOpen: false
    property bool dnd: false

    // Notificación actual para la Dynamic Island (Toast efímero)
    property var currentToast: null
    readonly property bool isToastActive: currentToast !== null && !isCenterOpen && !isLauncherOpen

    // Comprobación segura de estado de Launcher
        return (typeof LauncherService !== "undefined" && LauncherService && LauncherService.isOpen);
    }

    // Lista de notificaciones activas (más recientes al principio)
    property var notifications: []
    readonly property int count: notifications.length

    // Temporizador para actualizar los tiempos relativos cada 30 segundos
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root._ticker++
    }

    // Temporizador de cortesía de 4 segundos para el toast emergente
    Timer {
        interval: 4000
        onTriggered: {
            root.currentToast = null;
        }
    }

    function pauseToast() {
        toastTimer.stop();
    }

    function resumeToast() {
        if (root.currentToast) {
            toastTimer.interval = 3500;
            toastTimer.restart();
        }
    }

    function dismissToast() {
        toastTimer.stop();
        root.currentToast = null;
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
        return Quickshell.iconPath("com.visualstudio.code") ||
               Quickshell.iconPath("dialog-information") ||
               Quickshell.iconPath("preferences-desktop-notification") || "";
    }

    function handleNotification(notif) {
        if (!notif) return;
        console.warn("[NotificationService] Recibida notificación:", notif.id, notif.appName, notif.summary);

        // Mantener la notificación viva en el servidor hasta que se descarte
        notif.tracked = true;

        let icon = resolveAppIcon(notif.appIcon, notif.desktopEntry, notif.appName);
        let item = {
            id: notif.id,
            ref: notif,
            appName: notif.appName && notif.appName !== "" ? notif.appName : "Sistema",
            appIcon: icon,
            summary: notif.summary || "",
            body: notif.body || "",
            urgency: notif.urgency, // 0: Low, 1: Normal, 2: Critical
            image: notif.image || "",
            actions: notif.actions || [],
            timestamp: Date.now()
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
            root.currentToast = item;
            toastTimer.restart();
        }

        // Reproducir sonido si está habilitado y no está en DND (o si es urgente/crítica)
        if (root.soundEnabled && (!root.dnd || notif.urgency === 2)) {
            root.playSound();
        }
    }

    // Permite que servicios internos del sistema (como la batería) emitan notificaciones limpias
    function postInternalNotification(appName, summary, body, urgency, icon, customSound) {
        let notifId = Math.floor(Math.random() * 100000) + 900000;
        let item = {
            ref: null,
            appName: appName || "Sistema",
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
            root.currentToast = item;
            toastTimer.restart();
        }

        if (root.soundEnabled && (!root.dnd || urgency === 2)) {
            root.playSound(customSound);
        }
    }

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

    function invokeAction(id, action) {
        try {
            if (action && typeof action.invoke === "function") {
                action.invoke();
            } else {
                let notif = root.notifications.find(n => n.id === id);
                let actionId = (action && typeof action === "object" && action.id) ? action.id : action;
                if (notif && notif.ref && typeof notif.ref.invokeAction === "function") {
                    notif.ref.invokeAction(actionId);
                }
            }
        } catch (e) {
            console.log("[NotificationService] Error al invocar acción:", e);
        }
        root.dismiss(id);
    }

    function toggleCenter() {
        if (root.isCenterOpen) {
            root.closeCenter();
        } else {
            root.openCenter();
        }
    }

    function openCenter() {
        if (typeof LauncherService !== "undefined" && LauncherService && LauncherService.isOpen) {
            LauncherService.close();
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
        if (diff < 30) return "ahora";
        if (diff < 60) return "hace " + diff + "s";
        let mins = Math.floor(diff / 60);
        if (mins < 60) return "hace " + mins + "m";
        let hours = Math.floor(mins / 60);
        if (hours < 24) return "hace " + hours + "h";
        let days = Math.floor(hours / 24);
        return "hace " + days + "d";
    }
}
