import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"

Item {
    id: root

    property bool focused: false
    property int hoveredIndex: -1
    property int pressedIndex: -1
    property bool completed: false

    implicitWidth: 280
    implicitHeight: 38
    Layout.fillWidth: true

    readonly property var profiles: [
        { id: "power-save", label: "Eco", icon: "󰌪", activeColor: Theme.success },
        { id: "balanced", label: "Balance", icon: "󰾆", activeColor: Theme.wsActiveColor },
        { id: "performance", label: "Turbo", icon: "󰓅", activeColor: Theme.warning }
    ]

    readonly property int activeIndex: {
        for (let i = 0; i < profiles.length; i++) {
            if (profiles[i].id === PowerProfileService.currentProfile) return i;
        }
        return 1;
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            root.completed = true;
        });
    }

    function stepNext() {
        let next = (root.activeIndex + 1) % root.profiles.length;
        PowerProfileService.setProfile(root.profiles[next].id);
    }

    function stepPrev() {
        let prev = (root.activeIndex - 1 + root.profiles.length) % root.profiles.length;
        PowerProfileService.setProfile(root.profiles[prev].id);
    }

    // Pista base con bordes redondeados idénticos a SliderControl y QuickToggle (radius: 12)
    Rectangle {
        id: trackBg
        anchors.fill: parent
        radius: 12
        color: Theme.surfaceBase
        clip: true

        readonly property real segWidth: (width - 6 - (root.profiles.length - 1) * 4) / Math.max(1, root.profiles.length)

        // -------------------------------------------------------------
        // CAPA 1: Base inactiva con texto claro y efectos hover
        // -------------------------------------------------------------
        RowLayout {
            id: baseRow
            anchors.fill: parent
            anchors.margins: 3
            spacing: 4

            Repeater {
                model: root.profiles

                Item {
                    id: baseSegItem
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Fondo hover para segmentos inactivos
                    Rectangle {
                        anchors.fill: parent
                        radius: 9
                        color: (root.hoveredIndex === baseSegItem.index && root.activeIndex !== baseSegItem.index)
                               ? Theme.surfaceHover : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Theme.animFast }
                        }
                    }

                    // Contenido en texto claro (Theme.textSecondary / Theme.text en hover)
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: baseSegItem.modelData.icon
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: (root.hoveredIndex === baseSegItem.index || (root.focused && root.activeIndex === baseSegItem.index))
                                   ? Theme.text : Theme.textSecondary
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color {
                                ColorAnimation { duration: Theme.animFast }
                            }
                        }

                        Text {
                            text: baseSegItem.modelData.label
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: (root.hoveredIndex === baseSegItem.index || (root.focused && root.activeIndex === baseSegItem.index))
                                   ? Theme.text : Theme.textSecondary
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color {
                                ColorAnimation { duration: Theme.animFast }
                            }
                        }
                    }
                }
            }
        }

        // -------------------------------------------------------------
        // CAPA 2: Píldora activa deslizante con animación suave (x y color)
        // Revela el texto oscuro (#161616) mediante máscara (clip: true)
        // -------------------------------------------------------------
        Rectangle {
            id: activePill
            y: 3
            height: parent.height - 6
            width: trackBg.segWidth
            x: 3 + root.activeIndex * (trackBg.segWidth + 4)
            radius: 9
            clip: true

            color: (root.hoveredIndex === root.activeIndex || root.focused)
                   ? Qt.lighter(root.profiles[root.activeIndex].activeColor, 1.08)
                   : root.profiles[root.activeIndex].activeColor

            scale: (root.pressedIndex === root.activeIndex) ? 0.96 : 1.0

            Behavior on x {
                enabled: root.completed
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                enabled: root.completed
                ColorAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.animFast
                    easing.type: Easing.OutQuad
                }
            }

            // Contenedor invertido para alinear texto oscuro exactamente sobre el texto base
            Item {
                id: maskedContainer
                x: 3 - activePill.x
                y: 3 - activePill.y
                width: trackBg.width - 6
                height: trackBg.height - 6

                RowLayout {
                    anchors.fill: parent
                    spacing: 4

                    Repeater {
                        model: root.profiles

                        Item {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.icon
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    color: "#161616"
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: "#161616"
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }
        }

        // -------------------------------------------------------------
        // CAPA 3: Capa interactiva de clics (MouseAreas en nivel superior)
        // -------------------------------------------------------------
        RowLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 4
            z: 10

            Repeater {
                model: root.profiles

                Item {
                    id: clickSegItem
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: root.hoveredIndex = clickSegItem.index
                        onExited: {
                            if (root.hoveredIndex === clickSegItem.index) root.hoveredIndex = -1;
                        }
                        onPressed: root.pressedIndex = clickSegItem.index
                        onReleased: root.pressedIndex = -1
                        onCanceled: root.pressedIndex = -1

                        onClicked: {
                            PowerProfileService.setProfile(clickSegItem.modelData.id);
                        }
                    }
                }
            }
        }

        // -------------------------------------------------------------
        // CAPA 4: Anillo de foco nítido para teclado
        // -------------------------------------------------------------
        Rectangle {
            id: focusRing
            anchors.fill: parent
            radius: 12
            color: "transparent"
            border.width: root.focused ? 1.5 : 0
            border.color: Theme.highlight
            z: 20

            Behavior on border.width { NumberAnimation { duration: 40 } }
            Behavior on border.color { ColorAnimation { duration: 40 } }
        }
    }
}
