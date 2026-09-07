# Unused Code Report

## components/BarButton.qml
- Line 8: `signal` **rightClicked** – `    signal rightClicked()`
- Line 11: `property` **textColor** – `    property alias textColor: label.color`
- Line 14: `property` **fontWeight** – `    property alias fontWeight: label.font.weight`
- Line 18: `property` **defaultBgColor** – `    property color defaultBgColor: "transparent"`
- Line 80: `id` **barTooltip** – `        id: barTooltip`

## components/BarToolTip.qml
- Line 12: `property` **delay** – `    property int delay: 300`
- Line 24: `id` **showTimer** – `        id: showTimer`
- Line 26: `property` **shouldShow** – `        property bool shouldShow: false`

## components/Pill.qml
- Line 13: `property` **paddingVertical** – `    property int paddingVertical: Theme.pillPaddingVertical`
- Line 14: `property` **borderColor** – `    property alias borderColor: pillBackground.border.color`
- Line 15: `property` **borderWidth** – `    property alias borderWidth: pillBackground.border.width`
- Line 44: `property` **isExpanded** – `    readonly property bool isExpanded: pillBackground.height > 60`
- Line 48: `id` **shadowSource** – `        id: shadowSource`
- Line 80: `id` **pillBackground** – `        id: pillBackground`
- Line 118: `id` **contentLayout** – `            id: contentLayout`
- Line 130: `id` **pillMouse** – `        id: pillMouse`

## components/TrayMenu.qml
- Line 24: `id` **menuOpener** – `        id: menuOpener`
- Line 69: `id` **layout** – `                id: layout`
- Line 78: `id` **entryItem** – `                        id: entryItem`
- Line 143: `id` **entryMouse** – `                                id: entryMouse`

## modules/bar/Bar.qml
- Line 115: `id` **leftPill** – `                id: leftPill`
- Line 124: `id` **taskbarPill** – `                id: taskbarPill`
- Line 129: `id` **taskbar** – `                    id: taskbar`
- Line 146: `id` **centerIsland** – `                    id: centerIsland`
- Line 153: `id` **rightLayout** – `            id: rightLayout`
- Line 163: `id` **trayPill** – `                id: trayPill`
- Line 174: `id` **hardwarePill** – `                id: hardwarePill`
- Line 200: `id` **controlCenter** – `            id: controlCenter`

## modules/center/CenterIslandModule.qml
- Line 13: `property` **isMediaHovered** – `    readonly property bool isMediaHovered: mediaView.isHovered`
- Line 16: `property` **forceClock** – `    property bool forceClock: false`
- Line 17: `property` **manualMediaActive** – `    property bool manualMediaActive: false`
- Line 21: `id` **graceTimer** – `        id: graceTimer`
- Line 29: `property` **_wheelLocked** – `    property bool _wheelLocked: false`
- Line 31: `id` **wheelCooldown** – `        id: wheelCooldown`
- Line 43: `property` **isMediaActive** – `    readonly property bool isMediaActive: {`
- Line 67: `function` **onIsPlayingChanged** – `        function onIsPlayingChanged() {`
- Line 79: `function` **onHasMediaChanged** – `        function onHasMediaChanged() {`
- Line 99: `function` **onSelectedIndexChanged** – `        function onSelectedIndexChanged() {`
- Line 120: `function` **handleWheel** – `    function handleWheel() {`
- Line 143: `property` **launcherWidth** – `    readonly property int launcherWidth: 330 - (6 * 2)`
- Line 144: `property` **launcherHeight** – `    readonly property int launcherHeight: 323`
- Line 145: `property` **notificationCenterWidth** – `    readonly property int notificationCenterWidth: 330 - (6 * 2)`
- Line 146: `property` **notificationCenterHeight** – `    readonly property int notificationCenterHeight: 330`
- Line 199: `function` **ensureItemVisible** – `    function ensureItemVisible(idx) {`
- Line 217: `id` **clockView** – `        id: clockView`
- Line 247: `id` **mediaView** – `        id: mediaView`
- Line 268: `id` **notificationToastView** – `        id: notificationToastView`
- Line 283: `id` **notifCenterWrapper** – `        id: notifCenterWrapper`
- Line 314: `id` **launcherView** – `        id: launcherView`
- Line 381: `id` **searchField** – `                        id: searchField`
- Line 441: `id` **escBadgeText** – `                            id: escBadgeText`
- Line 485: `id` **appListView** – `                    id: appListView`
- Line 507: `id` **appItem** – `                        id: appItem`
- Line 512: `property` **isSelected** – `                        readonly property bool isSelected: index === LauncherService.selectedIndex`
- Line 574: `id` **enterBadgeText** – `                                        id: enterBadgeText`
- Line 587: `id` **itemMouse** – `                            id: itemMouse`

