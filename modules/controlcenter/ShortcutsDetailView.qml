import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"

Item {
    id: root

    implicitWidth: 320
    implicitHeight: 525
    height: implicitHeight
    Layout.fillWidth: true

    signal backRequested()

    property bool isKeyNavActive: false
    property string searchQuery: ""

    // Reseteo al abrir/cerrar la vista
    onVisibleChanged: {
        if (visible) {
            root.isKeyNavActive = false;
            root.searchQuery = "";
            searchInput.text = "";
            shortcutsList.currentIndex = 0;
        }
    }

    // Catálogo completo de atajos del entorno Quickshell / Hyprland
    // Estructura limpia y directa: catName, desc, keys
    readonly property var allShortcuts: [
        // --- HYPRLAND ---
        { cat: "hypr", catName: "Hyprland", desc: "Lanzador de Apps", keys: "Super + Space" },
        { cat: "hypr", catName: "Hyprland", desc: "Historial Portapapeles", keys: "Super + V" },
        { cat: "hypr", catName: "Hyprland", desc: "Centro de Notificaciones", keys: "Super + N" },
        { cat: "hypr", catName: "Hyprland", desc: "Centro de Control", keys: "Super + C" },
        { cat: "hypr", catName: "Hyprland", desc: "Hub de Configuración", keys: "Super + Shift + S" },
        { cat: "hypr", catName: "Hyprland", desc: "Ajustes de Pantallas", keys: "Super + Shift + D" },
        { cat: "hypr", catName: "Hyprland", desc: "Fondo de Pantalla", keys: "Super + Shift + W" },
        { cat: "hypr", catName: "Hyprland", desc: "Personalización de Tema", keys: "Super + Shift + T" },
        { cat: "hypr", catName: "Hyprland", desc: "Atajos del Sistema", keys: "Super + Shift + K" },
        { cat: "hypr", catName: "Hyprland", desc: "Bloquear Pantalla", keys: "Super + L" },
        { cat: "hypr", catName: "Hyprland", desc: "Ir a Workspace 1..5", keys: "Super + 1..5" },
        { cat: "hypr", catName: "Hyprland", desc: "Mover a Workspace", keys: "Super + Shift + 1..5" },
        { cat: "hypr", catName: "Hyprland", desc: "Subir / Bajar Volumen", keys: "Vol+ / Vol-" },
        { cat: "hypr", catName: "Hyprland", desc: "Silenciar Audio / Mic", keys: "Mute / MicMute" },
        { cat: "hypr", catName: "Hyprland", desc: "Subir / Bajar Brillo", keys: "Bri+ / Bri-" },

        // --- CENTRO DE CONTROL ---
        { cat: "cc", catName: "Centro de Control", desc: "Navegar Controles", keys: "Tab / Shift+Tab" },
        { cat: "cc", catName: "Centro de Control", desc: "Navegación en Cruz", keys: "↑ ↓ ← →" },
        { cat: "cc", catName: "Centro de Control", desc: "Conmutar / Silenciar", keys: "Space" },
        { cat: "cc", catName: "Centro de Control", desc: "Abrir Detalle / Submenú", keys: "Enter" },
        { cat: "cc", catName: "Centro de Control", desc: "Ajustar Sliders (±5%)", keys: "← / →" },
        { cat: "cc", catName: "Centro de Control", desc: "Volver a Vista Anterior", keys: "Esc / Backspace" },

        // --- NOTIFICACIONES ---
        { cat: "notif", catName: "Notificaciones", desc: "Siguiente / Anterior", keys: "↓ j / ↑ k" },
        { cat: "notif", catName: "Notificaciones", desc: "Abrir / Enfocar Ventana", keys: "Enter / Space" },
        { cat: "notif", catName: "Notificaciones", desc: "Descartar Notificación", keys: "d / Delete" },
        { cat: "notif", catName: "Notificaciones", desc: "Copiar Imagen o Texto", keys: "y / Ctrl+C" },
        { cat: "notif", catName: "Notificaciones", desc: "Limpiar Todas", keys: "c / Shift+Del" },
        { cat: "notif", catName: "Notificaciones", desc: "Alternar No Molestar", keys: "t" },

        // --- LANZADOR Y PORTAPAPELES ---
        { cat: "apps", catName: "Lanzador & Clipboard", desc: "Filtrar por Texto", keys: "Escribir" },
        { cat: "apps", catName: "Lanzador & Clipboard", desc: "Navegar en la Lista", keys: "↓ / ↑" },
        { cat: "apps", catName: "Lanzador & Clipboard", desc: "Ejecutar / Pegar", keys: "Enter" },
        { cat: "apps", catName: "Lanzador & Clipboard", desc: "Borrar Entrada", keys: "d / Delete" },
        { cat: "apps", catName: "Lanzador & Clipboard", desc: "Limpiar Historial", keys: "c" },

        // --- WORKSPACES ---
        { cat: "ws", catName: "Workspaces", desc: "Ciclar Workspaces", keys: "Scroll ↑ / ↓" },
        { cat: "ws", catName: "Workspaces", desc: "Cambiar a Workspace", keys: "Clic" }
    ]

    // Lista filtrada reactiva
    readonly property var filteredShortcuts: {
        let q = root.searchQuery.trim().toLowerCase();
        return root.allShortcuts.filter(item => {
            if (q === "") return true;
            let matchDesc = item.desc.toLowerCase().includes(q);
            let matchCatName = item.catName.toLowerCase().includes(q);
            let matchKeys = item.keys.toLowerCase().includes(q);
            return matchDesc || matchCatName || matchKeys;
        });
    }

    // Gestión de eventos de teclado
    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            if (searchInput.text !== "") {
                searchInput.text = "";
                root.searchQuery = "";
                return true;
            }
            root.backRequested();
            return true;
        }

        if (event.key === Qt.Key_Back || event.key === Qt.Key_Backspace) {
            if (searchInput.activeFocus && searchInput.text.length > 0) {
                return false;
            }
            root.backRequested();
            return true;
        }

        if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
            root.isKeyNavActive = true;
            if (shortcutsList.count > 0) {
                shortcutsList.currentIndex = Math.min(shortcutsList.count - 1, shortcutsList.currentIndex + 1);
                shortcutsList.positionViewAtIndex(shortcutsList.currentIndex, ListView.Contain);
            }
            return true;
        }

        if (event.key === Qt.Key_Up || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) || event.key === Qt.Key_Backtab) {
            root.isKeyNavActive = true;
            if (shortcutsList.count > 0) {
                shortcutsList.currentIndex = Math.max(0, shortcutsList.currentIndex - 1);
                shortcutsList.positionViewAtIndex(shortcutsList.currentIndex, ListView.Contain);
            }
            return true;
        }

        if (event.text && event.text.length === 1 && !event.modifiers && !searchInput.activeFocus) {
            searchInput.forceActiveFocus();
            searchInput.text += event.text;
            root.searchQuery = searchInput.text;
            return true;
        }

        return false;
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        spacing: 6

        // ==========================================
        // 1. CABECERA MINIMALISTA
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 28
            spacing: 8

            Rectangle {
                id: backBtn
                implicitWidth: 26
                implicitHeight: 26
                radius: 13
                readonly property bool isKeyFocused: root.isKeyNavActive && shortcutsList.currentIndex === -1
                color: isKeyFocused ? Theme.surfaceKeyFocus : (backMouse.containsMouse ? Theme.surfaceHover : "transparent")
                border.width: isKeyFocused ? 1 : 0
                border.color: Theme.highlight

                scale: backMouse.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on color { ColorAnimation { duration: backMouse.containsMouse ? Theme.animFast : 40 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: backMouse.containsMouse ? Theme.textBright : Theme.text
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

            Text {
                text: "Shortcuts"
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Theme.text
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Text {
                text: `${root.filteredShortcuts.length} atajos`
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.textMuted
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Divisor fino
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.dividerColor
        }

        // ==========================================
        // 2. BARRA DE BÚSQUEDA MINIMALISTA Y COMPACTA
        // ==========================================
        Rectangle {
            id: searchBox
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 6
            color: searchInput.activeFocus ? Theme.surfaceKeyFocus : Theme.surfaceBase
            border.width: searchInput.activeFocus ? 1 : 0
            border.color: Theme.highlight

            Behavior on color { ColorAnimation { duration: 40 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.text
                    clip: true
                    selectByMouse: true

                    onTextChanged: {
                        root.searchQuery = text;
                        shortcutsList.currentIndex = 0;
                    }

                    Text {
                        anchors.fill: parent
                        text: "Buscar atajo..."
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.textDisabled
                        visible: !searchInput.text && !searchInput.activeFocus
                    }
                }

                // Limpiar búsqueda
                Text {
                    visible: searchInput.text.length > 0
                    text: "󰅖"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: clearMouse.containsMouse ? Theme.textBright : Theme.textSecondary
                    Layout.alignment: Qt.AlignVCenter

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = "";
                            root.searchQuery = "";
                        }
                    }
                }
            }
        }

        // ==========================================
        // 3. LISTA DE ATAJOS (PLANA, SIN BOTONES NI ICONOS)
        // ==========================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: shortcutsList
                anchors.fill: parent
                clip: true
                spacing: 1
                boundsBehavior: Flickable.StopAtBounds
                model: root.filteredShortcuts
                currentIndex: 0

                // Agrupación por categoría limpia y tipográfica
                section.property: "catName"
                section.criteria: ViewSection.FullString
                section.delegate: Item {
                    width: shortcutsList.width - (vertScroll.visible ? 6 : 0)
                    implicitHeight: 22

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        text: section.toUpperCase()
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.textMuted
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    id: vertScroll
                    active: true
                    policy: shortcutsList.contentHeight > shortcutsList.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                    width: 3
                    contentItem: Rectangle {
                        radius: 1.5
                        color: vertScroll.pressed ? Theme.highlight : (vertScroll.hovered ? Theme.textSecondary : Theme.borderCard)
                    }
                }

                // Estado vacío
                Item {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    height: 80
                    visible: shortcutsList.count === 0

                    Text {
                        anchors.centerIn: parent
                        text: "No se encontraron atajos"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.textSecondary
                    }
                }

                // Delegate plano y minimalista: texto a la izquierda, atajo limpio a la derecha
                delegate: Rectangle {
                    id: shortcutItem
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: root.isKeyNavActive && shortcutsList.currentIndex === index
                    readonly property bool isHovered: itemMouse.containsMouse

                    width: shortcutsList.width - (vertScroll.visible ? 6 : 0)
                    implicitHeight: 25
                    radius: 4

                    // Resaltado sutil únicamente al enfocar con teclado o cursor
                    color: isSelected ? Theme.surfaceKeyFocus : (isHovered ? Theme.surfaceHover : "transparent")

                    Behavior on color { ColorAnimation { duration: 40 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 8

                        // Descripción limpia
                        Text {
                            text: shortcutItem.modelData.desc
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: shortcutItem.isSelected ? Theme.textBright : (shortcutItem.isHovered ? Theme.textBright : Theme.text)
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignVCenter
                        }

                        // Atajo de teclado en texto limpio y nítido (sin forma de botón ni cajas)
                        Text {
                            text: shortcutItem.modelData.keys
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: shortcutItem.isSelected ? Theme.highlight : Theme.textSecondary
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.ArrowCursor
                        onClicked: {
                            root.isKeyNavActive = false;
                            shortcutsList.currentIndex = shortcutItem.index;
                        }
                    }
                }
            }
        }
    }
}
