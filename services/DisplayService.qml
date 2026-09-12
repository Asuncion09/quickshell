pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../theme"

Item {
    id: root

    // Lista estructurada de monitores detectados
    property var monitors: []
    // Índice del monitor seleccionado actualmente en la interfaz
    property int selectedMonitorIndex: 0
    // Estado de carga/detección
    property bool isRefreshing: false
    // Feedback tras aplicar cambios
    property string statusMessage: ""
    // Bandera para persistir una vez consultados los valores reales actualizados de Hyprland
    property bool needsPersistence: false

    // Monitor activo seleccionado en los controles
    readonly property var selectedMonitor: {
        if (!root.monitors || root.monitors.length === 0) return null;
        let idx = Math.max(0, Math.min(root.selectedMonitorIndex, root.monitors.length - 1));
        return root.monitors[idx];
    }

    readonly property bool hasMultipleMonitors: root.monitors && root.monitors.length > 1

    // Ruta para persistir el último estado deseado de pantallas
    readonly property string stateFilePath: Quickshell.env("HOME") + "/.config/quickshell/state/monitors.json"

    // Proceso para aplicar cambios a Hyprland
    Process {
        id: applyProc
        onExited: exitCode => {
            if (exitCode === 0) {
                root.statusMessage = "Cambio aplicado con éxito";
                root.needsPersistence = true;
                refreshTimer.restart();
            } else {
                root.statusMessage = "Error al aplicar en Hyprland";
            }
            clearStatusTimer.restart();
        }
    }

    // Proceso asíncrono separado para guardar la persistencia sin bloquear applyProc
    Process {
        id: persistProc
    }

    // Proceso para consultar todos los monitores mediante hyprctl en formato JSON compacto
    Process {
        id: queryProc
        command: ["sh", "-c", "hyprctl monitors all -j | jq -c ."]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                let text = data.trim();
                if (!text || text.length === 0) return;
                try {
                    let rawList = JSON.parse(text);
                    if (Array.isArray(rawList)) {
                        let parsed = [];
                        for (let i = 0; i < rawList.length; i++) {
                            let m = rawList[i];
                            let modes = [];
                            if (Array.isArray(m.availableModes)) {
                                modes = m.availableModes;
                            }

                            // Dimensiones efectivas considerando escala y rotación (transform 1 y 3 intercambian w y h)
                            let isRotated = (m.transform === 1 || m.transform === 3);
                            let scaleVal = (m.scale && m.scale > 0) ? m.scale : 1.0;
                            let effW = isRotated ? (m.height / scaleVal) : (m.width / scaleVal);
                            let effH = isRotated ? (m.width / scaleVal) : (m.height / scaleVal);

                            parsed.push({
                                id: m.id !== undefined ? m.id : i,
                                name: m.name || ("Display-" + i),
                                description: m.description || m.model || m.name || "Monitor",
                                make: m.make || "",
                                model: m.model || "",
                                width: m.width || 1920,
                                height: m.height || 1080,
                                refreshRate: m.refreshRate ? Math.round(m.refreshRate * 100) / 100 : 60.0,
                                x: m.x !== undefined ? m.x : 0,
                                y: m.y !== undefined ? m.y : 0,
                                scale: scaleVal,
                                transform: m.transform !== undefined ? m.transform : 0,
                                focused: !!m.focused,
                                dpmsStatus: m.dpmsStatus !== undefined ? !!m.dpmsStatus : true,
                                vrr: !!m.vrr,
                                disabled: !!m.disabled,
                                mirrorOf: (m.mirrorOf && m.mirrorOf !== "none") ? m.mirrorOf : "",
                                availableModes: modes,
                                mode: (m.width && m.height) ? (m.width + "x" + m.height + "@" + (m.refreshRate ? Math.round(m.refreshRate * 100) / 100 : 60.0)) : "",
                                effectiveWidth: effW,
                                effectiveHeight: effH
                            });
                        }

                        // Preservar selección previa si sigue existiendo
                        let prevSelectedName = root.selectedMonitor ? root.selectedMonitor.name : "";
                        root.monitors = parsed;

                        if (prevSelectedName !== "") {
                            let found = false;
                            for (let j = 0; j < parsed.length; j++) {
                                if (parsed[j].name === prevSelectedName) {
                                    root.selectedMonitorIndex = j;
                                    found = true;
                                    break;
                                }
                            }
                            if (!found) root.selectedMonitorIndex = 0;
                        } else {
                            // Si ningún monitor estaba seleccionado, preferir el que tiene foco activo
                            for (let k = 0; k < parsed.length; k++) {
                                if (parsed[k].focused) {
                                    root.selectedMonitorIndex = k;
                                    break;
                                }
                            }
                        }

                        if (root.needsPersistence) {
                            root.needsPersistence = false;
                            root.persistConfig();
                        }
                    }
                } catch (e) {
                    console.warn("[DisplayService] Error al parsear JSON de monitores:", e);
                }
                root.isRefreshing = false;
            }
        }
    }

    // Refrescar lista de monitores
    function refreshMonitors() {
        if (queryProc.running) queryProc.running = false;
        root.isRefreshing = true;
        queryProc.running = true;
    }

    // Seleccionar monitor por índice
    function selectMonitor(index) {
        if (index >= 0 && index < root.monitors.length) {
            root.selectedMonitorIndex = index;
        }
    }

    // Aplicar configuración a un monitor específico (Soporte nativo Hyprland Lua + fallback)
    function applyMonitor(name, modeStr, posX, posY, scaleVal, transformVal, extraOptions) {
        if (!name || name === "") return;

        let luaFields = [];
        luaFields.push('output = "' + name + '"');

        if (modeStr && modeStr !== "") {
            luaFields.push('mode = "' + modeStr + '"');
        }

        let pX = (posX !== undefined) ? parseInt(posX) : 0;
        let pY = (posY !== undefined) ? parseInt(posY) : 0;
        luaFields.push('position = "' + pX + 'x' + pY + '"');

        let sVal = (scaleVal !== undefined && scaleVal > 0) ? Number(scaleVal) : 1.0;
        luaFields.push('scale = ' + sVal);

        let tVal = (transformVal !== undefined) ? parseInt(transformVal) : 0;
        luaFields.push('transform = ' + tVal);

        if (extraOptions) {
            if (extraOptions.mirror && extraOptions.mirror !== "") {
                luaFields.push('mirror = "' + extraOptions.mirror + '"');
            }
            if (extraOptions.vrr !== undefined) {
                luaFields.push('vrr = ' + (extraOptions.vrr ? "1" : "0"));
            }
            if (extraOptions.disabled !== undefined) {
                luaFields.push('disabled = ' + (extraOptions.disabled ? "true" : "false"));
            }
        }

        let luaCode = "hl.monitor({ " + luaFields.join(", ") + " })";

        // Parámetros legados por compatibilidad
        let legacyArgs = name + "," + (modeStr || "preferred") + "," + pX + "x" + pY + "," + sVal;
        if (tVal > 0) legacyArgs += ",transform," + tVal;
        if (extraOptions && extraOptions.mirror) legacyArgs += ",mirror," + extraOptions.mirror;

        // Actualizar el estado local inmediatamente para persistir con los valores exactos aplicados
        for (let i = 0; i < root.monitors.length; i++) {
            if (root.monitors[i].name === name) {
                if (modeStr && modeStr !== "") {
                    root.monitors[i].mode = modeStr;
                    let match = modeStr.match(/^(\d+)x(\d+)(?:@([\d\.]+))?/);
                    if (match) {
                        root.monitors[i].width = parseInt(match[1]);
                        root.monitors[i].height = parseInt(match[2]);
                        if (match[3]) {
                            root.monitors[i].refreshRate = parseFloat(match[3]);
                        }
                    }
                }
                if (scaleVal !== undefined && scaleVal > 0) root.monitors[i].scale = Number(scaleVal);
                if (transformVal !== undefined) root.monitors[i].transform = parseInt(transformVal);
                if (posX !== undefined) root.monitors[i].x = parseInt(posX);
                if (posY !== undefined) root.monitors[i].y = parseInt(posY);
                break;
            }
        }

        // Ejecutar hyprctl eval (nativo en configuraciones hyprland.lua) y fallback a hyprctl keyword
        let fullScript = "hyprctl eval '" + luaCode + "' 2>/dev/null || hyprctl keyword monitor \"" + legacyArgs + "\"";

        if (applyProc.running) applyProc.running = false;
        applyProc.command = ["sh", "-c", fullScript];
        applyProc.running = true;
    }

    // Aplicar configuración a múltiples monitores atómicamente en una sola sentencia Lua
    function applyMonitorsBatch(configs) {
        if (!configs || configs.length === 0) return;

        let luaStatements = [];
        let legacyStatements = [];

        for (let i = 0; i < configs.length; i++) {
            let c = configs[i];
            if (!c.name || c.name === "") continue;

            let luaFields = [];
            luaFields.push('output = "' + c.name + '"');
            if (c.mode && c.mode !== "") {
                luaFields.push('mode = "' + c.mode + '"');
            }
            let pX = (c.x !== undefined) ? parseInt(c.x) : 0;
            let pY = (c.y !== undefined) ? parseInt(c.y) : 0;
            luaFields.push('position = "' + pX + 'x' + pY + '"');

            let sVal = (c.scale !== undefined && c.scale > 0) ? Number(c.scale) : 1.0;
            luaFields.push('scale = ' + sVal);

            let tVal = (c.transform !== undefined) ? parseInt(c.transform) : 0;
            luaFields.push('transform = ' + tVal);

            if (c.mirror && c.mirror !== "") {
                luaFields.push('mirror = "' + c.mirror + '"');
            }
            if (c.vrr !== undefined) {
                luaFields.push('vrr = ' + (c.vrr ? "1" : "0"));
            }
            if (c.disabled !== undefined) {
                luaFields.push('disabled = ' + (c.disabled ? "true" : "false"));
            }

            luaStatements.push('hl.monitor({ ' + luaFields.join(', ') + ' })');

            let leg = c.name + "," + (c.mode || "preferred") + "," + pX + "x" + pY + "," + sVal;
            if (tVal > 0) leg += ",transform," + tVal;
            if (c.mirror) leg += ",mirror," + c.mirror;
            legacyStatements.push('hyprctl keyword monitor "' + leg + '"');
        }

        if (luaStatements.length === 0) return;

        // Actualizar el estado local en lote inmediatamente
        for (let j = 0; j < configs.length; j++) {
            let c = configs[j];
            for (let i = 0; i < root.monitors.length; i++) {
                if (root.monitors[i].name === c.name) {
                    if (c.mode && c.mode !== "") {
                        root.monitors[i].mode = c.mode;
                        let match = c.mode.match(/^(\d+)x(\d+)(?:@([\d\.]+))?/);
                        if (match) {
                            root.monitors[i].width = parseInt(match[1]);
                            root.monitors[i].height = parseInt(match[2]);
                            if (match[3]) {
                                root.monitors[i].refreshRate = parseFloat(match[3]);
                            }
                        }
                    }
                    if (c.scale !== undefined && c.scale > 0) root.monitors[i].scale = Number(c.scale);
                    if (c.transform !== undefined) root.monitors[i].transform = parseInt(c.transform);
                    if (c.x !== undefined) root.monitors[i].x = parseInt(c.x);
                    if (c.y !== undefined) root.monitors[i].y = parseInt(c.y);
                    break;
                }
            }
        }

        let fullLua = luaStatements.join('; ');
        let legacyCombined = legacyStatements.join(' && ');
        let fullScript = "hyprctl eval '" + fullLua + "' 2>/dev/null || (" + legacyCombined + ")";

        if (applyProc.running) applyProc.running = false;
        applyProc.command = ["sh", "-c", fullScript];
        applyProc.running = true;
    }

    // Habilitar o deshabilitar un monitor
    function toggleDisabled(name) {
        let mon = null;
        let activeCount = 0;
        for (let i = 0; i < root.monitors.length; i++) {
            if (root.monitors[i].name === name) mon = root.monitors[i];
            if (!root.monitors[i].disabled) activeCount++;
        }
        if (!mon) return;

        // Salvaguarda: no permitir desactivar la última pantalla activa
        if (!mon.disabled && activeCount <= 1) {
            root.statusMessage = "No se puede apagar la única pantalla";
            clearStatusTimer.restart();
            return;
        }

        if (mon.disabled) {
            applyMonitor(name, "preferred", mon.x, mon.y, mon.scale, mon.transform, { disabled: false });
        } else {
            applyMonitor(name, "", mon.x, mon.y, mon.scale, mon.transform, { disabled: true });
        }
    }

    // Posicionamiento relativo atómico respecto a otro monitor
    function setRelativePosition(targetName, refName, direction) {
        let target = null;
        let ref = null;
        for (let i = 0; i < root.monitors.length; i++) {
            if (root.monitors[i].name === targetName) target = root.monitors[i];
            if (root.monitors[i].name === refName) ref = root.monitors[i];
        }
        if (!target || !ref) return;

        let targetW = Math.round(target.effectiveWidth || 1920);
        let targetH = Math.round(target.effectiveHeight || 1080);
        let refW = Math.round(ref.effectiveWidth || 1920);
        let refH = Math.round(ref.effectiveHeight || 1080);

        let targetMode = target.mode || ((target.availableModes && target.availableModes.length > 0) ? target.availableModes[0].replace(/Hz$/i, "") : (target.width + "x" + target.height + "@" + target.refreshRate));
        let refMode = ref.mode || ((ref.availableModes && ref.availableModes.length > 0) ? ref.availableModes[0].replace(/Hz$/i, "") : (ref.width + "x" + ref.height + "@" + ref.refreshRate));

        if (direction === "mirror") {
            applyMonitor(target.name, "preferred", 0, 0, target.scale, target.transform, { mirror: ref.name });
            return;
        }

        let targetX = 0, targetY = 0;
        let refX = 0, refY = 0;

        if (direction === "right") {
            refX = 0;
            refY = 0;
            targetX = refW;
            targetY = 0;
        } else if (direction === "left") {
            targetX = 0;
            targetY = 0;
            refX = targetW;
            refY = 0;
        } else if (direction === "up") {
            targetX = 0;
            targetY = 0;
            refX = 0;
            refY = targetH;
        } else if (direction === "down") {
            refX = 0;
            refY = 0;
            targetX = 0;
            targetY = refH;
        }

        applyMonitorsBatch([
            {
                name: target.name,
                mode: targetMode,
                x: targetX,
                y: targetY,
                scale: target.scale,
                transform: target.transform
            },
            {
                name: ref.name,
                mode: refMode,
                x: refX,
                y: refY,
                scale: ref.scale,
                transform: ref.transform
            }
        ]);
    }

    // Persistir el estado actual en archivo JSON y en ~/.config/hypr/modules/monitors.lua
    function persistConfig() {
        if (!root.monitors || root.monitors.length === 0) return;
        let jsonStr = JSON.stringify(root.monitors, null, 2).replace(/"/g, '\\"');
        let scriptPath = Quickshell.env("HOME") + "/.config/quickshell/scripts/persist_monitors.py";
        let cmd = "mkdir -p $(dirname " + root.stateFilePath + ") && echo \"" + jsonStr + "\" > " + root.stateFilePath + " && python3 " + scriptPath;
        if (persistProc.running) persistProc.running = false;
        persistProc.command = ["sh", "-c", cmd];
        persistProc.running = true;
    }

    Timer {
        id: refreshTimer
        interval: 600
        repeat: false
        onTriggered: root.refreshMonitors()
    }

    Timer {
        id: clearStatusTimer
        interval: 3000
        repeat: false
        onTriggered: root.statusMessage = ""
    }

    // Auto-detección cuando cambia la topología de monitores en Hyprland
    Connections {
        target: Hyprland
        function onRawEvent(name, data) {
            if (name === "monitoradded" || name === "monitorremoved" || name === "monitorv2") {
                root.refreshMonitors();
            }
        }
    }

    Component.onCompleted: {
        root.refreshMonitors();
    }
}