## modules/center/ClockView.qml
- Line 9: `property` **currentDate** – `    property date currentDate: new Date()`
- Line 10: `property` **showDate** – `    property bool showDate: false`
- Line 13: `property` **timeString** – `    readonly property string timeString: Qt.formatDateTime(currentDate, "hh:mm AP")`
- Line 14: `property` **dateString** – `    readonly property string dateString: Qt.formatDateTime(currentDate, "ddd, dd MMM")`
- Line 16: `property` **activeText** – `    readonly property string activeText: showDate ? dateString : timeString`
- Line 45: `id` **textLabel** – `            id: textLabel`
- Line 68: `signal` **wakeMediaRequested** – `    signal wakeMediaRequested()`

## modules/center/MediaView.qml
- Line 13: `property` **expandProgress** – `    property real expandProgress: isHovered ? 1.0 : 0.0`
- Line 26: `signal` **dismissToClockRequested** – `    signal dismissToClockRequested()`
- Line 31: `id` **hoverArea** – `        id: hoverArea`
- Line 77: `id` **titleLabel** – `            id: titleLabel`
- Line 90: `id` **artistLabel** – `            id: artistLabel`
- Line 105: `id` **controlsContainer** – `            id: controlsContainer`
- Line 114: `id` **controlsRow** – `                id: controlsRow`
- Line 138: `id` **prevMouse** – `                        id: prevMouse`
- Line 169: `id` **playMouse** – `                        id: playMouse`
- Line 200: `id` **nextMouse** – `                        id: nextMouse`

## modules/center/NotificationCenterView.qml
- Line 37: `id` **titleBtn** – `                id: titleBtn`
- Line 46: `id` **titleRow** – `                    id: titleRow`
- Line 69: `id` **titleMouse** – `                    id: titleMouse`
- Line 117: `id` **dndMouse** – `                    id: dndMouse`
- Line 147: `id` **clearMouse** – `                    id: clearMouse`
- Line 203: `id` **notifListView** – `                id: notifListView`
- Line 223: `id` **cardItem** – `                    id: cardItem`
- Line 224: `property` **notifItem** – `                    readonly property var notifItem: modelData`
- Line 236: `id` **cardMouse** – `                        id: cardMouse`
- Line 242: `id` **cardContent** – `                        id: cardContent`
- Line 261: `id` **cardIconImg** – `                                    id: cardIconImg`
- Line 338: `id` **itemDismissMouse** – `                                    id: itemDismissMouse`
- Line 365: `id` **bodyBox** – `                            id: bodyBox`
- Line 374: `property` **isCmd** – `                            readonly property bool isCmd: {`
- Line 380: `id` **bodyText** – `                                id: bodyText`
- Line 422: `id` **actionLabel** – `                                        id: actionLabel`
- Line 432: `id` **actionMouse** – `                                        id: actionMouse`

## modules/center/NotificationToastView.qml
- Line 12: `property` **hasToast** – `    readonly property bool hasToast: currentToast !== null`
- Line 27: `id` **toastMouse** – `        id: toastMouse`
- Line 65: `id` **toastIconImg** – `                id: toastIconImg`
- Line 104: `id` **appNameText** – `                id: appNameText`
- Line 122: `id` **messageLabel** – `                id: messageLabel`
- Line 155: `id` **closeBtn** – `            id: closeBtn`

