# 🚀 Quickshell Desktop Shell para Hyprland

Entorno de escritorio y shell de usuario moderno, reactivo y de alto rendimiento diseñado para **Hyprland** (Wayland) utilizando **Quickshell** (Qt6 / QML). 

Incorpora una barra superior flotante estilo *Dynamic Island*, lanzador de aplicaciones integrado tipo Spotlight, centro de control rápido con submenús avanzados, sistema de temas dual con soporte de **Matugen (Material You)**, gestión nativa de fondos de pantalla con disolución cinematográfica, centro de notificaciones, gestor de portapapeles, agente de autenticación Polkit y conmutador de ventanas (*Alt-Tab*) con previsualizaciones en vivo.

---

## ✨ Características Destacadas

- 🎨 **Sistema Dual de Temas (Default vs Material You)**: Alterna al instante entre la elegante paleta original *Obsidian & Accent Blue* (`#78a9ff`) y el modo dinámico generado automáticamente por **Matugen** a partir de tu fondo de pantalla activo.
- 🔤 **Selector Dinámico de Fuentes**: Detección y aplicación en caliente de tipografías monoespaciadas y Nerd Fonts del sistema (`JetBrains Mono`, `Caskaydia Cove`, `Hack`, etc.) con propagación reactiva instantánea vía `Theme.fontFamily` sin reiniciar el entorno.
- 🔊 **Gestor de Temas de Sonido del Sistema**: Conmutador maestro de efectos sonoros y selector dinámico de paquetes de sonido (`freedesktop`, `ocean`, `breeze`, `oxygen`, `ubuntu`) con preescucha integrada directa.
- 🏝️ **Isla Dinámica Central (Dynamic Island)**: Metamorfosis fluida entre reloj tipográfico, controles multimedia (MPRIS), notificaciones OSD integradas (volumen/brillo/micrófono), lanzador Spotlight, centro de notificaciones y gestor de portapapeles con espaciado vertical unificado de 32px.
- 📋 **Portapapeles con Soporte de Imágenes y Fijado (Pin)**: Detección binaria de imágenes con miniaturas reales en la interfaz, inyección nativa en Wayland (`wl-copy --type`), sistema de clips fijados (`Ctrl+P`) y política de expiración programada de 24 horas.
- 🖼️ **Gestión de Fondos de Pantalla con Doble Buffer**: Transiciones suaves sin saltos de luz ni parpadeos (*zero white flash*), con galería visual en el Centro de Control y soporte multimonitor.
- 🖥️ **Configuración Multimonitor (Displays)**: Ajuste interactivo de resolución, frecuencia de refresco (Hz), escalado y rotación de pantallas directamente desde el Centro de Control.
- 🎛️ **Centro de Control Integral**: Toggles de Wi-Fi y Bluetooth con emparejamiento por PIN, sliders contextuales por pantalla, selector de perfiles de energía (Eco, Balance, Turbo), y submenús dedicados (Theme Style con 3 pestañas, Displays, Audio y Wallpapers).
- ⌨️ **Navegación Total por Teclado**: Cada panel, submenú y diálogo cuenta con navegación por flechas (`←` / `→` / `↑` / `↓`), `Tab`, `Espacio`, `Enter` y `Esc`.
- ⚡ **Rendimiento Óptimo**: 0.0% de consumo de CPU adicional en reposo, bindings de QML puros y llamadas asíncronas no bloqueantes.

---

## 📸 Demostración Visual

### Barra Superior Completa (Top Bar)
Diseño flotante segmentado en cápsulas (*pills*) con efecto *rim-light*, bordes suaves traslúcidos y sombras volumétricas por hardware.
![Barra Superior](assets/screenshots/bar.png)

---

### Módulos Principales

