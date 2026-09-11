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

    // Absorbe clics para evitar que se propaguen al dismissArea de Bar.qml
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: mouse => {
            mouse.accepted = true;
            searchField.forceActiveFocus();
        }
    }

    Connections {
        target: ClipboardService
        function onIsOpenChanged() {
            if (ClipboardService.isOpen) {
                searchField.text = "";
                Qt.callLater(() => {
                    searchField.forceActiveFocus();
                    root.ensureItemVisible(0);
                });
            }
        }
        function onSelectedIndexChanged() {
            root.ensureItemVisible(ClipboardService.selectedIndex);
        }
    }

    function ensureItemVisible(idx) {
        if (!clipListView || clipListView.count === 0) return;
        let slotHeight = 52; // 48 item height + 4 spacing
        let visibleCount = 5; // 5 ítems completos en pantalla
        let topIndex = Math.round(clipListView.contentY / slotHeight);
        let bottomIndex = topIndex + visibleCount - 1;

        if (idx < topIndex) {
            clipListView.positionViewAtIndex(idx, ListView.Beginning);
        } else if (idx > bottomIndex) {
            clipListView.positionViewAtIndex(idx, ListView.End);
        }
    }

    function formatTime(timestamp) {
        if (!timestamp) return "";
        let diff = Math.floor((Date.now() - timestamp) / 1000);
        if (diff < 30) return "Just now";
        if (diff < 60) return `${diff}s ago`;
        let mins = Math.floor(diff / 60);
        if (mins < 60) return `${mins}m ago`;
        let hours = Math.floor(mins / 60);
        if (hours < 24) return `${hours}h ago`;
        let days = Math.floor(hours / 24);
        return `${days}d ago`;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.bottomMargin: 8
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        spacing: 6

        // --- 1. Barra de Búsqueda Superior ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 32
            radius: 7
            color: searchField.activeFocus ? "#242424" : "#1c1c1c"
            border.width: 1
            border.color: searchField.activeFocus ? "#383838" : "#262626"

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    text: "󰍉"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: searchField.activeFocus ? Theme.text : Theme.textMuted
                    Layout.alignment: Qt.AlignVCenter
                }

                TextInput {
                    id: searchField
                    Layout.fillWidth: true
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Normal
                    color: "#ffffff"
                    selectionColor: "#454545"
                    selectedTextColor: "#ffffff"
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    selectByMouse: true
                    mouseSelectionMode: TextInput.SelectCharacters

                    onTextChanged: {
                        ClipboardService.searchQuery = text;
                    }

                    Text {
                        text: "Search clipboard..."
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.textMuted
                        visible: !searchField.text
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            event.accepted = true;
                            ClipboardService.close();
                            return;
                        }
                        if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                            event.accepted = true;
                            ClipboardService.nextItem();
                            return;
                        }
                        if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                            event.accepted = true;
                            ClipboardService.prevItem();
                            return;
                        }
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true;
                            ClipboardService.selectCurrent();
                            return;
                        }
                        if (event.key === Qt.Key_Delete) {
                            event.accepted = true;
                            let list = ClipboardService.filteredHistory;
                            if (list.length > 0 && ClipboardService.selectedIndex >= 0 && ClipboardService.selectedIndex < list.length) {
                                ClipboardService.deleteItem(list[ClipboardService.selectedIndex].id);
                            }
                            return;
                        }
                    }
                }

                // Botón para limpiar campo de búsqueda
                MouseArea {
                    implicitWidth: 16
                    implicitHeight: 16
                    visible: searchField.text !== ""
                    cursorShape: Qt.PointingHandCursor
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: {
                        searchField.text = "";
                        searchField.forceActiveFocus();
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: parent.containsMouse ? Theme.text : Theme.textMuted
                    }
                }
            }
        }

        // --- 2. Cinta Informativa y Acciones Rápidas ---
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            Layout.preferredHeight: 18

            Text {
                text: {
                    if (ClipboardService.searchQuery !== "") {
                        return `${ClipboardService.filteredHistory.length} matches`;
                    }
                    let count = ClipboardService.history.length;
                    return count === 1 ? "1 saved clip" : `${count} saved clips`;
                }
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Theme.textMuted
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            // Botón Limpiar Todo con Protección Anti-clic Accidental
            Rectangle {
                id: clearBtn
                implicitHeight: 18
                implicitWidth: clearText.implicitWidth + 12
                radius: 4
                visible: ClipboardService.history.length > 0
                color: clearMouse.containsMouse ? (confirmTimer.running ? Qt.rgba(238/255, 83/255, 150/255, 0.25) : "#2a2a2a") : "transparent"

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Timer {
                    id: confirmTimer
                    interval: 2500
                    onTriggered: clearText.text = "Clear All"
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: confirmTimer.running ? "󰀨" : "󰆴"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: confirmTimer.running ? Theme.critical : (clearMouse.containsMouse ? Theme.text : Theme.textMuted)
                    }

                    Text {
                        id: clearText
                        text: confirmTimer.running ? "Confirm?" : "Clear All"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: confirmTimer.running ? Theme.critical : (clearMouse.containsMouse ? Theme.text : Theme.textMuted)
                    }
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (confirmTimer.running) {
                            confirmTimer.stop();
                            clearText.text = "Clear All";
                            ClipboardService.clearAll();
                        } else {
                            confirmTimer.restart();
                            clearText.text = "Confirm?";
                        }
                    }
                }
            }
        }

        // Divisor Sutil
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.dividerColor
        }

        // --- 3. Lista de Elementos del Portapapeles ---
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 256
            clip: true

            // Estado Vacío
            ColumnLayout {
                anchors.centerIn: parent
                visible: ClipboardService.filteredHistory.length === 0
                spacing: 6

                Text {
                    text: ClipboardService.searchQuery !== "" ? "󰍉" : "󰅍"
                    font.family: Theme.fontFamily
                    font.pixelSize: 26
                    color: Theme.textMuted
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: ClipboardService.searchQuery !== ""
                          ? `No matches for "${ClipboardService.searchQuery}"`
                          : "Clipboard is empty"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.text
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: ClipboardService.searchQuery !== ""
                          ? "Try a different search query"
                          : "Copied text, links and code will appear here"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.textMuted
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            ListView {
                id: clipListView
                anchors.fill: parent
                visible: ClipboardService.filteredHistory.length > 0
                model: ClipboardService.filteredHistory
                currentIndex: ClipboardService.selectedIndex
                spacing: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                snapMode: ListView.SnapToItem

                WheelHandler {
                    target: null
                    orientation: Qt.Vertical
                    onWheel: event => {
                        let maxScroll = Math.max(0, clipListView.contentHeight - clipListView.height);
                        if (maxScroll <= 0) return;
                        let step = 52;
                        if (event.angleDelta.y < 0) {
                            clipListView.contentY = Math.min(maxScroll, clipListView.contentY + step);
                        } else if (event.angleDelta.y > 0) {
                            clipListView.contentY = Math.max(0, clipListView.contentY - step);
                        }
                    }
                }


                delegate: Rectangle {
                    id: itemCard
                    width: (ClipboardService.filteredHistory.length > 5) ? (clipListView.width - 12) : clipListView.width
                    height: 48
                    radius: 7

                    readonly property bool isSelected: index === ClipboardService.selectedIndex
                    readonly property bool isItemHovered: itemMouse.containsMouse || delMouse.containsMouse

                    color: isSelected ? "#2e2e2e" : (isItemHovered ? "#222222" : "transparent")
                    border.width: isSelected ? 1 : 0
                    border.color: isSelected ? "#383838" : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        z: 0
                        onClicked: {
                            ClipboardService.selectIndex(index);
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 10
                        spacing: 8
                        z: 1

                        // 1. Badge de Tipo Visual
                        Item {
                            implicitWidth: 26
                            implicitHeight: 26
                            Layout.alignment: Qt.AlignVCenter

                            // Tipo: Color HEX
                            Rectangle {
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                radius: 9
                                visible: modelData.type === "color"
                                color: modelData.color || "#ffffff"
                                border.width: 1.5
                                border.color: "#4a4a4a"
                            }

                            // Tipo: Enlace URL
                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                visible: modelData.type === "url"
                                color: Qt.rgba(120/255, 169/255, 255/255, 0.14)
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰌷"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    color: Theme.highlight
                                }
                            }

                            // Tipo: Código / Snippet
                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                visible: modelData.type === "code"
                                color: Qt.rgba(241/255, 196/255, 15/255, 0.14)
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅩"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    color: Theme.warning
                                }
                            }

                            // Tipo: Texto Plano
                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                visible: modelData.type === "text"
                                color: Qt.rgba(255, 255, 255, 0.06)
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰈙"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    color: Theme.textSecondary
                                }
                            }
                        }

                        // 2. Contenido del Texto
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                Layout.fillWidth: true
                                text: modelData.preview || ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Normal
                                color: isSelected ? "#ffffff" : Theme.text
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: {
                                        if (modelData.lines > 1) {
                                            return `${modelData.lines} lines • ${modelData.charCount} chars`;
                                        }
                                        return `${modelData.charCount} chars`;
                                    }
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: Theme.textMuted
                                }

                                Text {
                                    text: "•"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: Theme.textMuted
                                    visible: modelData.timestamp
                                }

                                Text {
                                    text: root.formatTime(modelData.timestamp)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: Theme.textMuted
                                    visible: modelData.timestamp
                                }
                            }
                        }

                        // 3. Acciones del Item
                        RowLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            // Botón de eliminar snippet individual
                            Rectangle {
                                id: delBtn
                                implicitWidth: 22
                                implicitHeight: 22
                                radius: 4
                                z: 10
                                color: delMouse.containsMouse ? Qt.rgba(238/255, 83/255, 150/255, 0.22) : "transparent"
                                visible: isItemHovered || isSelected

                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆴"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: delMouse.containsMouse ? Theme.critical : Theme.textMuted
                                }

                                MouseArea {
                                    id: delMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton
                                    preventStealing: true
                                    onPressed: mouse => mouse.accepted = true
                                    onClicked: mouse => {
                                        mouse.accepted = true;
                                        ClipboardService.deleteItem(modelData.id);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // --- Custom Minimal ScrollBar ---
            Item {
                id: scrollTrack
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.topMargin: 2
                anchors.bottomMargin: 2
                width: 14
                visible: clipListView.visible && (ClipboardService.filteredHistory.length > 5)
                z: 20

                readonly property real maxContentY: Math.max(1, clipListView.contentHeight - clipListView.height)
                readonly property real maxThumbY: Math.max(0, height - scrollThumb.height)

                // Cápsula / Pastilla del Scrollbar (Minimalista, sutil y dockeada a la derecha)
                Rectangle {
                    id: scrollThumb
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    width: scrollMouse.containsMouse || scrollMouse.pressed ? 4 : 3
                    radius: width / 2
                    height: Math.max(28, Math.min(scrollTrack.height, (clipListView.height / Math.max(clipListView.height, clipListView.contentHeight)) * scrollTrack.height))
                    y: scrollTrack.maxThumbY > 0
                       ? (Math.max(0, Math.min(1, clipListView.contentY / scrollTrack.maxContentY)) * scrollTrack.maxThumbY)
                       : 0

                    // Color sutil integrado a la paleta oscura
                    color: scrollMouse.pressed 
                           ? Qt.rgba(1, 1, 1, 0.55) 
                           : (scrollMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.18))

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on width { NumberAnimation { duration: Theme.animFast } }
                }

                // Interacción: Clic directo para saltar o arrastre fluido (drag)
                MouseArea {
                    id: scrollMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    property real dragStartY: 0
                    property real dragStartContentY: 0
                    property bool dragging: false

                    onPressed: mouse => {
                        if (mouse.y >= scrollThumb.y && mouse.y <= scrollThumb.y + scrollThumb.height) {
                            dragging = true;
                            dragStartY = mouse.y;
                            dragStartContentY = clipListView.contentY;
                        } else {
                            let targetThumbY = mouse.y - (scrollThumb.height / 2);
                            let ratio = Math.max(0, Math.min(1, targetThumbY / Math.max(1, scrollTrack.maxThumbY)));
                            clipListView.contentY = ratio * scrollTrack.maxContentY;
                            dragging = true;
                            dragStartY = mouse.y;
                            dragStartContentY = clipListView.contentY;
                        }
                    }

                    onPositionChanged: mouse => {
                        if (dragging && pressed && scrollTrack.maxThumbY > 0) {
                            let dy = mouse.y - dragStartY;
                            let deltaRatio = dy / scrollTrack.maxThumbY;
                            let targetContentY = dragStartContentY + (deltaRatio * scrollTrack.maxContentY);
                            clipListView.contentY = Math.max(0, Math.min(scrollTrack.maxContentY, targetContentY));
                        }
                    }

                    onReleased: {
                        dragging = false;
                    }

                    onCanceled: {
                        dragging = false;
                    }
                }
            }
        }
    }
}
