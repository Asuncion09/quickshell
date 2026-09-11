import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../theme"
import "../../services"

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: SwitcherService.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: -1

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: 0
        bottom: 0
        left: 0
        right: 0
    }

    implicitWidth: modelData ? modelData.width : 1920
    implicitHeight: modelData ? modelData.height : 1080

    color: "transparent"
    visible: SwitcherService.isOpen || cardWrapper.opacity > 0.01

    // Fondo oscurecido con clic para cancelar
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        opacity: SwitcherService.isOpen ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutQuad
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: SwitcherService.cancel()
        }
    }

    // Receptor de eventos de teclado
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: SwitcherService.isOpen

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Tab) {
                event.accepted = true;
                if (event.modifiers & Qt.ShiftModifier) {
                    SwitcherService.prev();
                } else {
                    SwitcherService.next();
                }
            } else if (event.key === Qt.Key_Backtab) {
                event.accepted = true;
                SwitcherService.prev();
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                event.accepted = true;
                SwitcherService.next();
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                event.accepted = true;
                SwitcherService.prev();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                event.accepted = true;
                SwitcherService.select();
            } else if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                SwitcherService.cancel();
            } else if (event.key === Qt.Key_Q || event.key === Qt.Key_Delete) {
                event.accepted = true;
                SwitcherService.closeCurrent();
            }
        }

        Keys.onReleased: event => {
            if (event.key === Qt.Key_Alt || event.key === Qt.Key_Meta || !(event.modifiers & Qt.AltModifier)) {
                event.accepted = true;
                SwitcherService.select();
            }
        }
    }

    Timer {
        id: focusTimer
        interval: 20
        repeat: false
        onTriggered: {
            if (SwitcherService.isOpen) {
                keyHandler.forceActiveFocus();
            }
        }
    }

    Connections {
        target: SwitcherService
        function onIsOpenChanged() {
            if (SwitcherService.isOpen) {
                keyHandler.forceActiveFocus();
                focusTimer.restart();
            }
        }
        function onSelectedIndexChanged() {
            if (windowListView.count > 0 && SwitcherService.selectedIndex >= 0) {
                windowListView.positionViewAtIndex(SwitcherService.selectedIndex, ListView.Contain);
            }
        }
    }

    // Contenedor animado con elevación y sombra
    Item {
        id: cardWrapper
        anchors.centerIn: parent

        readonly property int cardItemWidth: 128
        readonly property int cardItemSpacing: 10
        readonly property int cardCount: SwitcherService.displayedWindows.length
        readonly property int calculatedListWidth: (cardCount * cardItemWidth) + Math.max(0, cardCount - 1) * cardItemSpacing
        readonly property int maxAllowedWidth: (root.screen ? root.screen.width : 1920) - 80

        width: Math.min(maxAllowedWidth, Math.max(cardItemWidth + 28, calculatedListWidth + 28))
        height: 156

        scale: SwitcherService.isOpen ? 1.0 : 0.94
        opacity: SwitcherService.isOpen ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation { duration: 140; easing.type: Easing.OutQuad }
        }
        Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
        }

        // Sombra suave volumétrica por hardware (coherente con Centro de Control y OSD)
        Rectangle {
            id: shadowShape
            anchors.fill: mainCard
            radius: mainCard.radius
            color: "#000000"
            visible: false
        }

        MultiEffect {
            source: shadowShape
            anchors.fill: shadowShape
            visible: Theme.pillShadowEnabled
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.60
            shadowBlur: 0.55
            shadowVerticalOffset: 4
        }

        // Tarjeta principal (estilo Centro de Control)
        Rectangle {
            id: mainCard
            anchors.fill: parent

            radius: 16
            color: Theme.bgDark
            border.color: "#2e2e2e"
            border.width: 1

            // Lista horizontal de ventanas
            ListView {
                id: windowListView
                anchors.fill: parent
                anchors.margins: 14
                orientation: ListView.Horizontal
                spacing: cardWrapper.cardItemSpacing
                clip: true
                interactive: contentWidth > width

                model: SwitcherService.displayedWindows
                currentIndex: SwitcherService.selectedIndex

                delegate: Item {
                    id: cardDelegate
                    required property var modelData
                    required property int index

                    readonly property bool isCurrent: SwitcherService.selectedIndex === index
                    readonly property bool isHovered: cardMouseArea.containsMouse

                    width: cardWrapper.cardItemWidth
                    height: windowListView.height

                    Rectangle {
                        id: cardBg
                        anchors.fill: parent
                        radius: 12

                        // Tonalidad elegante y neutra coherente con el lanzador y la barra (sin bordes azules)
                        color: cardDelegate.isCurrent
                               ? "#2c2c2c"
                               : (cardDelegate.isHovered ? Theme.surfaceHover : Theme.surfaceBase)
                        border.color: cardDelegate.isCurrent
                                      ? Qt.rgba(1, 1, 1, 0.18)
                                      : (cardDelegate.isHovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                        border.width: 1

                        Behavior on color {
                            ColorAnimation { duration: 110 }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: 110 }
                        }

                        // Badge sutil de Workspace (estilo chip neutro)
                        Rectangle {
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            implicitWidth: wsLabel.implicitWidth + 8
                            implicitHeight: 16
                            radius: 8
                            color: cardDelegate.isCurrent ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.04)

                            Behavior on color {
                                ColorAnimation { duration: 110 }
                            }

                            Text {
                                id: wsLabel
                                anchors.centerIn: parent
                                text: "WS " + cardDelegate.modelData.workspaceId
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                color: cardDelegate.isCurrent ? Theme.text : Theme.textMuted
                            }
                        }

                        // Icono centrado
                        Item {
                            id: iconContainer
                            anchors.top: parent.top
                            anchors.topMargin: 16
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 44
                            height: 44

                            scale: cardDelegate.isCurrent ? 1.06 : (cardDelegate.isHovered ? 1.03 : 1.0)
                            Behavior on scale {
                                NumberAnimation { duration: 110; easing.type: Easing.OutQuad }
                            }

                            IconImage {
                                id: switcherIconImg
                                anchors.centerIn: parent
                                width: 42
                                height: 42
                                source: cardDelegate.modelData.iconSource
                                visible: cardDelegate.modelData.iconSource !== "" && status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 32
                                color: cardDelegate.isCurrent ? Theme.text : Theme.textMuted
                                visible: !switcherIconImg.visible
                            }
                        }

                        // Nombre de la app
                        Text {
                            id: appNameLabel
                            anchors.top: iconContainer.bottom
                            anchors.topMargin: 8
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            text: cardDelegate.modelData.appName
                            font.family: Theme.fontFamily
                            font.weight: cardDelegate.isCurrent ? Font.DemiBold : Font.Normal
                            font.pixelSize: 11
                            color: cardDelegate.isCurrent ? "#ffffff" : Theme.textSecondary
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        // Título de la ventana
                        Text {
                            id: titleLabel
                            anchors.top: appNameLabel.bottom
                            anchors.topMargin: 2
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            text: cardDelegate.modelData.title
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: cardDelegate.isCurrent ? Qt.rgba(221/255, 225/255, 231/255, 0.65) : Theme.textMuted
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: cardMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: SwitcherService.hoverIndex(cardDelegate.index)
                            onClicked: SwitcherService.selectIndex(cardDelegate.index)
                        }
                    }
                }
            }
        }
    }
}