| Módulo | Captura | Descripción |
| :--- | :---: | :--- |
| **Workspaces & Taskbar** | ![Workspaces y Taskbar](assets/screenshots/workspaces_taskbar.png) | Indicadores estilo GNOME (puntos inactivos y píldora activa alargada) totalmente sincronizados con Hyprland. Soportan colores dinámicos de Matugen (acento activo y color terciario armónico para espacios ocupados). |
| **Isla Dinámica (Reloj)** | ![Isla Dinámica Reloj](assets/screenshots/island_clock.png) | Cápsula central en estado de reposo con fecha y hora en jerarquía tipográfica limpia (`Tue, 08 Sep · 08:44 AM`). |
| **Isla Dinámica (Música)** | ![Isla Dinámica Música](assets/screenshots/island_media.png) | Metamorfosis automática al reproducir audio mediante integración MPRIS: icono de la app, título y artista. |
| **Isla Dinámica (Hover/Controles)** | ![Isla Dinámica Controles](assets/screenshots/island_media_controls.png) | Al pasar el cursor sobre la música, la cápsula se expande fluidamente revelando botones interactivos de pista anterior, play/pausa y siguiente. |
| **Bandeja & Hardware** | ![Bandeja del Sistema](assets/screenshots/tray_hardware.png) | Iconos de estado de conexión Wi-Fi, nivel de audio, batería y bandeja del sistema (*System Tray* / SNI). Al hacer clic abre el Centro de Control. |

---

### Paneles y Diálogos

#### 🔍 Lanzador de Aplicaciones (Spotlight)
Apertura fluida desde la isla central con búsqueda instantánea, calculadora matemática integrada, ejecución directa de comandos de terminal, búsqueda web rápida y navegación por teclado.
<p align="center">
  <img src="assets/screenshots/launcher.png" alt="Lanzador de aplicaciones" width="420"/>
</p>

#### 🎛️ Centro de Control y Submenús Avanzados
Panel de control desplegable con accesos directos (Wi-Fi, Bluetooth, Micrófono, Desvelo/Caffeine, Selector de Color y Captura de Pantalla), sliders interactivos de brillo y volumen, selector de perfiles energéticos y submenús dedicados:
- **🎨 Theme Style**: Subvista modular estructurada en 3 pestañas:
  - **`[ Colors ]`**: Conmutador entre el motor dinámico **Material You** (paleta extraída del fondo de pantalla mediante Matugen) y el tema oscuro **Obsidian Blue** por defecto.
  - **`[ Sounds ]`**: Conmutador maestro de efectos sonoros para notificaciones/alertas y selector de paquetes de sonido instalados (`Ocean`, `Breeze`, `Oxygen`, `Freedesktop`, `Ubuntu`) con pre-escucha unificada al seleccionar.
  - **`[ Fonts ]`**: Selector tipográfico dinámico que detecta automáticamente fuentes instaladas y aplica cambios al vuelo a todo el entorno (`Theme.fontFamily`) sin necesidad de reiniciar.
- **🖥️ Displays**: Subvista modular para gestión multimonitor con selección interactiva de pantallas, cambio de resolución y frecuencia (Hz), ajuste de escala de interfaz y orientación/rotación, equipada con navegación por teclado y botón de retorno unificado.
- **🖼️ Wallpapers**: Galería visual de fondos de pantalla locales con previsualización en miniatura y transición *cross-dissolve*.
- **🔊 Sound**: Selección de dispositivos de salida y entrada (sinks/sources) y gestión de volumen por hardware.

<p align="center">
  <img src="assets/screenshots/controlcenter.png" alt="Centro de Control" width="340"/>
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/screenshots/controlcenter_settings.png" alt="Ajustes y Selector de Tema" width="340"/>
</p>

#### 🔔 Centro de Notificaciones
Historial persistente con cabecera simétrica igualada al buscador de la isla central (32px de altura y 10px de margen superior), modo *No Molestar* (DND), botón para limpiar historial, soporte de cerrado con `Esc` y soporte para tarjetas interactivas:
- **Capturas de pantalla integradas**: Miniatura visual con acciones para abrir el visor, copiar imagen binaria a Wayland o eliminar el archivo.
- **Selector de color (Eyedropper)**: Muestra el color seleccionado con botones de un clic para copiar el valor HEX (`#RRGGBB`) o RGB.

<p align="center">
  <img src="assets/screenshots/notifications.png" alt="Centro de notificaciones" width="420"/>
</p>

