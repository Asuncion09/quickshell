import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../../theme"
import "../../components"
import "../../services"

Item {
    id: root

    focus: true

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true;
            NotificationService.closeCenter();
        }
    }

    Timer {
        id: focusTimer
        interval: 30
        repeat: false
        onTriggered: {
            if (NotificationService.isCenterOpen) {
                root.forceActiveFocus();
            }
        }
    }

    Connections {
        target: NotificationService
        function onIsCenterOpenChanged() {
            if (NotificationService.isCenterOpen) {
                Qt.callLater(() => root.forceActiveFocus());
                focusTimer.restart();
            }
        }
    }

    // Absorbe clics dentro de la isla para evitar que se propaguen al dismissArea
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: mouse => {
            mouse.accepted = true;
            root.forceActiveFocus();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: 8
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 6

        // --- 1. Cabecera del Centro de Notificaciones ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            spacing: 6

            // Icono de campana y título (Clic para cerrar y volver al reloj, sin hover visual)
            Rectangle {
                id: titleBtn
                implicitWidth: titleRow.implicitWidth + 8
                implicitHeight: 26
                radius: 6
                color: "transparent"
                border.width: 0
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    id: titleRow
                    anchors.centerIn: parent
                    spacing: 7

                    Text {
                        text: NotificationService.dnd ? "󰂛" : "󰂚"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: NotificationService.dnd ? Theme.warning : Theme.highlight
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: "Notifications"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        visible: NotificationService.count > 0
                        implicitWidth: Math.max(18, countText.implicitWidth + 8)
                        implicitHeight: 16
                        radius: 8
                        color: "#242424"
                        border.color: "#383838"
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: NotificationService.count
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: Theme.text
                        }
                    }
                }

                MouseArea {
                    id: titleMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        NotificationService.closeCenter();
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: 26

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        NotificationService.closeCenter();
                    }
                }
            }

            // Botón de Modo No Molestar (DND) (Píldora circular borderless)
            Rectangle {
                implicitWidth: 26
                implicitHeight: 26
                radius: 13
                color: NotificationService.dnd 
                       ? (dndMouse.containsMouse ? Qt.rgba(241/255, 196/255, 15/255, 0.28) : Qt.rgba(241/255, 196/255, 15/255, 0.18))
                       : (dndMouse.containsMouse ? Theme.surfaceHover : "transparent")
                border.width: 0
                Layout.alignment: Qt.AlignVCenter

                scale: dndMouse.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: NotificationService.dnd ? "󰂛" : "󰂚"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: NotificationService.dnd ? Theme.warning : (dndMouse.containsMouse ? Theme.text : Theme.textSecondary)
                }

                MouseArea {
                    id: dndMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.toggleDnd()
                }
            }

            // Botón de Limpiar todas (Píldora circular borderless)
            Rectangle {
                implicitWidth: 26
                implicitHeight: 26
                radius: 13
                visible: NotificationService.count > 0
                color: clearMouse.containsMouse ? Theme.surfaceHover : "transparent"
                border.width: 0
                Layout.alignment: Qt.AlignVCenter

                scale: clearMouse.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: "󰎟"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: clearMouse.containsMouse ? Theme.critical : Theme.textSecondary
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.clearAll()
                }
            }
        }

        // --- 2. Línea Divisoria Sutil ---
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.dividerColor
        }

        // --- 3. Contenedor Principal (Estado Vacío o Lista con Scroll) ---
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // Estado Vacío Elegante
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6
                visible: NotificationService.count === 0

                Text {
                    text: "󰂚"
                    font.family: Theme.fontFamily
                    font.pixelSize: 32
                    color: Qt.rgba(1, 1, 1, 0.12)
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "No pending notifications"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Theme.textSecondary
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "All caught up"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textMuted
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // Lista de Tarjetas de Notificaciones
            ListView {
                id: notifListView
                anchors.fill: parent
                visible: NotificationService.count > 0
                model: NotificationService.notifications
                spacing: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                WheelHandler {
                    target: null
                    orientation: Qt.Vertical
                    onWheel: event => {
                        let maxScroll = Math.max(0, notifListView.contentHeight - notifListView.height);
                        if (maxScroll <= 0) return;
                        let step = 60;
                        if (event.angleDelta.y < 0) {
                            notifListView.contentY = Math.min(maxScroll, notifListView.contentY + step);
                        } else if (event.angleDelta.y > 0) {
                            notifListView.contentY = Math.max(0, notifListView.contentY - step);
                        }
                    }
                }

                footer: Item {
                    width: notifListView.width
                    height: 6
                }

                delegate: Item {
                    id: cardWrapper
                    readonly property var notifItem: modelData
                    width: (notifListView.contentHeight > notifListView.height) ? (notifListView.width - 8) : notifListView.width
                    implicitHeight: cardBg.height + 8
                    height: implicitHeight

                    // 1. Silueta exacta para la sombra volumétrica
                    Rectangle {
                        id: cardShadowSource
                        anchors.fill: cardBg
                        radius: cardBg.radius
                        color: "#000000"
                        visible: false
                    }

                    // 2. Sombra volumétrica realista por hardware (MultiEffect)
                    MultiEffect {
                        source: cardShadowSource
                        anchors.fill: cardShadowSource
                        visible: Theme.pillShadowEnabled
                        shadowEnabled: true
                        shadowColor: "#000000"
                        shadowOpacity: cardHover.hovered ? 0.78 : 0.55
                        shadowBlur: 0.50
                        shadowVerticalOffset: cardHover.hovered ? 3.5 : 2.0
                        shadowHorizontalOffset: 0
                        autoPaddingEnabled: true

                        Behavior on shadowOpacity {
                            NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad }
                        }
                        Behavior on shadowVerticalOffset {
                            NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad }
                        }
                    }

                    // 3. Tarjeta visual elevada con estética consistente con el Centro de Control
                    Rectangle {
                        id: cardBg
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        anchors.topMargin: 2
                        height: cardContent.implicitHeight + 16
                        radius: 10

                        // Superficie tonal táctil idéntica a los módulos del Centro de Control
                        color: cardHover.hovered ? Theme.surfaceHover : Theme.surfaceBase
                        border.width: 1
                        border.color: cardHover.hovered ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                        // Gestor de hover unificado directamente anclado a la geometría de la tarjeta
                        HoverHandler {
                            id: cardHover
                        }

                        // Clic en la tarjeta: activar notificación y enfocar ventana en Hyprland
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            z: -1
                            onClicked: {
                                if (cardWrapper.notifItem) {
                                    NotificationService.activateNotification(cardWrapper.notifItem.id);
                                }
                            }
                        }

                        ColumnLayout {
                            id: cardContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            anchors.topMargin: 8
                            spacing: 4

                            // Fila superior: Icono de app + Nombre de app + Tiempo relativo + Botón de descarte
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                Item {
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    Layout.alignment: Qt.AlignVCenter

                                    IconImage {
                                        id: cardIconImg
                                        anchors.fill: parent
                                        source: (modelData.appIcon && !modelData.appIcon.startsWith("")) ? modelData.appIcon : ""
                                        visible: source !== "" && status === Image.Ready
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: {
                                            let a = (modelData.appName || "").toLowerCase();
                                            if (a.includes("antigravity") || a.includes("code") || a.includes("vscode")) return "󰅩";
                                            if (a.includes("term") || a.includes("bash") || a.includes("shell") || a.includes("kitty") || a.includes("alacritty")) return "󰆍";
                                            return "󰂚";
                                        }
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        color: modelData.urgency === 2 ? Theme.critical : Theme.wsActiveColor
                                        visible: !cardIconImg.visible
                                    }
                                }

                                Text {
                                    text: modelData.appName || "System"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: modelData.urgency === 2 ? Theme.critical : Theme.wsActiveColor
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: "•"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: Theme.textMuted
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: NotificationService.formatRelativeTime(modelData.timestamp)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: Theme.textMuted
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                // Indicador de urgencia si es crítica
                                Rectangle {
                                    implicitWidth: 5
                                    implicitHeight: 5
                                    radius: 2.5
                                    color: Theme.critical
                                    visible: modelData.urgency === 2
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Item { Layout.fillWidth: true }

                                // Botón de descarte individual (píldora circular borderless)
                                Rectangle {
                                    implicitWidth: 20
                                    implicitHeight: 20
                                    radius: 10
                                    color: itemDismissMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                    border.width: 0
                                    Layout.alignment: Qt.AlignVCenter

                                    scale: itemDismissMouse.pressed ? 0.88 : 1.0
                                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        color: itemDismissMouse.containsMouse ? Theme.critical : Theme.textMuted
                                    }

                                    MouseArea {
                                        id: itemDismissMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            NotificationService.dismiss(modelData.id);
                                        }
                                    }
                                }
                            }

                            // Título de la notificación (Summary)
                            Text {
                                Layout.fillWidth: true
                                visible: !modelData.isColorPicker && modelData.summary && modelData.summary !== "" && modelData.summary.toLowerCase() !== (modelData.appName || "").toLowerCase()
                                text: (modelData.summary || "").trim().replace(/\r?\n|\r/g, " ").replace(/\s+/g, " ")
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Theme.text
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            // Vista previa visual si es una captura de pantalla
                            Rectangle {
                                visible: modelData.isScreenshot && modelData.screenshotPath && modelData.screenshotPath !== ""
                                Layout.fillWidth: true
                                implicitHeight: 88
                                radius: 6
                                color: Qt.rgba(0, 0, 0, 0.4)
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: (modelData.isScreenshot && modelData.screenshotPath) ? ("file://" + modelData.screenshotPath) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                    smooth: true
                                }

                                // Sombra inferior sutil para el nombre del archivo
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 24
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
                                    }
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 4
                                    text: {
                                        if (!modelData.screenshotPath) return "";
                                        let parts = modelData.screenshotPath.split("/");
                                        return parts[parts.length - 1];
                                    }
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 10
                                    color: Qt.rgba(255, 255, 255, 0.9)
                                    elide: Text.ElideMiddle
                                    width: parent.width - 10
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        NotificationService.openScreenshot(modelData.screenshotPath);
                                    }
                                }
                            }

                            // Botones de acción para capturas en el centro de notificaciones
                            RowLayout {
                                visible: modelData.isScreenshot && modelData.screenshotPath && modelData.screenshotPath !== ""
                                Layout.fillWidth: true
                                spacing: 6

                                Rectangle {
                                    implicitWidth: copyCenterShotLbl.implicitWidth + 18
                                    implicitHeight: 24
                                    radius: 12
                                    color: copyCenterShotM.containsMouse ? Qt.lighter(Theme.wsActiveColor, 1.1) : Theme.wsActiveColor

                                    Text {
                                        id: copyCenterShotLbl
                                        anchors.centerIn: parent
                                        text: "󰆏 Copiar imagen"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        color: "#161616"
                                    }
                                    MouseArea {
                                        id: copyCenterShotM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotificationService.copyScreenshotImage(modelData.screenshotPath)
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    implicitWidth: delCenterShotLbl.implicitWidth + 16
                                    implicitHeight: 24
                                    radius: 12
                                    color: delCenterShotM.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    border.color: delCenterShotM.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)

                                    Text {
                                        id: delCenterShotLbl
                                        anchors.centerIn: parent
                                        text: "󰅖 Borrar"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                        color: delCenterShotM.containsMouse ? "#ffffff" : Theme.textSecondary
                                    }
                                    MouseArea {
                                        id: delCenterShotM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotificationService.deleteScreenshot(modelData.id, modelData.screenshotPath)
                                    }
                                }
                            }

                            // Muestra de color si es un selector de color
                            Rectangle {
                                visible: modelData.isColorPicker && modelData.pickedColor && modelData.pickedColor !== ""
                                Layout.fillWidth: true
                                implicitHeight: 52
                                radius: 8
                                color: Qt.rgba(0, 0, 0, 0.35)
                                border.width: 1
                                border.color: Qt.rgba(255, 255, 255, 0.08)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 10

                                    Rectangle {
                                        implicitWidth: 36
                                        implicitHeight: 36
                                        radius: 6
                                        color: modelData.pickedColor || "transparent"
                                        border.width: 1
                                        border.color: Qt.rgba(255, 255, 255, 0.25)
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: modelData.pickedColor || ""
                                            font.family: "JetBrainsMono Nerd Font Propo"
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                            color: "#ffffff"
                                        }

                                        Text {
                                            text: modelData.pickedRgb !== "" ? modelData.pickedRgb : "Color copiado al portapapeles"
                                            font.family: "JetBrainsMono Nerd Font Propo"
                                            font.pixelSize: 10
                                            color: Theme.textMuted
                                        }
                                    }

                                    // Botón rápido copiar HEX
                                    Rectangle {
                                        implicitWidth: 30
                                        implicitHeight: 30
                                        radius: 15
                                        color: copyHexHistMouse.containsMouse ? Theme.wsActiveColor : Qt.rgba(1, 1, 1, 0.08)

                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰆏"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 12
                                            color: copyHexHistMouse.containsMouse ? "#161616" : Theme.text
                                        }

                                        MouseArea {
                                            id: copyHexHistMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotificationService.copyText(modelData.pickedColor)
                                        }
                                    }
                                }
                            }

                            // Cuerpo del mensaje (Body) - Formateo limpio sin bordes duros
                            Rectangle {
                                id: bodyBox
                                Layout.fillWidth: true
                                implicitHeight: bodyText.implicitHeight + (isCmd ? 10 : 0)
                                radius: 6
                                color: isCmd ? Qt.rgba(0, 0, 0, 0.35) : "transparent"
                                border.width: 0
                                visible: (!modelData.isScreenshot || !modelData.screenshotPath) && !modelData.isColorPicker && modelData.body && modelData.body !== ""

                                readonly property bool isCmd: {
                                    let b = (modelData.body || "");
                                    return b.indexOf("Command:") !== -1 || b.indexOf("bash -c") !== -1 || b.indexOf("sh ") !== -1 || b.indexOf("python") !== -1;
                                }

                                Text {
                                    id: bodyText
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.leftMargin: bodyBox.isCmd ? 8 : 0
                                    anchors.rightMargin: bodyBox.isCmd ? 8 : 0
                                    anchors.topMargin: bodyBox.isCmd ? 5 : 0
                                    text: {
                                        let b = (modelData.body || "").trim();
                                        return b.replace(/\r?\n|\r/g, " ").replace(/\s+/g, " ");
                                    }
                                    font.family: bodyBox.isCmd ? "JetBrainsMono Nerd Font Propo" : Theme.fontFamily
                                    font.pixelSize: bodyBox.isCmd ? 11 : 12
                                    font.weight: Font.Normal
                                    color: bodyBox.isCmd ? Qt.rgba(1, 1, 1, 0.88) : Theme.textSecondary
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }
                            }

                            // Botones de acción interactiva (píldoras suaves sin borde)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                visible: (!modelData.isScreenshot || !modelData.screenshotPath) && !modelData.isColorPicker && modelData.actions && modelData.actions.length > 0

                                Item { Layout.fillWidth: true }

                                Repeater {
                                    model: modelData.actions || []
                                    delegate: Rectangle {
                                        implicitWidth: actionLabel.implicitWidth + 18
                                        implicitHeight: 24
                                        radius: 12
                                        color: actionMouse.containsMouse ? Theme.wsActiveColor : Qt.rgba(1, 1, 1, 0.08)
                                        border.width: 0

                                        scale: actionMouse.pressed ? 0.92 : 1.0
                                        Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                        Text {
                                            id: actionLabel
                                            anchors.centerIn: parent
                                            text: modelData.text || "Action"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            color: actionMouse.containsMouse ? "#161616" : Theme.text
                                        }

                                        MouseArea {
                                            id: actionMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                NotificationService.invokeAction(cardWrapper.notifItem ? cardWrapper.notifItem.id : 0, modelData);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // --- Custom Minimal ScrollBar ---
            Item {
                id: scrollTrack
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.topMargin: 2
                anchors.bottomMargin: 2
                width: 14
                visible: notifListView.visible && (notifListView.contentHeight > notifListView.height)
                z: 20

                readonly property real maxContentY: Math.max(1, notifListView.contentHeight - notifListView.height)
                readonly property real maxThumbY: Math.max(0, height - scrollThumb.height)

                // Cápsula / Pastilla del Scrollbar (Minimalista, sutil y dockeada a la derecha)
                Rectangle {
                    id: scrollThumb
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    width: scrollMouse.containsMouse || scrollMouse.pressed ? 4 : 3
                    radius: width / 2
                    height: Math.max(28, Math.min(scrollTrack.height, (notifListView.height / Math.max(notifListView.height, notifListView.contentHeight)) * scrollTrack.height))
                    y: scrollTrack.maxThumbY > 0
                       ? (Math.max(0, Math.min(1, notifListView.contentY / scrollTrack.maxContentY)) * scrollTrack.maxThumbY)
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
                            dragStartContentY = notifListView.contentY;
                        } else {
                            let targetThumbY = mouse.y - (scrollThumb.height / 2);
                            let ratio = Math.max(0, Math.min(1, targetThumbY / Math.max(1, scrollTrack.maxThumbY)));
                            notifListView.contentY = ratio * scrollTrack.maxContentY;
                            dragging = true;
                            dragStartY = mouse.y;
                            dragStartContentY = notifListView.contentY;
                        }
                    }

                    onPositionChanged: mouse => {
                        if (dragging && pressed && scrollTrack.maxThumbY > 0) {
                            let dy = mouse.y - dragStartY;
                            let deltaRatio = dy / scrollTrack.maxThumbY;
                            let targetContentY = dragStartContentY + (deltaRatio * scrollTrack.maxContentY);
                            notifListView.contentY = Math.max(0, Math.min(scrollTrack.maxContentY, targetContentY));
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