## modules/controlcenter/BatteryCard.qml
- Line 19: `function` **triggerLock** – `    function triggerLock() {`
- Line 51: `id` **normalLayer** – `        id: normalLayer`
- Line 66: `id` **batChip** – `                id: batChip`
- Line 82: `id` **batLayout** – `                    id: batLayout`
- Line 108: `id` **batMouse** – `                    id: batMouse`
- Line 122: `id` **lockBtn** – `                id: lockBtn`
- Line 153: `id` **lockMouse** – `                    id: lockMouse`
- Line 163: `id` **powerBtn** – `                id: powerBtn`
- Line 194: `id` **powerMouse** – `                    id: powerMouse`
- Line 208: `id` **powerLayer** – `        id: powerLayer`
- Line 266: `property` **hoveredHint** – `                readonly property string hoveredHint: {`
- Line 324: `id` **suspMouse** – `                        id: suspMouse`
- Line 356: `id` **exitMouse** – `                        id: exitMouse`
- Line 388: `id` **rebootMouse** – `                        id: rebootMouse`
- Line 420: `id` **shutMouse** – `                        id: shutMouse`

## modules/controlcenter/BluetoothDetailView.qml
- Line 21: `property` **passkeyNavIndex** – `    property int passkeyNavIndex: 1 // 0: Rechazar, 1: Confirmar`
- Line 180: `property` **nativeDevices** – `    readonly property var nativeDevices: {`
- Line 193: `property` **cliDevices** – `    property var cliDevices: []`
- Line 194: `property` **_accumulatedLines** – `    property var _accumulatedLines: []`
- Line 199: `id` **scanCtlProc** – `        id: scanCtlProc`
- Line 211: `id` **btScanProc** – `        id: btScanProc`
- Line 259: `function` **refreshBtScan** – `    function refreshBtScan() {`
- Line 272: `function` **stopBtScan** – `    function stopBtScan() {`
- Line 303: `property` **allDevices** – `    readonly property var allDevices: {`
- Line 336: `property` **pairedDevices** – `    readonly property var pairedDevices: {`
- Line 349: `property` **availableDevices** – `    readonly property var availableDevices: {`
- Line 359: `function` **deviceIcon** – `    function deviceIcon(dev) {`
- Line 479: `id` **btSwitch** – `                id: btSwitch`
- Line 523: `id` **passkeyCard** – `            id: passkeyCard`
- Line 532: `id` **passkeyCol** – `                id: passkeyCol`
- Line 621: `id` **rejectBtn** – `                        id: rejectBtn`
- Line 639: `id` **rejectMouse** – `                            id: rejectMouse`
- Line 648: `id` **confirmBtn** – `                        id: confirmBtn`
- Line 666: `id` **confirmMouse** – `                            id: confirmMouse`
- Line 713: `id` **devScroll** – `                id: devScroll`
- Line 746: `id` **devItem** – `                                id: devItem`
- Line 801: `id` **batBadge** – `                                        id: batBadge`
- Line 802: `property` **batLevel** – `                                        readonly property int batLevel: ControlCenterService.getDeviceBattery(modelData.address)`
- Line 809: `id` **batRow** – `                                            id: batRow`
- Line 843: `id` **forgetBtn** – `                                        id: forgetBtn`
- Line 860: `id` **forgetMouse** – `                                            id: forgetMouse`
- Line 870: `id` **rowMouse** – `                                    id: rowMouse`
- Line 939: `id` **availItem** – `                                id: availItem`
- Line 998: `id` **availMouse** – `                                    id: availMouse`

## modules/controlcenter/ControlCenter.qml
- Line 12: `property` **_isOpen** – `    property bool _isOpen: false`
- Line 13: `property` **currentView** – `    property int currentView: 0 // 0 = Principal, 1 = Wi-Fi, 2 = Bluetooth`
- Line 14: `property` **focusedIndex** – `    property int focusedIndex: 0 // 0..7 para los elementos del panel principal`
- Line 23: `function` **triggerSpaceAction** – `    function triggerSpaceAction(idx) {`
- Line 42: `function` **triggerEnterAction** – `    function triggerEnterAction(idx) {`
- Line 62: `id` **closeTimer** – `        id: closeTimer`
- Line 108: `function` **onHasPasskeyPromptChanged** – `        function onHasPasskeyPromptChanged() {`
- Line 117: `id` **animContainer** – `        id: animContainer`
- Line 177: `id` **mainCard** – `            id: mainCard`
- Line 402: `id` **viewsContainer** – `                id: viewsContainer`
- Line 411: `id` **mainView** – `                    id: mainView`
- Line 430: `id` **contentColumn** – `                        id: contentColumn`
- Line 458: `id` **toggleBt** – `                                id: toggleBt`
- Line 508: `id` **sliderVol** – `                                id: sliderVol`
- Line 520: `id` **sliderBri** – `                                id: sliderBri`
- Line 540: `id` **batCard** – `                            id: batCard`
- Line 552: `id` **wifiView** – `                    id: wifiView`
- Line 578: `id` **btView** – `                    id: btView`