#### 📋 Gestor de Portapapeles (Clipboard)
Historial modal accesible desde la isla o con `Super + V` con búsqueda instantánea y filtrado rápido:
- **Soporte Binario de Imágenes**: Detección nativa de capturas y archivos de imagen (`image/png`), previsualización en miniatura con badge de peso e inyección sin pérdidas al portapapeles de Wayland para pegar en cualquier programa.
- **Fijado Permanente (Pin `Ctrl + P`)**: Los elementos fijados se distinguen con borde de acento, icono de chincheta permanente y quedan inmunes ante el botón de vaciado ("Clear All") y ante la política de expiración programada de 24 horas.

#### 🔀 Conmutador de Ventanas (Alt + Tab)
Selector modal centrado con historial de ventanas MRU (*Most Recently Used*), detección de liberación de `Alt` vía IPC y salto inmediato al espacio de trabajo de la ventana seleccionada.
<p align="center">
  <img src="assets/screenshots/switcher.png" alt="Window Switcher" width="340"/>
</p>

---

### 🎛️ Notificaciones en Pantalla (OSD) y Alertas

La barra superior integra directamente en la **Isla Dinámica** los avisos OSD de volumen, brillo y estado del micrófono, optimizando el espacio visual sin ventanas invasivas.

| OSD / Alerta | Captura | Descripción |
| :--- | :---: | :--- |
| **OSD Volumen** | ![OSD Volumen](assets/screenshots/osd_volume.png) | Metamorfosis instantánea de la isla central al pulsar teclas de volumen, mostrando icono, barra de progreso y porcentaje. |
| **OSD Brillo** | ![OSD Brillo](assets/screenshots/osd_brightness.png) | Indicador visual de brillo de pantalla con barra animada reactiva a teclas de brillo. |
| **OSD Micrófono** | ![OSD Micrófono](assets/screenshots/osd_mic.png) | Aviso en color crítico al silenciar o activar el micrófono mediante atajos de hardware. |
| **Alerta Batería Crítica** | ![Alerta Batería Crítica](assets/screenshots/osd_battery_critical.png) | Tarjeta flotante en esquina superior derecha con borde pulsante rosa, aviso sonoro y advertencia inmediata. |

---

## 🎨 Sistema de Tematización Dual (Matugen & Default)

El proyecto cuenta con un sistema centralizado de diseño en [`theme/Theme.qml`](theme/Theme.qml) que elimina cualquier color hexadecimal fijo y soporta dos modalidades instantáneas:

1. **Modo Default (`"default"`):**
   - Preserva la paleta oscura original basada en Waybar: acento azul `#78a9ff`, fondos oscuros `#161616` / `#121212` y verde esmeralda `#42be65` para workspaces activos con programas.
2. **Modo Dinámico (`"matugen"`):**
   - Extrae automáticamente la paleta Material You del fondo de pantalla actual usando el CLI nativo `matugen`.
   - El acento principal (`highlight`), tarjetas, fondos, bordes y el color terciario de los workspaces ocupados se armonizan en tiempo real.
   - El estado se persiste en `~/.config/quickshell/state/theme_mode.txt` y se almacena en caché en `~/.config/quickshell/state/dynamic_theme.json`.

---

## 📦 Requisitos e Instalación en Fedora

### 1. Habilitar Copr para Quickshell, Matugen y Herramientas Hyprland
En Fedora, el repositorio de la comunidad **lionheartp/Hyprland** provee `quickshell`, `matugen`, `hyprpicker`, `hyprshot` y las herramientas esenciales del ecosistema:
```bash
sudo dnf copr enable lionheartp/Hyprland -y
```

### 2. Paquetes y Dependencias del Sistema
Instala todos los paquetes requeridos con un solo comando:
```bash
sudo dnf install -y \
    quickshell \
    matugen \
    hyprpicker \
    hyprshot \
    power-profiles-daemon \
    sound-theme-freedesktop \
    ocean-sound-theme \
    oxygen-sounds \
    pop-sound-theme \
    yaru-sound-theme \
    libcanberra-gtk3 \
    pipewire \
    wireplumber \
    brightnessctl \
    playerctl \
    NetworkManager \
    bluez \
    python3-dbus \
    python3-gobject-base \
    hyprland \
    hyprlock \
    hypridle \
    grim \
    slurp \
    jq \
    wl-clipboard
```

