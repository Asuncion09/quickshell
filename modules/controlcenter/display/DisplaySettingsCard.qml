import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 6

    property string selectedMode: ""
    property real selectedScale: 1.0
    property int selectedTransform: 0
    property string openMenu: ""
    property int navIndex: 0
    property bool isKeyNavActive: false
    property int menuNavIndex: 0

    property var modeOptions: []
    property var scaleOptions: []
    property var orientationOptions: []

    signal modeSelected(string mode)
    signal scaleSelected(real scale)
    signal transformSelected(int transform)
    signal menuToggled(string menuName)

    function getScaleLabel(val) {
        if (Math.abs(val - 1.0) < 0.01) return "1.0x (100%)";
        if (Math.abs(val - 1.25) < 0.01) return "1.25x (125%)";
        if (Math.abs(val - 1.5) < 0.01) return "1.5x (150%)";
        if (Math.abs(val - 1.75) < 0.01) return "1.75x (175%)";
        if (Math.abs(val - 2.0) < 0.01) return "2.0x (200%)";
        return Number(val).toFixed(2) + "x";
    }

    function getTransformLabel(val) {
        if (val === 1) return "90° (Portrait Left)";
        if (val === 2) return "180° (Inverted)";
        if (val === 3) return "270° (Portrait Right)";
        return "0° (Normal)";
    }

    function scrollModeIntoView(idx) {
        if (idx < 0) return;
        let itemY = idx * 32;
        let viewTop = modesFlickable.contentY;
        let viewHeight = modesFlickable.height;
        if (viewHeight <= 0) return;
        let viewBottom = viewTop + viewHeight;

        if (itemY < viewTop) {
            modesFlickable.contentY = Math.max(0, itemY);
        } else if (itemY + 30 > viewBottom) {
            modesFlickable.contentY = Math.max(0, itemY + 30 - viewHeight);
        }
    }

    Text {
        text: "CONFIGURATION"
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.weight: Font.DemiBold
        color: Theme.textMuted
        Layout.leftMargin: 4
    }

    Rectangle {
        id: settingsCard
        Layout.fillWidth: true
        implicitHeight: settingsCardCol.implicitHeight + 8
        radius: 12
        color: Theme.surfaceBase
        border.width: 1
        border.color: Theme.borderDark
        clip: true

        ColumnLayout {
            id: settingsCardCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            spacing: 0

            // ------------------------------------------
            // Fila 1: Resolution & Refresh
            // ------------------------------------------
            Item {
                Layout.fillWidth: true
                implicitHeight: 46

                Rectangle {
                    anchors.fill: parent
                    radius: 8

                    readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === 1
                    readonly property bool isOpen: root.openMenu === "resolution"
                    readonly property bool isHovered: modeRowMouse.containsMouse

                    color: isKeyFocused ? Theme.surfaceKeyFocus : Theme.surfaceHover
                    opacity: isKeyFocused ? 1.0 : (isHovered ? 1.0 : (isOpen ? 0.35 : 0.0))

                    border.width: isKeyFocused ? 1.5 : 0
                    border.color: (isKeyFocused && isOpen) ? Qt.rgba(1, 1, 1, 0.25) : Theme.highlight

                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    Text {
                        text: "󰍺"
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        color: Theme.highlight
                    }

                    ColumnLayout {
                        spacing: 1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Resolution"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Theme.text
                        }

                        Text {
                            text: "Mode & refresh rate"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.textMuted
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.selectedMode !== "" ? root.selectedMode.replace(/\.00Hz/i, "Hz").replace(/\.00$/i, "") : "Auto"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                        Layout.maximumWidth: 140
                    }

                    Text {
                        text: root.openMenu === "resolution" ? "󰅃" : "󰅀"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.textMuted
                    }
                }

                MouseArea {
                    id: modeRowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.menuToggled("resolution")
                }
            }

            // Lista fluida integrada para Resolución
            Rectangle {
                id: modesTray
                Layout.fillWidth: true
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                Layout.topMargin: 2
                Layout.bottomMargin: root.openMenu === "resolution" ? 4 : 0
                implicitHeight: root.openMenu === "resolution" ? Math.min(166, modesCol.implicitHeight + 4) : 0
                visible: implicitHeight > 0
                clip: true
                color: "transparent"

                Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on Layout.bottomMargin { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Flickable {
                    id: modesFlickable
                    anchors.fill: parent
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    contentHeight: modesCol.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: modesCol
                        width: parent.width - (modesFlickable.visibleArea.heightRatio < 1.0 ? 8 : 0)
                        spacing: 2

                        Repeater {
                            model: root.modeOptions

                            Rectangle {
                                id: modeItemBox
                                required property string modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: 30
                                radius: 6
                                readonly property bool isCurrent: root.selectedMode === modelData
                                readonly property bool isKeyFocused: root.isKeyNavActive && root.openMenu === "resolution" && root.menuNavIndex === index
                                readonly property var parts: {
                                    let raw = modelData.replace(/\.00Hz/i, "Hz").replace(/\.00$/i, "");
                                    let atIdx = raw.indexOf("@");
                                    if (atIdx !== -1) {
                                        return { res: raw.substring(0, atIdx), rate: raw.substring(atIdx + 1) };
                                    }
                                    return { res: raw, rate: "" };
                                }
                                color: isKeyFocused ? Theme.surfaceKeyFocus : (isCurrent ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.12) : "transparent")
                                border.width: isKeyFocused ? 1.5 : 0
                                border.color: Theme.highlight

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: Theme.surfaceHover
                                    opacity: (!modeItemBox.isKeyFocused && !modeItemBox.isCurrent && modeItemMouse.containsMouse) ? 1.0 : (modeItemBox.isCurrent && modeItemMouse.containsMouse ? 0.35 : 0.0)
                                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 6

                                    Text {
                                        text: modeItemBox.parts.res
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        color: (modeItemBox.isKeyFocused || modeItemBox.isCurrent) ? Theme.textBright : Theme.textSecondary
                                        font.weight: (modeItemBox.isKeyFocused || modeItemBox.isCurrent) ? Font.DemiBold : Font.Normal
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        visible: modeItemBox.parts.rate !== ""
                                        text: modeItemBox.parts.rate
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        color: modeItemBox.isCurrent ? Theme.highlight : (modeItemBox.isKeyFocused ? Theme.text : Theme.textMuted)
                                        font.weight: Font.Medium
                                    }

                                    Text {
                                        visible: modeItemBox.isCurrent
                                        text: "󰄬"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        color: Theme.highlight
                                    }
                                }

                                MouseArea {
                                    id: modeItemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.modeSelected(modelData);
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 1
                        y: modesFlickable.visibleArea.yPosition * modesFlickable.height
                        height: Math.max(16, modesFlickable.visibleArea.heightRatio * modesFlickable.height)
                        width: 3
                        radius: 1.5
                        color: Qt.rgba(1, 1, 1, 0.25)
                        visible: modesFlickable.visibleArea.heightRatio < 1.0
                    }
                }
            }

            // Separador 1px
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                height: 1
                color: Theme.dividerColor
            }

            // ------------------------------------------
            // Fila 2: Scale
            // ------------------------------------------
            Item {
                Layout.fillWidth: true
                implicitHeight: 46

                Rectangle {
                    anchors.fill: parent
                    radius: 8

                    readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === 2
                    readonly property bool isOpen: root.openMenu === "scale"
                    readonly property bool isHovered: scaleRowMouse.containsMouse

                    color: isKeyFocused ? Theme.surfaceKeyFocus : Theme.surfaceHover
                    opacity: isKeyFocused ? 1.0 : (isHovered ? 1.0 : (isOpen ? 0.35 : 0.0))

                    border.width: isKeyFocused ? 1.5 : 0
                    border.color: (isKeyFocused && isOpen) ? Qt.rgba(1, 1, 1, 0.25) : Theme.highlight

                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    Text {
                        text: "󰹑"
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        color: Theme.highlight
                    }

                    ColumnLayout {
                        spacing: 1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Scale"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Theme.text
                        }

                        Text {
                            text: "UI magnification"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.textMuted
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.getScaleLabel(root.selectedScale)
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Theme.textSecondary
                    }

                    Text {
                        text: root.openMenu === "scale" ? "󰅃" : "󰅀"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.textMuted
                    }
                }

                MouseArea {
                    id: scaleRowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.menuToggled("scale")
                }
            }

            // Lista fluida integrada para Escala
            Rectangle {
                id: scaleTray
                Layout.fillWidth: true
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                Layout.topMargin: 2
                Layout.bottomMargin: root.openMenu === "scale" ? 4 : 0
                implicitHeight: root.openMenu === "scale" ? (scaleListCol.implicitHeight + 4) : 0
                visible: implicitHeight > 0
                clip: true
                color: "transparent"

                Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on Layout.bottomMargin { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Flickable {
                    anchors.fill: parent
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    contentHeight: scaleListCol.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: scaleListCol
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: root.scaleOptions

                            Rectangle {
                                id: scaleItemBox
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: 30
                                radius: 6
                                readonly property bool isCurrent: Math.abs(root.selectedScale - modelData.value) < 0.01
                                readonly property bool isKeyFocused: root.isKeyNavActive && root.openMenu === "scale" && root.menuNavIndex === index
                                color: isKeyFocused ? Theme.surfaceKeyFocus : (isCurrent ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.12) : "transparent")
                                border.width: isKeyFocused ? 1.5 : 0
                                border.color: Theme.highlight

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: Theme.surfaceHover
                                    opacity: (!scaleItemBox.isKeyFocused && !scaleItemBox.isCurrent && scaleItemMouse.containsMouse) ? 1.0 : (scaleItemBox.isCurrent && scaleItemMouse.containsMouse ? 0.35 : 0.0)
                                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10

                                    Text {
                                        text: modelData.label
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        color: (scaleItemBox.isKeyFocused || scaleItemBox.isCurrent) ? Theme.textBright : Theme.textSecondary
                                        font.weight: (scaleItemBox.isKeyFocused || scaleItemBox.isCurrent) ? Font.Bold : Font.Normal
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        visible: scaleItemBox.isCurrent
                                        text: "󰄬"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        color: Theme.highlight
                                    }
                                }

                                MouseArea {
                                    id: scaleItemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.scaleSelected(modelData.value);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Separador 1px
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                height: 1
                color: Theme.dividerColor
            }

            // ------------------------------------------
            // Fila 3: Orientation
            // ------------------------------------------
            Item {
                Layout.fillWidth: true
                implicitHeight: 46

                Rectangle {
                    anchors.fill: parent
                    radius: 8

                    readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === 3
                    readonly property bool isOpen: root.openMenu === "orientation"
                    readonly property bool isHovered: orientRowMouse.containsMouse

                    color: isKeyFocused ? Theme.surfaceKeyFocus : Theme.surfaceHover
                    opacity: isKeyFocused ? 1.0 : (isHovered ? 1.0 : (isOpen ? 0.35 : 0.0))

                    border.width: isKeyFocused ? 1.5 : 0
                    border.color: (isKeyFocused && isOpen) ? Qt.rgba(1, 1, 1, 0.25) : Theme.highlight

                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    Text {
                        text: "󰑓"
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        color: Theme.highlight
                    }

                    ColumnLayout {
                        spacing: 1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Orientation"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Theme.text
                        }

                        Text {
                            text: "Screen rotation"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.textMuted
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.getTransformLabel(root.selectedTransform)
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                        Layout.maximumWidth: 120
                    }

                    Text {
                        text: root.openMenu === "orientation" ? "󰅃" : "󰅀"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.textMuted
                    }
                }

                MouseArea {
                    id: orientRowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.menuToggled("orientation")
                }
            }

            // Lista fluida integrada para Orientación
            Rectangle {
                id: orientTray
                Layout.fillWidth: true
                Layout.leftMargin: 0
                Layout.rightMargin: 0
                Layout.topMargin: 2
                Layout.bottomMargin: root.openMenu === "orientation" ? 4 : 0
                implicitHeight: root.openMenu === "orientation" ? (orientListCol.implicitHeight + 4) : 0
                visible: implicitHeight > 0
                clip: true
                color: "transparent"

                Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on Layout.bottomMargin { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Flickable {
                    anchors.fill: parent
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    contentHeight: orientListCol.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: orientListCol
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: root.orientationOptions

                            Rectangle {
                                id: orientItemBox
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: 30
                                radius: 6
                                readonly property bool isCurrent: root.selectedTransform === modelData.value
                                readonly property bool isKeyFocused: root.isKeyNavActive && root.openMenu === "orientation" && root.menuNavIndex === index
                                color: isKeyFocused ? Theme.surfaceKeyFocus : (isCurrent ? Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.12) : "transparent")
                                border.width: isKeyFocused ? 1.5 : 0
                                border.color: Theme.highlight

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: Theme.surfaceHover
                                    opacity: (!orientItemBox.isKeyFocused && !orientItemBox.isCurrent && orientItemMouse.containsMouse) ? 1.0 : (orientItemBox.isCurrent && orientItemMouse.containsMouse ? 0.35 : 0.0)
                                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10

                                    Text {
                                        text: modelData.label
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        color: (orientItemBox.isKeyFocused || orientItemBox.isCurrent) ? Theme.textBright : Theme.textSecondary
                                        font.weight: (orientItemBox.isKeyFocused || orientItemBox.isCurrent) ? Font.Bold : Font.Normal
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        visible: orientItemBox.isCurrent
                                        text: "󰄬"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        color: Theme.highlight
                                    }
                                }

                                MouseArea {
                                    id: orientItemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.transformSelected(modelData.value);
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
