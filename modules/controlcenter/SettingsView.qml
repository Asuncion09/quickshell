import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../../services"

Item {
    id: root

    implicitWidth: 280
    implicitHeight: contentCol.implicitHeight
    height: implicitHeight
    Layout.fillWidth: true

    signal backRequested()
    signal soundRequested()
    signal wallpaperRequested()

    property int navIndex: 0
    property bool isKeyNavActive: false

    onVisibleChanged: {
        root.isKeyNavActive = false;
        root.navIndex = 0;
    }

    function triggerCurrentItem() {
        if (root.navIndex === 0) {
            root.backRequested();
            return;
        }
        if (root.navIndex === 1) {
            root.soundRequested();
            return;
        }
        if (root.navIndex === 2) {
            root.wallpaperRequested();
            return;
        }
    }

    function handleKey(event) {
        let totalItems = 3; // 0: Volver, 1: Sound, 2: Wallpaper

        if (!root.isKeyNavActive) {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Up || event.key === Qt.Key_Right || event.key === Qt.Key_Left || event.key === Qt.Key_Tab) {
                root.isKeyNavActive = true;
                root.navIndex = 0;
                return true;
            }
        }

        if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
            root.isKeyNavActive = true;
            root.navIndex = (root.navIndex + 1) % totalItems;
            return true;
        }

        if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
            root.isKeyNavActive = true;
            root.navIndex = (root.navIndex - 1 + totalItems) % totalItems;
            return true;
        }

        if (event.key === Qt.Key_Left) {
            root.isKeyNavActive = true;
            root.backRequested();
            return true;
        }

        if (event.key === Qt.Key_Right) {
            root.isKeyNavActive = true;
            if (root.navIndex === 0) root.navIndex = 1;
            return true;
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.triggerCurrentItem();
            return true;
        }

        if (event.key === Qt.Key_Escape) {
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
        // 1. CABECERA: Volver + Título
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
                text: "Settings"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.text
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }
        }

        // Divisor fino
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.dividerColor
        }

        // ==========================================
        // 2. SECCIÓN DE CONFIGURACIONES DEL SISTEMA
        // ==========================================
        Text {
            text: "SYSTEM"
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: Theme.textMuted
            Layout.leftMargin: 4
            Layout.topMargin: 2
        }

        // Tarjeta Interactiva 1: Sound (Sonido)
        Rectangle {
            id: soundSettingCard
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 10

            readonly property bool isFocused: root.isKeyNavActive && root.navIndex === 1
            readonly property bool isHovered: soundMouse.containsMouse

            color: isFocused ? "#2c2c2c" : (isHovered ? Theme.surfaceHover : Theme.surfaceBase)
            border.width: isFocused ? 1.5 : 0
            border.color: Theme.highlight

            scale: soundMouse.pressed ? 0.98 : 1.0
            Behavior on scale { NumberAnimation { duration: Theme.animFast } }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Behavior on border.width { NumberAnimation { duration: 40 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 12
                spacing: 10

                // Icono temático de Audio
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 8
                    color: Qt.rgba(Theme.wsActiveColor.r, Theme.wsActiveColor.g, Theme.wsActiveColor.b, 0.16)

                    Text {
                        anchors.centerIn: parent
                        text: AudioService.outputIcon || "󰓃"
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        color: Theme.wsActiveColor
                    }
                }

                // Textos (Título y Dispositivo activo)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Sound"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                    }

                    Text {
                        text: AudioService.outputDescription || "Audio devices & volume"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Normal
                        color: Theme.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Chevron indicador de submenú
                Text {
                    text: "󰅂"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: soundSettingCard.isHovered || soundSettingCard.isFocused ? "#ffffff" : Theme.textMuted

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
            }

            MouseArea {
                id: soundMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.soundRequested()
            }
        }

        // Tarjeta Interactiva 2: Wallpaper (Fondo de pantalla)
        Rectangle {
            id: wallpaperSettingCard
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 10

            readonly property bool isFocused: root.isKeyNavActive && root.navIndex === 2
            readonly property bool isHovered: wallpaperMouse.containsMouse

            color: isFocused ? "#2c2c2c" : (isHovered ? Theme.surfaceHover : Theme.surfaceBase)
            border.width: isFocused ? 1.5 : 0
            border.color: Theme.highlight

            scale: wallpaperMouse.pressed ? 0.98 : 1.0
            Behavior on scale { NumberAnimation { duration: Theme.animFast } }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Behavior on border.width { NumberAnimation { duration: 40 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 12
                spacing: 10

                // Miniatura o icono de Wallpaper
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 8
                    clip: true
                    color: Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.16)

                    Image {
                        id: thumbPreview
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        source: WallpaperService.currentWallpaper ? ("file://" + WallpaperService.currentWallpaper) : ""
                        sourceSize.width: 64
                        sourceSize.height: 64
                        visible: WallpaperService.currentWallpaper !== ""
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰸉"
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        color: Theme.highlight
                        visible: !thumbPreview.visible || thumbPreview.status !== Image.Ready
                    }
                }

                // Textos (Título y Fondo activo)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Wallpaper"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                    }

                    Text {
                        text: {
                            let p = WallpaperService.currentWallpaper;
                            if (!p) return "Select wallpaper";
                            let parts = p.split("/");
                            return parts[parts.length - 1];
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Normal
                        color: Theme.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Chevron indicador de submenú
                Text {
                    text: "󰅂"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: wallpaperSettingCard.isHovered || wallpaperSettingCard.isFocused ? "#ffffff" : Theme.textMuted

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
            }

            MouseArea {
                id: wallpaperMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.wallpaperRequested()
            }
        }
    }
}