#### 📋 Resumen de utilidades clave:
- **`quickshell`**: Motor reactivo Qt6/QML para la capa de interfaz de usuario en Wayland.
- **`matugen`**: Extractor dinámico de paletas Material You a partir de fondos de pantalla.
- **`jq`**: Procesamiento de alto rendimiento del árbol JSON del tema dinámico.
- **`wl-clipboard`**: Demonio y buffer de portapapeles (`wl-paste`, `wl-copy`) con soporte de imágenes.
- **`sound-theme-freedesktop` / `ocean-sound-theme` / `oxygen-sounds` / `pop-sound-theme` / `yaru-sound-theme`**: Paquetes de temas sonoros del sistema instalados y conmutables desde Ajustes.
- **`libcanberra-gtk3`**: Provee `canberra-gtk-play` para la reproducción instantánea de efectos sonoros y notificaciones.
- **`python3-dbus` & `python3-gobject-base`**: Runtimes de Python para demonios de fondo e introspección GObject.
- **`hyprpicker` & `hyprshot`**: Selector de color gotero y capturas de región desde el Centro de Control.
- **`power-profiles-daemon`**: Control y conmutación de perfiles energéticos (Eco, Balance, Turbo).
- **`pipewire` & `wireplumber` (`wpctl`)**: Gestión reactiva de sonido, micrófonos y cambio de sinks.
- **`brightnessctl`**: Regulación de brillo multimonitor.
- **`NetworkManager` (`nmcli`) & `bluez` (`bluetoothctl`)**: Gestión de redes y dispositivos Bluetooth.

### 3. Tipografía e Iconos
Instala **JetBrainsMono Nerd Font Propo** (o tus Nerd Fonts preferidas como `CaskaydiaCove` o `Hack`) para garantizar la correcta visualización de todos los iconos y disfrutar del selector tipográfico en caliente:
```bash
mkdir -p ~/.local/share/fonts
cd /tmp
curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
tar -xf JetBrainsMono.tar.xz -C ~/.local/share/fonts/
fc-cache -fv
```
> [!TIP]
> Cualquier fuente monoespaciada o Nerd Font instalada en el sistema será detectada automáticamente y estará disponible de inmediato en la subvista **Settings > Theme Style > Fonts**.

---

## ⌨️ Integración con Hyprland (`hyprland.conf`)

Agrega lo siguiente a tu archivo `~/.config/hypr/hyprland.conf`:

### Autoinicio
```ini
# Iniciar Quickshell al arrancar Hyprland
exec-once = quickshell
```

### Atajos de Teclado Recomendados
```ini
# Lanzador Spotlight (Super + Espacio)
bind = SUPER, SPACE, exec, quickshell ipc call launcher toggle

# Centro de Control (Super + C)
bind = SUPER, C, exec, quickshell ipc call controlcenter toggle

# Centro de Notificaciones (Super + N)
bind = SUPER, N, exec, quickshell ipc call notifications toggle

# Portapapeles (Super + V)
bind = SUPER, V, exec, quickshell ipc call clipboard toggle

# Conmutador de Ventanas Alt + Tab
bind = ALT, TAB, exec, quickshell ipc call switcher next
bind = ALT SHIFT, TAB, exec, quickshell ipc call switcher prev

# Alternar Tema entre Por Defecto y Matugen Dinámico
bind = SUPER SHIFT, T, exec, quickshell ipc call theme toggle

# Subvistas Directas del Centro de Control
bind = SUPER SHIFT, S, exec, quickshell ipc call controlcenter openSettings
bind = SUPER SHIFT, D, exec, quickshell ipc call controlcenter openDisplays

# Cambiar de Fondo de Pantalla (Siguiente / Anterior)
bind = SUPER SHIFT, W, exec, quickshell ipc call wallpaper next
bind = SUPER CTRL, W, exec, quickshell ipc call wallpaper prev

# Teclas Multimedia y Hardware
bind = , XF86AudioRaiseVolume, exec, quickshell ipc call audio raise
bind = , XF86AudioLowerVolume, exec, quickshell ipc call audio lower
bind = , XF86AudioMute, exec, quickshell ipc call audio mute
bind = , XF86AudioMicMute, exec, quickshell ipc call audio micMute
bind = , XF86MonBrightnessUp, exec, quickshell ipc call brightness raise
bind = , XF86MonBrightnessDown, exec, quickshell ipc call brightness lower
```

