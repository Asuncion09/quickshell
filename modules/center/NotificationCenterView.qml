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

    // Absorbe clics dentro de la isla para evitar que se propaguen al dismissArea
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: mouse => mouse.accepted = true
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
                implicitWidth: titleRow.implicitWidth + 8
                implicitHeight: 26
                radius: 6
                color: "transparent"
                border.width: 0
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
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
                }

                MouseArea {
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

            // Botón de Modo No Molestar (DND)
            Rectangle {
                implicitWidth: 26
                implicitHeight: 24
                radius: 6
                color: NotificationService.dnd 
                       ? Qt.rgba(241/255, 196/255, 15/255, 0.20) 
                       : (dndMouse.containsMouse ? "#282828" : "#1c1c1c")
                border.width: 1
                border.color: NotificationService.dnd ? Qt.rgba(241/255, 196/255, 15/255, 0.40) : "#262626"
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: NotificationService.dnd ? "󰂛" : "󰂚"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: NotificationService.dnd ? Theme.warning : (dndMouse.containsMouse ? Theme.text : Theme.textSecondary)
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.toggleDnd()
                }
            }

            // Botón de Limpiar todas (solo visible cuando hay notificaciones)
            Rectangle {
                implicitWidth: 26
                implicitHeight: 24
                radius: 6
                visible: NotificationService.count > 0
                color: clearMouse.containsMouse ? "#282828" : "#1c1c1c"
                border.width: 1
                border.color: clearMouse.containsMouse ? "#3a3a3a" : "#262626"
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    anchors.centerIn: parent
                    text: "󰎟"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: clearMouse.containsMouse ? "#ffffff" : Theme.textSecondary
                }

                MouseArea {
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
                    color: Qt.rgba(1, 1, 1, 0.15)
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Sin notificaciones pendientes"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.textMuted
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Todo está al día"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.textDisabled
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // Lista de Tarjetas de Notificaciones
            ListView {
                anchors.fill: parent
                visible: NotificationService.count > 0
                model: NotificationService.notifications
                spacing: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds

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
                    width: notifListView.width
                    implicitHeight: cardContent.implicitHeight + 10
                    radius: 6
                    color: cardMouse.containsMouse ? "#222222" : "#1a1a1a"
                    border.width: 1
                    border.color: cardMouse.containsMouse ? "#303030" : "#222222"

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        anchors.topMargin: 5
                        anchors.bottomMargin: 5
                        spacing: 2

                        // Fila superior: Icono de app + Nombre de app + Tiempo relativo + Botón de descarte
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            Item {
                                implicitWidth: 16
                                implicitHeight: 16
                                Layout.alignment: Qt.AlignVCenter

                                IconImage {
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
                                    color: modelData.urgency === 2 ? Theme.critical : Theme.highlight
                                    visible: !cardIconImg.visible
                                }
                            }

                            Text {
                                text: modelData.appName || "Sistema"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: modelData.urgency === 2 ? Theme.critical : Theme.highlight
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

                            // Botón de descarte individual
                            Rectangle {
                                implicitWidth: 16
                                implicitHeight: 16
                                radius: 8
                                color: itemDismissMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: itemDismissMouse.containsMouse ? "#ffffff" : Theme.textMuted
                                }

                                MouseArea {
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
                            color: "#ffffff"
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        // Cuerpo del mensaje (Body) - Formateo limpio con chip completo si es comando de terminal
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: bodyText.implicitHeight + (isCmd ? 8 : 0)
                            radius: 4
                            color: isCmd ? Qt.rgba(0, 0, 0, 0.35) : "transparent"
                            border.width: isCmd ? 1 : 0
                            border.color: isCmd ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                            visible: modelData.body && modelData.body !== ""

                                let b = (modelData.body || "");
                                return b.indexOf("Command:") !== -1 || b.indexOf("bash -c") !== -1 || b.indexOf("sh ") !== -1 || b.indexOf("python") !== -1;
                            }

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: bodyBox.isCmd ? 6 : 0
                                anchors.rightMargin: bodyBox.isCmd ? 6 : 0
                                anchors.topMargin: bodyBox.isCmd ? 4 : 0
                                anchors.bottomMargin: bodyBox.isCmd ? 4 : 0
                                text: {
                                    let b = (modelData.body || "").trim();
                                    return b.replace(/\r?\n|\r/g, " ").replace(/\s+/g, " ");
                                }
                                font.family: bodyBox.isCmd ? "monospace" : Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Normal
                                color: bodyBox.isCmd ? Qt.rgba(1, 1, 1, 0.88) : Theme.textSecondary
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }

                        // Botones de acción interactiva (alineados a la derecha de forma prolija)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            visible: modelData.actions && modelData.actions.length > 0

                            Item { Layout.fillWidth: true }

                            Repeater {
                                model: modelData.actions || []
                                delegate: Rectangle {
                                    implicitWidth: actionLabel.implicitWidth + 14
                                    implicitHeight: 20
                                    radius: 4
                                    color: actionMouse.containsMouse ? Theme.highlight : Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    border.color: actionMouse.containsMouse ? Theme.highlight : Qt.rgba(1, 1, 1, 0.12)

                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.text || "Acción"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        color: actionMouse.containsMouse ? "#ffffff" : Theme.text
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            NotificationService.invokeAction(cardItem.notifItem ? cardItem.notifItem.id : 0, modelData);
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
}