## modules/controlcenter/QuickToggle.qml
- Line 15: `signal` **submenuClicked** – `    signal submenuClicked()`
- Line 35: `id` **cardBg** – `        id: cardBg`
- Line 107: `id` **arrowContainer** – `                id: arrowContainer`
- Line 146: `id` **mainMouse** – `            id: mainMouse`
- Line 152: `property` **isOverArrow** – `            readonly property bool isOverArrow: root.hasSubmenu && mainMouse.containsMouse && (mouseX >= (cardBg.width - 34))`

## modules/controlcenter/SliderControl.qml
- Line 13: `signal` **valueChangedByUser** – `    signal valueChangedByUser(int newValue)`
- Line 14: `signal` **iconClicked** – `    signal iconClicked()`
- Line 34: `id` **trackBg** – `        id: trackBg`
- Line 50: `id` **fillRect** – `            id: fillRect`
- Line 90: `id` **iconText** – `                    id: iconText`
- Line 117: `id` **iconMouse** – `                    id: iconMouse`
- Line 159: `function` **updateFromMouse** – `            function updateFromMouse(posX) {`

## modules/controlcenter/WifiDetailView.qml
- Line 166: `property` **wifiDevice** – `    readonly property var wifiDevice: {`
- Line 179: `function` **updateScanner** – `    function updateScanner(enable) {`
- Line 206: `property` **nativeNetworks** – `    readonly property var nativeNetworks: {`
- Line 231: `property` **cliNetworks** – `    property var cliNetworks: []`
- Line 232: `property` **_accumulatedNetLines** – `    property var _accumulatedNetLines: []`
- Line 236: `id` **scanProc** – `        id: scanProc`
- Line 300: `function` **refreshScan** – `    function refreshScan() {`
- Line 306: `function` **stopScan** – `    function stopScan() {`
- Line 312: `property` **displayNetworks** – `    readonly property var displayNetworks: {`
- Line 376: `property` **knownSavedMap** – `    property var knownSavedMap: ({})`
- Line 378: `function` **syncKnownSaved** – `    function syncKnownSaved() {`
- Line 393: `function` **isNetworkSaved** – `    function isNetworkSaved(name) {`
- Line 400: `function` **markSaved** – `    function markSaved(name) {`
- Line 409: `function` **forgetSaved** – `    function forgetSaved(name) {`
- Line 417: `function` **isConnectingNet** – `    function isConnectingNet(netName) {`
- Line 425: `property` **savedNetworks** – `    readonly property var savedNetworks: {`
- Line 439: `property` **availableNetworks** – `    readonly property var availableNetworks: {`
- Line 448: `function` **signalIcon** – `    function signalIcon(strength) {`
- Line 458: `property` **passwordText** – `    property string passwordText: ""`
- Line 459: `property` **showPassword** – `    property bool showPassword: false`
- Line 461: `function` **promptPassword** – `    function promptPassword(ssid) {`
- Line 476: `function` **submitPassword** – `    function submitPassword() {`
- Line 483: `function` **onSavedWifiConnectionsChanged** – `        function onSavedWifiConnectionsChanged() {`
- Line 486: `function` **onWifiConnectionFinished** – `        function onWifiConnectionFinished() {`
- Line 495: `function` **onConnectingWifiSsidChanged** – `        function onConnectingWifiSsidChanged() {`
- Line 509: `function` **onConnectionNameChanged** – `        function onConnectionNameChanged() {`
- Line 627: `id` **wifiSwitch** – `                id: wifiSwitch`
- Line 671: `id` **passwordCard** – `            id: passwordCard`
- Line 684: `id` **passCol** – `                id: passCol`
- Line 729: `id` **passBox** – `                    id: passBox`
- Line 738: `id` **passBoxMouse** – `                        id: passBoxMouse`
- Line 753: `id` **passInput** – `                            id: passInput`
- Line 799: `id` **eyeMouse** – `                                id: eyeMouse`
- Line 829: `id` **cancelBtn** – `                        id: cancelBtn`
- Line 845: `id` **cancelMouse** – `                            id: cancelMouse`
- Line 854: `id` **connectBtn** – `                        id: connectBtn`
- Line 943: `id` **netScroll** – `                id: netScroll`
- Line 976: `id` **savedItem** – `                                id: savedItem`
- Line 1043: `id` **forgetNetBtn** – `                                        id: forgetNetBtn`
- Line 1060: `id` **forgetNetMouse** – `                                            id: forgetNetMouse`
- Line 1073: `id` **savedRowMouse** – `                                    id: savedRowMouse`
- Line 1140: `id` **availNetItem** – `                                id: availNetItem`
- Line 1209: `id` **availNetMouse** – `                                    id: availNetMouse`

