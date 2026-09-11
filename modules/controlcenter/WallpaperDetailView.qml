import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import "../../theme"
import "../../services"

Item {
    id: root

    implicitWidth: 304
    implicitHeight: contentCol.implicitHeight
    height: implicitHeight
    Layout.fillWidth: true

    signal backRequested()

    property int navIndex: 0
    property bool isKeyNavActive: false

    onVisibleChanged: {
        root.isKeyNavActive = false;
        root.navIndex = 0;
        if (visible) {
            WallpaperService.scanWallpapers();
        }
    }

    function triggerCurrentItem() {
        if (root.navIndex === 0) {
            root.backRequested();
            return;
        }

        let count = WallpaperService.wallpapers ? WallpaperService.wallpapers.length : 0;
        let wpIdx = root.navIndex - 1;
        if (wpIdx >= 0 && wpIdx < count) {
            WallpaperService.setWallpaper(WallpaperService.wallpapers[wpIdx].path);
        }
    }

    function handleKey(event) {
        let count = WallpaperService.wallpapers ? WallpaperService.wallpapers.length : 0;
        let totalItems = 1 + count; // 0: Volver, 1..N: Wallpapers

        if (!root.isKeyNavActive) {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Up || event.key === Qt.Key_Right || event.key === Qt.Key_Left || event.key === Qt.Key_Tab) {
                root.isKeyNavActive = true;
                root.navIndex = 0;
                return true;
            }
        }

        // Navegación en cuadrícula de 2 columnas para los wallpapers (navIndex 1..N)
        if (root.navIndex > 0) {
            let currentWp = root.navIndex - 1; // 0-indexed en la lista de wallpapers

            if (event.key === Qt.Key_Right) {
                if (currentWp < count - 1) {
                    root.navIndex++;
                    return true;
                }
            }

            if (event.key === Qt.Key_Left) {
                if (currentWp > 0) {
                    root.navIndex--;
                    return true;
                } else {
                    root.navIndex = 0; // Volver al botón Atrás
                    return true;
                }
            }

            if (event.key === Qt.Key_Down) {
                if (currentWp + 2 < count) {
                    root.navIndex += 2;
                    return true;
                }
            }

            if (event.key === Qt.Key_Up) {
                if (currentWp >= 2) {
                    root.navIndex -= 2;
                    return true;
                } else {
                    root.navIndex = 0;
                    return true;
                }
            }
        } else {
            // Desde botón Volver (navIndex === 0)
            if (event.key === Qt.Key_Down && count > 0) {
                root.navIndex = 1;
                return true;
            }
        }

        if (event.key === Qt.Key_Tab) {
            root.isKeyNavActive = true;
            root.navIndex = (root.navIndex + 1) % totalItems;
            return true;
        }

        if (event.key === Qt.Key_Backtab) {
            root.isKeyNavActive = true;
            root.navIndex = (root.navIndex - 1 + totalItems) % totalItems;
            return true;
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.triggerCurrentItem();
            return true;
        }

        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Backspace) {
            root.backRequested();
            return true;
        }

        return false;
    }

    ColumnLayout {
        id: contentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 10

        // ==========================================
        // 1. CABECERA: Volver + Título + Contador
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 32
            spacing: 8

            Rectangle {
                id: backBtn
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === 0
                color: isKeyFocused ? "#2c2c2c" : (backMouse.containsMouse ? Theme.surfaceHover : "transparent")
                border.width: isKeyFocused ? 1.5 : 0
                border.color: Theme.highlight

                scale: backMouse.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on border.width { NumberAnimation { duration: 40 } }
                Behavior on border.color { ColorAnimation { duration: 40 } }
                Behavior on color { ColorAnimation { duration: backMouse.containsMouse ? Theme.animFast : 40 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: backBtn.isKeyFocused ? Theme.highlight : (backMouse.containsMouse ? "#ffffff" : Theme.text)
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
                text: "Wallpaper"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.text
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Text {
                text: WallpaperService.wallpapers ? (WallpaperService.wallpapers.length + " available") : ""
                font.family: Theme.fontFamily
                font.pixelSize: 10
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
        // 2. VISTA PREVIA DEL FONDO ACTUAL ACTIVO
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 96
            radius: 10
            color: "transparent"

            // Máscara redondeada para la vista previa
            Rectangle {
                id: topMask
                anchors.fill: parent
                radius: 10
                visible: false
                layer.enabled: true
            }

            Item {
                id: topContent
                anchors.fill: parent
                visible: false

                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: WallpaperService.currentWallpaper ? ("file://" + WallpaperService.currentWallpaper) : ""
                    asynchronous: true
                    cache: true
                }

                // Sombra inferior con información del fondo activo
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 32
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.85) }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.wsActiveColor
                        }

                        Text {
                            text: {
                                let p = WallpaperService.currentWallpaper;
                                if (!p) return "None";
                                let parts = p.split("/");
                                return parts[parts.length - 1];
                            }
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: "#ffffff"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "Active"
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.Normal
                            color: Theme.wsActiveColor
                        }
                    }
                }
            }

            // Efecto de redondeo sin bordes rectos
            MultiEffect {
                anchors.fill: parent
                source: topContent
                maskEnabled: true
                maskSource: topMask
            }

            // Borde sutil del contenedor
            Rectangle {
                anchors.fill: parent
                radius: 10
                color: "transparent"
                border.width: 1
                border.color: Theme.dividerColor
            }
        }

        // ==========================================
        // 3. SECCIÓN: GALERÍA DE FONDOS DISPONIBLES
        // ==========================================
        Text {
            text: "SELECT WALLPAPER"
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: Theme.textMuted
            Layout.leftMargin: 4
            Layout.topMargin: 2
        }

        // Cuadrícula simétrica de 2 columnas que ocupa el 100% del ancho
        GridLayout {
            id: wallpaperGrid
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            Repeater {
                model: WallpaperService.wallpapers

                delegate: Item {
                    id: cardItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: 84

                    readonly property int itemNavIndex: index + 1
                    readonly property bool isActive: WallpaperService.currentWallpaper === modelData.path
                    readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === itemNavIndex
                    readonly property bool isHovered: cardMouse.containsMouse

                    scale: cardMouse.pressed ? 0.96 : (isHovered ? 1.02 : 1.0)
                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }

                    // Máscara redondeada para recortar la imagen (radius: 10)
                    Rectangle {
                        id: cardMask
                        anchors.fill: parent
                        radius: 10
                        visible: false
                        layer.enabled: true
                    }

                    // Contenido visual (imagen + gradiente + texto)
                    Item {
                        id: cardVisual
                        anchors.fill: parent
                        visible: false

                        Image {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            source: "file://" + modelData.path
                            sourceSize.width: 296
                            sourceSize.height: 168
                            asynchronous: true
                            cache: true
                        }

                        // Sombra inferior para nombre
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 24
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.85) }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 6
                                text: modelData.name
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                color: "#ffffff"
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // MultiEffect para aplicar las esquinas redondeadas
                    MultiEffect {
                        anchors.fill: parent
                        source: cardVisual
                        maskEnabled: true
                        maskSource: cardMask
                    }

                    // Velo sutil de hover (limpio, sin bordes grises)
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: (cardItem.isHovered && !cardItem.isActive) ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    // Borde de navegación por teclado (solo cuando se navega con teclas)
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: "transparent"
                        border.width: cardItem.isKeyFocused ? 2 : 0
                        border.color: cardItem.isKeyFocused ? Theme.highlight : "transparent"

                        Behavior on border.width { NumberAnimation { duration: 60 } }
                        Behavior on border.color { ColorAnimation { duration: 60 } }
                    }

                    // Badge de activo con icono de check (único indicador de selección)
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 7
                        width: 20
                        height: 20
                        radius: 10
                        color: Theme.wsActiveColor
                        visible: cardItem.isActive
                        border.width: 1.5
                        border.color: "#161616"

                        Text {
                            anchors.centerIn: parent
                            text: "󰄬"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: "#161616"
                            font.weight: Font.Bold
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.navIndex = cardItem.itemNavIndex;
                            WallpaperService.setWallpaper(modelData.path);
                        }
                    }
                }
            }
        }
    }
}
