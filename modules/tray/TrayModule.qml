import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../theme"
import "../../components"

Row {
    id: root

    spacing: 8

    readonly property int activeCount: (SystemTray.items && SystemTray.items.values) ? SystemTray.items.values.length : 0
    readonly property bool hasItems: activeCount > 0

    Repeater {
        id: trayRepeater
        model: SystemTray.items

        Item {
            id: trayButton

            required property var modelData

            width: 22
            height: 26
            implicitWidth: 22
            implicitHeight: 26

            // Resuelve el icono original a color de la aplicación si el cliente expone un icono simbólico genérico
            readonly property string resolvedSource: {
                let raw = trayButton.modelData.icon || "";

                // 1. Si el icono se llama algo como com.spotify.Client-symbolic, buscar la versión oficial a color
                let cleanName = raw.replace(/^image:\/\/icon\//, "").replace(/-symbolic$/, "").replace(/_mono$/, "").split("?")[0];
                if (cleanName !== "" && Quickshell.hasThemeIcon(cleanName)) {
                    return Quickshell.iconPath(cleanName);
                }

                // 2. Si existe un icono de aplicación correspondiente al ID (ej: steam, discord, etc.)
                let idClean = (trayButton.modelData.id || "").replace(/-client$/, "").replace(/_client$/, "");
                if (idClean !== "" && Quickshell.hasThemeIcon(idClean)) {
                    return Quickshell.iconPath(idClean);
                }

                return raw;
            }

            IconImage {
                id: iconImg
                anchors.centerIn: parent
                width: 16
                height: 16
                source: trayButton.resolvedSource
                scale: mouseArea.pressed ? 0.86 : (mouseArea.containsMouse ? 1.10 : 1.0)

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.animFast
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.4
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animFast }
                }
            }

            // Menú contextual 100% en QML integrado con el diseño de la barra
            TrayMenu {
                id: trayMenu
                menu: trayButton.modelData.menu
                targetItem: trayButton
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        if (typeof trayButton.modelData.activate === "function") {
                            trayButton.modelData.activate();
                        }
                    } else if (mouse.button === Qt.RightButton) {
                        if (trayButton.modelData.hasMenu && trayMenu.menu) {
                            trayMenu.visible = !trayMenu.visible;
                        } else if (typeof trayButton.modelData.secondaryActivate === "function") {
                            trayButton.modelData.secondaryActivate();
                        }
                    }
                }
            }
        }
    }
}
