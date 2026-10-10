import "../components"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: osd
    required property var shellRoot
    property bool showing: false
    property int activeWorkspace: 1
    property int previousWorkspace: 1
    property bool transferring: false
    property int sourceWorkspace: 0
    property int destinationWorkspace: 0
    property string windowTitle: ""
    property string transferredIcon: ""
    property var windowCache: ({})
    property real transferProgress: 1
    property double lastTransfer: 0
    property string monitorName: ""
    readonly property bool motion: !shellRoot.reduceMotion
    readonly property real cellWidth: Math.min(76, ((screen ? screen.width : 1920) - 80) / 10 - 6)
    readonly property real cellStep: cellWidth + 6
    readonly property real stripWidth: cellStep * 10 - 6

    screen: {
        const name = monitorName || (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "")
        return Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0]
    }
    visible: showing || card.opacity > 0
    anchors { bottom: true; left: true }
    margins { bottom: 42; left: Math.max(0, ((screen ? screen.width : 1920) - implicitWidth) / 2) }
    implicitWidth: stripWidth + 56
    implicitHeight: osd.transferring ? 192 : 176
    color: "transparent"
    mask: Region {} // Completely passive: keep wallpaper scrolling and app input working.
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-workspace-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    function appIcon(win) {
        if (!win) return ""
        const appId = (win.wayland ? win.wayland.appId : "") || (win.lastIpcObject ? win.lastIpcObject.class : "") || ""
        const entry = DesktopEntries.heuristicLookup(appId)
        return Quickshell.iconPath(entry && entry.icon ? entry.icon : appId, true)
    }
    function normalizedAddress(address) { return address.replace(/^0x/, "").toLowerCase() }
    function refreshCache() {
        const cache = {}
        for (const win of Hyprland.toplevels.values) {
            cache[normalizedAddress(win.address)] = {
                workspace: win.workspace ? win.workspace.id : 0,
                title: win.title,
                icon: appIcon(win),
                monitor: win.monitor ? win.monitor.name : ""
            }
        }
        windowCache = cache
    }
    function reveal() { showing = true; hideTimer.restart() }
    function handleEvent(event) {
        if (event.name === "workspacev2") {
            const parts = event.parse(2)
            const next = Number(parts[0])
            if (!Number.isFinite(next) || next === activeWorkspace) return
            previousWorkspace = activeWorkspace
            activeWorkspace = next
            monitorName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
            // A non-silent move emits a workspace switch too. Keep its transfer feedback.
            if (Date.now() - lastTransfer > 250) transferring = false
            reveal()
        } else if (event.name === "movewindowv2") {
            const parts = event.parse(3)
            const address = normalizedAddress(parts[0])
            const destination = Number(parts[1])
            const old = windowCache[address]
            if (old && old.workspace !== destination && destination > 0 && old.workspace > 0) {
                transferring = true
                sourceWorkspace = old.workspace
                destinationWorkspace = destination
                windowTitle = old.title || "Window"
                transferredIcon = old.icon || ""
                monitorName = old.monitor
                lastTransfer = Date.now()
                reveal()
                transferPulse.restart()
                transferTravel.restart()
            }
            // Update immediately so repeated moves during a burst have the right source.
            if (old) {
                const cache = Object.assign({}, windowCache)
                cache[address] = { workspace: destination, title: old.title, icon: old.icon, monitor: old.monitor }
                windowCache = cache
            }
            cacheTimer.restart()
        } else if (event.name === "openwindow" || event.name === "closewindow" || event.name === "windowtitlev2") {
            cacheTimer.restart()
        }
    }
    Component.onCompleted: {
        activeWorkspace = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
        previousWorkspace = activeWorkspace
        refreshCache()
        cacheTimer.restart()
    }
    Connections {
        target: Hyprland.toplevels
        function onValuesChanged() { cacheTimer.restart() }
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) { osd.handleEvent(event) }
    }
    Timer { id: cacheTimer; interval: 70; onTriggered: osd.refreshCache() }
    Timer { id: hideTimer; interval: osd.transferring ? 1900 : 1200; onTriggered: osd.showing = false }

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 4
        radius: 22
        color: shellRoot.surface
        opacity: osd.showing ? 1 : 0
        scale: osd.showing ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: osd.motion ? 160 : 0; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: osd.motion ? 220 : 0; easing.type: Easing.OutCubic } }
        Rectangle {
            x: 16; y: 12
            width: heading.implicitWidth + 20; height: 32; radius: 14
            color: shellRoot.readableSurface
            Text {
                id: heading
                anchors.centerIn: parent
                text: osd.transferring ? "Window moved" : "Workspaces"
                color: shellRoot.foreground
                font.family: "Adwaita Sans"; font.pixelSize: 16; font.weight: Font.DemiBold
            }
        }
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: 24; y: 17
            width: routeLabel.implicitWidth + 22; height: 28; radius: 14
            color: shellRoot.inset
            Text {
                id: routeLabel
                anchors.centerIn: parent
                text: osd.transferring ? osd.sourceWorkspace + "  to  " + osd.destinationWorkspace : String(osd.activeWorkspace)
                color: shellRoot.muted
                font.family: "Adwaita Sans"; font.pixelSize: 12; font.weight: Font.Medium
            }
        }
        Item {
            id: strip
            x: 24; y: 62
            width: osd.stripWidth; height: 92
            Rectangle {
                visible: osd.activeWorkspace >= 1 && osd.activeWorkspace <= 10
                x: (Math.max(1, Math.min(10, osd.activeWorkspace)) - 1) * osd.cellStep
                width: osd.cellWidth; height: 92; radius: 18
                color: shellRoot.accentContainer
                Behavior on x { NumberAnimation { duration: osd.motion && osd.showing ? 240 : 0; easing.type: Easing.OutCubic } }
            }
            Repeater {
                model: 10
                delegate: Item {
                    id: cell
                    required property int index
                    readonly property int workspaceId: index + 1
                    readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === workspaceId) || null
                    readonly property int windowCount: workspace ? workspace.toplevels.values.length : 0
                    readonly property bool isSource: osd.transferring && workspaceId === osd.sourceWorkspace
                    readonly property bool isDestination: osd.transferring && workspaceId === osd.destinationWorkspace
                    x: index * osd.cellStep
                    width: osd.cellWidth; height: 92
                    Rectangle {
                        anchors.fill: parent; radius: 18
                        color: cell.isDestination ? shellRoot.accentContainer : shellRoot.readableSurface
                        opacity: cell.isDestination ? destinationPulse.opacity : cell.isSource ? 1 : cell.workspaceId === osd.activeWorkspace ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: osd.motion ? 160 : 0 } }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: cell.windowCount === 0 ? (cell.height - implicitHeight) / 2 : 13
                        text: cell.workspaceId
                        color: cell.workspaceId === osd.activeWorkspace || cell.isDestination ? shellRoot.foreground : shellRoot.muted
                        font.family: "Adwaita Sans"; font.pixelSize: 22
                        font.weight: cell.workspaceId === osd.activeWorkspace || cell.isDestination ? Font.DemiBold : Font.Normal
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter; y: 46; spacing: 4
                        Repeater {
                            model: cell.workspace ? cell.workspace.toplevels.values.slice(0, cell.windowCount > 3 ? 2 : 3) : []
                            ThemedAppIcon {
                                required property var modelData
                                shellRoot: osd.shellRoot
                                width: Math.min(21, (cell.width - 16) / 3); height: width
                                source: osd.appIcon(modelData)
                            }
                        }
                        Text {
                            visible: cell.windowCount > 3
                            text: "+" + (cell.windowCount - 2)
                            color: shellRoot.muted; font.family: "Adwaita Sans"; font.pixelSize: 10
                        }
                    }
                    Rectangle {
                        visible: cell.workspaceId === osd.activeWorkspace
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 86; width: 16; height: 3; radius: 1.5; color: shellRoot.accent
                    }
                }
            }
        }
        ThemedAppIcon {
            shellRoot: osd.shellRoot
            // The actual app icon travels between workspaces; no arrow or connecting line.
            visible: osd.transferring && osd.sourceWorkspace >= 1 && osd.sourceWorkspace <= 10 && osd.destinationWorkspace >= 1 && osd.destinationWorkspace <= 10
            x: strip.x + ((osd.sourceWorkspace - 1) + (osd.destinationWorkspace - osd.sourceWorkspace) * osd.transferProgress) * osd.cellStep + osd.cellWidth / 2 - width / 2
            y: strip.y + 94
            width: 28; height: 28; radius: 9
            source: osd.transferredIcon

        }

    }
    NumberAnimation {
        id: transferTravel
        target: osd; property: "transferProgress"
        from: 0; to: 1; duration: osd.motion ? 650 : 0
        easing.type: Easing.InOutCubic
    }
    QtObject { id: destinationPulse; property real opacity: 1 }
    SequentialAnimation {
        id: transferPulse
        NumberAnimation { target: destinationPulse; property: "opacity"; from: 0.3; to: 1; duration: osd.motion ? 250 : 0 }
        NumberAnimation { target: destinationPulse; property: "opacity"; to: 0.4; duration: osd.motion ? 250 : 0 }
        NumberAnimation { target: destinationPulse; property: "opacity"; to: 1; duration: osd.motion ? 250 : 0 }
    }
}
