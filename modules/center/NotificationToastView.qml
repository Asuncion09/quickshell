import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../theme"
import "../../services"

Item {
    id: root

    readonly property var currentToast: NotificationService.currentToast
    readonly property bool hasToast: currentToast !== null
    readonly property bool isExpanded: NotificationService.isToastExpanded
    readonly property bool isBatteryToast: currentToast !== null && (
        (currentToast.appName && (currentToast.appName.toLowerCase().includes("batería") || currentToast.appName.toLowerCase().includes("battery"))) ||
        (currentToast.summary && (currentToast.summary.toLowerCase().includes("batería") || currentToast.summary.toLowerCase().includes("battery")))
    )
    readonly property bool isScreenshot: currentToast !== null && (
        currentToast.isScreenshot === true ||
        (currentToast.appName && currentToast.appName.toLowerCase().includes("hyprshot")) ||
        (currentToast.summary && currentToast.summary.toLowerCase().includes("screenshot"))
    )
    readonly property string screenshotPath: currentToast ? (currentToast.screenshotPath || "") : ""
    property bool copiedPathFeedback: false

    Timer {
        id: copiedFeedbackTimer
        interval: 2000
        onTriggered: root.copiedPathFeedback = false
    }

    focus: isExpanded

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true;
            NotificationService.dismissToast();
        }
    }

    onIsExpandedChanged: {
        if (isExpanded) {
            Qt.callLater(() => root.forceActiveFocus());
        }
    }

    implicitHeight: {
        if (!hasToast) return 26;
        if (root.isExpanded) {
            if (root.isScreenshot && root.screenshotPath !== "") {
                return Math.min(270, Math.max(120, expandedCol.implicitHeight + 14));
            }
            return Math.min(240, Math.max(80, expandedCol.implicitHeight + 14));
        }
        return 26;
    }

    implicitWidth: {
        if (!hasToast) return 100;
        if (root.isExpanded) {
            if (root.isScreenshot) {
                return 358;
            }
            return 330 - (6 * 2); // 318px
        }
        let baseW = 8 + 16 + 6;
        let urgencyW = (currentToast && currentToast.urgency === 2) ? 11 : 0;
        let appW = appNameText.implicitWidth + 5;
        let dotW = 8 + 5;
        let msgW = Math.min(240, messageLabel.implicitWidth);
        return Math.min(380, Math.max(120, Math.round(baseW + urgencyW + appW + dotW + msgW)));
    }

    // Absorbedor de clics cuando está expandida para evitar que pasen a dismissArea
    MouseArea {
        anchors.fill: parent
        visible: root.isExpanded
        z: -1
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: mouse => mouse.accepted = true
    }

    // -----------------------------------------------------------------
    // MODO COMPACTO (Fila individual en la barra dinámica)
    // -----------------------------------------------------------------
    MouseArea {
        id: toastMouse
        anchors.fill: parent
        enabled: !root.isExpanded
        visible: !root.isExpanded
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onEntered: {
            NotificationService.pauseToast();
        }

        onExited: {
            NotificationService.resumeToast();
        }

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                NotificationService.dismissToast();
            } else {
                NotificationService.expandToast();
            }
        }
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 6
        visible: !root.isExpanded
        opacity: root.isExpanded ? 0.0 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
        }

        // Icono de la aplicación
        Item {
            implicitWidth: 16
            implicitHeight: 16
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                id: toastIconImg
                anchors.fill: parent
                source: (root.currentToast && root.currentToast.appIcon && root.currentToast.appIcon.length > 2) ? root.currentToast.appIcon : ""
                visible: !root.isScreenshot && source !== "" && status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: {
                    if (!root.currentToast) return "󰂚";
                    if (root.isScreenshot) return "󰹑";
                    if (root.currentToast.appIcon && root.currentToast.appIcon.length <= 2) {
                        return root.currentToast.appIcon;
                    }
                    let a = (root.currentToast.appName || "").toLowerCase();
                    if (a.includes("batería") || a.includes("battery")) return BatteryService.icon || "󰁻";
                    if (a.includes("antigravity") || a.includes("code") || a.includes("vscode")) return "󰅩";
                    if (a.includes("term") || a.includes("bash") || a.includes("shell") || a.includes("kitty") || a.includes("alacritty")) return "󰆍";
                    return "󰂚";
                }
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: root.isScreenshot ? Theme.wsActiveColor : ((!root.isExpanded && root.isBatteryToast) ? "#161616" : ((root.currentToast && root.currentToast.urgency === 2) ? Theme.critical : Theme.highlight))
                visible: !toastIconImg.visible || root.isScreenshot
            }
        }

        // Punto indicador de urgencia si es crítica
        Rectangle {
            implicitWidth: 5
            implicitHeight: 5
            radius: 2.5
            color: (!root.isExpanded && root.isBatteryToast) ? "#161616" : Theme.critical
            visible: root.currentToast && root.currentToast.urgency === 2
            Layout.alignment: Qt.AlignVCenter
        }

        // Título / App y contenido en una línea fluida y limpia
        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            clip: true

            Text {
                id: appNameText
                text: root.currentToast ? (root.isScreenshot ? "Hyprshot" : (root.currentToast.appName || "Notice")) : ""
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: root.isScreenshot ? Theme.wsActiveColor : ((!root.isExpanded && root.isBatteryToast) ? "#161616" : ((root.currentToast && root.currentToast.urgency === 2) ? Theme.critical : Theme.highlight))
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: "•"
                font.family: Theme.fontFamily
                font.pixelSize: 9
                color: (!root.isExpanded && root.isBatteryToast) ? Qt.rgba(0, 0, 0, 0.45) : Theme.textMuted
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: messageLabel
                text: {
                    if (!root.currentToast) return "";
                    if (root.isScreenshot) {
                        return root.screenshotPath !== "" ? "Captura guardada" : "Captura en portapapeles";
                    }
                    let s = (root.currentToast.summary || "").trim();
                    let b = (root.currentToast.body || "").trim();
                    let a = (root.currentToast.appName || "").trim();
                    if (s.toLowerCase() === a.toLowerCase()) s = "";

                    s = s.replace(/[\r\n\t]+/g, " ").replace(/\s{2,}/g, " ").trim();
                    b = b.replace(/[\r\n\t]+/g, " ").replace(/\s{2,}/g, " ").trim();

                    if (s.toLowerCase().indexOf("requesting your permission in terminal") !== -1) {
                        s = "Terminal Permission";
                    }

                    if (a.toLowerCase().includes("batería") || a.toLowerCase().includes("battery")) {
                        if (s !== "") {
                            return s.replace(/^⚠️\s*/, "");
                        }
                        return b;
                    }

                    if (s !== "" && b !== "") return s + " — " + b;
                    return s !== "" ? s : b;
                }
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Normal
                color: (!root.isExpanded && root.isBatteryToast) ? "#161616" : Theme.text
                maximumLineCount: 1
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // -----------------------------------------------------------------
    // MODO EXPANDIDO (Tarjeta completa de la notificación en la isla)
    // -----------------------------------------------------------------
    ColumnLayout {
        id: expandedCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 6
        spacing: 6
        visible: root.isExpanded
        opacity: root.isExpanded ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 110; easing.type: Easing.OutQuad }
        }

        // 1. Cabecera (Icono + App + Punto + Tiempo + Botón cerrar)
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Item {
                implicitWidth: 18
                implicitHeight: 18
                Layout.alignment: Qt.AlignVCenter

                IconImage {
                    id: expIconImg
                    anchors.fill: parent
                    source: (root.currentToast && root.currentToast.appIcon && root.currentToast.appIcon.length > 2) ? root.currentToast.appIcon : ""
                    visible: !root.isScreenshot && source !== "" && status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (!root.currentToast) return "󰂚";
                        if (root.isScreenshot) return "󰹑";
                        if (root.currentToast.appIcon && root.currentToast.appIcon.length <= 2) {
                            return root.currentToast.appIcon;
                        }
                        let a = (root.currentToast.appName || "").toLowerCase();
                        if (a.includes("batería") || a.includes("battery")) return BatteryService.icon || "󰁻";
                        if (a.includes("antigravity") || a.includes("code") || a.includes("vscode")) return "󰅩";
                        if (a.includes("term") || a.includes("bash") || a.includes("shell") || a.includes("kitty") || a.includes("alacritty")) return "󰆍";
                        return "󰂚";
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: root.isScreenshot ? Theme.wsActiveColor : (root.isBatteryToast ? Theme.warning : ((root.currentToast && root.currentToast.urgency === 2) ? Theme.critical : Theme.highlight))
                    visible: !expIconImg.visible || root.isScreenshot
                }
            }

            Text {
                text: root.currentToast ? (root.isScreenshot ? "Hyprshot" : (root.currentToast.appName || "Notice")) : ""
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: root.isScreenshot ? Theme.wsActiveColor : (root.isBatteryToast ? Theme.warning : ((root.currentToast && root.currentToast.urgency === 2) ? Theme.critical : Theme.highlight))
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
                text: "now"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.textMuted
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: 20
                implicitHeight: 20
                radius: 10
                color: closeExpMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: closeExpMouse.containsMouse ? "#ffffff" : Theme.textSecondary
                }

                MouseArea {
                    id: closeExpMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.dismissToast()
                }
            }
        }

        // 2a. Vista previa visual de captura (Screenshot Preview Card)
        Rectangle {
            id: screenshotPreviewBox
            visible: root.isScreenshot && root.screenshotPath !== ""
            Layout.fillWidth: true
            implicitHeight: 126
            radius: 8
            color: Qt.rgba(0, 0, 0, 0.45)
            clip: true
            border.width: 1
            border.color: shotHover.containsMouse ? Qt.rgba(255, 255, 255, 0.28) : Qt.rgba(255, 255, 255, 0.08)

            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

            Image {
                id: screenshotImg
                anchors.fill: parent
                source: root.screenshotPath !== "" ? ("file://" + root.screenshotPath) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                smooth: true
            }

            // Sombra inferior sutil para destacar el nombre del archivo
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 28
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.75) }
                }
            }

            // Nombre del archivo de la captura
            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 6
                spacing: 4

                Text {
                    text: "󰄄"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Qt.rgba(255, 255, 255, 0.75)
                }

                Text {
                    Layout.fillWidth: true
                    text: {
                        if (!root.screenshotPath) return "";
                        let parts = root.screenshotPath.split("/");
                        return parts[parts.length - 1];
                    }
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 10
                    color: Qt.rgba(255, 255, 255, 0.9)
                    elide: Text.ElideMiddle
                }
            }

            // Overlay al pasar el cursor (hint de "Click para abrir")
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.38)
                opacity: shotHover.containsMouse ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: Qt.rgba(0, 0, 0, 0.6)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.2)

                        Text {
                            anchors.centerIn: parent
                            text: "󰈟"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: "#ffffff"
                        }
                    }

                    Text {
                        text: "Click para abrir"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                    }
                }
            }

            MouseArea {
                id: shotHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    NotificationService.openScreenshot(root.screenshotPath);
                }
            }
        }

        // 2b. Contenido completo del mensaje para notificaciones normales o avisos sin archivo
        Item {
            visible: !root.isScreenshot || root.screenshotPath === ""
            Layout.fillWidth: true
            implicitHeight: visible ? fullTextCol.implicitHeight : 0

            ColumnLayout {
                id: fullTextCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 3

                Text {
                    id: fullSummary
                    visible: text !== ""
                    text: {
                        if (!root.currentToast) return "";
                        let s = (root.currentToast.summary || "").trim();
                        let a = (root.currentToast.appName || "").trim();
                        return (s.toLowerCase() !== a.toLowerCase()) ? s : "";
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                Text {
                    id: fullBody
                    visible: text !== ""
                    text: root.currentToast ? (root.currentToast.body || "").trim() : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Normal
                    color: Theme.textSecondary
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    maximumLineCount: 8
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.currentToast) {
                        NotificationService.activateNotification(root.currentToast.id);
                    }
                }
            }
        }

        // 3. Imagen adjunta para notificaciones normales si existe
        Item {
            visible: !(root.isScreenshot && root.screenshotPath !== "") && root.currentToast && root.currentToast.image && root.currentToast.image !== ""
            Layout.fillWidth: true
            implicitHeight: expNotifImg.visible ? Math.min(80, expNotifImg.implicitHeight) : 0

            Image {
                id: expNotifImg
                source: (root.currentToast && root.currentToast.image) ? root.currentToast.image : ""
                fillMode: Image.PreserveAspectFit
                anchors.fill: parent
                visible: status === Image.Ready
            }
        }

        // 4a. Botones de acción dedicados para capturas de pantalla
        RowLayout {
            visible: root.isScreenshot && root.screenshotPath !== ""
            Layout.fillWidth: true
            spacing: 8

            // Botón 1: Copiar imagen al portapapeles (datos PNG reales)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 28
                radius: 14
                color: root.copiedPathFeedback ? Qt.rgba(76/255, 175/255, 80/255, 0.28) : (copyImgMouse.containsMouse ? Qt.lighter(Theme.wsActiveColor, 1.1) : Theme.wsActiveColor)

                scale: copyImgMouse.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: root.copiedPathFeedback ? "󰄬" : "󰆏"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: root.copiedPathFeedback ? "#81c784" : "#161616"
                    }
                    Text {
                        text: root.copiedPathFeedback ? "¡Copiada al portapapeles!" : "Copiar imagen"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: root.copiedPathFeedback ? "#81c784" : "#161616"
                    }
                }

                MouseArea {
                    id: copyImgMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        NotificationService.copyScreenshotImage(root.screenshotPath);
                        root.copiedPathFeedback = true;
                        copiedFeedbackTimer.restart();
                    }
                }
            }

            // Botón 2: Borrar captura
            Rectangle {
                implicitWidth: 86
                implicitHeight: 28
                radius: 14
                color: delShotMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                border.color: delShotMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)

                scale: delShotMouse.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    Text {
                        text: "󰅖"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: delShotMouse.containsMouse ? "#ffffff" : Theme.textSecondary
                    }
                    Text {
                        text: "Borrar"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: delShotMouse.containsMouse ? "#ffffff" : Theme.textSecondary
                    }
                }

                MouseArea {
                    id: delShotMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.currentToast) {
                            NotificationService.deleteScreenshot(root.currentToast.id, root.screenshotPath);
                        }
                    }
                }
            }
        }

        // 4b. Botones de acción estándar para notificaciones normales
        RowLayout {
            visible: !(root.isScreenshot && root.screenshotPath !== "")
            Layout.fillWidth: true
            spacing: 6

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: closeLabel.implicitWidth + 16
                implicitHeight: 24
                radius: 12
                color: closeBtnMouse2.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    id: closeLabel
                    anchors.centerIn: parent
                    text: "Close"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: closeBtnMouse2.containsMouse ? "#ffffff" : Theme.textSecondary
                }

                MouseArea {
                    id: closeBtnMouse2
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.dismissToast()
                }
            }

            Repeater {
                model: (root.currentToast && root.currentToast.actions) ? root.currentToast.actions : []
                delegate: Rectangle {
                    implicitWidth: actionLbl.implicitWidth + 16
                    implicitHeight: 24
                    radius: 12
                    color: actionMouse2.containsMouse ? Theme.wsActiveColor : Qt.rgba(1, 1, 1, 0.08)

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        id: actionLbl
                        anchors.centerIn: parent
                        text: modelData.text || "Action"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: actionMouse2.containsMouse ? "#161616" : Theme.text
                    }

                    MouseArea {
                        id: actionMouse2
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NotificationService.invokeAction(root.currentToast.id, modelData);
                        }
                    }
                }
            }

            Rectangle {
                visible: (!root.currentToast || !root.currentToast.actions || root.currentToast.actions.length === 0) && !root.isScreenshot
                implicitWidth: openLbl.implicitWidth + 16
                implicitHeight: 24
                radius: 12
                color: openMouse2.containsMouse ? Qt.lighter(Theme.wsActiveColor, 1.1) : Theme.wsActiveColor

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    id: openLbl
                    anchors.centerIn: parent
                    text: "Open"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: "#161616"
                }

                MouseArea {
                    id: openMouse2
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.currentToast) {
                            NotificationService.activateNotification(root.currentToast.id);
                        }
                    }
                }
            }
        }
    }
}