---

## 📡 Control por Terminal / IPC

Quickshell expone una API completa por IPC accesible mediante `quickshell ipc call <target> <método>`:

| Objetivo (`target`) | Métodos disponibles | Descripción |
| :--- | :--- | :--- |
| `theme` | `setMode("default" \| "matugen")`, `toggle()` | Cambia o alterna el modo de tema entre fijo y dinámico. |
| `sound` | `setTheme(theme)`, `play(sound)` | Asigna el tema de sonido activo del sistema o reproduce una muestra. |
| `font` | `setFont(font)` | Cambia en caliente la tipografía del sistema (`Theme.fontFamily`) sin reiniciar. |
| `wallpaper` | `next()`, `prev()`, `set(path)`, `scan()` | Navega o asigna un fondo de pantalla con animación suave. |
| `controlcenter` | `toggle()`, `open()`, `close()`, `openSettings()`, `openAudio()`, `openWallpaper()`, `openDisplays()`, `openTheme()`, `openSounds()`, `openFonts()` | Controla la apertura del Centro de Control o submenús específicos. |
| `launcher` | `toggle()`, `open()`, `close()`, `next()`, `prev()`, `launch()` | Controla el lanzador Spotlight. |
| `clipboard` | `toggle()`, `open()`, `close()`, `select(idx)`, `togglePin(id)`, `clear()` | Gestiona el historial de portapapeles, fijado de clips (Pin) y selección. |
| `notifications` | `toggle()`, `open()`, `close()`, `clear()`, `dnd()`, `expand()` | Controla el centro de notificaciones, modo no molestar y expansión de toasts. |
| `audio` | `raise()`, `lower()`, `mute()`, `micMute()` | Regula volumen y mute de audio/micrófono. |
| `brightness` | `raise()`, `lower()` | Regula el nivel de brillo de pantalla. |
| `power` | `set(profile)`, `cycle()`, `save()`, `balanced()`, `performance()` | Conmuta perfiles energéticos del sistema. |
| `switcher` | `next()`, `prev()`, `open()`, `close()`, `select()`, `cancel()` | Controla el selector modal de ventanas Alt+Tab. |
| `session` | `toggle()`, `open()`, `close()`, `lock()`, `suspend()`, `logout()`, `reboot()`, `shutdown()` | Acciones de energía y sesión. |
| `polkit` | `submit(password)`, `cancel()` | Responde a solicitudes del agente de autenticación integrado. |
| `lock` | `lock()`, `unlock()` | Controla la pantalla de bloqueo y animación de desbloqueo. |

---

## 🗂️ Estructura del Proyecto

