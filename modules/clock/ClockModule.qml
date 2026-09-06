import QtQuick
import "../../theme"

Item {
    id: root

    property date currentDate: new Date()
    property bool showAlt: false

    // Formateo de fecha y hora idéntico a Waybar
    // Principal: " 01:42 PM"
    // Alternativo al click: "󰸗 Sat, 06 Sep 2026"
    readonly property string timeText: " " + Qt.formatDateTime(currentDate, "hh:mm AP")
    readonly property string dateText: "󰸗 " + Qt.formatDateTime(currentDate, "ddd, dd MMM yyyy")

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    // Actualizador de tiempo cada 1 segundo
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.currentDate = new Date();
        }
    }

    Text {
        id: label
        anchors.centerIn: parent

        text: root.showAlt ? root.dateText : root.timeText
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Font.ExtraBold // font-weight: 800 de tu style.css

        color: mouseArea.containsMouse ? Qt.lighter(Theme.highlight, 1.15) : Theme.highlight
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        Behavior on color {
            ColorAnimation { duration: Theme.animNormal }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.showAlt = !root.showAlt;
        }
    }
}

