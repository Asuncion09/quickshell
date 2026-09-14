pragma Singleton
import QtQuick

QtObject {
    id: root

    // --- Sistema Dual de Temas: "default" (Obsidian & Accent Blue) | "matugen" (Material You Dinámico) ---
    property string themeMode: "default"
    property var dynamicPalette: null

    // Detección reactiva de modo dinámico válido
    readonly property bool isDynamic: themeMode === "matugen" && dynamicPalette !== null && dynamicPalette.colors !== undefined

    // --- Paleta Base por Defecto Fija (Waybar style.css original) ---
    readonly property color defaultHighlight: "#78a9ff"          // @highlight (azul acento)
    readonly property color defaultBgDark: "#161616"             // @dark-9
    readonly property color defaultBgDarkAlt: "#1e1e1e"          // Hover sutil sobre cápsulas
    readonly property color defaultBgDarkest: "#121212"          // Fondo más profundo (wallpapers, capas base)
    readonly property color defaultTextOnAccent: "#121212"       // Contraste oscuro sobre color de acento o sliders (on_primary)
    readonly property color defaultSurfaceBase: "#202020"        // Superficie uniforme inactiva (toggles, sliders, chips)
    readonly property color defaultSurfaceHover: "#282828"       // Hover uniforme para cualquier superficie inactiva
    readonly property color defaultSurfaceKeyFocus: "#2c2c2c"    // Superficie con foco de navegación por teclado
    readonly property color defaultBorderCard: "#2e2e2e"         // Borde sutil para tarjetas y menús flotantes
    readonly property color defaultDividerColor: "#262626"       // Divisores ultra-sutiles
    readonly property color defaultCritical: "#ee5396"           // Rosa/Rojo (urgent, error, batería crítica)
    readonly property color defaultWsOccupied: "#42be65"         // Verde esmeralda Waybar para workspaces con ventanas

    // --- Paleta Reactiva Dual (Conmuta instantáneamente entre Default y Matugen) ---
    readonly property color highlight: isDynamic ? dynamicPalette.colors.primary.dark.color : defaultHighlight
    readonly property color hoverBg: Qt.rgba(highlight.r, highlight.g, highlight.b, 0.12)
    readonly property color textOnAccent: isDynamic ? dynamicPalette.colors.on_primary.dark.color : defaultTextOnAccent
    readonly property color bgDark: isDynamic ? dynamicPalette.colors.surface_container_lowest.dark.color : defaultBgDark
    readonly property color bgDarkAlt: isDynamic ? dynamicPalette.colors.surface_container.dark.color : defaultBgDarkAlt
    readonly property color bgDarkest: isDynamic ? dynamicPalette.colors.surface_container_lowest.dark.color : defaultBgDarkest
    readonly property color surfaceBase: isDynamic ? dynamicPalette.colors.surface_container.dark.color : defaultSurfaceBase
    readonly property color surfaceHover: isDynamic ? dynamicPalette.colors.surface_container_high.dark.color : defaultSurfaceHover
    readonly property color surfaceKeyFocus: isDynamic ? dynamicPalette.colors.surface_container_highest.dark.color : defaultSurfaceKeyFocus
    readonly property color borderCard: isDynamic ? dynamicPalette.colors.outline_variant.dark.color : defaultBorderCard
    readonly property color dividerColor: isDynamic ? Qt.rgba(borderCard.r, borderCard.g, borderCard.b, 0.35) : defaultDividerColor
    readonly property color critical: isDynamic ? dynamicPalette.colors.error.dark.color : defaultCritical

    // --- Tokens Fijos Neutros y Semánticos ---
    readonly property color borderDark: Qt.rgba(1, 1, 1, 0.08)  // Borde sutil de relieve (rim light)
    readonly property color borderModal: Qt.rgba(1, 1, 1, 0.12) // Borde suave traslúcido para ventanas flotantes (idéntico al Launcher)
    readonly property color dark6: "#80525252"            // @dark-6 (50% opacity)
    readonly property color dark5: "#1f525252"            // @dark-5 (12% opacity)
    
    readonly property color text: "#dde1e7"               // Texto principal
    readonly property color textSecondary: "#a0a8b7"      // Texto secundario (artista, subtítulo, 65% contraste)
    readonly property color textMuted: "#59dde1e7"        // 35% opacidad
    readonly property color textDisabled: "#66dde1e7"     // 40% opacidad
    readonly property color textBright: "#ffffff"         // Texto blanco nítido / máximo contraste
    readonly property color selectionBg: "#454545"        // Selección de texto en campos de entrada

    readonly property color defaultSuccess: "#42be65"
    readonly property color defaultWarning: "#f1c40f"
    readonly property color success: isDynamic ? highlight : defaultSuccess
    readonly property color successFeedback: "#81c784"    // Verde suave para confirmación de copiado
    readonly property color warning: defaultWarning       // Amarillo (batería warning)

    // --- Perfiles de Energía y Batería (Dual Default / Matugen) ---
    readonly property color defaultPowerEco: "#42be65"
    readonly property color defaultPowerBalanced: defaultHighlight
    readonly property color defaultPowerTurbo: "#f1c40f"
    readonly property color defaultBatteryCharging: "#42be65"

    readonly property color powerEcoColor: (isDynamic && dynamicPalette.colors.tertiary)
                                           ? dynamicPalette.colors.tertiary.dark.color
                                           : defaultPowerEco
    readonly property color powerBalancedColor: isDynamic ? highlight : defaultPowerBalanced
    readonly property color powerTurboColor: (isDynamic && dynamicPalette.colors.error)
                                             ? dynamicPalette.colors.error.dark.color
                                             : defaultPowerTurbo
    readonly property color batteryChargingColor: (isDynamic && dynamicPalette.colors.tertiary)
                                                  ? dynamicPalette.colors.tertiary.dark.color
                                                  : defaultBatteryCharging

    // Contraste tipográfico sobre cada píldora activa de perfil
    readonly property color textOnPowerEco: (isDynamic && dynamicPalette.colors.on_tertiary)
                                            ? dynamicPalette.colors.on_tertiary.dark.color
                                            : defaultTextOnAccent
    readonly property color textOnPowerBalanced: textOnAccent
    readonly property color textOnPowerTurbo: (isDynamic && dynamicPalette.colors.on_error)
                                             ? dynamicPalette.colors.on_error.dark.color
                                             : defaultTextOnAccent

    // Superficies activas derivadas dinámicamente del azul del workspace o acento
    readonly property color surfaceActive: Qt.rgba(wsActiveColor.r, wsActiveColor.g, wsActiveColor.b, 0.20)
    readonly property color surfaceActiveHover: Qt.rgba(wsActiveColor.r, wsActiveColor.g, wsActiveColor.b, 0.28)
    readonly property color shadowColor: "#000000"

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
    readonly property int wsActiveWidth: 16
    readonly property int wsHeight: 8
    readonly property int wsRadius: 4

    readonly property color wsActiveColor: highlight           // #78a9ff en default | primary en Matugen
    readonly property color wsOccupiedColor: (isDynamic && dynamicPalette.colors.tertiary)
                                            ? dynamicPalette.colors.tertiary.dark.color
                                            : defaultWsOccupied // #42be65 en default | tertiary armónico en Matugen
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
