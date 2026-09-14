import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../../services"

Item {
    id: root

    implicitWidth: 320
    implicitHeight: contentCol.implicitHeight
    height: implicitHeight
    Layout.fillWidth: true

    signal backRequested()

    property int currentTab: 0 // 0: Colors, 1: Sounds
    property int navIndex: 0
    property bool isKeyNavActive: false

    readonly property color dynamicPrimary: (Theme.dynamicPalette && Theme.dynamicPalette.colors && Theme.dynamicPalette.colors.primary)
                                            ? Theme.dynamicPalette.colors.primary.dark.color
                                            : "#81d3dd"

    onVisibleChanged: {
        root.isKeyNavActive = false;
        root.navIndex = 0;
    }

    function triggerCurrentItem() {
        if (root.navIndex === 0) {
            root.backRequested();
            return;
        }

        if (root.currentTab === 0) {
            if (root.navIndex === 1) {
                root.currentTab = (root.currentTab + 1) % 2;
                return;
            }
            if (root.navIndex === 2) {
                WallpaperService.setThemeMode("matugen");
                return;
            }
            if (root.navIndex === 3) {
                WallpaperService.setThemeMode("default");
                return;
            }
        } else if (root.currentTab === 1) {
            if (root.navIndex === 1) {
                root.currentTab = (root.currentTab + 1) % 2;
                return;
            }
            if (root.navIndex === 2) {
                SoundService.setSoundEnabled(!SoundService.soundEnabled);
                return;
            }
            let themeIdx = root.navIndex - 3;
            if (themeIdx >= 0 && themeIdx < SoundService.soundThemes.length) {
                let tid = SoundService.soundThemes[themeIdx].id;
                if (SoundService.currentTheme !== tid) {
                    SoundService.setTheme(tid);
                } else {
                    SoundService.preview("message-new-instant", tid);
                }
                return;
            }
        }
    }

    function handleKey(event) {
        let totalItems = 4;
        if (root.currentTab === 0) {
            totalItems = 4;
        } else {
            totalItems = 3 + SoundService.soundThemes.length;
        }

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
            if (root.navIndex === 0) {
                root.backRequested();
                return true;
            }
            root.currentTab = (root.currentTab - 1 + 2) % 2;
            return true;
        }

        if (event.key === Qt.Key_Right) {
            root.currentTab = (root.currentTab + 1) % 2;
            return true;
        }

        if (event.key === Qt.Key_P && root.currentTab === 1) {
            let themeIdx = root.navIndex - 3;
            if (themeIdx >= 0 && themeIdx < SoundService.soundThemes.length) {
                SoundService.preview("message-new-instant", SoundService.soundThemes[themeIdx].id);
                return true;
            }
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
        spacing: 9

        // ==========================================
        // 1. HEADER: Back Button + View Title
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
                color: isKeyFocused ? Theme.surfaceKeyFocus : (backMouse.containsMouse ? Theme.surfaceHover : "transparent")
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
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: (backMouse.containsMouse || backBtn.isKeyFocused) ? Theme.text : Theme.textSecondary
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
                text: "Theme Style"
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Theme.text
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }
        }

        // Divider line matching SettingsView and AudioDetailView
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.dividerColor
        }

        // ==========================================
        // 2. SEGMENTED TAB SELECTOR (2 TABS: Colors, Sounds)
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 32
            radius: 8
            color: Theme.surfaceBase
            border.color: Theme.borderModal
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                // Tab 0: Colors
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 6
                    readonly property bool isTabActive: root.currentTab === 0
                    color: isTabActive ? Theme.surfaceHover : (tabColorsMouse.containsMouse ? Qt.rgba(255,255,255,0.04) : "transparent")
                    border.width: isTabActive ? 1 : 0
                    border.color: isTabActive ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.4) : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            text: "󰔎"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: parent.parent.isTabActive ? Theme.highlight : Theme.textMuted
                        }
                        Text {
                            text: "Colors"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: parent.parent.isTabActive ? Font.DemiBold : Font.Normal
                            color: parent.parent.isTabActive ? Theme.textBright : Theme.textMuted
                        }
                    }

                    MouseArea {
                        id: tabColorsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentTab = 0
                    }
                }

                // Tab 1: Sounds
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 6
                    readonly property bool isTabActive: root.currentTab === 1
                    color: isTabActive ? Theme.surfaceHover : (tabSoundsMouse.containsMouse ? Qt.rgba(255,255,255,0.04) : "transparent")
                    border.width: isTabActive ? 1 : 0
                    border.color: isTabActive ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.4) : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            text: "󰓃"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: parent.parent.isTabActive ? Theme.highlight : Theme.textMuted
                        }
                        Text {
                            text: "Sounds"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: parent.parent.isTabActive ? Font.DemiBold : Font.Normal
                            color: parent.parent.isTabActive ? Theme.textBright : Theme.textMuted
                        }
                    }

                    MouseArea {
                        id: tabSoundsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentTab = 1
                    }
                }
            }
        }

        // ==========================================
        // 3. TAB 0: COLORS & PALETTE
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: root.currentTab === 0

            // CARD 1: MATERIAL YOU
            Rectangle {
                id: matugenCard
                Layout.fillWidth: true
                implicitHeight: 48
                radius: 10

                readonly property bool isSelected: Theme.themeMode === "matugen"
                readonly property bool isFocused: root.isKeyNavActive && root.navIndex === 2
                readonly property bool isHovered: matugenMouse.containsMouse

                color: isFocused ? Theme.surfaceKeyFocus : (isHovered ? Theme.surfaceHover : Theme.surfaceBase)
                border.width: isFocused ? 1.5 : (isSelected ? 1.5 : 1)
                border.color: isFocused ? Theme.highlight : (isSelected ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.5) : Theme.borderModal)

                scale: matugenMouse.pressed ? 0.98 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.width { NumberAnimation { duration: 40 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 12
                    spacing: 10

                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: 8
                        Layout.alignment: Qt.AlignVCenter
                        color: Qt.rgba(root.dynamicPrimary.r, root.dynamicPrimary.g, root.dynamicPrimary.b, 0.16)

                        Text {
                            anchors.centerIn: parent
                            text: "󰔎"
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            color: root.dynamicPrimary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Material You"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Theme.textBright
                        }

                        Text {
                            text: "Dynamic wallpaper colors"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Normal
                            color: Theme.textMuted
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        radius: 9
                        Layout.alignment: Qt.AlignVCenter
                        color: matugenCard.isSelected ? Theme.highlight : "transparent"
                        border.width: matugenCard.isSelected ? 0 : 1.5
                        border.color: matugenCard.isSelected ? "transparent" : Theme.textMuted

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰄬"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.bgDark
                            visible: matugenCard.isSelected
                        }
                    }
                }

                MouseArea {
                    id: matugenMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WallpaperService.setThemeMode("matugen")
                }
            }

            // CARD 2: OBSIDIAN BLUE (DEFAULT)
            Rectangle {
                id: defaultCard
                Layout.fillWidth: true
                implicitHeight: 48
                radius: 10

                readonly property bool isSelected: Theme.themeMode === "default"
                readonly property bool isFocused: root.isKeyNavActive && root.navIndex === 3
                readonly property bool isHovered: defaultMouse.containsMouse

                color: isFocused ? Theme.surfaceKeyFocus : (isHovered ? Theme.surfaceHover : Theme.surfaceBase)
                border.width: isFocused ? 1.5 : (isSelected ? 1.5 : 1)
                border.color: isFocused ? Theme.highlight : (isSelected ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.5) : Theme.borderModal)

                scale: defaultMouse.pressed ? 0.98 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.width { NumberAnimation { duration: 40 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 12
                    spacing: 10

                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: 8
                        Layout.alignment: Qt.AlignVCenter
                        color: Qt.rgba(Theme.defaultHighlight.r, Theme.defaultHighlight.g, Theme.defaultHighlight.b, 0.16)

                        Text {
                            anchors.centerIn: parent
                            text: "󰏘"
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            color: Theme.defaultHighlight
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Obsidian Blue"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Theme.textBright
                        }

                        Text {
                            text: "Default dark theme"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Normal
                            color: Theme.textMuted
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        radius: 9
                        Layout.alignment: Qt.AlignVCenter
                        color: defaultCard.isSelected ? Theme.highlight : "transparent"
                        border.width: defaultCard.isSelected ? 0 : 1.5
                        border.color: defaultCard.isSelected ? "transparent" : Theme.textMuted

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰄬"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.bgDark
                            visible: defaultCard.isSelected
                        }
                    }
                }

                MouseArea {
                    id: defaultMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WallpaperService.setThemeMode("default")
                }
            }
        }

        // ==========================================
        // 4. TAB 1: SYSTEM SOUNDS
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: root.currentTab === 1

            // Master sound switch
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: 10
                readonly property bool isFocused: root.isKeyNavActive && root.navIndex === 2
                readonly property bool isHovered: soundToggleMouse.containsMouse

                color: isFocused ? Theme.surfaceKeyFocus : (isHovered ? Theme.surfaceHover : Theme.surfaceBase)
                border.width: isFocused ? 1.5 : 1
                border.color: isFocused ? Theme.highlight : Theme.borderModal

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 12
                    spacing: 10

                    Rectangle {
                        implicitWidth: 30
                        implicitHeight: 30
                        radius: 8
                        Layout.alignment: Qt.AlignVCenter
                        color: SoundService.soundEnabled
                               ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.16)
                               : Qt.rgba(Theme.textMuted.r, Theme.textMuted.g, Theme.textMuted.b, 0.12)

                        Text {
                            anchors.centerIn: parent
                            text: SoundService.soundEnabled ? "󰓃" : "󰓄"
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            color: SoundService.soundEnabled ? Theme.highlight : Theme.textMuted
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Sound effects"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Theme.textBright
                        }

                        Text {
                            text: SoundService.soundEnabled ? "Notifications & alerts" : "Muted system sounds"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Normal
                            color: Theme.textMuted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Switch Pill
                    Rectangle {
                        implicitWidth: 36
                        implicitHeight: 20
                        radius: 10
                        Layout.alignment: Qt.AlignVCenter
                        color: SoundService.soundEnabled ? Theme.highlight : Theme.surfaceHover
                        border.width: 1
                        border.color: SoundService.soundEnabled ? Theme.highlight : Theme.borderModal

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            color: SoundService.soundEnabled ? Theme.bgDark : Theme.textMuted
                            anchors.verticalCenter: parent.verticalCenter
                            x: SoundService.soundEnabled ? parent.width - width - 3 : 3

                            Behavior on x { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                MouseArea {
                    id: soundToggleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SoundService.setSoundEnabled(!SoundService.soundEnabled)
                }
            }

            // Sound theme cards
            Repeater {
                model: SoundService.soundThemes

                delegate: Rectangle {
                    id: soundThemeCard
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: 10

                    readonly property bool isSelected: SoundService.currentTheme === modelData.id
                    readonly property bool isFocused: root.isKeyNavActive && root.navIndex === (index + 3)
                    readonly property bool isHovered: cardMouse.containsMouse

                    color: isFocused ? Theme.surfaceKeyFocus : (isHovered ? Theme.surfaceHover : Theme.surfaceBase)
                    border.width: isFocused ? 1.5 : (isSelected ? 1.5 : 1)
                    border.color: isFocused ? Theme.highlight : (isSelected ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.5) : Theme.borderModal)

                    scale: cardMouse.pressed ? 0.98 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.width { NumberAnimation { duration: 40 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 12
                        spacing: 10

                        Rectangle {
                            implicitWidth: 30
                            implicitHeight: 30
                            radius: 8
                            Layout.alignment: Qt.AlignVCenter
                            color: soundThemeCard.isSelected
                                   ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.16)
                                   : Qt.rgba(255, 255, 255, 0.04)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon || "󰓃"
                                font.family: Theme.fontFamily
                                font.pixelSize: 15
                                color: soundThemeCard.isSelected ? Theme.highlight : Theme.text
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: modelData.name
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Theme.textBright
                            }

                            Text {
                                text: modelData.desc
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Normal
                                color: Theme.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Radio Check Indicator
                        Rectangle {
                            implicitWidth: 18
                            implicitHeight: 18
                            radius: 9
                            Layout.alignment: Qt.AlignVCenter
                            color: soundThemeCard.isSelected ? Theme.highlight : "transparent"
                            border.width: soundThemeCard.isSelected ? 0 : 1.5
                            border.color: soundThemeCard.isSelected ? "transparent" : Theme.textMuted

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰄬"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.bgDark
                                visible: soundThemeCard.isSelected
                            }
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (SoundService.currentTheme !== modelData.id) {
                                SoundService.setTheme(modelData.id);
                            } else {
                                SoundService.preview("message-new-instant", modelData.id);
                            }
                        }
                    }
                }
            }
        }
    }
}
