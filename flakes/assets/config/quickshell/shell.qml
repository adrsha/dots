import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets
import "ui/panels"
import "ui/desktop"

ShellRoot {
    id: shell
    property string page: ""
    property var apps: []
    property var walls: []
    property var wallCategories: []
    property var wallThemes: []
    property string selectedWall: ""
    property string pendingWallDelete: ""
    property bool studioDockTop: false
    property bool studioDiscoverRight: false
    property string savedWebWall: ""
    property string savedWebId: ""
    property string selectedCategory: "All"
    property string selectedTheme: ""
    property string wallFilter: ""
    property var webWalls: []
    property var selectedWebWall: null
    property string webError: ""
    property string webProvider: "wallhaven"
    property bool webMode: false
    property var info: ({})
    property string wallpaperPath: ""
    property string activeVideoPath: ""
    readonly property bool videoRunning: videoWallpaper.running
    property string activeVideoStill: ""
    property string feedback: ""
    property string osdKind: ""
    property string osdMessage: ""
    property real osdValue: -1
    property string captureScope: "region"
    property string captureDestination: "save"
    property string captureFilename: ""
    property bool editAfterScreenshot: true
    property string editorSource: ""
    property string editorOutput: ""
    property string editorDestination: "save"
    property string editorFilename: ""
    function showOsd(kind, message, value) {
        osdKind = kind; osdMessage = message; osdValue = value === undefined ? -1 : value
        osdTimeout.restart()
    }
    Timer { id: osdTimeout; interval: 2300; onTriggered: shell.osdKind = "" }
    function screenshot(scope, destination) {
        if (!["region", "window", "output"].includes(scope) || !["save", "clipboard", "lens"].includes(destination)) { showOsd("screenshot", "Invalid screenshot option"); return }
        if (captureRequest.running || captureDelay.running || editorSource !== "") { showOsd("screenshot", "Screenshot already running"); return }
        captureScope = scope; captureDestination = destination
        editorDestination = destination; editorFilename = captureFilename
        osdTimeout.stop(); osdKind = ""
        page = ""
        captureDelay.restart()
    }
    Timer { id: captureDelay; interval: 260; onTriggered: { captureRequest.command = ["python3", shell.backend, "screenshot", shell.captureScope, shell.editorDestination, shell.editorFilename, shell.editAfterScreenshot ? "edit" : "direct"]; captureRequest.running = true } }
    Process { id: captureRequest
        stdout: StdioCollector { onStreamFinished: {
            try {
                const result = JSON.parse(this.text)
                if (result.editing) {
                    shell.editorSource = result.path; shell.editorOutput = result.output
                    shell.page = "screenshot-editor"
                } else if (!result.cancelled) shell.showOsd("screenshot", result.error || result.message || "Screenshot failed")
            } catch (e) { shell.showOsd("screenshot", "Screenshot failed") }
        } }
        stderr: StdioCollector { onStreamFinished: if (this.text.trim()) shell.showOsd("screenshot", "Screenshot failed: " + this.text.trim()) }
    }
    Process { id: brightnessRequest
        onRunningChanged: if (!running && shell.pendingBrightness !== 0) brightnessFollowup.restart()
        stdout: StdioCollector { onStreamFinished: {
            try {
                const result = JSON.parse(this.text)
                shell.showOsd("brightness", result.error || result.message, result.value)
            } catch (e) { shell.showOsd("brightness", "Brightness unavailable") }
            if (shell.pendingBrightness !== 0) brightnessFollowup.restart()
        } }
        stderr: StdioCollector { onStreamFinished: if (this.text.trim()) shell.showOsd("brightness", "DDC brightness failed") }
    }
    property int pendingBrightness: 0
    function changeBrightness(delta) {
        const step = Number(delta)
        if (step !== -5 && step !== 5) return
        pendingBrightness = Math.max(-20, Math.min(20, pendingBrightness + step))
        brightnessFollowup.restart()
    }
    Timer { id: brightnessFollowup; interval: 60; onTriggered: {
        if (brightnessRequest.running || shell.pendingBrightness === 0) return
        const step = shell.pendingBrightness > 0 ? 5 : -5
        shell.pendingBrightness -= step
        brightnessRequest.command = ["python3", shell.backend, "brightness", String(step)]
        brightnessRequest.running = true
    } }
    property int pendingVolume: 0
    Process { id: volumeRequest
        onRunningChanged: if (!running && shell.pendingVolume !== 0) volumeFollowup.restart()
        stdout: StdioCollector { onStreamFinished: {
            try {
                const result = JSON.parse(this.text)
                shell.showOsd("volume", result.error || result.message || "Volume", result.value)
                shell.refresh()
            } catch (e) { shell.showOsd("volume", "Volume unavailable") }
            if (shell.pendingVolume !== 0) volumeFollowup.restart()
        } }
    }
    function changeVolume(delta) {
        const step = Number(delta) < 0 ? -5 : 5
        pendingVolume = Math.max(-30, Math.min(30, pendingVolume + step))
        volumeFollowup.restart()
    }
    Timer { id: volumeFollowup; interval: 40; onTriggered: {
        if (volumeRequest.running || shell.pendingVolume === 0) return
        const step = shell.pendingVolume > 0 ? 5 : -5
        shell.pendingVolume -= step
        volumeRequest.command = ["python3", shell.backend, "volume", String(step)]
        volumeRequest.running = true
    } }
    property var notificationHistory: []
    property var popupEntries: []
    property bool popupReplyFocus: false
    property bool doNotDisturb: false
    function hidePopup(id) {
        popupEntries = popupEntries.filter(function(n) { return n.id !== id })
        if (popupEntries.length === 0) popupReplyFocus = false
    }
    function removeNotification(id) {
        notificationHistory = notificationHistory.filter(function(n) { return n.id !== id })
        hidePopup(id)
    }
    NotificationServer {
        id: notificationServer
        actionsSupported: true
        imageSupported: true
        actionIconsSupported: true
        inlineReplySupported: true
        onNotification: notification => {
            notification.tracked = true
            const item = {id: notification.id, app: notification.appName || "Application", title: notification.summary || "Notification", body: notification.body || "", icon: notification.appIcon || "", picture: notification.image || "", urgency: notification.urgency, progress: notification.hints.value, live: notification}
            if (!notification.transient) shell.notificationHistory = [item].concat(shell.notificationHistory.filter(function(n) { return n.id !== item.id })).slice(0, 80)
            notification.closed.connect(function() {
                // Preserve closed entries as history, but never retain destroyed QObjects.
                shell.notificationHistory = shell.notificationHistory.map(function(n) {
                    return n.id === item.id && n.live === notification ? {id: n.id, app: n.app, title: n.title, body: n.body, icon: n.icon, picture: n.picture, urgency: n.urgency, progress: n.progress, live: null} : n
                })
                if (shell.popupEntries.some(function(n) { return n.id === item.id && n.live === notification })) shell.hidePopup(item.id)
            })
            if (!shell.doNotDisturb && !notification.lastGeneration) {
                // Newest first; older overflow remains available in history.
                shell.popupEntries = [item].concat(shell.popupEntries.filter(function(n) { return n.id !== item.id })).slice(0, 3)
            }
        }
    }
    // Big Thinker monitor: polls `backend.py big-thinker`
    // (equiv. `curl -fsS $BIG_THINKER_URL -H "Authorization: Bearer ..." | jq`).
    // Sends one persistent notification on the false -> true transition.
    // Requires BIG_THINKER_URL + BIG_THINKER_API_KEY in the qs process environment.
    property bool bigThinkerUp: false
    property string bigThinkerDetail: ""
    function pushBigThinkerNotification(detail) {
        const id = "big-thinker-online"
        const suffix = detail ? (" " + detail).slice(0, 300) : ""
        const item = {id: id, app: "Big Thinker", title: "Big Thinker API online", body: "Endpoint returned valid JSON." + suffix, icon: "", picture: "", urgency: 1, progress: -1, persistent: true, live: null}
        notificationHistory = [item].concat(notificationHistory.filter(function(n) { return n.id !== id })).slice(0, 80)
        // Persistent monitor alert bypasses DND; dismiss manually via popup/center.
        popupEntries = [item].concat(popupEntries.filter(function(n) { return n.id !== id })).slice(0, 3)
    }
    Process {
        id: bigThinkerRequest
        command: ["python3", shell.backend, "big-thinker"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                const res = JSON.parse(this.text)
                if (res.ok) {
                    shell.bigThinkerDetail = res.detail || ""
                    if (!shell.bigThinkerUp) {
                        shell.bigThinkerUp = true
                        shell.pushBigThinkerNotification(shell.bigThinkerDetail)
                    }
                } else {
                    shell.bigThinkerUp = false
                    shell.bigThinkerDetail = res.error || "check failed"
                }
            } catch (e) { shell.bigThinkerUp = false; shell.bigThinkerDetail = "Invalid monitor response" }
        } }
        stderr: StdioCollector { onStreamFinished: if (this.text.trim()) console.warn("big-thinker:", this.text.trim()) }
    }
    Timer {
        id: bigThinkerPoll
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!bigThinkerRequest.running) bigThinkerRequest.running = true
    }
    property int launcherWidth: 460
    property int launcherHeight: 790
    property bool launcherGrid: false
    property int panelTop: 8
    property int panelRight: 8
    property var themeColors: ({})
    property string themeVariant: "dark"
    property real themeOpacity: 1
    property point dragOrigin
    property int dragTop
    property int dragRight
    function startDrag(area, mouse) {
        dragOrigin = area.mapToGlobal(mouse.x, mouse.y)
        dragTop = launcherPanel.margins.top
        dragRight = launcherPanel.margins.right
    }
    function dragPanel(area, mouse) {
        if (!area.pressed) return
        const pos = area.mapToGlobal(mouse.x, mouse.y)
        panelTop = Math.max(0, Math.min((launcherPanel.screen ? launcherPanel.screen.height : 1080) - launcherPanel.height, dragTop + pos.y - dragOrigin.y))
        panelRight = Math.max(0, Math.min((launcherPanel.screen ? launcherPanel.screen.width : 1920) - launcherPanel.width, dragRight + dragOrigin.x - pos.x))
    }
    function themeColor(key, fallback) {
        const value = themeColors[key]
        return typeof value === "string" && /^#[0-9a-fA-F]{6}$/.test(value) ? value : fallback
    }
    readonly property var filteredApps: apps.filter(function(app) { return (app.name + " " + app.description).toLowerCase().includes(launcherPanel.query.toLowerCase()) })
    // User configuration: Escape (default) or quick jk to leave text insertion.
    property string normalModeKey: "escape"
    property int jkTimeoutMs: 250
    FileView {
        id: userSettings
        path: Quickshell.shellPath("shell-settings.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const settings = JSON.parse(text())
                shell.normalModeKey = settings.normalModeKey === "jk" ? "jk" : "escape"
                const timeout = Number(settings.jkTimeoutMs)
                shell.jkTimeoutMs = Number.isFinite(timeout) ? Math.max(80, Math.min(1000, timeout)) : 250
            } catch (e) { console.warn("Invalid shell-settings.json:", e) }
        }
    }
    property bool reduceMotion: false
    function toggleStudioDock() { studioDockTop = !studioDockTop; saveStudioState() }
    function toggleDiscoverSide() { studioDiscoverRight = !studioDiscoverRight; saveStudioState() }
    function saveStudioState() { studioState.setText(JSON.stringify({dockTop: studioDockTop, discoverRight: studioDiscoverRight})) }
    FileView { id: studioState; path: Quickshell.shellPath("studio-state.json"); onLoaded: { try { const state = JSON.parse(text()); shell.studioDockTop = state.dockTop === true; shell.studioDiscoverRight = state.discoverRight === true } catch (e) { shell.studioDockTop = false; shell.studioDiscoverRight = false } } }
    function saveLauncherState() {
        launcherState.setText(JSON.stringify({width: launcherWidth, height: launcherHeight, grid: launcherGrid, top: panelTop, right: panelRight}))
    }
    FileView {
        id: launcherState
        path: Quickshell.shellPath("launcher-state.json")
        onLoaded: {
            try {
                const state = JSON.parse(text())
                if (Number.isFinite(state.width)) shell.launcherWidth = Math.max(320, Math.min(1000, state.width))
                if (Number.isFinite(state.height)) shell.launcherHeight = Math.max(280, Math.min(1400, state.height))
                shell.launcherGrid = state.grid === true
                if (Number.isFinite(state.top)) shell.panelTop = Math.max(0, state.top)
                if (Number.isFinite(state.right)) shell.panelRight = Math.max(0, state.right)
            } catch (e) { console.warn("Launcher state invalid:", e) }
        }
    }
    function refreshTheme() {
        try {
            const snapshot = JSON.parse(themeSnapshot.text())
            themeColors = snapshot.colors || {}
            themeVariant = snapshot.variant || "dark"
            const rawOpacity = snapshot.opacity !== undefined ? snapshot.opacity : snapshot.values && snapshot.values.TRANSPARENT
            const opacity = Number(rawOpacity)
            themeOpacity = rawOpacity !== undefined && rawOpacity !== null && Number.isFinite(opacity) ? Math.max(0, Math.min(1, opacity)) : 1
            const path = snapshot.values && snapshot.values.WALLPAPER || ""
            activeVideoPath = /\.(mp4|m4v|mkv|mov|webm)$/i.test(path) ? path : ""
            wallpaperPath = activeVideoPath || path === "none" ? "" : path
        } catch (e) {
            console.warn("Theme snapshot unavailable:", e)
        }
    }
    FileView {
        id: themeSnapshot
        path: "/home/chilly/.local/state/theme/active.json"
        watchChanges: true
        onLoaded: shell.refreshTheme()
        onFileChanged: reload()
    }
    onActiveVideoPathChanged: {
        videoStart.stop()
        videoWallpaper.running = false
        activeVideoStill = ""
        if (activeVideoPath) {
            stillRequest.command = ["python3", shell.backend, "video-still", activeVideoPath]
            stillRequest.running = true
        }
    }
    Process {
        id: stillRequest
        stdout: StdioCollector { onStreamFinished: {
            try {
                const result = JSON.parse(this.text)
                if (shell.activeVideoPath === result.source && result.still.endsWith(".jpg")) shell.activeVideoStill = result.still
            } catch (e) { console.warn("Invalid video still response") }
        } }
        stderr: StdioCollector { onStreamFinished: if (this.text.trim()) console.warn("Video still:", this.text.trim()) }
    }
    onActiveVideoStillChanged: if (activeVideoStill && activeVideoPath) videoStart.restart()
    Timer { id: videoStart; interval: 180; onTriggered: if (shell.activeVideoPath && shell.activeVideoStill) videoWallpaper.running = true }
    Process {
        id: videoWallpaper
        command: ["mpvpaper", "--auto-stop", "--auto-mode", "FULL", "--mpv-options", "no-audio loop-file=inf", "ALL", shell.activeVideoPath]
        stderr: StdioCollector { onStreamFinished: if (this.text.trim()) console.warn("mpvpaper:", this.text.trim()) }
    }
    property bool wifiEnabled: true
    property bool bluetoothEnabled: false
    readonly property string backend: Quickshell.shellPath("services/backend.py")
    // Apply theme alpha to backing surfaces only; content retains full contrast.
    readonly property bool lightTheme: themeVariant === "light"
    readonly property color surface: {
        const base = Qt.color(themeColor(lightTheme ? "BASE07" : "BASE01", "#1c1b24"))
        return Qt.rgba(base.r, base.g, base.b, themeOpacity)
    }
    // Local content cards retain contrast even when the outer glass is near clear.
    readonly property color readableSurface: {
        const base = Qt.color(themeColor(lightTheme ? "BASE06" : "BASE02", "#292832"))
        return Qt.rgba(base.r, base.g, base.b, Math.max(0.88, themeOpacity))
    }
    readonly property color inset: themeColor(lightTheme ? "BASE06" : "BASE02", "#292832")
    readonly property color raised: themeColor(lightTheme ? "BASE05" : "BASE03", "#35333e")
    readonly property color foreground: themeColor(lightTheme ? "BASE00" : "BASE06", "#f1eff5")
    readonly property color muted: themeColor(lightTheme ? "BASE03" : "BASE04", "#bcb8c6")
    readonly property color accent: themeColor(lightTheme ? "BASE0D" : "BASE0E", "#d4c4f4")
    readonly property color accentContainer: themeColor(lightTheme ? "BASE05" : "BASE03", "#49405b")
    readonly property color outline: themeColor("BORDER_COLOR", "#494652")

    function show(name) {
        if (page === name) { page = ""; return }
        popupReplyFocus = false
        page = name
        feedback = ""
        if (name === "launcher") { appRequest.running = true; launcherPanel.query = "" }
        if (name === "wallpapers") { wallRequest.running = true; wallFilter = ""; pendingWallDelete = "" }
        statusRequest.running = true
        if (name === "launcher") Qt.callLater(function() { launcherPanel.focusSearch() })
    }
    function act() {
        action.command = ["python3", backend, "action"].concat(Array.from(arguments))
        action.running = true
    }
    readonly property bool actionRunning: action.running
    readonly property bool searchRunning: webRequest.running
    function searchWalls(query) { feedback = ""; webError = ""; webWalls = []; selectedWebWall = null; webRequest.command = ["python3", backend, "wall-search", webProvider, query]; webRequest.running = true }
    function refresh() { statusRequest.running = true }

    Process {
        id: appRequest
        command: ["python3", shell.backend, "apps"]
        stdout: StdioCollector { onStreamFinished: { try { shell.apps = JSON.parse(this.text) } catch (e) { shell.feedback = "Application index unavailable" } } }
    }
    Process {
        id: wallRequest
        command: ["python3", shell.backend, "walls"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                const inventory = JSON.parse(this.text)
                shell.walls = inventory.walls || []
                shell.wallCategories = inventory.categories || []
                shell.wallThemes = inventory.themes || []
                if (!shell.selectedTheme || !shell.wallThemes.some(function(t) { return t.name === shell.selectedTheme })) {
                    const active = shell.wallThemes.find(function(t) { return t.active })
                    shell.selectedTheme = active ? active.name : (shell.wallThemes.length ? shell.wallThemes[0].name : "")
                }
                if (!shell.selectedWall || !shell.walls.some(function(w) { return w.path === shell.selectedWall })) shell.selectedWall = shell.walls.length ? shell.walls[0].path : ""
            } catch (e) { shell.feedback = "Wallpapers unavailable" }
        } }
    }
    Process {
        id: webRequest
        stdout: StdioCollector { onStreamFinished: {
            try { const response = JSON.parse(this.text); shell.webWalls = response.results || []; shell.webError = response.error || ""; shell.selectedWebWall = shell.webWalls.length ? shell.webWalls[0] : null }
            catch (e) { shell.webError = "Search failed" }
        } }
    }
    Process {
        id: statusRequest
        command: ["python3", shell.backend, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    shell.info = JSON.parse(this.text)
                    shell.bluetoothEnabled = shell.info.bluetooth
                    shell.wifiEnabled = shell.info.wifiEnabled
                } catch (e) { shell.feedback = "System status unavailable" }
            }
        }
    }
    Process {
        id: action
        stdout: StdioCollector { onStreamFinished: {
            const result = this.text.trim()
            let message = result
            try { message = JSON.parse(result) } catch (e) {}
            shell.feedback = message
            if (action.command[3] === "wall-download" && typeof message === "string" && message.startsWith("/")) {
                shell.savedWebWall = message
                shell.savedWebId = action.command[5]
                shell.feedback = "Saved. Choose Set saved to apply to theme."
            }
            shell.refresh(); wallRequest.running = true
        } }
        stderr: StdioCollector { onStreamFinished: { if (this.text.trim()) shell.feedback = this.text.trim() } }
    }
    Timer { interval: 5000; running: shell.page !== ""; repeat: true; onTriggered: shell.refresh() }

    IpcHandler {
        target: "shell"
        function toggleLauncher() { shell.show("launcher") }
        function toggleSidePanel() { shell.show("dashboard") }
        function toggleControls() { shell.show("controls") }
        function toggleMedia() { shell.show("media") }
        function togglePower() { shell.show("power") }
        function toggleTodo() { shell.show("dashboard") }
        function toggleWallpapers() { shell.show("wallpapers") }
        function toggleStudioDock() { shell.toggleStudioDock() }
        function toggleNotifications() { shell.show("notifications") }
        function close() { shell.page = "" }
        function capture() { if (shell.page === "wallpapers") wallpaperStudio.capture("/tmp/quickshell-review") }
        function changeVolume(delta: string) { shell.changeVolume(delta) }
        function changeBrightness(delta: string) { shell.changeBrightness(delta) }
        function toggleScreenshot() { shell.show("screenshot") }
        function screenshot(scope: string, destination: string) { shell.screenshot(scope, destination) }
        function checkBigThinker() { if (!bigThinkerRequest.running) bigThinkerRequest.running = true }
    }

    WallpaperBackground { shellRoot: shell }
    NotificationPopup { shellRoot: shell }

    WallpaperStudio { id: wallpaperStudio; shellRoot: shell }

    DesktopOsd { shellRoot: shell }
    WorkspaceOsd { shellRoot: shell }

    NotificationCenter { shellRoot: shell }

    LauncherPanel { id: launcherPanel; shellRoot: shell }
    ScreenshotPanel { shellRoot: shell }
    ScreenshotEditor { shellRoot: shell }
}
