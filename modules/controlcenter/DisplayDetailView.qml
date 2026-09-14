import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../../services"
import "display"

Item {
    id: root

    implicitWidth: 320
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
            Qt.callLater(() => { settingsCard.scrollModeIntoView(root.menuNavIndex); });
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
                    if (root.openMenu === "resolution") settingsCard.scrollModeIntoView(root.menuNavIndex);
                }
                return true;
            }

            if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                if (subItemsCount > 0) {
                    root.menuNavIndex = (root.menuNavIndex - 1 + subItemsCount) % subItemsCount;
                    if (root.openMenu === "resolution") settingsCard.scrollModeIntoView(root.menuNavIndex);
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
        // 1. CABECERA: Volver + Título
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 32
            spacing: 8

            Rectangle {
                id: backBtn
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === 0
                color: isKeyFocused ? Theme.surfaceKeyFocus : (backMouse.containsMouse ? Theme.surfaceHover : "transparent")
                border.width: isKeyFocused ? 1.5 : 0
                border.color: Theme.highlight

                scale: backMouse.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on border.width { NumberAnimation { duration: 40 } }
                Behavior on border.color { ColorAnimation { duration: 40 } }
                Behavior on color { ColorAnimation { duration: backMouse.containsMouse ? Theme.animFast : 40 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: (backMouse.containsMouse || backBtn.isKeyFocused) ? Theme.text : Theme.textSecondary
                    Behavior on color { ColorAnimation { duration: backMouse.containsMouse ? Theme.animFast : 40 } }
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

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
        // 2. MINI-LIENZO TOPOLÓGICO DE PANTALLAS
        // ==========================================
        DisplayTopologyCanvas {
            selectedMode: root.selectedMode
            selectedScale: root.selectedScale
            selectedTransform: root.selectedTransform
        }

        // ==========================================
        // 3. SELECTOR DE PANTALLA ACTIVA
        // ==========================================
        DisplaySelectorTabs {}

        // ==========================================
        // 4. TARJETA UNIFICADA DE CONFIGURACIÓN
        // ==========================================
        DisplaySettingsCard {
            id: settingsCard
            selectedMode: root.selectedMode
            selectedScale: root.selectedScale
            selectedTransform: root.selectedTransform
            openMenu: root.openMenu
            navIndex: root.navIndex
            isKeyNavActive: root.isKeyNavActive
            menuNavIndex: root.menuNavIndex
            modeOptions: root.modeOptions
            scaleOptions: root.scaleOptions
            orientationOptions: root.orientationOptions

            onModeSelected: mode => {
                root.selectedMode = mode;
                root.openMenu = "";
            }
            onScaleSelected: scale => {
                root.selectedScale = scale;
                root.openMenu = "";
            }
            onTransformSelected: transform => {
                root.selectedTransform = transform;
                root.openMenu = "";
            }
            onMenuToggled: menuName => {
                root.toggleMenu(menuName);
            }
        }

        // ==========================================
        // 5. ARREGLO RELATIVO Y BOTÓN DE APLICAR
        // ==========================================
        DisplayActionButtons {
            hasPendingChanges: root.hasPendingChanges
            isKeyFocused: root.isKeyNavActive && root.navIndex === 4
            onApplyClicked: root.applyCurrentConfig()
        }
    }
}
