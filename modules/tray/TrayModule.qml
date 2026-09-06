import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../theme"
import "../../components"

RowLayout {
    id: root

    spacing: 10
    visible: SystemTray.items && SystemTray.items.values && SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items ? SystemTray.items.values : []

        Item {
            id: trayButton

            required property var modelData

            implicitWidth: 18
            implicitHeight: 20

            IconImage {
                id: iconImg
                anchors.centerIn: parent
                width: 16
                height: 16
                source: trayButton.modelData.icon || ""
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
