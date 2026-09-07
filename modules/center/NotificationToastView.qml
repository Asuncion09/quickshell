import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../theme"
import "../../services"

Item {
    id: root

    readonly property var currentToast: NotificationService.currentToast

    implicitHeight: 26
    implicitWidth: {
        if (!hasToast) return 100;
        let baseW = 8 + 16 + 6;
        let urgencyW = (currentToast && currentToast.urgency === 2) ? 11 : 0;
        let appW = appNameText.implicitWidth + 5;
        let dotW = 8 + 5;
        let msgW = Math.min(240, messageLabel.implicitWidth);
        let closeW = toastMouse.containsMouse ? 22 : 0;
        return Math.min(380, Math.max(120, Math.round(baseW + urgencyW + appW + dotW + msgW + closeW)));
    }

    MouseArea {
        anchors.fill: parent
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
                // Al hacer clic se abre el Centro de Notificaciones completo
                NotificationService.openCenter();
            }
        }
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 6

        // Icono de la aplicación
        Item {
            implicitWidth: 16
            implicitHeight: 16
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                anchors.fill: parent
                source: root.currentToast ? (root.currentToast.appIcon || "") : ""
                visible: source !== "" && status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: {
                    if (!root.currentToast) return "󰂚";
                    let a = (root.currentToast.appName || "").toLowerCase();
                    if (a.includes("antigravity") || a.includes("code") || a.includes("vscode")) return "󰅩";
                    if (a.includes("term") || a.includes("bash") || a.includes("shell") || a.includes("kitty") || a.includes("alacritty")) return "󰆍";
                    return "󰂚";
                }
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: (root.currentToast && root.currentToast.urgency === 2) ? Theme.critical : Theme.highlight
                visible: !toastIconImg.visible
            }
        }

        // Punto indicador de urgencia si es crítica
        Rectangle {
            implicitWidth: 5
            implicitHeight: 5
            radius: 2.5
            color: Theme.critical
            visible: root.currentToast && root.currentToast.urgency === 2
            Layout.alignment: Qt.AlignVCenter
        }

        // Título / App y contenido en una línea fluida y limpia
        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            clip: true

            Text {
                text: root.currentToast ? (root.currentToast.appName || "Aviso") : ""
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: (root.currentToast && root.currentToast.urgency === 2) ? Theme.critical : Theme.highlight
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
                text: {
                    if (!root.currentToast) return "";
                    let s = (root.currentToast.summary || "").trim();
                    let b = (root.currentToast.body || "").trim();
                    let a = (root.currentToast.appName || "").trim();
                    if (s.toLowerCase() === a.toLowerCase()) s = "";

                    // Reemplazar todo salto de línea y secuencias de espacios por un único espacio
                    s = s.replace(/[\r\n\t]+/g, " ").replace(/\s{2,}/g, " ").trim();
                    b = b.replace(/[\r\n\t]+/g, " ").replace(/\s{2,}/g, " ").trim();

                    // Acortar prefijo verboso de permisos para priorizar la visibilidad del comando
                    if (s.toLowerCase().indexOf("requesting your permission in terminal") !== -1) {
                        s = "Permiso Terminal";
                    }

                    if (s !== "" && b !== "") return s + " — " + b;
                    return s !== "" ? s : b;
                }
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Normal
                color: Theme.text
                maximumLineCount: 1
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Botón discreto de cierre rápido al pasar el cursor
        Rectangle {
            implicitWidth: toastMouse.containsMouse ? 16 : 0
            implicitHeight: 16
            radius: 8
            clip: true
            color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.08)
            opacity: toastMouse.containsMouse ? 1.0 : 0.0
            visible: implicitWidth > 0 || opacity > 0
            Layout.alignment: Qt.AlignVCenter

            Behavior on implicitWidth { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutQuad } }
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Text {
                anchors.centerIn: parent
                text: "󰅖"
                font.family: Theme.fontFamily
                font.pixelSize: 9
                color: closeMouse.containsMouse ? "#ffffff" : Theme.textSecondary
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    NotificationService.dismissToast();
                }
            }
        }
    }
}