## modules/osd/CriticalBatteryAlert.qml
- Line 40: `property` **displayed** – `    property bool displayed: false`
- Line 41: `property` **isPluggedNotice** – `    property bool isPluggedNotice: false`
- Line 44: `property` **pulseAlpha** – `    property real pulseAlpha: 0.4`
- Line 66: `id` **soundAlert** – `        id: soundAlert`
- Line 72: `id` **plugNoticeTimer** – `        id: plugNoticeTimer`
- Line 84: `function` **onShouldAlertCriticalChanged** – `        function onShouldAlertCriticalChanged() {`
- Line 116: `id` **cardContainer** – `        id: cardContainer`
- Line 159: `id` **alertCard** – `            id: alertCard`
- Line 282: `id` **snoozeRow** – `                            id: snoozeRow`
- Line 295: `id` **snoozeBtnLabel** – `                                id: snoozeBtnLabel`
- Line 306: `id` **snoozeMouse** – `                            id: snoozeMouse`

## modules/osd/VolumeOsd.qml
- Line 28: `property` **osdOpacity** – `    property real osdOpacity: 0.0`
- Line 39: `property` **currentMode** – `    property string currentMode: "volume"`
- Line 40: `property` **currentValue** – `    property int currentValue: 0`
- Line 41: `property` **currentIcon** – `    property string currentIcon: "󰕾"`
- Line 45: `id` **hideTimer** – `        id: hideTimer`
- Line 52: `function` **onVolumeChangedTriggered** – `        function onVolumeChangedTriggered(percent, muted) {`
- Line 64: `function` **onBrightnessChangedTriggered** – `        function onBrightnessChangedTriggered(percent) {`
- Line 103: `id` **osdContainer** – `            id: osdContainer`

## modules/taskbar/TaskbarModule.qml
- Line 31: `id` **focusProc** – `        id: focusProc`
- Line 36: `id` **closeProc** – `        id: closeProc`
- Line 40: `function` **focusWindow** – `    function focusWindow(address, workspaceId, toplevel) {`
- Line 59: `function` **closeWindow** – `    function closeWindow(address, toplevel) {`
- Line 70: `property` **currentWorkspaceId** – `    readonly property int currentWorkspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1`
- Line 73: `property` **activeAddress** – `    readonly property string activeAddress: {`
- Line 179: `property` **activeWindows** – `    readonly property var activeWindows: {`
- Line 234: `id` **taskItem** – `                id: taskItem`
- Line 309: `id` **taskMouse** – `                    id: taskMouse`

## modules/tray/TrayModule.qml
- Line 14: `property` **activeCount** – `    readonly property int activeCount: (SystemTray.items && SystemTray.items.values) ? SystemTray.items.values.length : 0`
- Line 18: `id` **trayRepeater** – `        id: trayRepeater`
- Line 22: `id` **trayButton** – `            id: trayButton`
- Line 32: `property` **resolvedSource** – `            readonly property string resolvedSource: {`
- Line 51: `id` **iconImg** – `                id: iconImg`
- Line 73: `id` **trayMenu** – `                id: trayMenu`

