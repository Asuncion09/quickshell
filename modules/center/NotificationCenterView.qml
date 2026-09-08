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
                        text: "Notificaciones"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        visible: NotificationService.count > 0
                        implicitWidth: countText.implicitWidth + 8
                        implicitHeight: 16
                        radius: 8
                        color: Qt.rgba(120/255, 169/255, 255/255, 0.16)
                        border.color: Qt.rgba(120/255, 169/255, 255/255, 0.32)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: NotificationService.count
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.highlight
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
                    font.pixelSize: 12
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
                    font.pixelSize: 12
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
                    font.pixelSize: 28
                    color: Qt.rgba(1, 1, 1, 0.12)
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Sin notificaciones pendientes"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.textSecondary
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Todo está al día"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
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

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 4
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: parent.pressed ? Theme.highlight : (parent.hovered ? Qt.lighter(Theme.dark6, 1.3) : Qt.rgba(1, 1, 1, 0.22))
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                }

                footer: Item {
                    width: notifListView.width
                    height: (notifListView.contentHeight > notifListView.height) ? 22 : 0
                }

                delegate: Item {
                    id: cardWrapper
                    readonly property var notifItem: modelData
                    width: notifListView.width
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
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    Layout.alignment: Qt.AlignVCenter

                                    IconImage {
                                        id: cardIconImg
                                        anchors.fill: parent
                                        source: modelData.appIcon || ""
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
                                        font.pixelSize: 12
                                        color: modelData.urgency === 2 ? Theme.critical : Theme.wsActiveColor
                                        visible: !cardIconImg.visible
                                    }
                                }

                                Text {
                                    text: modelData.appName || "Sistema"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    color: modelData.urgency === 2 ? Theme.critical : Theme.wsActiveColor
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: "•"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 8
                                    color: Theme.textMuted
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: NotificationService.formatRelativeTime(modelData.timestamp)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
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
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    radius: 9
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
                                        font.pixelSize: 10
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
                                visible: modelData.summary && modelData.summary !== "" && modelData.summary.toLowerCase() !== (modelData.appName || "").toLowerCase()
                                text: (modelData.summary || "").trim().replace(/\r?\n|\r/g, " ").replace(/\s+/g, " ")
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.text
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            // Cuerpo del mensaje (Body) - Formateo limpio sin bordes duros
                            Rectangle {
                                id: bodyBox
                                Layout.fillWidth: true
                                implicitHeight: bodyText.implicitHeight + (isCmd ? 10 : 0)
                                radius: 6
                                color: isCmd ? Qt.rgba(0, 0, 0, 0.35) : "transparent"
                                border.width: 0
                                visible: modelData.body && modelData.body !== ""

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
                                    font.pixelSize: 10
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
                                visible: modelData.actions && modelData.actions.length > 0

                                Item { Layout.fillWidth: true }

                                Repeater {
                                    model: modelData.actions || []
                                    delegate: Rectangle {
                                        implicitWidth: actionLabel.implicitWidth + 16
                                        implicitHeight: 22
                                        radius: 11
                                        color: actionMouse.containsMouse ? Theme.wsActiveColor : Qt.rgba(1, 1, 1, 0.08)
                                        border.width: 0

                                        scale: actionMouse.pressed ? 0.92 : 1.0
                                        Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                        Text {
                                            id: actionLabel
                                            anchors.centerIn: parent
                                            text: modelData.text || "Acción"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
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

            // Desvanecimiento inferior para sugerir continuidad de contenido
            Rectangle {
                id: bottomFade
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 28
                z: 5
                visible: opacity > 0.01
                opacity: (NotificationService.count > 0 && notifListView.contentHeight > notifListView.height + 6 && !notifListView.atYEnd) ? 1.0 : 0.0
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Theme.bgDark }
                }

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad }
                }
            }

            // Indicador interactivo flotante "... 󰅀" cuando hay más contenido debajo
            Rectangle {
                id: moreIndicator
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                z: 10
                implicitWidth: moreRow.implicitWidth + 14
                implicitHeight: 20
                radius: 10
                color: moreHover.containsMouse ? Theme.surfaceHover : Qt.rgba(24/255, 24/255, 24/255, 0.94)
                border.color: moreHover.containsMouse ? Qt.lighter(Theme.highlight, 1.1) : Qt.rgba(1, 1, 1, 0.15)
                border.width: 1

                visible: opacity > 0.01
                opacity: (NotificationService.count > 0 && notifListView.contentHeight > notifListView.height + 6 && !notifListView.atYEnd) ? 1.0 : 0.0

                scale: moreHover.pressed ? 0.92 : (moreHover.containsMouse ? 1.04 : 1.0)

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad }
                }
                Behavior on scale {
                    NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad }
                }
                Behavior on color {
                    ColorAnimation { duration: Theme.animFast }
                }
                Behavior on border.color {
                    ColorAnimation { duration: Theme.animFast }
                }

                Row {
                    id: moreRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: "•••"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: moreHover.containsMouse ? Theme.text : Theme.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "󰅀"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.highlight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: moreHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        notifListView.contentY = Math.min(notifListView.contentHeight - notifListView.height, notifListView.contentY + 90);
                    }
                }
            }
        }
    }
}
