---
name: quickshell-design
description: >-
  Use this skill whenever designing, creating, modifying, or refactoring UI components,
  views, dialogs, or panels in this Quickshell (Qt6/QML) desktop shell for Hyprland.
  Enforces design system tokens, zero-hardcoded colors, dual-theme compatibility (Material You and Obsidian),
  standard metrics, keyboard navigation ergonomics, and Wayland LayerShell guidelines.
---

# Guía de Diseño y Estándares UI para Quickshell en Hyprland

Esta skill documenta las reglas estrictas de diseño, arquitectura visual, ergonomía y sistemas de tokens que rigen la interfaz de usuario de este proyecto. **Cualquier agente que agregue, modifique o refactorice código QML debe adherirse rigurosamente a estas directrices.**

---

## 1. Reglas de Oro (Mandatorias)

1. **CERO Colores Hexadecimales Hardcodeados**:
   - **NUNCA** escribir valores hexadecimales directos en componentes visuales (como `"#ffffff"`, `"#161616"`, `"#78a9ff"`).
   - **SIEMPRE** consumir los tokens semánticos definidos en [`theme/Theme.qml`](file:///home/daniel/.config/quickshell/theme/Theme.qml) (`Theme.highlight`, `Theme.text`, `Theme.surfaceBase`, etc.).
2. **Compatibilidad con Sistema Dual de Temas**:
   - Toda la interfaz debe reaccionar de forma fluida tanto al tema por defecto (**Obsidian & Accent Blue**) como al tema dinámico **Material You** (generado con Matugen a partir del fondo de pantalla).
   - Asegurar contraste con `Theme.textOnAccent` sobre fondos de acento (`Theme.highlight`).
3. **Navegación Total por Teclado**:
   - Todo panel, modal, submenú o lista desplegable **DEBE** implementar la función `handleKey(event)`.
   - El anillo o borde de foco del teclado solo debe ser visible cuando el usuario interactúa mediante teclas (`isKeyNavActive = true`), no cuando interactúa exclusivamente con el ratón.
4. **Tipografía e Iconografía Estandarizadas**:
   - Toda fuente debe invocar `Theme.fontFamily` (`JetBrainsMono Nerd Font Propo`).
   - Los iconos vectoriales deben proceder exclusivamente de **Nerd Fonts** (ej. `"󰅁"`, `"󰍺"`, `"󰄬"`).
5. **Máscaras de Entrada de Hardware en Wayland**:
   - No crear ventanas transparentes que bloqueen los clics al escritorio. Usar siempre `mask: Region { ... }` para que las zonas transparentes sean 100% permeables a las ventanas de Hyprland.

---

## 2. Catálogo de Tokens Semánticos (`theme/Theme.qml`)

| Token Semántico | Uso / Propósito | Comportamiento Dual |
| :--- | :--- | :--- |
| `Theme.highlight` | Color principal de acento, sliders activos, bordes de foco | `#78a9ff` (Default) \| `primary.dark` (Matugen) |
| `Theme.hoverBg` | Fondo de hover con baja opacidad | Derivado dinámico con 12% alfa de `highlight` |
| `Theme.textOnAccent` | Color de texto/iconos sobre superficies de acento | `#121212` (Default) \| `on_primary.dark` (Matugen) |
| `Theme.bgDark` | Fondo primario de ventanas y lienzos de base | `#161616` (Default) \| `surface_container_lowest` |
| `Theme.surfaceBase` | Fondo base de tarjetas, toggles, chips y filas | `#202020` (Default) \| `surface_container` |
| `Theme.surfaceHover` | Fondo al pasar el cursor (MouseArea `containsMouse`) | `#282828` (Default) \| `surface_container_high` |
| `Theme.surfaceKeyFocus` | Fondo del elemento enfocado por navegación por teclado | `#2c2c2c` (Default) \| `surface_container_highest` |
| `Theme.borderDark` | Borde sutil de relieve (rim-light) en tarjetas (`1px`) | `rgba(255, 255, 255, 0.08)` |
| `Theme.borderModal` | Borde de ventanas modales flotantes (`1px`) | `rgba(255, 255, 255, 0.12)` |
| `Theme.dividerColor` | Líneas divisorias sutiles (`1px` de altura) | `#262626` (Default) \| 35% alfa de `borderCard` |
| `Theme.critical` | Errores, avisos urgentes, batería crítica | `#ee5396` (Default) \| `error.dark` (Matugen) |
| `Theme.success` | Confirmaciones y estados exitosos | `#42be65` (Default) \| `highlight` (Matugen) |
| `Theme.text` | Texto principal estándar | `#dde1e7` |
| `Theme.textBright` | Texto en blanco puro de máximo contraste | `#ffffff` |
| `Theme.textSecondary` | Subtítulos, artista multimedia, valores secundarios | `#a0a8b7` (65% contraste) |
| `Theme.textMuted` | Etiquetas de sección en mayúsculas, ayudas, hints | `#59dde1e7` (35% contraste) |
| `Theme.fontFamily` | Familia tipográfica monoespaciada | `"JetBrainsMono Nerd Font Propo"` |
| `Theme.animFast` | Animaciones de hover, escala, feedback | `120ms` |
| `Theme.animNormal` | Transición estándar de paneles y expansiones | `180ms` |
| `Theme.animWorkspaces`| Desplazamiento y metamorfosis de workspaces | `250ms` |

---

## 3. Guía de Construcción de Componentes

### A. Fila de Control Interactiva (Tarjetas Agrupadas)
Las opciones deben organizarse dentro de una tarjeta base (`radius: 12`, `color: Theme.surfaceBase`, `border.color: Theme.borderDark`), con filas internas de `implicitHeight: 46` y hover concéntrico (`radius: 8`):

```qml
Item {
    Layout.fillWidth: true
    implicitHeight: 46

    // Fondo reactivo a hover y foco de teclado
    Rectangle {
        anchors.fill: parent
        radius: 8
        readonly property bool isKeyFocused: root.isKeyNavActive && root.navIndex === index
        color: isKeyFocused ? Theme.surfaceKeyFocus : Theme.surfaceHover
        opacity: isKeyFocused ? 1.0 : (rowMouse.containsMouse ? 1.0 : 0.0)
        border.width: isKeyFocused ? 1.5 : 0
        border.color: Theme.highlight

        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10

        // Icono de acento
        Text {
            text: "󰍺"
            font.family: Theme.fontFamily
            font.pixelSize: 16
            color: Theme.highlight
        }

        // Título y subtítulo
        ColumnLayout {
            spacing: 1
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Título de la Opción"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.text
            }

            Text {
                text: "Descripción breve"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.textMuted
            }
        }

        Item { Layout.fillWidth: true }

        // Valor actual
        Text {
            text: "Valor"
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.textSecondary
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { /* Acción */ }
    }
}
```

### B. Etiquetas de Encabezado de Sección
Deben situarse fuera de las tarjetas, en mayúsculas y alineadas:
```qml
Text {
    text: "SECTION NAME"
    font.family: Theme.fontFamily
    font.pixelSize: 10
    font.weight: Font.DemiBold
    color: Theme.textMuted
    Layout.leftMargin: 4
}
```

### C. Botón de Acción / Aplicar (Estado Reactivo)
Los botones de aplicar o guardar deben ser reactivos:
- Cuando **hay cambios pendientes**: color de acento `Theme.highlight`, texto en `Theme.textOnAccent` y `cursorShape: Qt.PointingHandCursor`.
- Cuando **está al día**: color sobrio `Theme.surfaceBase`, opacidad reducida (`0.65`) y cursor estándar.

---

## 4. Patrón Estándar de Navegación por Teclado

Todo componente contenedor (vista o diálogo) debe gestionar eventos de teclado con la siguiente estructura:

```javascript
property int navIndex: 0
property bool isKeyNavActive: false

function handleKey(event) {
    let totalItems = 5; // Cantidad total de elementos navegables

    // Activar indicador visual solo si se presiona una tecla de navegación
    if (!root.isKeyNavActive) {
        if (event.key === Qt.Key_Down || event.key === Qt.Key_Up ||
            event.key === Qt.Key_Right || event.key === Qt.Key_Left ||
            event.key === Qt.Key_Tab) {
            root.isKeyNavActive = true;
            root.navIndex = 0;
            return true;
        }
    }

    // Navegación vertical y cíclica
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

    // Retorno o escape
    if (event.key === Qt.Key_Escape) {
        root.backRequested();
        return true;
    }

    // Activación
    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
        root.triggerCurrentIndex(root.navIndex);
        return true;
    }

    return false;
}
```

---

## 5. Reglas de Wayland LayerShell y Ventanas

1. **Estabilidad de Lienzo (Evitar Parpadeo)**:
   - Mantener las ventanas de barra y overlays fijas en tamaño de pantalla (`implicitHeight: root.screen ? root.screen.height : 1080`).
   - La exclusión de ventanas (`WlrLayershell.exclusiveZone`) debe corresponder únicamente a la altura visual de la barra flotante (`Theme.barHeight`).
2. **Máscaras de Entrada por Hardware**:
   ```qml
   mask: Region {
       // Si hay un diálogo modal abierto, captura toda la pantalla para cerrar al hacer clic afuera
       Region {
           x: 0; y: 0
           width: root.isModalOpen ? root.screen.width : 0
           height: root.isModalOpen ? root.screen.height : 0
       }
       // Superficies interactivas constantes
       Region { item: leftPill }
       Region { item: centerPill }
       Region { item: rightPill }
   }
   ```
3. **Foco de Teclado Condicional**:
   - `WlrLayershell.keyboardFocus: root.isModalOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None`.

---

## 6. Modularización de Vistas Complejas
Cuando una vista crezca por encima de las 350-400 líneas, **debe ser descompuesta** en subcomponentes especializados colocados en un subdirectorio correspondiente (ejemplo: `modules/controlcenter/display/` o `modules/controlcenter/wifi/`), con un archivo `qmldir` local para el registro formal de componentes.