## modules/workspaces/WorkspacesModule.qml
- Line 14: `id` **wsProcess** – `        id: wsProcess`
- Line 19: `function` **switchToWorkspace** – `    function switchToWorkspace(id) {`
- Line 40: `property` **_toplevelsCount** – `    readonly property int _toplevelsCount: (Hyprland.toplevels && Hyprland.toplevels.values) ? Hyprland.toplevels.values.length : 0`
- Line 41: `property` **_workspacesCount** – `    readonly property int _workspacesCount: (Hyprland.workspaces && Hyprland.workspaces.values) ? Hyprland.workspaces.values.length : 0`
- Line 135: `property` **workspaceIds** – `    readonly property var workspaceIds: {`
- Line 160: `id` **wsButton** – `            id: wsButton`
- Line 164: `property` **wsId** – `            readonly property int wsId: modelData`
- Line 165: `property` **isActive** – `            readonly property bool isActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId`
- Line 168: `property` **isOccupied** – `            readonly property bool isOccupied: {`
- Line 174: `property` **isUrgent** – `            readonly property bool isUrgent: {`
- Line 189: `id` **wsPill** – `                id: wsPill`
- Line 228: `id` **wsMouse** – `                id: wsMouse`

## services/AudioService.qml
- Line 14: `property` **defaultSink** – `    readonly property PwNode defaultSink: Pipewire.defaultAudioSink`
- Line 16: `property` **volumePercent** – `    readonly property int volumePercent: Math.round(volume * 100)`
- Line 18: `property` **sinkName** – `    readonly property string sinkName: defaultSink ? (defaultSink.description || defaultSink.name || "Altavoz") : "Sin salida"`
- Line 27: `signal` **volumeChangedTriggered** – `    signal volumeChangedTriggered(int percent, bool muted)`
- Line 40: `property` **_lastReportedMuted** – `    property bool _lastReportedMuted: false`
- Line 66: `id` **wpctlProc** – `        id: wpctlProc`
- Line 114: `property` **defaultSource** – `    readonly property PwNode defaultSource: Pipewire.defaultAudioSource`
- Line 118: `id` **micWpctlProc** – `        id: micWpctlProc`

## services/BatteryService.qml
- Line 12: `property` **defaultIcons** – `    readonly property var defaultIcons: [`
- Line 16: `property` **chargingIcons** – `    readonly property var chargingIcons: [`
- Line 21: `property` **_sysCapacity** – `    property int _sysCapacity: 100`
- Line 22: `property` **_sysStatus** – `    property string _sysStatus: "Discharging"`
- Line 25: `id` **batReader** – `        id: batReader`
- Line 50: `property` **testPercentage** – `    property int testPercentage: -1`
- Line 51: `property` **testCharging** – `    property int testCharging: -1`
- Line 72: `property` **isSnoozed** – `    property bool isSnoozed: false`
- Line 75: `id` **snoozeTimer** – `        id: snoozeTimer`
- Line 87: `function` **resetSnooze** – `    function resetSnooze(): void {`
- Line 112: `property` **_notifiedLow** – `    property bool _notifiedLow: false`
- Line 113: `property` **_notifiedFull** – `    property bool _notifiedFull: false`
- Line 115: `function` **checkBatteryAlerts** – `    function checkBatteryAlerts() {`
- Line 172: `property` **isWarning** – `    readonly property bool isWarning: percentage <= 25 && !isCharging`
- Line 179: `property` **iconIndex** – `    readonly property int iconIndex: Math.min(10, Math.max(0, Math.floor(percentage / 10)))`

## services/BluetoothService.qml
- Line 11: `property` **_sysPowered** – `    property bool _sysPowered: false`
- Line 13: `property` **_sysDeviceName** – `    property string _sysDeviceName: ""`
- Line 16: `id` **btReader** – `        id: btReader`

## services/BrightnessService.qml
- Line 15: `signal` **brightnessChangedTriggered** – `    signal brightnessChangedTriggered(int percent)`
- Line 40: `id` **readProc** – `        id: readProc`
- Line 59: `id` **setProc** – `        id: setProc`

