pragma Singleton
import QtQuick
import Quickshell.Services.Mpris

Item {
    id: root

    // Resolver el reproductor activo (prioridad: estado Playing, luego el primero disponible con metadatos)
    readonly property var activePlayer: {
        if (!Mpris.players || !Mpris.players.values) return null;
        let players = Mpris.players.values;
        if (players.length === 0) return null;

        // 1. Buscar el que esté reproduciendo activamente
        for (let i = 0; i < players.length; i++) {
            let p = players[i];
            if (p && p.playbackState === MprisPlaybackState.Playing) {
                return p;
            }
        }

        // 2. Si ninguno está reproduciendo, devolver el primero disponible que tenga título o identidad
        for (let i = 0; i < players.length; i++) {
            let p = players[i];
            if (p && (p.trackTitle || p.identity)) {
                return p;
            }
        }

        return players[0] || null;
    }

    readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle !== "" || activePlayer.identity !== "")
    readonly property bool isPlaying: activePlayer !== null && activePlayer.playbackState === MprisPlaybackState.Playing

    readonly property string title: {
        if (!activePlayer) return "";
        return activePlayer.trackTitle || "Sin título";
    }

    readonly property string artist: {
        if (!activePlayer) return "";
        if (activePlayer.trackArtist) return activePlayer.trackArtist;
        if (activePlayer.trackArtists && activePlayer.trackArtists.length > 0) {
            return activePlayer.trackArtists.join(", ");
        }
        return "";
    }

    readonly property string album: activePlayer ? (activePlayer.trackAlbum || "") : ""

    readonly property string artUrl: {
        if (!activePlayer || !activePlayer.trackArtUrl) return "";
        let url = activePlayer.trackArtUrl;
        if (url.startsWith("/")) return "file://" + url;
        return url;
    }

    readonly property string identity: activePlayer ? (activePlayer.identity || "") : ""

    readonly property string appIcon: {
        let id = identity.toLowerCase();
        let t = title.toLowerCase();
        let a = artist.toLowerCase();
        if (id.includes("spotify")) return "󰓇";
        if (id.includes("youtube") || t.includes("youtube") || a.includes("youtube")) return "󰗃";
        if (id.includes("firefox")) return "󰈹";
        if (id.includes("chrome") || id.includes("chromium") || id.includes("brave")) return "󰊯";
        if (id.includes("vlc") || id.includes("mpv")) return "󰕼";
        return "󰝚"; // Icono musical genérico
    }

    readonly property bool canPlay: activePlayer ? activePlayer.canPlay : false
    readonly property bool canPause: activePlayer ? activePlayer.canPause : false
    readonly property bool canGoNext: activePlayer ? activePlayer.canGoNext : false
    readonly property bool canGoPrevious: activePlayer ? activePlayer.canGoPrevious : false
    readonly property bool canRaise: activePlayer ? activePlayer.canRaise : false

    function playPause() {
        if (!activePlayer) return;
        if (activePlayer.togglePlaying) {
            activePlayer.togglePlaying();
        } else if (activePlayer.playPause) {
            activePlayer.playPause();
        } else if (isPlaying && activePlayer.pause) {
            activePlayer.pause();
        } else if (activePlayer.play) {
            activePlayer.play();
        }
    }

    function next() {
        if (activePlayer && activePlayer.next) {
            activePlayer.next();
        }
    }

    function previous() {
        if (activePlayer && activePlayer.previous) {
            activePlayer.previous();
        }
    }

    function raise() {
        if (activePlayer && activePlayer.canRaise && activePlayer.raise) {
            activePlayer.raise();
        }
    }
}
