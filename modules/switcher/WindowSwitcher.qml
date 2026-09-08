import QtQuick
import QtQuick.Layouts
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
    visible: SwitcherService.isOpen || mainCard.opacity > 0.01

    // Fondo oscurecido con clic para cancelar
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.50)
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

    // Tarjeta central flotante estilo macOS / Windows
    Rectangle {
        id: mainCard
        anchors.centerIn: parent

        // Ancho reactivo: se ajusta al número de elementos sin sobrepasar la pantalla
        readonly property int cardItemWidth: 124
        readonly property int cardItemSpacing: 10
        readonly property int calculatedListWidth: (SwitcherService.displayedWindows.length * cardItemWidth) + Math.max(0, SwitcherService.displayedWindows.length - 1) * cardItemSpacing
        readonly property int maxAllowedWidth: (root.screen ? root.screen.width : 1920) - 80
        
        width: Math.min(maxAllowedWidth, Math.max(460, calculatedListWidth + 48))
        height: 188

        color: Theme.bgDark
        border.color: Theme.borderDark
        border.width: 1
        radius: 16

        opacity: SwitcherService.isOpen ? 1.0 : 0.0
        scale: SwitcherService.isOpen ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation {
                duration: 130
                easing.type: Easing.OutQuad
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        // Borde interior sutil (rim light)
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: parent.radius
            border.color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // Lista horizontal de ventanas centrada
            ListView {
                id: windowListView
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(parent.width, mainCard.calculatedListWidth)
                Layout.preferredHeight: 128
                orientation: ListView.Horizontal
                spacing: mainCard.cardItemSpacing
                clip: false
                interactive: contentWidth > width

                model: SwitcherService.displayedWindows
                currentIndex: SwitcherService.selectedIndex

                delegate: Item {
                    id: cardDelegate
                    required property var modelData
                    required property int index

                    readonly property bool isCurrent: SwitcherService.selectedIndex === index
                    readonly property bool isHovered: cardMouseArea.containsMouse

                    width: mainCard.cardItemWidth
                    height: 128

                    Rectangle {
                        id: cardBg
                        anchors.fill: parent
                        radius: 12

                        color: cardDelegate.isCurrent ? Theme.surfaceActive : (cardDelegate.isHovered ? Theme.surfaceHover : Theme.surfaceBase)
                        border.color: cardDelegate.isCurrent ? Theme.highlight : (cardDelegate.isHovered ? Qt.rgba(1, 1, 1, 0.16) : Theme.dividerColor)
                        border.width: cardDelegate.isCurrent ? 2 : 1

                        Behavior on color {
                            ColorAnimation { duration: 90 }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: 90 }
                        }

                        // Badge de Workspace en esquina superior derecha
                        Rectangle {
                            id: wsBadge
                            anchors.top: parent.top
                            anchors.topMargin: 6
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            width: wsText.implicitWidth + 10
                            height: 17
                            radius: 8.5

                            color: cardDelegate.isCurrent ? Theme.highlight : Qt.rgba(255, 255, 255, 0.08)

                            Text {
                                id: wsText
                                anchors.centerIn: parent
                                text: "WS " + cardDelegate.modelData.workspaceId
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                color: cardDelegate.isCurrent ? "#000000" : Theme.textSecondary
                            }
                        }

                        // Botón de cerrar (✕) en esquina superior izquierda
                        Rectangle {
                            id: closeBtn
                            anchors.top: parent.top
                            anchors.topMargin: 6
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            width: 17
                            height: 17
                            radius: 8.5
                            visible: cardDelegate.isHovered || cardDelegate.isCurrent
                            opacity: visible ? 1.0 : 0.0

                            color: closeBtnArea.containsMouse ? Theme.critical : Qt.rgba(255, 255, 255, 0.08)

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.pixelSize: 9
                                font.family: Theme.fontFamily
                                color: closeBtnArea.containsMouse ? "#ffffff" : Theme.textMuted
                            }

                            MouseArea {
                                id: closeBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    SwitcherService.closeWindow(cardDelegate.modelData.address, cardDelegate.modelData.toplevel);
                                }
                            }
                        }

                        // Contenido central: Icono grande
                        Item {
                            id: iconContainer
                            anchors.top: parent.top
                            anchors.topMargin: 20
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 46
                            height: 46

                            scale: cardDelegate.isCurrent ? 1.08 : (cardDelegate.isHovered ? 1.04 : 1.0)
                            Behavior on scale {
                                NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                            }

                            IconImage {
                                anchors.centerIn: parent
                                width: 44
                                height: 44
                                source: cardDelegate.modelData.iconSource
                                visible: cardDelegate.modelData.iconSource !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 34
                                color: cardDelegate.isCurrent ? Theme.highlight : Theme.textMuted
                                visible: !cardDelegate.modelData.iconSource || cardDelegate.modelData.iconSource === ""
                            }
                        }

                        // Nombre de la app
                        Text {
                            id: appNameLabel
                            anchors.top: iconContainer.bottom
                            anchors.topMargin: 8
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            text: cardDelegate.modelData.appName
                            font.family: Theme.fontFamily
                            font.bold: true
                            font.pixelSize: 11
                            color: cardDelegate.isCurrent ? Theme.text : Theme.textSecondary
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        // Título de la ventana
                        Text {
                            id: titleLabel
                            anchors.top: appNameLabel.bottom
                            anchors.topMargin: 2
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            text: cardDelegate.modelData.title
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.textMuted
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

            // Divisor sutil
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.dividerColor
            }

            // Barra inferior con solo el título centrado
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 18

                Text {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 24, implicitWidth)
                    text: SwitcherService.currentWindow ? (SwitcherService.currentWindow.appName + "  ›  " + SwitcherService.currentWindow.title) : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textSecondary
                    elide: Text.ElideMiddle
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