## services/ControlCenterService.qml
- Line 44: `id` **connectingWifiTimer** – `        id: connectingWifiTimer`
- Line 55: `id` **wifiToggleProc** – `        id: wifiToggleProc`
- Line 65: `property` **_accumulatedSavedLines** – `    property var _accumulatedSavedLines: []`
- Line 68: `id` **wifiSavedProc** – `        id: wifiSavedProc`
- Line 94: `id` **wifiConnProc** – `        id: wifiConnProc`
- Line 124: `signal` **wifiConnectionFinished** – `    signal wifiConnectionFinished()`
- Line 127: `id` **wifiDeleteProc** – `        id: wifiDeleteProc`
- Line 220: `id` **connectingTimer** – `        id: connectingTimer`
- Line 227: `id` **btToggleProc** – `        id: btToggleProc`
- Line 232: `id` **btConnProc** – `        id: btConnProc`
- Line 240: `id` **btRemoveProc** – `        id: btRemoveProc`
- Line 243: `property` **deviceBatteries** – `    property var deviceBatteries: ({})`
- Line 246: `id` **btBatteryTimer** – `        id: btBatteryTimer`
- Line 256: `function` **onIsConnectedChanged** – `        function onIsConnectedChanged() {`
- Line 266: `id` **btBatteryProc** – `        id: btBatteryProc`
- Line 343: `property` **promptMac** – `    property string promptMac: ""`
- Line 348: `id` **btAgentProc** – `        id: btAgentProc`
- Line 390: `id` **btAgentRestartTimer** – `        id: btAgentRestartTimer`
- Line 415: `property` **isDnd** – `    readonly property bool isDnd: NotificationService.dnd`
- Line 433: `id` **sysActionProc** – `        id: sysActionProc`
- Line 436: `function` **runSysCommand** – `    function runSysCommand(cmd) {`

## services/LauncherService.qml
- Line 13: `signal` **appLaunched** – `    signal appLaunched()`
- Line 16: `property` **allApplications** – `    readonly property var allApplications: {`
- Line 106: `property` **preferredTerminal** – `    readonly property string preferredTerminal: {`
- Line 113: `id` **terminalAppProc** – `        id: terminalAppProc`

## services/MediaService.qml
- Line 9: `property` **activePlayer** – `    readonly property var activePlayer: {`
- Line 53: `property` **album** – `    readonly property string album: activePlayer ? (activePlayer.trackAlbum || "") : ""`
- Line 55: `property` **artUrl** – `    readonly property string artUrl: {`
- Line 62: `property` **identity** – `    readonly property string identity: activePlayer ? (activePlayer.identity || "") : ""`
- Line 76: `property` **canPlay** – `    readonly property bool canPlay: activePlayer ? activePlayer.canPlay : false`
- Line 77: `property` **canPause** – `    readonly property bool canPause: activePlayer ? activePlayer.canPause : false`
- Line 78: `property` **canGoNext** – `    readonly property bool canGoNext: activePlayer ? activePlayer.canGoNext : false`
- Line 79: `property` **canGoPrevious** – `    readonly property bool canGoPrevious: activePlayer ? activePlayer.canGoPrevious : false`
- Line 80: `property` **canRaise** – `    readonly property bool canRaise: activePlayer ? activePlayer.canRaise : false`

## services/NetworkService.qml
- Line 12: `property` **_sysIsWifi** – `    property bool _sysIsWifi: false`
- Line 13: `property` **_sysIsEthernet** – `    property bool _sysIsEthernet: false`
- Line 14: `property` **_sysConnectionName** – `    property string _sysConnectionName: ""`
- Line 17: `id` **netReader** – `        id: netReader`
- Line 86: `property` **isEthernet** – `    readonly property bool isEthernet: {`

## services/NotificationService.qml
- Line 15: `property` **soundEnabled** – `    property bool soundEnabled: true`
- Line 16: `property` **defaultSoundPath** – `    property string defaultSoundPath: "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"`
- Line 19: `id` **soundProc** – `        id: soundProc`
- Line 23: `function` **playSound** – `    function playSound(customPath) {`
- Line 40: `property` **isLauncherOpen** – `    readonly property bool isLauncherOpen: {`
- Line 47: `property` **hasNotifications** – `    readonly property bool hasNotifications: count > 0`
- Line 50: `property` **_ticker** – `    property int _ticker: 0`
- Line 60: `id` **toastTimer** – `        id: toastTimer`
- Line 177: `id` **notifId** – `            id: notifId,`
- Line 203: `function` **removeNotification** – `    function removeNotification(id) {`

## shell.qml
- Line 14: `id` **notifServer** – `        id: notifServer`
- Line 102: `function` **dump** – `        function dump(): void {`

## theme/Theme.qml
- Line 10: `property` **dark5** – `    readonly property color dark5: "#1f525252"            // @dark-5 (12% opacity)`
- Line 71: `property` **iconSize** – `    readonly property int iconSize: 16`

