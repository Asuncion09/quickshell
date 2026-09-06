import QtQuick
import "../../theme"
import "../../components"
import "../../services"

Item {
    id: root

    readonly property bool isMediaHovered: mediaView.isHovered

    // Estados para control manual y temporizador de gracia
    property bool forceClock: false
    property bool manualMediaActive: false

    // Temporizador de gracia de 5 segundos al retirar el cursor de música en pausa
    Timer {
        id: graceTimer
        interval: 5000
        onTriggered: {
            root.manualMediaActive = false;
        }
    }

    // Cooldown anti-rebote para touchpad (absorbe la inercia de libinput de ~300ms)
    property bool _wheelLocked: false
    Timer {
        id: wheelCooldown
        interval: 350
        onTriggered: root._wheelLocked = false
    }

    // Evaluación reactiva de modo:
    // 1. Si no hay reproductor activo en memoria -> Reloj
    // 2. Si el usuario forzó el reloj (clic derecho / scroll en media) -> Reloj
    // 3. Si está reproduciendo activamente -> Multimedia
    // 4. Si el usuario lo despertó manualmente (clic rueda ratón / scroll en reloj) -> Multimedia
    // 5. Si está en pausa y el cursor está encima de la música (Regla 1: Anti-frustración) -> Multimedia
    // 6. Si está en pausa y corre el temporizador de gracia (Regla 2: 5s grace period) -> Multimedia
    readonly property bool isMediaActive: {
        if (!MediaService.hasMedia || MediaService.title === "") return false;
        if (root.forceClock) return false;
        if (MediaService.isPlaying) return true;
        if (root.manualMediaActive) return true;
        if (root.isMediaHovered) return true;
        if (graceTimer.running) return true;
        return false;
    }

    onIsMediaHoveredChanged: {
        if (root.isMediaHovered) {
            // Cancelar cuenta regresiva mientras el usuario interactúa con la música
            graceTimer.stop();
        } else {
            // Al retirar el ratón de la música en pausa, iniciar los 5 segundos de cortesía
            if (!MediaService.isPlaying && isMediaActive) {
                graceTimer.restart();
            }
        }
    }

    Connections {
        target: MediaService
        function onIsPlayingChanged() {
            if (MediaService.isPlaying) {
                root.forceClock = false;
                root.manualMediaActive = false;
                graceTimer.stop();
            } else {
                // Si se pausa externamente y el cursor no está encima, dar 5s antes de volver al reloj
                if (!root.isMediaHovered && isMediaActive) {
                    graceTimer.restart();
                }
            }
        }
        function onHasMediaChanged() {
            if (!MediaService.hasMedia) {
                root.forceClock = false;
                root.manualMediaActive = false;
                graceTimer.stop();
            }
        }
    }

    function wakeMedia() {
        if (MediaService.hasMedia && MediaService.title !== "") {
            root.forceClock = false;
            root.manualMediaActive = true;
            if (!root.isMediaHovered) {
                graceTimer.restart();
            }
        }
    }

    function dismissToClock() {
        root.forceClock = true;
        root.manualMediaActive = false;
        graceTimer.stop();
    }

    function handleWheel() {
        if (root._wheelLocked) return;
        root._wheelLocked = true;
        wheelCooldown.restart();

        if (root.isMediaActive) {
            root.dismissToClock();
        } else {
            root.wakeMedia();
        }
    }

    // WheelHandler a nivel superior que cubre toda la cápsula central
    WheelHandler {
        target: null
        orientation: Qt.Vertical | Qt.Horizontal
        onWheel: event => {
            root.handleWheel();
        }
    }

    implicitWidth: Math.round(isMediaActive ? mediaView.implicitWidth : clockView.implicitWidth)
    implicitHeight: 26
    width: implicitWidth
    height: implicitHeight
    clip: true

    // Animar SOLO cuando se cambia de modo entre Reloj y Multimedia (Play / Pause / Recall).
    // Durante el hover dentro de MediaView, el propio MediaView anima su expansión en sincronía exacta.
    property bool _modeChanging: false
    Timer {
        id: modeTimer
        interval: Theme.animNormal + 50
        onTriggered: root._modeChanging = false
    }

    onIsMediaActiveChanged: {
        root._modeChanging = true;
        modeTimer.restart();
    }

    Behavior on implicitWidth {
        enabled: root._modeChanging
        NumberAnimation {
            duration: Theme.animNormal
            easing.type: Easing.OutCubic
        }
    }

    // 1. Vista de Reloj (Reposo / En Pausa tras gracia)
    ClockView {
        id: clockView
        anchors.centerIn: parent
        width: implicitWidth
        height: implicitHeight
        opacity: root.isMediaActive ? 0.0 : 1.0
        visible: opacity > 0.01

        onWakeMediaRequested: root.wakeMedia()
        onWheelRequested: root.handleWheel()

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutQuad
            }
        }
    }

    // 2. Vista de Reproductor Multimedia (Dynamic Island)
    MediaView {
        id: mediaView
        anchors.centerIn: parent
        width: implicitWidth
        height: implicitHeight
        opacity: root.isMediaActive ? 1.0 : 0.0
        visible: opacity > 0.01

        onDismissToClockRequested: root.dismissToClock()
        onWheelRequested: root.handleWheel()

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
                easing.type: Easing.OutQuad
            }
        }
    }
}
