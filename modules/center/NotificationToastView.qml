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
            return Math.min(240, Math.max(80, expandedCol.implicitHeight + 14));
        }
        return 26;
    }

    implicitWidth: {
        if (!hasToast) return 100;
        if (root.isExpanded) {
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
                visible: source !== "" && status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: {
                    if (!root.currentToast) return "󰂚";
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
                color: (!root.isExpanded && root.isBatteryToast) ? "#161616" : ((root.currentToast && root.currentToast.urgency === 2) ? Theme.critical : Theme.highlight)
                visible: !toastIconImg.visible
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
                text: root.currentToast ? (root.currentToast.appName || "Aviso") : ""
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: (!root.isExpanded && root.isBatteryToast) ? "#161616" : ((root.currentToast && root.currentToast.urgency === 2) ? Theme.critical : Theme.highlight)
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
                    let s = (root.currentToast.summary || "").trim();
                    let b = (root.currentToast.body || "").trim();
                    let a = (root.currentToast.appName || "").trim();
                    if (s.toLowerCase() === a.toLowerCase()) s = "";

                    s = s.replace(/[\r\n\t]+/g, " ").replace(/\s{2,}/g, " ").trim();
                    b = b.replace(/[\r\n\t]+/g, " ").replace(/\s{2,}/g, " ").trim();

                    if (s.toLowerCase().indexOf("requesting your permission in terminal") !== -1) {
                        s = "Permiso Terminal";
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
                font.pixelSize: 11
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
                    visible: source !== "" && status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (!root.currentToast) return "󰂚";
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
                    color: root.isBatteryToast ? Theme.warning : ((root.currentToast && root.currentToast.urgency === 2) ? Theme.critical : Theme.highlight)
                    visible: !expIconImg.visible
                }
            }

            Text {
                text: root.currentToast ? (root.currentToast.appName || "Aviso") : ""
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: root.isBatteryToast ? Theme.warning : ((root.currentToast && root.currentToast.urgency === 2) ? Theme.critical : Theme.highlight)
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
                text: "ahora"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.textMuted
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: 18
                implicitHeight: 18
                radius: 9
                color: closeExpMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08)
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
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

        // 2. Contenido completo del mensaje
        Item {
            Layout.fillWidth: true
            implicitHeight: fullTextCol.implicitHeight

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
                    font.pixelSize: 12
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
                    font.pixelSize: 11
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

        // 3. Imagen adjunta si existe
        Item {
            visible: root.currentToast && root.currentToast.image && root.currentToast.image !== ""
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

        // 4. Botones de acción inferiores
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: closeLabel.implicitWidth + 14
                implicitHeight: 22
                radius: 6
                color: closeBtnMouse2.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    id: closeLabel
                    anchors.centerIn: parent
                    text: "Cerrar"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
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
                    implicitWidth: actionLbl.implicitWidth + 14
                    implicitHeight: 22
                    radius: 6
                    color: actionMouse2.containsMouse ? Theme.wsActiveColor : Qt.rgba(1, 1, 1, 0.08)

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        id: actionLbl
                        anchors.centerIn: parent
                        text: modelData.text || "Acción"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
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
                visible: !root.currentToast || !root.currentToast.actions || root.currentToast.actions.length === 0
                implicitWidth: openLbl.implicitWidth + 14
                implicitHeight: 22
                radius: 6
                color: openMouse2.containsMouse ? Qt.lighter(Theme.wsActiveColor, 1.1) : Theme.wsActiveColor

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    id: openLbl
                    anchors.centerIn: parent
                    text: "Abrir"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
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
