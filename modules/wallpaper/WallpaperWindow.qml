import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Capa de fondo nativa Wayland (por debajo de ventanas y barras)
    WlrLayershell.layer: WlrLayer.Background
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Totalmente permeable a clics del ratón
    mask: Region {}

    color: Theme.shadowColor

    property string activePath: ""
    property bool showingA: true

    function applyNewWallpaper(newPath) {
        if (!newPath) return;
        let cleanPath = newPath.trim();
        let fileUrl = "file://" + cleanPath;

        if (activePath === "") {
            // Carga inicial directa
            activePath = cleanPath;
            imgA.source = fileUrl;
            imgA.opacity = 1.0;
            imgA.scale = 1.0;
            imgA.z = 2;
            imgB.opacity = 0.0;
            imgB.z = 1;
            showingA = true;
            return;
        }

        if (activePath === cleanPath) return;
        activePath = cleanPath;

        if (showingA) {
            // Preparar Buffer B sobre Buffer A
            transToB.stop();
            transToA.stop();
            imgA.opacity = 1.0;
            imgB.opacity = 0.0;
            imgB.scale = 1.04;
            imgB.z = 2;
            imgA.z = 1;
            imgB.source = fileUrl;
            if (imgB.status === Image.Ready) {
                transToB.restart();
            }
        } else {
            // Preparar Buffer A sobre Buffer B
            transToB.stop();
            transToA.stop();
            imgB.opacity = 1.0;
            imgA.opacity = 0.0;
            imgA.scale = 1.04;
            imgA.z = 2;
            imgB.z = 1;
            imgA.source = fileUrl;
            if (imgA.status === Image.Ready) {
                transToA.restart();
            }
        }
    }

    Connections {
        target: WallpaperService
        function onCurrentWallpaperChanged() {
            root.applyNewWallpaper(WallpaperService.currentWallpaper);
        }
    }

    Component.onCompleted: {
        root.applyNewWallpaper(WallpaperService.currentWallpaper);
    }

    // Transición cinematográfica fluida hacia Buffer B (Buffer B entra sobre Buffer A)
    ParallelAnimation {
        id: transToB
        onStarted: {
            root.showingA = false;
            imgB.z = 2;
            imgA.z = 1;
        }
        onFinished: {
            imgA.opacity = 0.0;
            imgA.scale = 1.0;
        }

        NumberAnimation {
            target: imgB
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 800
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: imgB
            property: "scale"
            from: 1.04
            to: 1.0
            duration: 950
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: imgA
            property: "scale"
            from: 1.0
            to: 0.98
            duration: 800
            easing.type: Easing.InOutCubic
        }
    }

    // Transición cinematográfica fluida hacia Buffer A (Buffer A entra sobre Buffer B)
    ParallelAnimation {
        id: transToA
        onStarted: {
            root.showingA = true;
            imgA.z = 2;
            imgB.z = 1;
        }
        onFinished: {
            imgB.opacity = 0.0;
            imgB.scale = 1.0;
        }

        NumberAnimation {
            target: imgA
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 800
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: imgA
            property: "scale"
            from: 1.04
            to: 1.0
            duration: 950
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: imgB
            property: "scale"
            from: 1.0
            to: 0.98
            duration: 800
            easing.type: Easing.InOutCubic
        }
    }

    // Buffer de imagen A
    Image {
        id: imgA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize.width: root.screen ? Math.round(root.screen.width * (root.screen.devicePixelRatio || 1)) : 1920
        sourceSize.height: root.screen ? Math.round(root.screen.height * (root.screen.devicePixelRatio || 1)) : 1080
        opacity: 0.0
        scale: 1.0

        onStatusChanged: {
            if (status === Image.Ready && !root.showingA && root.activePath && source.toString() === ("file://" + root.activePath)) {
                transToA.restart();
            }
        }
    }

    // Buffer de imagen B
    Image {
        id: imgB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize.width: root.screen ? Math.round(root.screen.width * (root.screen.devicePixelRatio || 1)) : 1920
        sourceSize.height: root.screen ? Math.round(root.screen.height * (root.screen.devicePixelRatio || 1)) : 1080
        opacity: 0.0
        scale: 1.0

        onStatusChanged: {
            if (status === Image.Ready && root.showingA && root.activePath && source.toString() === ("file://" + root.activePath)) {
                transToB.restart();
            }
        }
    }
}
