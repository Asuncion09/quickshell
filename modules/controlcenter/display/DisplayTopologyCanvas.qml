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

    function handleMonitorDropped(draggedIdx, dropX, dropY) {
        let mons = DisplayService.monitors;
        if (!mons || mons.length < 2) return;

        let draggedMon = mons[draggedIdx];
        if (!draggedMon) return;

        // Calcular centro horizontal en coordenadas del lienzo
        let items = [];
        for (let i = 0; i < mons.length; i++) {
            let m = mons[i];
            let mw = (m.effectiveWidth || 1920) * canvasBox.zoom;
            let cx = 0;
            if (i === draggedIdx) {
                cx = dropX + (mw / 2);
            } else {
                let tx = canvasBox.offsetX + ((m.x - canvasBox.bounds.minX) * canvasBox.zoom);
                cx = tx + (mw / 2);
            }
            items.push({ index: i, monitor: m, centerX: cx });
        }

        // Ordenar horizontalmente de izquierda a derecha
        items.sort((a, b) => a.centerX - b.centerX);

        // Generar coordenadas normalizadas comenzando en x = 0
        let batch = [];
        let curX = 0;
        let changed = false;

        for (let k = 0; k < items.length; k++) {
            let m = items[k].monitor;
            let isCurrentSelected = (DisplayService.selectedMonitor && DisplayService.selectedMonitor.name === m.name);
            let modeStr = isCurrentSelected && root.selectedMode ? root.selectedMode.replace(/Hz$/i, "") : (m.mode ? m.mode.replace(/Hz$/i, "") : (m.width + "x" + m.height + "@" + m.refreshRate));
            let sVal = isCurrentSelected ? root.selectedScale : ((m.scale && m.scale > 0) ? m.scale : 1.0);
            let tVal = isCurrentSelected ? root.selectedTransform : (m.transform || 0);

            if (curX !== m.x || m.y !== 0) {
                changed = true;
            }

            batch.push({
                name: m.name,
                mode: modeStr,
                x: curX,
                y: 0,
                scale: sVal,
                transform: tVal
            });

            curX += Math.round(m.effectiveWidth || 1920);
        }

        if (changed) {
            DisplayService.applyMonitorsBatch(batch);
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4

        Text {
            text: "LAYOUT"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Theme.textMuted
        }

        Item { Layout.fillWidth: true }

        Text {
            text: DisplayService.hasMultipleMonitors ? (DisplayService.monitors.length + " screens • Drag to reorder") : (DisplayService.monitors.length + " screen")
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.textMuted
        }
    }

    Rectangle {
        id: canvasBox
        Layout.fillWidth: true
        implicitHeight: 96
        radius: 12
        color: Theme.bgDark
        border.color: Theme.borderDark
        border.width: 1
        clip: true

        readonly property var bounds: {
            let mons = DisplayService.monitors;
            if (!mons || mons.length === 0) {
                return { minX: 0, minY: 0, totalW: 1920, totalH: 1080 };
            }
            let minX = mons[0].x, minY = mons[0].y;
            let maxX = mons[0].x + (mons[0].effectiveWidth || 1920);
            let maxY = mons[0].y + (mons[0].effectiveHeight || 1080);
            for (let i = 1; i < mons.length; i++) {
                let m = mons[i];
                let mw = m.effectiveWidth || 1920;
                let mh = m.effectiveHeight || 1080;
                if (m.x < minX) minX = m.x;
                if (m.y < minY) minY = m.y;
                if (m.x + mw > maxX) maxX = m.x + mw;
                if (m.y + mh > maxY) maxY = m.y + mh;
            }
            let tw = Math.max(1, maxX - minX);
            let th = Math.max(1, maxY - minY);
            return { minX: minX, minY: minY, totalW: tw, totalH: th };
        }

        readonly property real padX: 18
        readonly property real padY: 14
        readonly property real availableW: canvasBox.width - (padX * 2)
        readonly property real availableH: canvasBox.height - (padY * 2)
        readonly property real zoom: Math.min(availableW / bounds.totalW, availableH / bounds.totalH)
        readonly property real offsetX: (canvasBox.width - (bounds.totalW * zoom)) / 2
        readonly property real offsetY: (canvasBox.height - (bounds.totalH * zoom)) / 2

        Text {
            anchors.centerIn: parent
            visible: !DisplayService.monitors || DisplayService.monitors.length === 0
            text: "No screens detected"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            color: Theme.textMuted
        }

        // Renderizado de monitores: bloque plano de color completo sin bordes + Drag & Drop interactivo
        Repeater {
            model: DisplayService.monitors

            Item {
                id: monitorRectContainer
                required property var modelData
                required property int index

                readonly property var mon: modelData
                readonly property bool isSelected: DisplayService.selectedMonitorIndex === index
                readonly property real monW: (mon.effectiveWidth || 1920) * canvasBox.zoom
                readonly property real monH: (mon.effectiveHeight || 1080) * canvasBox.zoom
                readonly property real posX: canvasBox.offsetX + ((mon.x - canvasBox.bounds.minX) * canvasBox.zoom)
                readonly property real posY: canvasBox.offsetY + ((mon.y - canvasBox.bounds.minY) * canvasBox.zoom)

                property bool isDragging: false
                property real dragX: 0

                x: isDragging ? dragX : posX
                y: posY
                width: monW
                height: monH
                z: isDragging ? 100 : (isSelected ? 2 : 1)

                Behavior on x {
                    enabled: !monitorRectContainer.isDragging
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
                Behavior on y {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                // Rectángulo de color completo sin borde
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    border.width: 0

                    // Color sólido completo: seleccionado (Theme.surfaceKeyFocus) vs inactivo (Theme.surfaceBase) vs arrastrando (Theme.selectionBg) vs hover (Theme.surfaceHover)
                    color: {
                        if (mon.disabled) return Theme.surfaceBase;
                        if (monitorRectContainer.isDragging) return Theme.selectionBg;
                        if (isSelected) return Theme.surfaceKeyFocus;
                        return monMouse.containsMouse ? Theme.surfaceHover : Theme.surfaceBase;
                    }
                    opacity: mon.disabled ? 0.35 : (monitorRectContainer.isDragging ? 0.92 : 1.0)
                    scale: monitorRectContainer.isDragging ? 1.05 : 1.0

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: mon.name.startsWith("eDP") ? "󰌢" : "󰍹"
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Math.min(18, Math.max(13, monH * 0.35)))
                            color: (isSelected || monitorRectContainer.isDragging) ? Theme.textBright : Theme.textSecondary
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: mon.name
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Math.min(12, Math.max(10, monH * 0.24)))
                            font.weight: (isSelected || monitorRectContainer.isDragging) ? Font.Bold : Font.DemiBold
                            color: (isSelected || monitorRectContainer.isDragging) ? Theme.textBright : Theme.textSecondary
                            elide: Text.ElideRight
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    // Punto indicador verde de foco
                    Rectangle {
                        visible: mon.focused
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.success
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 5
                    }

                    MouseArea {
                        id: monMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: monitorRectContainer.isDragging ? Qt.ClosedHandCursor : (DisplayService.hasMultipleMonitors ? Qt.OpenHandCursor : Qt.PointingHandCursor)

                        property real grabOffsetX: 0
                        property real startCanvasX: 0
                        property bool dragActivated: false

                        onPressed: mouse => {
                            DisplayService.selectMonitor(index);
                            let p = monMouse.mapToItem(canvasBox, mouse.x, mouse.y);
                            grabOffsetX = mouse.x;
                            startCanvasX = p.x;
                            dragActivated = false;
                            monitorRectContainer.dragX = monitorRectContainer.posX;
                        }

                        onPositionChanged: mouse => {
                            if (!pressed) return;
                            if (!DisplayService.hasMultipleMonitors) return;

                            let p = monMouse.mapToItem(canvasBox, mouse.x, mouse.y);
                            let delta = Math.abs(p.x - startCanvasX);

                            if (!dragActivated && delta > 6) {
                                dragActivated = true;
                                monitorRectContainer.isDragging = true;
                            }

                            if (monitorRectContainer.isDragging) {
                                let proposedX = p.x - grabOffsetX;
                                let minX = 4;
                                let maxX = canvasBox.width - monitorRectContainer.monW - 4;
                                monitorRectContainer.dragX = Math.max(minX, Math.min(maxX, proposedX));
                            }
                        }

                        onReleased: mouse => {
                            if (monitorRectContainer.isDragging) {
                                monitorRectContainer.isDragging = false;
                                root.handleMonitorDropped(index, monitorRectContainer.dragX, monitorRectContainer.posY);
                            }
                            dragActivated = false;
                        }

                        onCanceled: {
                            monitorRectContainer.isDragging = false;
                            dragActivated = false;
                        }
                    }
                }
            }
        }
    }
}
