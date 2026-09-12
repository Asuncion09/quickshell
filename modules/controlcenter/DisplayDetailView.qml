import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../../services"

Item {
    id: root

    implicitWidth: 304
    implicitHeight: contentCol.implicitHeight
    height: implicitHeight
    Layout.fillWidth: true

    signal backRequested()

    property int navIndex: 0
    property bool isKeyNavActive: false
    property int menuNavIndex: 0

    // Opciones estandarizadas para los selects
    readonly property var scaleOptions: [
        { label: "1.0x (100%)", value: 1.0 },
        { label: "1.25x (125%)", value: 1.25 },
        { label: "1.5x (150%)", value: 1.5 },
        { label: "1.75x (175%)", value: 1.75 },
        { label: "2.0x (200%)", value: 2.0 }
    ]

    readonly property var orientationOptions: [
        { label: "0° (Normal)", value: 0 },
        { label: "90° (Portrait Left)", value: 1 },
        { label: "180° (Inverted)", value: 2 },
        { label: "270° (Portrait Right)", value: 3 }
    ]

    readonly property var modeOptions: (DisplayService.selectedMonitor && DisplayService.selectedMonitor.availableModes) ? DisplayService.selectedMonitor.availableModes : []

    // Valores temporales editables para el monitor seleccionado
    property string selectedMode: ""
    property real selectedScale: 1.0
    property int selectedTransform: 0

    // Control de menús desplegables: "" | "resolution" | "scale" | "orientation"
    property string openMenu: ""

    function parseMode(str) {
        if (!str) return null;
        let s = str.replace(/Hz$/i, "").trim();
        let parts = s.split("@");
        let res = parts[0].split("x");
        if (res.length < 2) return null;
        let w = parseInt(res[0], 10);
        let h = parseInt(res[1], 10);
        let hz = parts.length > 1 ? parseFloat(parts[1]) : 60.0;
        return { width: w, height: h, refreshRate: hz };
    }

    // Detección de cambios pendientes de aplicar (considera resolución, tasa de refresco Hz, escala y rotación)
    readonly property bool hasPendingChanges: {
        let m = DisplayService.selectedMonitor;
        if (!m) return false;
        let modeChanged = false;
        if (root.selectedMode !== "") {
            let target = root.parseMode(root.selectedMode);
            if (target) {
                let wDiff = (target.width !== m.width);
                let hDiff = (target.height !== m.height);
                let curRate = (m.refreshRate && m.refreshRate > 0) ? m.refreshRate : 60.0;
                let rDiff = Math.abs(target.refreshRate - curRate) > 0.1;
                if (wDiff || hDiff || rDiff) {
                    modeChanged = true;
                }
            }
        }
        let scaleChanged = (m.scale && m.scale > 0) ? (Math.abs(root.selectedScale - m.scale) > 0.01) : false;
        let transformChanged = (m.transform !== undefined) ? (root.selectedTransform !== m.transform) : false;
        return modeChanged || scaleChanged || transformChanged;
    }

    onVisibleChanged: {
        root.isKeyNavActive = false;
        root.navIndex = 0;
        root.menuNavIndex = 0;
        root.openMenu = "";
        if (visible) {
            DisplayService.refreshMonitors();
            syncValuesWithSelected();
        }
    }

    function initMenuNavIndex(menuName) {
        if (menuName === "resolution") {
            let modes = root.modeOptions;
            let idx = modes.indexOf(root.selectedMode);
            root.menuNavIndex = idx >= 0 ? idx : 0;
            Qt.callLater(() => { root.scrollModeIntoView(root.menuNavIndex); });
        } else if (menuName === "scale") {
            let scales = root.scaleOptions;
            let idx = 0;
            for (let i = 0; i < scales.length; i++) {
                if (Math.abs(root.selectedScale - scales[i].value) < 0.01) {
                    idx = i;
                    break;
                }
            }
            root.menuNavIndex = idx;
        } else if (menuName === "orientation") {
            let orients = root.orientationOptions;
            let idx = 0;
            for (let i = 0; i < orients.length; i++) {
                if (root.selectedTransform === orients[i].value) {
                    idx = i;
                    break;
                }
            }
            root.menuNavIndex = idx;
        }
    }

    function toggleMenu(menuName) {
        if (root.openMenu === menuName) {
            root.openMenu = "";
        } else {
            root.openMenu = menuName;
            root.initMenuNavIndex(menuName);
        }
    }

    function scrollModeIntoView(idx) {
        if (idx < 0) return;
        let itemY = idx * 32; // 30 height + 2 spacing
        let viewTop = modesFlickable.contentY;
        let viewHeight = modesFlickable.height;
        if (viewHeight <= 0) return;
        let viewBottom = viewTop + viewHeight;

        if (itemY < viewTop) {
            modesFlickable.contentY = Math.max(0, itemY);
        } else if (itemY + 30 > viewBottom) {
            modesFlickable.contentY = Math.max(0, itemY + 30 - viewHeight);
        }
    }

    function stepScale(delta) {
        let scales = root.scaleOptions;
        let curIdx = 0;
        for (let i = 0; i < scales.length; i++) {
            if (Math.abs(root.selectedScale - scales[i].value) < 0.01) {
                curIdx = i;
                break;
            }
        }
        let nextIdx = Math.max(0, Math.min(scales.length - 1, curIdx + delta));
        root.selectedScale = scales[nextIdx].value;
    }

    function stepOrientation(delta) {
        let orients = root.orientationOptions;
        let curIdx = 0;
        for (let i = 0; i < orients.length; i++) {
            if (root.selectedTransform === orients[i].value) {
                curIdx = i;
                break;
            }
        }
        let nextIdx = (curIdx + delta + orients.length) % orients.length;
        root.selectedTransform = orients[nextIdx].value;
    }

    function getScaleLabel(val) {
        if (Math.abs(val - 1.0) < 0.01) return "1.0x (100%)";
        if (Math.abs(val - 1.25) < 0.01) return "1.25x (125%)";
        if (Math.abs(val - 1.5) < 0.01) return "1.5x (150%)";
        if (Math.abs(val - 1.75) < 0.01) return "1.75x (175%)";
        if (Math.abs(val - 2.0) < 0.01) return "2.0x (200%)";
        return Number(val).toFixed(2) + "x";
    }

    function getTransformLabel(val) {
        if (val === 1) return "90° (Portrait Left)";
        if (val === 2) return "180° (Inverted)";
        if (val === 3) return "270° (Portrait Right)";
        return "0° (Normal)";
    }

    // Sincronizar propiedades locales con el monitor seleccionado
    function syncValuesWithSelected() {
        let m = DisplayService.selectedMonitor;
        if (m) {
            root.selectedScale = (m.scale && m.scale > 0) ? m.scale : 1.0;
            root.selectedTransform = m.transform || 0;
            if (m.availableModes && m.availableModes.length > 0) {
                let curRate = (m.refreshRate && m.refreshRate > 0) ? m.refreshRate : 60.0;
                let matchedExact = false;
                let matchedRes = -1;

                for (let i = 0; i < m.availableModes.length; i++) {
                    let pm = root.parseMode(m.availableModes[i]);
                    if (pm && pm.width === m.width && pm.height === m.height) {
                        if (matchedRes === -1) matchedRes = i;
                        if (Math.abs(pm.refreshRate - curRate) < 0.2) {
                            root.selectedMode = m.availableModes[i];
                            matchedExact = true;
                            break;
                        }
                    }
                }
                if (!matchedExact) {
                    if (matchedRes !== -1) {
                        root.selectedMode = m.availableModes[matchedRes];
                    } else {
                        root.selectedMode = m.availableModes[0];
                    }
                }
            } else {
                root.selectedMode = m.width + "x" + m.height + "@" + (m.refreshRate || 60.0) + "Hz";
            }
        }
    }

    Connections {
        target: DisplayService
        function onSelectedMonitorIndexChanged() {
            root.syncValuesWithSelected();
        }
        function onMonitorsChanged() {
            root.syncValuesWithSelected();
        }
    }

    function applyCurrentConfig() {
        let m = DisplayService.selectedMonitor;
        if (!m) return;

        let modeParam = root.selectedMode ? root.selectedMode.replace(/Hz$/i, "") : (m.width + "x" + m.height + "@" + m.refreshRate);
        DisplayService.applyMonitor(m.name, modeParam, m.x, m.y, root.selectedScale, root.selectedTransform);
    }

    function handleMonitorDropped(draggedIdx, dropX, dropY) {
        let mons = DisplayService.monitors;
        if (!mons || mons.length < 2) return;

        let draggedMon = mons[draggedIdx];
        if (!draggedMon) return;

        // Calcular centro horizontal en coordenadas del lienzo
        let items = [];
        for (let i = 0; i < mons.length; i++) {
            let m = mons[i];
            let mw = (m.effectiveWidth || 1920) * canvasBox.zoom;
            let cx = 0;
            if (i === draggedIdx) {
                cx = dropX + (mw / 2);
            } else {
                let tx = canvasBox.offsetX + ((m.x - canvasBox.bounds.minX) * canvasBox.zoom);
                cx = tx + (mw / 2);
            }
            items.push({ index: i, monitor: m, centerX: cx });
        }

        // Ordenar horizontalmente de izquierda a derecha
        items.sort((a, b) => a.centerX - b.centerX);

        // Generar coordenadas normalizadas comenzando en x = 0
        let batch = [];
        let curX = 0;
        let changed = false;

        for (let k = 0; k < items.length; k++) {
            let m = items[k].monitor;
            let isCurrentSelected = (DisplayService.selectedMonitor && DisplayService.selectedMonitor.name === m.name);
            let modeStr = isCurrentSelected && root.selectedMode ? root.selectedMode.replace(/Hz$/i, "") : (m.mode ? m.mode.replace(/Hz$/i, "") : (m.width + "x" + m.height + "@" + m.refreshRate));
            let sVal = isCurrentSelected ? root.selectedScale : ((m.scale && m.scale > 0) ? m.scale : 1.0);
            let tVal = isCurrentSelected ? root.selectedTransform : (m.transform || 0);

            if (curX !== m.x || m.y !== 0) {
                changed = true;
            }

            batch.push({
                name: m.name,
                mode: modeStr,
                x: curX,
                y: 0,
                scale: sVal,
                transform: tVal
            });

            curX += Math.round(m.effectiveWidth || 1920);
        }

        if (changed) {
            DisplayService.applyMonitorsBatch(batch);
        }
    }

    function handleKey(event) {
        let totalItems = 5; // 0: Volver, 1: Res, 2: Scale, 3: Orient, 4: Apply

        if (!root.isKeyNavActive) {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Up || event.key === Qt.Key_Right || event.key === Qt.Key_Left || event.key === Qt.Key_Tab) {
                root.isKeyNavActive = true;
                root.navIndex = 0;
                return true;
            }
        }

        // =========================================================
        // NAVEGACIÓN DENTRO DE MENÚS DESPLEGABLES ABIERTOS (SELECTS)
        // =========================================================
        if (root.openMenu !== "") {
            let subItemsCount = 0;
            if (root.openMenu === "resolution") subItemsCount = root.modeOptions.length;
            else if (root.openMenu === "scale") subItemsCount = root.scaleOptions.length;
            else if (root.openMenu === "orientation") subItemsCount = root.orientationOptions.length;

            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Left) {
                root.openMenu = "";
                return true;
            }

            if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                if (subItemsCount > 0) {
                    root.menuNavIndex = (root.menuNavIndex + 1) % subItemsCount;
                    if (root.openMenu === "resolution") root.scrollModeIntoView(root.menuNavIndex);
                }
                return true;
            }

            if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                if (subItemsCount > 0) {
                    root.menuNavIndex = (root.menuNavIndex - 1 + subItemsCount) % subItemsCount;
                    if (root.openMenu === "resolution") root.scrollModeIntoView(root.menuNavIndex);
                }
                return true;
            }

            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                if (root.openMenu === "resolution") {
                    if (root.menuNavIndex >= 0 && root.menuNavIndex < root.modeOptions.length) {
                        root.selectedMode = root.modeOptions[root.menuNavIndex];
                    }
                } else if (root.openMenu === "scale") {
                    if (root.menuNavIndex >= 0 && root.menuNavIndex < root.scaleOptions.length) {
                        root.selectedScale = root.scaleOptions[root.menuNavIndex].value;
                    }
                } else if (root.openMenu === "orientation") {
                    if (root.menuNavIndex >= 0 && root.menuNavIndex < root.orientationOptions.length) {
                        root.selectedTransform = root.orientationOptions[root.menuNavIndex].value;
                    }
                }
                root.openMenu = "";
                return true;
            }

            return true;
        }

        // =========================================================
        // NAVEGACIÓN ENTRE FILAS PRINCIPALES (MENÚS CERRADOS)
        // =========================================================
        if (event.key === Qt.Key_Escape) {
            root.backRequested();
            return true;
        }

        if (event.key === Qt.Key_Left) {
            root.isKeyNavActive = true;
            if (root.navIndex === 0) {
                root.backRequested();
                return true;
            }
            if (root.navIndex === 2) {
                root.stepScale(-1);
                return true;
            }
            if (root.navIndex === 3) {
                root.stepOrientation(-1);
                return true;
            }
            root.navIndex = Math.max(0, root.navIndex - 1);
            return true;
        }

        if (event.key === Qt.Key_Right) {
            root.isKeyNavActive = true;
            if (root.navIndex === 0) {
                root.navIndex = 1;
                return true;
            }
            if (root.navIndex === 2) {
                root.stepScale(1);
                return true;
            }
            if (root.navIndex === 3) {
                root.stepOrientation(1);
                return true;
            }
            root.navIndex = Math.min(totalItems - 1, root.navIndex + 1);
            return true;
        }

        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down) {
            root.isKeyNavActive = true;
            root.navIndex = (root.navIndex + 1) % totalItems;
            return true;
        }

        if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up) {
            root.isKeyNavActive = true;
            root.navIndex = (root.navIndex - 1 + totalItems) % totalItems;
            return true;
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (root.navIndex === 0) {
                root.backRequested();
                return true;
            }
            if (root.navIndex === 1) {
                root.toggleMenu("resolution");
                return true;
            }
            if (root.navIndex === 2) {
                root.toggleMenu("scale");
                return true;
            }
            if (root.navIndex === 3) {
                root.toggleMenu("orientation");
                return true;
            }
            if (root.navIndex === 4) {
                if (root.hasPendingChanges) {
                    root.applyCurrentConfig();
                }
                return true;
            }
            return true;
        }

        return false;
    }

    ColumnLayout {
        id: contentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 12

        // ==========================================
        // 1. CABECERA: Volver + Título limpio (sin botón de refresco redundante)
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 32
            spacing: 8

            // Botón Volver
            Rectangle {
                id: backBtn
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === 0
                color: isKeyFocused ? "#2c2c2c" : Theme.surfaceHover
                opacity: (isKeyFocused || backMouse.containsMouse) ? 1.0 : 0.0
                border.width: isKeyFocused ? 1.5 : 0
                border.color: Theme.highlight

                scale: backMouse.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: (backMouse.containsMouse || backBtn.isKeyFocused) ? Theme.text : Theme.textSecondary
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

            // Título de la vista
            Text {
                text: "Displays"
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Theme.text
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }
        }

        // Línea divisoria fina
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.dividerColor
        }

        // ==========================================
        // 2. MINI-LIENZO TOPOLÓGICO DE PANTALLAS (BLOQUE SÓLIDO SIN BORDES)
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4

                Text {
                    text: "LAYOUT"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: Theme.textMuted
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: DisplayService.hasMultipleMonitors ? (DisplayService.monitors.length + " screens • Drag to reorder") : (DisplayService.monitors.length + " screen")
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textMuted
                }
            }

            Rectangle {
                id: canvasBox
                Layout.fillWidth: true
                implicitHeight: 96
                radius: 12
                color: "#161616"
                border.color: Theme.borderDark
                border.width: 1
                clip: true

                readonly property var bounds: {
                    let mons = DisplayService.monitors;
                    if (!mons || mons.length === 0) {
                        return { minX: 0, minY: 0, totalW: 1920, totalH: 1080 };
                    }
                    let minX = mons[0].x, minY = mons[0].y;
                    let maxX = mons[0].x + (mons[0].effectiveWidth || 1920);
                    let maxY = mons[0].y + (mons[0].effectiveHeight || 1080);
                    for (let i = 1; i < mons.length; i++) {
                        let m = mons[i];
                        let mw = m.effectiveWidth || 1920;
                        let mh = m.effectiveHeight || 1080;
                        if (m.x < minX) minX = m.x;
                        if (m.y < minY) minY = m.y;
                        if (m.x + mw > maxX) maxX = m.x + mw;
                        if (m.y + mh > maxY) maxY = m.y + mh;
                    }
                    let tw = Math.max(1, maxX - minX);
                    let th = Math.max(1, maxY - minY);
                    return { minX: minX, minY: minY, totalW: tw, totalH: th };
                }

                readonly property real padX: 18
                readonly property real padY: 14
                readonly property real availableW: canvasBox.width - (padX * 2)
                readonly property real availableH: canvasBox.height - (padY * 2)
                readonly property real zoom: Math.min(availableW / bounds.totalW, availableH / bounds.totalH)
                readonly property real offsetX: (canvasBox.width - (bounds.totalW * zoom)) / 2
                readonly property real offsetY: (canvasBox.height - (bounds.totalH * zoom)) / 2

                Text {
                    anchors.centerIn: parent
                    visible: !DisplayService.monitors || DisplayService.monitors.length === 0
                    text: "No screens detected"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.textMuted
                }

                // Renderizado de monitores: bloque plano de color completo sin bordes + Drag & Drop interactivo
                Repeater {
                    model: DisplayService.monitors

                    Item {
                        id: monitorRectContainer
                        required property var modelData
                        required property int index

                        readonly property var mon: modelData
                        readonly property bool isSelected: DisplayService.selectedMonitorIndex === index
                        readonly property real monW: (mon.effectiveWidth || 1920) * canvasBox.zoom
                        readonly property real monH: (mon.effectiveHeight || 1080) * canvasBox.zoom
                        readonly property real posX: canvasBox.offsetX + ((mon.x - canvasBox.bounds.minX) * canvasBox.zoom)
                        readonly property real posY: canvasBox.offsetY + ((mon.y - canvasBox.bounds.minY) * canvasBox.zoom)

                        property bool isDragging: false
                        property real dragX: 0

                        x: isDragging ? dragX : posX
                        y: posY
                        width: monW
                        height: monH
                        z: isDragging ? 100 : (isSelected ? 2 : 1)

                        Behavior on x {
                            enabled: !monitorRectContainer.isDragging
                            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                        }
                        Behavior on y {
                            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                        }
                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                        // Rectángulo de color completo sin borde
                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            border.width: 0

                            // Color sólido completo: seleccionado (#3a3a3a) vs inactivo (#242424) vs arrastrando (#484848) vs hover (#2f2f2f)
                            color: {
                                if (mon.disabled) return "#1c1c1c";
                                if (monitorRectContainer.isDragging) return "#484848";
                                if (isSelected) return "#3a3a3a";
                                return monMouse.containsMouse ? "#2f2f2f" : "#242424";
                            }
                            opacity: mon.disabled ? 0.35 : (monitorRectContainer.isDragging ? 0.92 : 1.0)
                            scale: monitorRectContainer.isDragging ? 1.05 : 1.0

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            Behavior on scale { NumberAnimation { duration: Theme.animFast } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    text: mon.name.startsWith("eDP") ? "󰌢" : "󰍹"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Math.round(Math.min(18, Math.max(13, monH * 0.35)))
                                    color: (isSelected || monitorRectContainer.isDragging) ? "#ffffff" : Theme.textSecondary
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: mon.name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Math.round(Math.min(12, Math.max(10, monH * 0.24)))
                                    font.weight: (isSelected || monitorRectContainer.isDragging) ? Font.Bold : Font.DemiBold
                                    color: (isSelected || monitorRectContainer.isDragging) ? "#ffffff" : Theme.textSecondary
                                    elide: Text.ElideRight
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            // Punto indicador verde de foco
                            Rectangle {
                                visible: mon.focused
                                width: 6
                                height: 6
                                radius: 3
                                color: Theme.success
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 5
                            }

                            MouseArea {
                                id: monMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: monitorRectContainer.isDragging ? Qt.ClosedHandCursor : (DisplayService.hasMultipleMonitors ? Qt.OpenHandCursor : Qt.PointingHandCursor)

                                property real grabOffsetX: 0
                                property real startCanvasX: 0
                                property bool dragActivated: false

                                onPressed: mouse => {
                                    DisplayService.selectMonitor(index);
                                    let p = monMouse.mapToItem(canvasBox, mouse.x, mouse.y);
                                    grabOffsetX = mouse.x;
                                    startCanvasX = p.x;
                                    dragActivated = false;
                                    monitorRectContainer.dragX = monitorRectContainer.posX;
                                }

                                onPositionChanged: mouse => {
                                    if (!pressed) return;
                                    if (!DisplayService.hasMultipleMonitors) return;

                                    let p = monMouse.mapToItem(canvasBox, mouse.x, mouse.y);
                                    let delta = Math.abs(p.x - startCanvasX);

                                    if (!dragActivated && delta > 6) {
                                        dragActivated = true;
                                        monitorRectContainer.isDragging = true;
                                    }

                                    if (monitorRectContainer.isDragging) {
                                        let proposedX = p.x - grabOffsetX;
                                        let minX = 4;
                                        let maxX = canvasBox.width - monitorRectContainer.monW - 4;
                                        monitorRectContainer.dragX = Math.max(minX, Math.min(maxX, proposedX));
                                    }
                                }

                                onReleased: mouse => {
                                    if (monitorRectContainer.isDragging) {
                                        monitorRectContainer.isDragging = false;
                                        root.handleMonitorDropped(index, monitorRectContainer.dragX, monitorRectContainer.posY);
                                    }
                                    dragActivated = false;
                                }

                                onCanceled: {
                                    monitorRectContainer.isDragging = false;
                                    dragActivated = false;
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 3. SELECTOR DE PANTALLA ACTIVA (SI HAY VARIAS)
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: DisplayService.hasMultipleMonitors

            Repeater {
                model: DisplayService.monitors

                Rectangle {
                    id: monPill
                    required property var modelData
                    required property int index
                    readonly property bool isSelected: DisplayService.selectedMonitorIndex === index

                    implicitHeight: 32
                    Layout.fillWidth: true
                    radius: 8
                    border.width: 0
                    color: isSelected ? "#3a3a3a" : (pillMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase)

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: modelData.name.startsWith("eDP") ? "󰌢" : "󰍹"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: isSelected ? "#ffffff" : Theme.textMuted
                        }

                        Text {
                            text: modelData.name
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: isSelected ? Font.DemiBold : Font.Normal
                            color: isSelected ? "#ffffff" : Theme.textSecondary
                        }
                    }

                    MouseArea {
                        id: pillMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DisplayService.selectMonitor(index)
                    }
                }
            }
        }

        // ==========================================
        // 4. TARJETA UNIFICADA DE CONFIGURACIÓN (GROUPED INSET CARD)
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "CONFIGURATION"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Theme.textMuted
                Layout.leftMargin: 4
            }

            Rectangle {
                id: settingsCard
                Layout.fillWidth: true
                implicitHeight: settingsCardCol.implicitHeight + 8
                radius: 12
                color: Theme.surfaceBase
                border.width: 1
                border.color: Theme.borderDark
                clip: true

                ColumnLayout {
                    id: settingsCardCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 0

                    // ------------------------------------------
                    // Fila 1: Resolution & Refresh
                    // ------------------------------------------
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 46

                        // Rectángulo con hover redondeado (radius: 8, concéntrico con la tarjeta radius 12 con margen 4px)
                        Rectangle {
                            anchors.fill: parent
                            radius: 8

                            readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === 1
                            readonly property bool isOpen: root.openMenu === "resolution"
                            readonly property bool isHovered: modeRowMouse.containsMouse

                            color: isKeyFocused ? "#2c2c2c" : Theme.surfaceHover
                            opacity: isKeyFocused ? 1.0 : (isHovered ? 1.0 : (isOpen ? 0.35 : 0.0))

                            border.width: isKeyFocused ? 1.5 : 0
                            border.color: (isKeyFocused && isOpen) ? Qt.rgba(1, 1, 1, 0.25) : Theme.highlight

                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            Text {
                                text: "󰍺"
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                color: Theme.highlight
                            }

                            ColumnLayout {
                                spacing: 1
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: "Resolution"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: Theme.text
                                }

                                Text {
                                    text: "Mode & refresh rate"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: root.selectedMode !== "" ? root.selectedMode.replace(/\.00Hz/i, "Hz").replace(/\.00$/i, "") : "Auto"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Theme.textSecondary
                                elide: Text.ElideRight
                                Layout.maximumWidth: 140
                            }

                            Text {
                                text: root.openMenu === "resolution" ? "󰅃" : "󰅀"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: Theme.textMuted
                            }
                        }

                        MouseArea {
                            id: modeRowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleMenu("resolution")
                        }
                    }

                    // Lista fluida integrada para Resolución (sin fondo negro ni borde tosco)
                    Rectangle {
                        id: modesTray
                        Layout.fillWidth: true
                        Layout.leftMargin: 0
                        Layout.rightMargin: 0
                        Layout.topMargin: 2
                        Layout.bottomMargin: root.openMenu === "resolution" ? 4 : 0
                        implicitHeight: root.openMenu === "resolution" ? Math.min(166, modesCol.implicitHeight + 4) : 0
                        visible: implicitHeight > 0
                        clip: true
                        color: "transparent"

                        Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on Layout.bottomMargin { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        Flickable {
                            id: modesFlickable
                            anchors.fill: parent
                            anchors.leftMargin: 2
                            anchors.rightMargin: 2
                            anchors.topMargin: 2
                            anchors.bottomMargin: 2
                            contentHeight: modesCol.implicitHeight
                            clip: true

                            ColumnLayout {
                                id: modesCol
                                width: parent.width - (modesFlickable.visibleArea.heightRatio < 1.0 ? 8 : 0)
                                spacing: 2

                                Repeater {
                                    model: root.modeOptions

                                    Rectangle {
                                        id: modeItemBox
                                        required property string modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        implicitHeight: 30
                                        radius: 6
                                        readonly property bool isCurrent: root.selectedMode === modelData
                                        readonly property bool isKeyFocused: root.isKeyNavActive && root.openMenu === "resolution" && root.menuNavIndex === index
                                        readonly property var parts: {
                                            let raw = modelData.replace(/\.00Hz/i, "Hz").replace(/\.00$/i, "");
                                            let atIdx = raw.indexOf("@");
                                            if (atIdx !== -1) {
                                                return { res: raw.substring(0, atIdx), rate: raw.substring(atIdx + 1) };
                                            }
                                            return { res: raw, rate: "" };
                                        }
                                        color: isKeyFocused ? "#383838" : (isCurrent ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.12) : "transparent")
                                        border.width: isKeyFocused ? 1.5 : 0
                                        border.color: Theme.highlight

                                        // Hover independiente para el fondo
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 6
                                            color: Theme.surfaceHover
                                            opacity: (!modeItemBox.isKeyFocused && !modeItemBox.isCurrent && modeItemMouse.containsMouse) ? 1.0 : (modeItemBox.isCurrent && modeItemMouse.containsMouse ? 0.35 : 0.0)
                                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 6

                                            Text {
                                                text: modeItemBox.parts.res
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                color: (modeItemBox.isKeyFocused || modeItemBox.isCurrent) ? "#ffffff" : Theme.textSecondary
                                                font.weight: (modeItemBox.isKeyFocused || modeItemBox.isCurrent) ? Font.DemiBold : Font.Normal
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                visible: modeItemBox.parts.rate !== ""
                                                text: modeItemBox.parts.rate
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                                color: modeItemBox.isCurrent ? Theme.highlight : (modeItemBox.isKeyFocused ? Theme.text : Theme.textMuted)
                                                font.weight: Font.Medium
                                            }

                                            Text {
                                                visible: modeItemBox.isCurrent
                                                text: "󰄬"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 12
                                                color: Theme.highlight
                                            }
                                        }

                                        MouseArea {
                                            id: modeItemMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.selectedMode = modelData;
                                                root.openMenu = "";
                                            }
                                        }
                                    }
                                }
                            }

                            // Indicador de barra de scroll sutil
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 1
                                y: modesFlickable.visibleArea.yPosition * modesFlickable.height
                                height: Math.max(16, modesFlickable.visibleArea.heightRatio * modesFlickable.height)
                                width: 3
                                radius: 1.5
                                color: Qt.rgba(1, 1, 1, 0.25)
                                visible: modesFlickable.visibleArea.heightRatio < 1.0
                            }
                        }
                    }

                    // Separador 1px
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        Layout.rightMargin: 6
                        Layout.topMargin: 2
                        Layout.bottomMargin: 2
                        height: 1
                        color: Theme.dividerColor
                    }

                    // ------------------------------------------
                    // Fila 2: Scale
                    // ------------------------------------------
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 46

                        // Rectángulo con hover redondeado (radius: 8)
                        Rectangle {
                            anchors.fill: parent
                            radius: 8

                            readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === 2
                            readonly property bool isOpen: root.openMenu === "scale"
                            readonly property bool isHovered: scaleRowMouse.containsMouse

                            color: isKeyFocused ? "#2c2c2c" : Theme.surfaceHover
                            opacity: isKeyFocused ? 1.0 : (isHovered ? 1.0 : (isOpen ? 0.35 : 0.0))

                            border.width: isKeyFocused ? 1.5 : 0
                            border.color: (isKeyFocused && isOpen) ? Qt.rgba(1, 1, 1, 0.25) : Theme.highlight

                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            Text {
                                text: "󰹑"
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                color: Theme.highlight
                            }

                            ColumnLayout {
                                spacing: 1
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: "Scale"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: Theme.text
                                }

                                Text {
                                    text: "UI magnification"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: root.getScaleLabel(root.selectedScale)
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Theme.textSecondary
                            }

                            Text {
                                text: root.openMenu === "scale" ? "󰅃" : "󰅀"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: Theme.textMuted
                            }
                        }

                        MouseArea {
                            id: scaleRowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleMenu("scale")
                        }
                    }

                    // Lista fluida integrada para Escala (sin fondo negro ni borde tosco)
                    Rectangle {
                        id: scaleTray
                        Layout.fillWidth: true
                        Layout.leftMargin: 0
                        Layout.rightMargin: 0
                        Layout.topMargin: 2
                        Layout.bottomMargin: root.openMenu === "scale" ? 4 : 0
                        implicitHeight: root.openMenu === "scale" ? (scaleListCol.implicitHeight + 4) : 0
                        visible: implicitHeight > 0
                        clip: true
                        color: "transparent"

                        Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on Layout.bottomMargin { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        Flickable {
                            anchors.fill: parent
                            anchors.leftMargin: 2
                            anchors.rightMargin: 2
                            anchors.topMargin: 2
                            anchors.bottomMargin: 2
                            contentHeight: scaleListCol.implicitHeight
                            clip: true

                            ColumnLayout {
                                id: scaleListCol
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    model: root.scaleOptions

                                    Rectangle {
                                        id: scaleItemBox
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        implicitHeight: 30
                                        radius: 6
                                        readonly property bool isCurrent: Math.abs(root.selectedScale - modelData.value) < 0.01
                                        readonly property bool isKeyFocused: root.isKeyNavActive && root.openMenu === "scale" && root.menuNavIndex === index
                                        color: isKeyFocused ? "#383838" : (isCurrent ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.12) : "transparent")
                                        border.width: isKeyFocused ? 1.5 : 0
                                        border.color: Theme.highlight

                                        // Hover independiente para el fondo
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 6
                                            color: Theme.surfaceHover
                                            opacity: (!scaleItemBox.isKeyFocused && !scaleItemBox.isCurrent && scaleItemMouse.containsMouse) ? 1.0 : (scaleItemBox.isCurrent && scaleItemMouse.containsMouse ? 0.35 : 0.0)
                                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10

                                            Text {
                                                text: modelData.label
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                color: (scaleItemBox.isKeyFocused || scaleItemBox.isCurrent) ? "#ffffff" : Theme.textSecondary
                                                font.weight: (scaleItemBox.isKeyFocused || scaleItemBox.isCurrent) ? Font.Bold : Font.Normal
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                visible: scaleItemBox.isCurrent
                                                text: "󰄬"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 12
                                                color: Theme.highlight
                                            }
                                        }

                                        MouseArea {
                                            id: scaleItemMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.selectedScale = modelData.value;
                                                root.openMenu = "";
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Separador 1px
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        Layout.rightMargin: 6
                        Layout.topMargin: 2
                        Layout.bottomMargin: 2
                        height: 1
                        color: Theme.dividerColor
                    }

                    // ------------------------------------------
                    // Fila 3: Orientation (icono correcto de giro: 󰑓)
                    // ------------------------------------------
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 46

                        // Rectángulo con hover redondeado (radius: 8)
                        Rectangle {
                            anchors.fill: parent
                            radius: 8

                            readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === 3
                            readonly property bool isOpen: root.openMenu === "orientation"
                            readonly property bool isHovered: orientRowMouse.containsMouse

                            color: isKeyFocused ? "#2c2c2c" : Theme.surfaceHover
                            opacity: isKeyFocused ? 1.0 : (isHovered ? 1.0 : (isOpen ? 0.35 : 0.0))

                            border.width: isKeyFocused ? 1.5 : 0
                            border.color: (isKeyFocused && isOpen) ? Qt.rgba(1, 1, 1, 0.25) : Theme.highlight

                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            Text {
                                text: "󰑓"
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                color: Theme.highlight
                            }

                            ColumnLayout {
                                spacing: 1
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: "Orientation"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: Theme.text
                                }

                                Text {
                                    text: "Screen rotation"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: root.getTransformLabel(root.selectedTransform)
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Theme.textSecondary
                                elide: Text.ElideRight
                                Layout.maximumWidth: 120
                            }

                            Text {
                                text: root.openMenu === "orientation" ? "󰅃" : "󰅀"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: Theme.textMuted
                            }
                        }

                        MouseArea {
                            id: orientRowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleMenu("orientation")
                        }
                    }

                    // Lista fluida integrada para Orientación (sin fondo negro ni borde tosco)
                    Rectangle {
                        id: orientTray
                        Layout.fillWidth: true
                        Layout.leftMargin: 0
                        Layout.rightMargin: 0
                        Layout.topMargin: 2
                        Layout.bottomMargin: root.openMenu === "orientation" ? 4 : 0
                        implicitHeight: root.openMenu === "orientation" ? (orientListCol.implicitHeight + 4) : 0
                        visible: implicitHeight > 0
                        clip: true
                        color: "transparent"

                        Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on Layout.bottomMargin { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        Flickable {
                            anchors.fill: parent
                            anchors.leftMargin: 2
                            anchors.rightMargin: 2
                            anchors.topMargin: 2
                            anchors.bottomMargin: 2
                            contentHeight: orientListCol.implicitHeight
                            clip: true

                            ColumnLayout {
                                id: orientListCol
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    model: root.orientationOptions

                                    Rectangle {
                                        id: orientItemBox
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        implicitHeight: 30
                                        radius: 6
                                        readonly property bool isCurrent: root.selectedTransform === modelData.value
                                        readonly property bool isKeyFocused: root.isKeyNavActive && root.openMenu === "orientation" && root.menuNavIndex === index
                                        color: isKeyFocused ? "#383838" : (isCurrent ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.12) : "transparent")
                                        border.width: isKeyFocused ? 1.5 : 0
                                        border.color: Theme.highlight

                                        // Hover independiente para el fondo
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 6
                                            color: Theme.surfaceHover
                                            opacity: (!orientItemBox.isKeyFocused && !orientItemBox.isCurrent && orientItemMouse.containsMouse) ? 1.0 : (orientItemBox.isCurrent && orientItemMouse.containsMouse ? 0.35 : 0.0)
                                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10

                                            Text {
                                                text: modelData.label
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                color: (orientItemBox.isKeyFocused || orientItemBox.isCurrent) ? "#ffffff" : Theme.textSecondary
                                                font.weight: (orientItemBox.isKeyFocused || orientItemBox.isCurrent) ? Font.Bold : Font.Normal
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                visible: orientItemBox.isCurrent
                                                text: "󰄬"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 12
                                                color: Theme.highlight
                                            }
                                        }

                                        MouseArea {
                                            id: orientItemMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.selectedTransform = modelData.value;
                                                root.openMenu = "";
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 5. POSICIONAMIENTO RELATIVO (MULTIMONITOR)
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5
            visible: DisplayService.hasMultipleMonitors

            Text {
                text: "ARRANGEMENT"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Theme.textMuted
                Layout.leftMargin: 4
            }

            RowLayout {
                id: relPosRow
                Layout.fillWidth: true
                spacing: 4

                readonly property string otherMonitorName: {
                    let mons = DisplayService.monitors;
                    if (!mons || mons.length < 2) return "";
                    let curIdx = DisplayService.selectedMonitorIndex;
                    let otherIdx = (curIdx === 0) ? 1 : 0;
                    return mons[otherIdx].name;
                }

                Repeater {
                    model: [
                        { id: "left", label: "󰁍 Left" },
                        { id: "right", label: "Right 󰁔" },
                        { id: "up", label: "󰁝 Top" },
                        { id: "down", label: "Bottom 󰁅" },
                        { id: "mirror", label: "󰍺 Mirror" }
                    ]

                    Rectangle {
                        id: posBtn
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: 8
                        color: posMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase
                        border.width: 0

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: posMouse.containsMouse ? "#ffffff" : Theme.textSecondary
                        }

                        MouseArea {
                            id: posMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let curMon = DisplayService.selectedMonitor;
                                if (curMon && relPosRow.otherMonitorName !== "") {
                                    DisplayService.setRelativePosition(curMon.name, relPosRow.otherMonitorName, modelData.id);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Feedback / Mensaje de estado tras aplicar
        RowLayout {
            Layout.fillWidth: true
            visible: DisplayService.statusMessage !== ""
            spacing: 6
            Layout.alignment: Qt.AlignHCenter

            Text {
                text: "󰄬"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: Theme.success
            }

            Text {
                text: DisplayService.statusMessage
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.success
                font.weight: Font.Medium
            }
        }

        // ==========================================
        // 6. BOTÓN DE ACCIÓN: APLICAR (REACTIVO CON ESTADO)
        // ==========================================
        Rectangle {
            id: applyBtn
            Layout.fillWidth: true
            Layout.topMargin: 4
            implicitHeight: 40
            radius: 10
            readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === 4
            readonly property bool canApply: root.hasPendingChanges

            // Estado reactivo: Theme.highlight cuando hay cambios pendientes, superficie sobria cuando todo está al día
            color: {
                if (canApply) {
                    return isKeyFocused ? Qt.lighter(Theme.highlight, 1.15) : (applyMouse.containsMouse ? Qt.lighter(Theme.highlight, 1.08) : Theme.highlight);
                } else {
                    return isKeyFocused ? "#2c2c2c" : (applyMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase);
                }
            }

            border.width: isKeyFocused ? 1.5 : (canApply ? 0 : 1)
            border.color: isKeyFocused ? Theme.highlight : Theme.borderDark
            opacity: canApply ? 1.0 : 0.65

            scale: (canApply && applyMouse.pressed) ? 0.98 : 1.0
            Behavior on scale { NumberAnimation { duration: Theme.animFast } }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "󰄬"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: applyBtn.canApply ? "#121212" : Theme.textMuted
                }

                Text {
                    text: applyBtn.canApply ? "Apply Display Settings" : "Display Settings Up to Date"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: applyBtn.canApply ? Font.Bold : Font.Medium
                    color: applyBtn.canApply ? "#121212" : Theme.textMuted
                }
            }

            MouseArea {
                id: applyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: applyBtn.canApply ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (applyBtn.canApply) {
                        root.applyCurrentConfig();
                    }
                }
            }
        }
    }
}
