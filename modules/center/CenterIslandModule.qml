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


    // Estados para control manual y temporizador de gracia

    // Temporizador de gracia de 5 segundos al retirar el cursor de música en pausa
    Timer {
        interval: 5000
        onTriggered: {
            root.manualMediaActive = false;
        }
    }

    // Cooldown anti-rebote para touchpad (absorbe la inercia de libinput de ~300ms)
    Timer {
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
        if (!MediaService.hasMedia || MediaService.title === "") return false;
        if (root.forceClock) return false;
        if (MediaService.isPlaying) return true;
        if (root.manualMediaActive) return true;
        if (root.isMediaHovered) return true;
        if (graceTimer.running) return true;
        return false;
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
            root.ensureItemVisible(LauncherService.selectedIndex);
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

        if (LauncherService.isOpen || NotificationService.isCenterOpen) return;
        if (root._wheelLocked) return;
        root._wheelLocked = true;
        wheelCooldown.restart();

        if (root.isMediaActive) {
            root.dismissToClock();
        } else {
            root.wakeMedia();
        }
    }

    // WheelHandler a nivel superior que cubre toda la cápsula central
    WheelHandler {
        target: null
        orientation: Qt.Vertical | Qt.Horizontal
        onWheel: event => {
            root.handleWheel();
        }
    }

    // Dimensiones optimizadas: más angosto (330px total) y altura calibrada para múltiplos exactos de ítems

    implicitWidth: {
        if (LauncherService.isOpen) {
            return launcherWidth;
        }
        if (NotificationService.isCenterOpen) {
            return notificationCenterWidth;
        }
        if (NotificationService.isToastActive) {
            return notificationToastView.implicitWidth;
        }
        return Math.round(isMediaActive ? mediaView.implicitWidth : clockView.implicitWidth);
    }

    implicitHeight: {
        if (LauncherService.isOpen) {
            return launcherHeight;
        }
        if (NotificationService.isCenterOpen) {
            return notificationCenterHeight;
        }
        return 28;
    }

    width: implicitWidth
    height: implicitHeight
    clip: true

    Behavior on implicitWidth {
        enabled: !(root.isMediaActive && mediaView.isHovered)
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
        if (iconName.startsWith("/") || iconName.startsWith("file://")) return iconName;
        if (Quickshell.hasThemeIcon(iconName)) return Quickshell.iconPath(iconName);
        let lower = iconName.toLowerCase();
        if (Quickshell.hasThemeIcon(lower)) return Quickshell.iconPath(lower);
        return Quickshell.iconPath("application-x-executable") || "";
    }

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
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: implicitWidth
        height: 28
        opacity: (!LauncherService.isOpen && !NotificationService.isCenterOpen && !NotificationService.isToastActive && root.height <= 36) ? (root.isMediaActive ? 0.0 : 1.0) : 0.0
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
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: implicitWidth
        height: 28
        opacity: (LauncherService.isOpen || NotificationService.isCenterOpen || NotificationService.isToastActive) ? 0.0 : (root.isMediaActive ? 1.0 : 0.0)
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

    // 3. Vista de Notificación Emergente (Toast en la Dynamic Island)
    NotificationToastView {
        anchors.fill: parent
        opacity: (!LauncherService.isOpen && !NotificationService.isCenterOpen && NotificationService.isToastActive) ? 1.0 : 0.0
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
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.notificationCenterWidth
        height: root.notificationCenterHeight
        opacity: (!LauncherService.isOpen && NotificationService.isCenterOpen && root.width >= 260) ? 1.0 : 0.0
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
            anchors.fill: parent
        }
    }

    // 5. Vista Unificada del Lanzador de Aplicaciones (Isla Metamorfoseada)
    Item {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.launcherWidth
        height: root.launcherHeight
        opacity: (LauncherService.isOpen && root.width >= 260) ? 1.0 : 0.0
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
                    anchors.rightMargin: 6
                    spacing: 8

                    Text {
                        text: "󰍉"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: searchField.activeFocus ? Theme.text : Theme.textMuted
                        Layout.alignment: Qt.AlignVCenter
                    }

                    TextInput {
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
                            text: "Buscar aplicaciones..."
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

                    Rectangle {
                        implicitWidth: escBadgeText.implicitWidth + 8
                        implicitHeight: 18
                        radius: 4
                        color: Qt.rgba(1, 1, 1, 0.05)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: "ESC"
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.Normal
                            color: Qt.rgba(1, 1, 1, 0.35)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: LauncherService.close()
                        }
                    }
                }
            }

            // --- Línea Divisoria Sutil ---
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.dividerColor
                visible: LauncherService.filteredApplications.length > 0
            }

            // --- Lista de Aplicaciones con Scroll por Hardware (Exactamente 6 ítems sin recorte de texto) ---
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 260
                clip: true

                Text {
                    anchors.centerIn: parent
                    visible: LauncherService.filteredApplications.length === 0
                    text: LauncherService.searchQuery !== ""
                          ? `No se encontró "${LauncherService.searchQuery}"`
                          : "Cargando aplicaciones..."
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.textMuted
                }

                ListView {
                    anchors.fill: parent
                    visible: LauncherService.filteredApplications.length > 0
                    model: LauncherService.filteredApplications
                    currentIndex: LauncherService.selectedIndex
                    spacing: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    snapMode: ListView.SnapToItem

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 4
                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: parent.pressed ? "#555555" : (parent.hovered ? "#444444" : "#303030")
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }
                    }

                    delegate: Rectangle {
                        width: appListView.width
                        height: 40
                        radius: 7


                        // Señalización elegante mediante fondo tonal neutro suave (cero bordes o líneas azules)
                        color: isSelected ? "#2e2e2e" : (itemMouse.containsMouse ? "#222222" : "transparent")
                        border.width: 0

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            IconImage {
                                implicitWidth: 24
                                implicitHeight: 24
                                source: root.resolveAppIcon(modelData.icon)
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name || "Aplicación"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: isSelected ? Font.DemiBold : Font.Normal
                                    color: isSelected ? "#ffffff" : Theme.text
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: modelData.genericName || modelData.comment || ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: isSelected ? Qt.rgba(1, 1, 1, 0.70) : Theme.textSecondary
                                    elide: Text.ElideRight
                                }
                            }

                            // Badge sutil y discreto de ejecución rápida (no compite con el nombre de la app)
                            RowLayout {
                                spacing: 4
                                visible: isSelected
                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    implicitWidth: enterBadgeText.implicitWidth + 8
                                    implicitHeight: 18
                                    radius: 4
                                    color: Qt.rgba(1, 1, 1, 0.05)
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.08)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "↵ abrir"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.weight: Font.Normal
                                        color: Qt.rgba(1, 1, 1, 0.35)
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                LauncherService.launchApp(modelData);
                            }
                        }
                    }
                }
            }
        }
    }
}
