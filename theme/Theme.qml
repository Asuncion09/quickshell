pragma Singleton
import QtQuick

QtObject {
    // --- Paleta de colores (extraída de Waybar style.css) ---
    readonly property color bgDark: "#161616"             // @dark-9
    readonly property color bgDarkAlt: "#1e1e1e"          // Hover sutil sobre cápsulas (sutilmente más claro que #161616)
    readonly property color borderDark: Qt.rgba(1, 1, 1, 0.08)  // Borde sutil de relieve (rim light)
    readonly property color dark6: "#80525252"            // @dark-6 (50% opacity)
    readonly property color dark5: "#1f525252"            // @dark-5 (12% opacity)
    readonly property color highlight: "#78a9ff"          // @highlight (azul acento)
    readonly property color hoverBg: "#1f78a9ff"          // rgba(120, 169, 255, 0.12)
    
    readonly property color text: "#dde1e7"               // Texto principal
    readonly property color textSecondary: "#a0a8b7"      // Texto secundario (artista, subtítulo, 65% contraste)
    readonly property color textMuted: "#59dde1e7"        // 35% opacidad
    readonly property color textDisabled: "#66dde1e7"     // 40% opacidad
    
    readonly property color success: "#42be65"            // Verde (charging / persistent)
    readonly property color warning: "#f1c40f"            // Amarillo (batería warning)
    readonly property color critical: "#ee5396"           // Rosa/Rojo (urgent, error, batería crítica)

    // --- Superficies y Capas del Centro de Control (Sistema Tonal Limpio) ---
    readonly property color surfaceBase: "#202020"                                                 // Superficie uniforme inactiva (toggles, sliders, chips)
    readonly property color surfaceHover: "#282828"                                                // Hover uniforme para cualquier superficie inactiva
    readonly property color surfaceActive: Qt.rgba(wsActiveColor.r, wsActiveColor.g, wsActiveColor.b, 0.20)      // Superficie activa derivada del azul del workspace activo
    readonly property color surfaceActiveHover: Qt.rgba(wsActiveColor.r, wsActiveColor.g, wsActiveColor.b, 0.28) // Hover uniforme para elementos activos
    readonly property color dividerColor: "#262626"                                                // Divisores ultra-sutiles

    // --- Métricas y Dimensiones de la Barra ---
    readonly property int barHeight: 32
    readonly property int barMarginTop: 6
    readonly property int barMarginBottom: 0
    readonly property int barMarginLeft: 8
    readonly property int barMarginRight: 8

    // --- Dimensiones de Cápsulas (Pills) ---
    readonly property int pillRadius: 10
    readonly property int pillBorderWidth: 1
    readonly property int pillPaddingVertical: 2
    readonly property int pillPaddingHorizontal: 8
    readonly property int centerPillPaddingHorizontal: 14

    // --- Workspaces Tokens (Estilo GNOME: puntos inactivos compactos y cápsula activa alargada) ---
    readonly property int wsInactiveWidth: 8
    readonly property int wsActiveWidth: 22
    readonly property int wsHeight: 8
    readonly property int wsRadius: 4

    readonly property color wsActiveColor: highlight           // #78a9ff (Azul activo)
    readonly property color wsOccupiedColor: success           // #42be65 (Verde esmeralda vistoso de tu Waybar)
    // Opciones alternativas vistosas:
    // "#42be65" (Verde esmeralda Waybar)
    // "#33b1ff" (Cyan eléctrico)
    // "#be95ff" (Lavanda / Púrpura)
    // "#f1c40f" (Ámbar dorado)
    readonly property color wsEmptyColor: dark6                // #80525252 (Vacío)
    readonly property color wsUrgentColor: critical            // #ee5396 (Urgente)

    // --- Tokens de Sombra para Píldoras ---
    readonly property bool pillShadowEnabled: true
    readonly property color pillShadowColor: "#000000"
    readonly property real pillShadowOpacity: 0.58
    readonly property real pillShadowBlur: 0.52
    readonly property real pillShadowOffsetY: 3.5

    // --- Tipografía ---
    readonly property string fontFamily: "JetBrainsMono Nerd Font Propo"
    readonly property int fontSize: 13
    readonly property int launcherFontSize: 15
    readonly property int iconSize: 16

    // --- Tiempos de Animación ---
    readonly property int animFast: 120
    readonly property int animNormal: 180
    readonly property int animWorkspaces: 250
}
