import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../theme"

PopupWindow {
    id: root

    property alias menu: menuOpener.menu
    property alias targetItem: root.anchor.item

    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6
    color: "transparent"
    visible: false
    grabFocus: true



    QsMenuOpener {
    }

    implicitWidth: container.implicitWidth + 16
    implicitHeight: container.implicitHeight + 16

    Item {
        anchors.fill: parent

        // Sombra de profundidad para el menú flotante
        Rectangle {
            id: shadowShape
            anchors.fill: container
            radius: 8
            color: "#000000"
            visible: false
        }

        MultiEffect {
            source: shadowShape
            anchors.fill: shadowShape
            visible: Theme.pillShadowEnabled
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.5
            shadowBlur: 0.45
            shadowVerticalOffset: 3
        }

        // Contenedor principal con estilo idéntico a la barra
        Rectangle {
            id: container
            anchors.centerIn: parent

            width: implicitWidth
            height: implicitHeight
            implicitWidth: Math.max(160, layout.implicitWidth + 16)
            implicitHeight: layout.implicitHeight + 8

            radius: 8
            color: Theme.bgDark
            border.color: "#393939"
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                width: container.implicitWidth - 12
                spacing: 2

                Repeater {
                    model: (menuOpener.children && menuOpener.children.values) ? menuOpener.children.values : []

                    delegate: Item {
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: modelData.isSeparator ? 7 : 26

                        // Separador
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width
                            height: 1
                            color: "#393939"
                            visible: entryItem.modelData.isSeparator
                        }

                        // Opción de menú interactiva
                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            visible: !entryItem.modelData.isSeparator
                            color: entryMouse.containsMouse && entryItem.modelData.enabled ? Theme.hoverBg : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: Theme.animFast }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                IconImage {
                                    width: 14
                                    height: 14
                                    source: entryItem.modelData.icon || ""
                                    visible: entryItem.modelData.icon !== ""
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: entryItem.modelData.text ? entryItem.modelData.text.replace(/&/g, "").replace(/_/g, "") : ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    color: !entryItem.modelData.enabled
                                           ? Theme.textDisabled
                                           : (entryMouse.containsMouse ? Theme.highlight : Theme.text)
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter

                                    Behavior on color {
                                        ColorAnimation { duration: Theme.animFast }
                                    }
                                }

                                Text {
                                    text: "›"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    color: Theme.textMuted
                                    visible: entryItem.modelData.hasChildren ?? false
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: entryItem.modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                                onClicked: {
                                    if (entryItem.modelData.enabled) {
                                        entryItem.modelData.triggered();
                                        root.visible = false;
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

