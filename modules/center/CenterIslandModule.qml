import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "../../theme"
import "../../components"
import "../../services"

Item {
    id: root

    property bool isPillHovered: false
    readonly property bool isBatteryToast: notificationToastView.isBatteryToast && NotificationService.isToastActive
    readonly property bool isBatteryAlertActive: batteryAlertIslandView.isActive
    readonly property bool isBatteryAlertDisplaying: batteryAlertIslandView.isActive && !ClipboardService.isOpen && !LauncherService.isOpen && !NotificationService.isCenterOpen && !NotificationService.isToastActive && !OsdService.isVisible
    readonly property color batteryBorderColor: batteryAlertIslandView.alertBorderColor
    readonly property color batteryBgColor: batteryAlertIslandView.alertBgColor
    readonly property real batteryBorderWidth: batteryAlertIslandView.alertBorderWidth
    readonly property bool isMediaHovered: (!ClipboardService.isOpen && !LauncherService.isOpen && !NotificationService.isCenterOpen && !NotificationService.isToastActive && !OsdService.isVisible && !batteryAlertIslandView.isActive) && (isPillHovered || mediaView.isHovered)

    // Estados para control manual y temporizador de gracia
    property bool forceClock: false
    property bool manualMediaActive: false

    // Temporizador de gracia de 5 segundos al retirar el cursor de música en pausa
    Timer {
        id: graceTimer
        interval: 5000
        onTriggered: {
            root.manualMediaActive = false;
        }
    }

    // Cooldown anti-rebote para touchpad (absorbe la inercia de libinput de ~300ms)
    property bool _wheelLocked: false
    Timer {
        id: wheelCooldown
        interval: 350
        onTriggered: root._wheelLocked = false
    }

    // Evaluación reactiva de modo:
    // 1. Si no hay reproductor activo en memoria -> Reloj
    // 2. Si el usuario forzó el reloj (clic derecho / scroll en media) -> Reloj
    // 3. Si está reproduciendo activamente -> Multimedia
    // 4. Si el usuario lo despertó manualmente (clic rueda ratón / scroll en reloj) -> Multimedia
    // 5. Si está en pausa y el cursor está encima de la música (Regla 1: Anti-frustración) -> Multimedia
    // 6. Si está en pausa y corre el temporizador de gracia (Regla 2: 5s grace period) -> Multimedia
    readonly property bool isMediaActive: {
        if (batteryAlertIslandView.isActive) return false;
        if (!MediaService.hasMedia || MediaService.title === "") return false;
        if (root.forceClock) return false;
        if (MediaService.isPlaying) return true;
        if (root.manualMediaActive) return true;
        if (root.isMediaHovered) return true;
        if (graceTimer.running) return true;
        return false;
    }

    // Indicador para animar el ancho solo al cambiar entre modos (Reloj <-> Media),
    // dejando que MediaView anime su expansión en hover de forma 100% sincronizada sin desfase del contenedor.
    property bool _modeChanging: false
    Timer {
        id: modeTimer
        interval: Theme.animNormal + 50
        onTriggered: root._modeChanging = false
    }

    onIsMediaActiveChanged: {
        root._modeChanging = true;
        modeTimer.restart();
    }

    onIsMediaHoveredChanged: {
        if (root.isMediaHovered) {
            // Cancelar cuenta regresiva mientras el usuario interactúa con la música
            graceTimer.stop();
        } else {
            // Al retirar el ratón de la música en pausa, iniciar los 5 segundos de cortesía
            if (!MediaService.isPlaying && isMediaActive) {
                graceTimer.restart();
            }
        }
    }

    Connections {
        target: MediaService
        function onIsPlayingChanged() {
            if (MediaService.isPlaying) {
                root.forceClock = false;
                root.manualMediaActive = false;
                graceTimer.stop();
            } else {
                // Si se pausa externamente y el cursor no está encima, dar 5s antes de volver al reloj
                if (!root.isMediaHovered && isMediaActive) {
                    graceTimer.restart();
                }
            }
        }
        function onHasMediaChanged() {
            if (!MediaService.hasMedia) {
                root.forceClock = false;
                root.manualMediaActive = false;
                graceTimer.stop();
            }
        }
    }

    Connections {
        target: LauncherService
        function onIsOpenChanged() {
            if (LauncherService.isOpen) {
                searchField.text = "";
                Qt.callLater(() => {
                    searchField.forceActiveFocus();
                    root.ensureItemVisible(0);
                });
            }
        }
        function onSelectedIndexChanged() {
            root.ensureItemVisible(LauncherService.selectedIndex);
        }
    }

    Connections {
        target: NotificationService
        function onIsCenterOpenChanged() {
            if (NotificationService.isCenterOpen) {
                Qt.callLater(() => {
                    notifCenterView.forceActiveFocus();
                });
            }
        }
    }

    Connections {
        target: ClipboardService
        function onIsOpenChanged() {
            if (ClipboardService.isOpen) {
                // Focus handled internally by ClipboardIslandView
            }
        }
    }

    function wakeMedia() {
        if (MediaService.hasMedia && MediaService.title !== "") {
            root.forceClock = false;
            root.manualMediaActive = true;
            if (!root.isMediaHovered) {
                graceTimer.restart();
            }
        }
    }

    function dismissToClock() {
        root.forceClock = true;
        root.manualMediaActive = false;
        graceTimer.stop();
    }

    function handleWheel() {
        if (ClipboardService.isOpen || LauncherService.isOpen || NotificationService.isCenterOpen || OsdService.isVisible || batteryAlertIslandView.isActive) return;
        if (root._wheelLocked) return;
        root._wheelLocked = true;
        wheelCooldown.restart();

        if (root.isMediaActive) {
            root.dismissToClock();
        } else {
            root.wakeMedia();
        }
    }

    // WheelHandler a nivel superior que cubre toda la cápsula central (solo activo en reloj/media para conmutar)
    WheelHandler {
        target: null
        orientation: Qt.Vertical | Qt.Horizontal
        enabled: !ClipboardService.isOpen && !LauncherService.isOpen && !NotificationService.isCenterOpen && !OsdService.isVisible && !batteryAlertIslandView.isActive
        onWheel: event => {
            root.handleWheel();
        }
    }

    // Dimensiones unificadas para las vistas modales de la Isla (Launcher, Notificaciones, Clipboard)
    readonly property int modalWidth: 370 - (6 * 2) // 358px (+40px más ancho)
    readonly property int modalHeight: 343

    readonly property int launcherWidth: modalWidth
    readonly property int launcherHeight: modalHeight
    readonly property int notificationCenterWidth: modalWidth
    readonly property int notificationCenterHeight: modalHeight
    readonly property int clipboardWidth: modalWidth
    readonly property int clipboardHeight: modalHeight

    implicitWidth: {
        if (ClipboardService.isOpen || LauncherService.isOpen || NotificationService.isCenterOpen) {
            return modalWidth;
        }
        if (OsdService.isVisible) {
            return osdIslandView.implicitWidth;
        }
        if (NotificationService.isToastActive) {
            return notificationToastView.implicitWidth;
        }
        if (batteryAlertIslandView.isActive) {
            return batteryAlertIslandView.implicitWidth;
        }
        return Math.round(isMediaActive ? mediaView.implicitWidth : clockView.implicitWidth);
    }

    implicitHeight: {
        if (ClipboardService.isOpen || LauncherService.isOpen || NotificationService.isCenterOpen) {
            return modalHeight;
        }
        if (NotificationService.isToastActive && NotificationService.isToastExpanded) {
            return notificationToastView.implicitHeight;
        }
        return 28;
    }

    width: implicitWidth
    height: implicitHeight
    clip: true

    Behavior on implicitWidth {
        enabled: !root.isMediaActive || root._modeChanging || ClipboardService.isOpen || LauncherService.isOpen || NotificationService.isCenterOpen || OsdService.isVisible || NotificationService.isToastActive || batteryAlertIslandView.isActive
        NumberAnimation {
            duration: Theme.animNormal
            easing.type: Easing.OutCubic
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Theme.animNormal
            easing.type: Easing.OutCubic
        }
    }

    function resolveAppIcon(iconName) {
        if (!iconName) return Quickshell.iconPath("application-x-executable") || "";
        let lower = iconName.toLowerCase().trim();
        if (lower === "btop" || lower.includes("btop")) {
            return Qt.resolvedUrl("../../assets/icons/btop.svg");
        }
        if (lower === "htop" || lower.includes("htop")) {
            return Qt.resolvedUrl("../../assets/icons/htop.svg");
        }
        if (iconName.startsWith("/") || iconName.startsWith("file://")) return iconName;
        if (Quickshell.hasThemeIcon(iconName)) return Quickshell.iconPath(iconName);
        if (Quickshell.hasThemeIcon(lower)) return Quickshell.iconPath(lower);
        return Quickshell.iconPath("application-x-executable") || "";
    }

    function ensureItemVisible(idx) {
        if (!appListView || appListView.count === 0) return;
        let slotHeight = 44; // 40 item height + 4 spacing
        let visibleCount = 6;
        let topIndex = Math.round(appListView.contentY / slotHeight);
        let bottomIndex = topIndex + visibleCount - 1;

        if (idx < topIndex) {
            appListView.positionViewAtIndex(idx, ListView.Beginning);
        } else if (idx > bottomIndex) {
            appListView.positionViewAtIndex(idx, ListView.End);
        }
    }

    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

    // 1. Vista de Reloj (Reposo / En Pausa tras gracia)
    ClockView {
        id: clockView
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: implicitWidth
        height: 28
        opacity: (!ClipboardService.isOpen && !LauncherService.isOpen && !NotificationService.isCenterOpen && !NotificationService.isToastActive && !OsdService.isVisible && !batteryAlertIslandView.isActive && root.height <= 36) ? (root.isMediaActive ? 0.0 : 1.0) : 0.0
        scale: opacity > 0.8 ? 1.0 : 0.94
        transformOrigin: Item.Center
        visible: opacity > 0.01

        onWakeMediaRequested: root.wakeMedia()
        onWheelRequested: root.handleWheel()

        Behavior on opacity {
            NumberAnimation {
                duration: 70
                easing.type: Easing.OutQuad
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 70
                easing.type: Easing.OutQuad
            }
        }
    }

    // 2. Vista de Reproductor Multimedia (Dynamic Island)
    MediaView {
        id: mediaView
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: implicitWidth
        height: 28
        isContainerHovered: root.isPillHovered
        opacity: (ClipboardService.isOpen || LauncherService.isOpen || NotificationService.isCenterOpen || NotificationService.isToastActive || OsdService.isVisible || batteryAlertIslandView.isActive) ? 0.0 : (root.isMediaActive ? 1.0 : 0.0)
        visible: opacity > 0.01

        onDismissToClockRequested: root.dismissToClock()
        onWheelRequested: root.handleWheel()

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutQuad
            }
        }
    }

    // 2.5. Vista de Alerta de Batería Crítica / Confirmación de Cargador Conectado
    BatteryAlertIslandView {
        id: batteryAlertIslandView
        anchors.centerIn: parent
        isHovered: root.isPillHovered
        opacity: (!ClipboardService.isOpen && !LauncherService.isOpen && !NotificationService.isCenterOpen && !NotificationService.isToastActive && !OsdService.isVisible && batteryAlertIslandView.isActive) ? 1.0 : 0.0
        scale: opacity > 0.5 ? 1.0 : 0.94
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutQuad
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutQuad
            }
        }
    }

    // 3.5. Vista de OSD (Volumen / Brillo / Micrófono en la Dynamic Island)
    OsdIslandView {
        id: osdIslandView
        anchors.centerIn: parent
        opacity: (!ClipboardService.isOpen && !LauncherService.isOpen && !NotificationService.isCenterOpen && OsdService.isVisible) ? 1.0 : 0.0
        scale: opacity > 0.5 ? 1.0 : 0.94
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutQuad
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutQuad
            }
        }
    }

    // 3. Vista de Notificación Emergente (Toast en la Dynamic Island)
    NotificationToastView {
        id: notificationToastView
        anchors.fill: parent
        opacity: (!ClipboardService.isOpen && !LauncherService.isOpen && !NotificationService.isCenterOpen && NotificationService.isToastActive && !OsdService.isVisible) ? 1.0 : 0.0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutQuad
            }
        }
    }

    // 4. Vista Unificada del Centro de Notificaciones (Isla Metamorfoseada)
    Item {
        id: notifCenterWrapper
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.notificationCenterWidth
        height: root.notificationCenterHeight
        opacity: (!ClipboardService.isOpen && !LauncherService.isOpen && NotificationService.isCenterOpen && root.width >= 260) ? 1.0 : 0.0
        scale: opacity > 0.5 ? 1.0 : 0.96
        transformOrigin: Item.Top
        visible: NotificationService.isCenterOpen && opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: NotificationService.isCenterOpen ? 90 : 0
                easing.type: Easing.OutQuad
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 90
                easing.type: Easing.OutQuad
            }
        }

        NotificationCenterView {
            id: notifCenterView
            anchors.fill: parent
        }
    }

    // 5. Vista Unificada del Lanzador de Aplicaciones (Isla Metamorfoseada)
    Item {
        id: launcherView
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.launcherWidth
        height: root.launcherHeight
        opacity: (!ClipboardService.isOpen && LauncherService.isOpen && root.width >= 260) ? 1.0 : 0.0
        scale: opacity > 0.5 ? 1.0 : 0.96
        transformOrigin: Item.Top
        visible: LauncherService.isOpen && opacity > 0.01

        // Absorbe clics dentro de la isla del lanzador para evitar que se propaguen a dismissArea
        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPressed: mouse => mouse.accepted = true
        }

        Behavior on opacity {
            NumberAnimation {
                duration: LauncherService.isOpen ? 90 : 0
                easing.type: Easing.OutQuad
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 90
                easing.type: Easing.OutQuad
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 10
            anchors.bottomMargin: 8
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            spacing: 6

            // --- Barra de Búsqueda Superior Integrada (Compacta, con margen superior y sin bordes azules) ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: 7
                color: searchField.activeFocus ? "#242424" : "#1c1c1c"
                border.width: 1
                border.color: searchField.activeFocus ? "#383838" : "#262626"

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: "󰍉"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: searchField.activeFocus ? Theme.text : Theme.textMuted
                        Layout.alignment: Qt.AlignVCenter
                    }

                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Normal
                        color: "#ffffff"
                        selectionColor: "#454545"
                        selectedTextColor: "#ffffff"
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        selectByMouse: true
                        mouseSelectionMode: TextInput.SelectCharacters

                        onTextChanged: {
                            LauncherService.searchQuery = text;
                        }

                        Text {
                            text: "Search apps, math, >cmd, ?web..."
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.textMuted
                            visible: !searchField.text
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                event.accepted = true;
                                LauncherService.close();
                                return;
                            }
                            if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                event.accepted = true;
                                LauncherService.nextItem();
                                return;
                            }
                            if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                                event.accepted = true;
                                LauncherService.prevItem();
                                return;
                            }
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                event.accepted = true;
                                LauncherService.launchCurrent();
                                return;
                            }
                        }
                    }

                    // Botón para limpiar campo de búsqueda (idéntico al de Clipboard)
                    MouseArea {
                        implicitWidth: 16
                        implicitHeight: 16
                        visible: searchField.text !== ""
                        cursorShape: Qt.PointingHandCursor
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: {
                            searchField.text = "";
                            searchField.forceActiveFocus();
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: parent.containsMouse ? Theme.text : Theme.textMuted
                        }
                    }
                }
            }

            // --- Línea Divisoria Sutil ---
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.dividerColor
                visible: LauncherService.filteredItems.length > 0
            }

            // --- Lista de Aplicaciones y Spotlight con Scroll por Hardware ---
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 280
                clip: true

                Text {
                    anchors.centerIn: parent
                    visible: LauncherService.filteredItems.length === 0
                    text: LauncherService.searchQuery !== ""
                          ? `No matches for "${LauncherService.searchQuery}"`
                          : "Loading applications..."
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.textMuted
                }

                ListView {
                    id: appListView
                    anchors.fill: parent
                    visible: LauncherService.filteredItems.length > 0
                    model: LauncherService.filteredItems
                    currentIndex: LauncherService.selectedIndex
                    spacing: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    snapMode: ListView.SnapToItem

                    WheelHandler {
                        target: null
                        orientation: Qt.Vertical
                        onWheel: event => {
                            let maxScroll = Math.max(0, appListView.contentHeight - appListView.height);
                            if (maxScroll <= 0) return;
                            let step = 44;
                            if (event.angleDelta.y < 0) {
                                appListView.contentY = Math.min(maxScroll, appListView.contentY + step);
                            } else if (event.angleDelta.y > 0) {
                                appListView.contentY = Math.max(0, appListView.contentY - step);
                            }
                        }
                    }

                    delegate: Rectangle {
                        id: appItem
                        width: (appListView.contentHeight > appListView.height) ? (appListView.width - 12) : appListView.width
                        height: 42
                        radius: 7

                        readonly property bool isSelected: index === LauncherService.selectedIndex

                        // Señalización elegante mediante fondo tonal neutro suave (cero bordes o líneas azules)
                        color: isSelected ? "#2e2e2e" : (itemMouse.containsMouse ? "#222222" : "transparent")
                        border.width: 0

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Item {
                                implicitWidth: 24
                                implicitHeight: 24
                                Layout.alignment: Qt.AlignVCenter

                                IconImage {
                                    id: appIconImg
                                    anchors.fill: parent
                                    source: (!modelData.isSpecial && modelData.icon) ? root.resolveAppIcon(modelData.icon) : ""
                                    visible: !modelData.isSpecial && source !== "" && status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.isSpecial ? modelData.iconGlyph : "󰘔"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 16
                                    color: {
                                        if (modelData.specialType === "calc") return Theme.wsActiveColor;
                                        if (modelData.specialType === "cmd") return Theme.warning;
                                        if (modelData.specialType === "web") return Theme.highlight;
                                        return Theme.textSecondary;
                                    }
                                    visible: modelData.isSpecial || !appIconImg.visible
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: modelData.name || ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: appItem.isSelected ? Font.Medium : Font.Normal
                                    color: appItem.isSelected ? "#ffffff" : Theme.text
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: modelData.comment || modelData.genericName || "Application"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: modelData.isSpecial && modelData.specialType === "calc" ? Theme.wsActiveColor : Theme.textMuted
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Badge de acción rápida minimalista y neutro en selección
                            Rectangle {
                                implicitWidth: enterBadgeText.implicitWidth + 8
                                implicitHeight: 16
                                radius: 4
                                color: Qt.rgba(255, 255, 255, 0.06)
                                visible: appItem.isSelected
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    id: enterBadgeText
                                    anchors.centerIn: parent
                                    text: modelData.badge || "↵ Open"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    font.weight: Font.Normal
                                    color: Qt.rgba(1, 1, 1, 0.45)
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                LauncherService.launchItem(modelData);
                            }
                        }
                    }
                }

                // --- Custom Minimal ScrollBar (Idéntico a Clipboard y Notificaciones) ---
                Item {
                    id: scrollTrack
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    width: 14
                    visible: appListView.visible && (appListView.contentHeight > appListView.height)
                    z: 20

                    readonly property real maxContentY: Math.max(1, appListView.contentHeight - appListView.height)
                    readonly property real maxThumbY: Math.max(0, height - scrollThumb.height)

                    // Cápsula / Pastilla del Scrollbar (Minimalista, sutil y dockeada a la derecha)
                    Rectangle {
                        id: scrollThumb
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        width: scrollMouse.containsMouse || scrollMouse.pressed ? 4 : 3
                        radius: width / 2
                        height: Math.max(28, Math.min(scrollTrack.height, (appListView.height / Math.max(appListView.height, appListView.contentHeight)) * scrollTrack.height))
                        y: scrollTrack.maxThumbY > 0
                           ? (Math.max(0, Math.min(1, appListView.contentY / scrollTrack.maxContentY)) * scrollTrack.maxThumbY)
                           : 0

                        // Color sutil integrado a la paleta oscura
                        color: scrollMouse.pressed 
                               ? Qt.rgba(1, 1, 1, 0.55) 
                               : (scrollMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.18))

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on width { NumberAnimation { duration: Theme.animFast } }
                    }

                    // Interacción: Clic directo para saltar o arrastre fluido (drag)
                    MouseArea {
                        id: scrollMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        property real dragStartY: 0
                        property real dragStartContentY: 0
                        property bool dragging: false

                        onPressed: mouse => {
                            if (mouse.y >= scrollThumb.y && mouse.y <= scrollThumb.y + scrollThumb.height) {
                                dragging = true;
                                dragStartY = mouse.y;
                                dragStartContentY = appListView.contentY;
                            } else {
                                let targetThumbY = mouse.y - (scrollThumb.height / 2);
                                let ratio = Math.max(0, Math.min(1, targetThumbY / Math.max(1, scrollTrack.maxThumbY)));
                                appListView.contentY = ratio * scrollTrack.maxContentY;
                                dragging = true;
                                dragStartY = mouse.y;
                                dragStartContentY = appListView.contentY;
                            }
                        }

                        onPositionChanged: mouse => {
                            if (dragging && pressed && scrollTrack.maxThumbY > 0) {
                                let dy = mouse.y - dragStartY;
                                let deltaRatio = dy / scrollTrack.maxThumbY;
                                let targetContentY = dragStartContentY + (deltaRatio * scrollTrack.maxContentY);
                                appListView.contentY = Math.max(0, Math.min(scrollTrack.maxContentY, targetContentY));
                            }
                        }

                        onReleased: {
                            dragging = false;
                        }

                        onCanceled: {
                            dragging = false;
                        }
                    }
                }
            }
        }
    }

    // 6. Vista Unificada del Portapapeles (Isla Metamorfoseada)
    Item {
        id: clipboardView
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.clipboardWidth
        height: root.clipboardHeight
        opacity: (ClipboardService.isOpen && root.width >= 260) ? 1.0 : 0.0
        scale: opacity > 0.5 ? 1.0 : 0.96
        transformOrigin: Item.Top
        visible: ClipboardService.isOpen && opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: ClipboardService.isOpen ? 90 : 0
                easing.type: Easing.OutQuad
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 90
                easing.type: Easing.OutQuad
            }
        }

        ClipboardIslandView {
            id: clipboardIslandView
            anchors.fill: parent
        }
    }
}