```text
~/.config/quickshell/
├── assets/                  # Capturas de pantalla e iconos vectoriales
├── components/              # Componentes base reutilizables (Pill, BarButton, TrayMenu)
├── modules/                 # Vistas y capas visuales de la interfaz
│   ├── bar/                 # Lienzo y píldoras horizontales de la barra superior
│   ├── center/              # Isla dinámica (Reloj, Media, Notificaciones, Portapapeles, Polkit)
│   ├── controlcenter/       # Centro de Control, Ajustes, Theme Style (Colors, Sounds, Fonts), Displays, Wallpapers y Audio
│   ├── hardware/            # Indicadores de estado de hardware (Batería, Red, Audio)
│   ├── launcher/            # Botón del lanzador de aplicaciones
│   ├── lock/                # Ventana y superficie de bloqueo de pantalla
│   ├── osd/                 # Alertas de batería crítica y OSD de volumen/brillo
│   ├── session/             # Ventana modal de energía y fin de sesión
│   ├── switcher/            # Conmutador modal de ventanas Alt+Tab
│   ├── taskbar/             # Barra de tareas agrupada por espacio de trabajo
│   ├── tray/                # Bandeja del sistema (StatusNotifierItem)
│   ├── wallpaper/           # Lienzo nativo Wayland para fondo de pantalla con cross-dissolve
│   └── workspaces/          # Puntos interactivos y sincronización de workspaces
├── scripts/                 # Scripts auxiliares y demonios en Python
│   ├── clip_daemon.py       # Demonio de portapapeles con socket IPC y soporte de imágenes
│   ├── list_fonts.py        # Descubrimiento e indexación de fuentes instaladas
│   └── list_sound_themes.py # Detección e indexación de temas de sonido del sistema
├── services/                # Servicios singleton reactivos y conectores de sistema
│   ├── AudioService.qml     # Control de sinks/sources mediante wpctl
│   ├── BatteryService.qml   # Monitoreo de batería y alertas de descarga
│   ├── BluetoothService.qml # Detección bluetoothctl y agente PIN
│   ├── BrightnessService.qml# Control multimonitor con brightnessctl
│   ├── ClipboardService.qml # Demonio y registro de portapapeles con soporte de imágenes y pin
│   ├── ControlCenterService.qml # Estado global del panel de control
│   ├── DisplayService.qml   # Detección y ajustes de resolución/Hz con hyprctl
│   ├── FontService.qml      # Detección, persistencia y aplicación dinámica de fuentes
│   ├── LauncherService.qml  # Indexación de .desktop, matemáticas y web
│   ├── LockService.qml      # Lógica de bloqueo de pantalla y pam
│   ├── MediaService.qml     # Cliente MPRIS de reproducción multimedia
│   ├── NetworkService.qml   # Detección de redes y Wi-Fi mediante nmcli
│   ├── NotificationService.qml # Servidor D-Bus de notificaciones freedesktop
│   ├── PolkitService.qml    # Agente de autorización Polkit integrado
│   ├── PowerProfileService.qml # Perfiles power-profiles-daemon
│   ├── SessionService.qml   # Control logind de suspensión, reinicio y apagado
│   ├── SoundService.qml     # Reproductor reactivo de efectos de sonido del sistema
│   ├── SoundThemeService.qml# Gestión de temas sonoros instalados
│   ├── SwitcherService.qml  # Historial MRU y navegación de ventanas
│   └── WallpaperService.qml # Servicio de escaneo, persistencia y extracción con Matugen
├── state/                   # Estado persistente (wallpaper.txt, theme_mode.txt, font.txt, sound_theme.txt, etc.)
├── theme/
│   └── Theme.qml            # Tokens semánticos globales, paletas fijas y dinámicas, tipografía reactiva
├── shell.qml                # Punto de entrada principal y registro de controladores IPC
└── README.md                # Documentación técnica completa
```

---

## 🛠️ Solución de Problemas Frecuentes

1. **Las notificaciones no emiten sonido**:
   - Comprueba tener instalados `sound-theme-freedesktop` (o alguno de los temas como `ocean-sound-theme`) y `libcanberra-gtk3`.
   - Puedes probar manualmente la reproducción en la terminal con:
     ```bash
     canberra-gtk-play -i message-new-instant
     ```

2. **Los iconos aparecen como cuadrados o caracteres extraños**:
   - Asegúrate de haber instalado y actualizado la caché de fuentes con `JetBrainsMono Nerd Font Propo`:
     ```bash
     fc-cache -fv
     ```

3. **No se puede modificar el brillo desde el slider**:
   - Revisa que tu usuario pertenezca al grupo `video`:
     ```bash
     sudo usermod -aG video $USER
     ```
   - Reinicia la sesión para que el cambio de grupo surta efecto.

4. **Matugen no extrae colores al cambiar de fondo**:
   - Verifica que el binario de Matugen esté en `/usr/bin/matugen` o accesible en tu `$PATH`:
     ```bash
     matugen --version
     ```
   - Comprueba que `jq` esté instalado para el procesamiento del JSON:
     ```bash
     sudo dnf install jq -y
     ```
