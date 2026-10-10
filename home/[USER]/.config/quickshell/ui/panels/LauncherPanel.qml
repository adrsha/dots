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

import "../components"

    PanelWindow {
        id: panel
        property var shellRoot
        FontLoader { id: symbols; source: Qt.resolvedUrl("../../assets/fonts/MaterialSymbolsRounded.ttf") }
        property alias query: search.text
        function focusSearch() { search.forceActiveFocus() }
        visible: ["launcher", "dashboard", "controls", "media", "power"].includes(shellRoot.page)
        anchors { top: true; right: true }
        margins { top: Math.min(shellRoot.panelTop, Math.max(0, (screen ? screen.height : 1080) - height)); right: Math.min(shellRoot.panelRight, Math.max(0, (screen ? screen.width : 1920) - width)) }
        implicitWidth: Math.min(shellRoot.launcherWidth, screen ? screen.width - 16 : shellRoot.launcherWidth)
        implicitHeight: Math.min(shellRoot.launcherHeight, screen ? screen.height - 16 : shellRoot.launcherHeight)
        color: "transparent"
        WlrLayershell.namespace: "quickshell"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Rectangle {
            id: panelSurface
            anchors.fill: parent
            radius: 22
            color: shellRoot.surface
            border.width: 0
            MouseArea {
                id: panelDrag
                anchors.fill: parent
                cursorShape: Qt.OpenHandCursor
                onPressed: mouse => { shellRoot.startDrag(panelDrag, mouse); cursorShape = Qt.ClosedHandCursor }
                onPositionChanged: mouse => shellRoot.dragPanel(panelDrag, mouse)
                onReleased: { cursorShape = Qt.OpenHandCursor; shellRoot.saveLauncherState() }
            }
        }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16
            RowLayout {
                visible: shellRoot.page !== "dashboard"
                Layout.fillWidth: true
                Layout.rightMargin: shellRoot.page === "launcher" ? 76 : 40
                ColumnLayout {
                    Layout.fillWidth: true
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: headerLabels.implicitHeight + 16
                        radius: 14
                        color: "transparent"
                        Column {
                            id: headerLabels
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 3
                            Text { text: ({ launcher: "Applications", controls: "Quick controls", wallpapers: "Wallpapers", media: "Now playing", notifications: "Notifications", power: "Session", screenshot: "Take screenshot" })[shellRoot.page] || "Space"; color: shellRoot.foreground; font.pixelSize: 22; font.weight: Font.DemiBold }
                            Text { text: shellRoot.page === "launcher" ? shellRoot.filteredApps.length + " installed apps" : shellRoot.info.window || "Desktop"; color: shellRoot.muted; font.pixelSize: 12; elide: Text.ElideRight; width: parent.width }
                        }
                    }
                }
            }
            StudioField { normalModeKey: shellRoot.normalModeKey; jkTimeoutMs: shellRoot.jkTimeoutMs;
                borderless: true
                id: search
                Layout.fillWidth: true
                visible: shellRoot.page === "launcher"
                placeholderText: shellRoot.page === "launcher" ? "Search installed apps…" : "Filter local wallpapers…"
                reduceMotion: shellRoot.reduceMotion
                inkColor: shellRoot.foreground
                hintColor: shellRoot.muted
                surfaceColor: shellRoot.inset
                focusColor: shellRoot.raised
                leftPadding: 40
                rightPadding: 14
                topPadding: 9
                bottomPadding: 9
                cornerRadius: 17
                leadingIcon: "⌕"
                onAccepted: {
                    if (shellRoot.page === "launcher" && shellRoot.filteredApps.length) {
                        const index = Math.max(0, Math.min(shellRoot.launcherGrid ? appGrid.currentIndex : appList.currentIndex, shellRoot.filteredApps.length - 1))
                        shellRoot.act("launch", shellRoot.filteredApps[index].id)
                        shellRoot.page = ""
                    }
                }
                Keys.onPressed: event => {
                    if (shellRoot.page === "launcher" && shellRoot.filteredApps.length > 0) {
                        const grid = shellRoot.launcherGrid
                        const columns = Math.max(1, Math.floor(appGrid.width / appGrid.cellWidth))
                        const step = event.key === Qt.Key_Down ? (grid ? columns : 1) : event.key === Qt.Key_Up ? (grid ? -columns : -1) : event.key === Qt.Key_Right && grid ? 1 : event.key === Qt.Key_Left && grid ? -1 : 0
                        if (step !== 0) {
                            const view = grid ? appGrid : appList
                            view.currentIndex = Math.max(0, Math.min(shellRoot.filteredApps.length - 1, view.currentIndex + step))
                            view.positionViewAtIndex(view.currentIndex, grid ? GridView.Contain : ListView.Contain)
                            event.accepted = true
                        }
                    }
                }
                onTextChanged: { appList.currentIndex = 0; appGrid.currentIndex = 0 }
                Keys.onEscapePressed: event => { panel.contentItem.forceActiveFocus(); event.accepted = true }
            }
            Flickable {
                id: contentScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: sections.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                MouseArea {
                    id: contentDrag
                    width: parent.width
                    height: Math.max(parent.height, sections.implicitHeight)
                    cursorShape: Qt.OpenHandCursor
                    preventStealing: true
                    onPressed: mouse => { shellRoot.startDrag(contentDrag, mouse); cursorShape = Qt.ClosedHandCursor }
                    onPositionChanged: mouse => shellRoot.dragPanel(contentDrag, mouse)
                    onReleased: { cursorShape = Qt.OpenHandCursor; shellRoot.saveLauncherState() }
                }
                Column {
                    id: sections
                    width: parent.width
                    spacing: 14
                    Column {
                        visible: shellRoot.page === "dashboard"
                        width: parent.width
                        spacing: 6
                        Text { text: "WORKSPACE  " + (shellRoot.info.workspace || "—"); color: shellRoot.accent; font.letterSpacing: 2; font.pixelSize: 12 }
                        Tile { shellRoot: panel.shellRoot; title: "Focused window"; subtitle: shellRoot.page === "launcher" ? shellRoot.filteredApps.length + " apps · Find your next task" : shellRoot.info.window || "Desktop"; onActivated: shellRoot.page = "" }
                        Grid {
                            width: parent.width; columns: width >= 440 ? 3 : 2; spacing: 10
                            Tile { stacked: true; width: (parent.width - parent.spacing * (parent.columns - 1)) / parent.columns; shellRoot: panel.shellRoot; title: "Applications"; subtitle: "Launch installed apps"; onActivated: shellRoot.show("launcher") }
                            Tile { stacked: true; width: (parent.width - parent.spacing * (parent.columns - 1)) / parent.columns; shellRoot: panel.shellRoot; title: "Quick controls"; subtitle: "Network · Bluetooth · Volume"; onActivated: shellRoot.show("controls") }
                            Tile { stacked: true; width: (parent.width - parent.spacing * (parent.columns - 1)) / parent.columns; shellRoot: panel.shellRoot; title: "Wallpaper studio"; subtitle: "Browse your local collection"; onActivated: shellRoot.show("wallpapers") }
                            Tile { stacked: true; width: (parent.width - parent.spacing * (parent.columns - 1)) / parent.columns; shellRoot: panel.shellRoot; title: "Music"; subtitle: shellRoot.info.track || "Nothing playing"; onActivated: shellRoot.show("media") }
                            Tile { stacked: true; width: (parent.width - parent.spacing * (parent.columns - 1)) / parent.columns; shellRoot: panel.shellRoot; title: "Notifications"; subtitle: "Open notification history"; onActivated: shellRoot.show("notifications") }
                            Tile { stacked: true; width: (parent.width - parent.spacing * (parent.columns - 1)) / parent.columns; shellRoot: panel.shellRoot; title: "Session"; subtitle: "Secure lock · Power"; onActivated: shellRoot.show("power") }
                        }
                    }
                    Grid {
                        visible: shellRoot.page === "controls"
                        width: parent.width
                        columns: width >= 440 ? 3 : 2
                        spacing: 10
                        Tile { stacked: true; width: (parent.width - parent.spacing * (parent.columns - 1)) / parent.columns; shellRoot: panel.shellRoot; title: "Wi-Fi"; selected: shellRoot.wifiEnabled; subtitle: shellRoot.wifiEnabled ? (shellRoot.info.wifi || "Disconnected") : "Off"; onActivated: shellRoot.act("wifi", shellRoot.wifiEnabled ? "off" : "on") }
                        Tile { stacked: true; width: (parent.width - parent.spacing * (parent.columns - 1)) / parent.columns; shellRoot: panel.shellRoot; title: "Bluetooth"; selected: shellRoot.bluetoothEnabled; subtitle: shellRoot.bluetoothEnabled ? "On" : "Off"; onActivated: shellRoot.act("bluetooth", shellRoot.bluetoothEnabled ? "off" : "on") }
                        Tile { stacked: true; width: (parent.width - parent.spacing * (parent.columns - 1)) / parent.columns; shellRoot: panel.shellRoot; title: "Volume up"; subtitle: shellRoot.info.volume || "Increase 5%"; onActivated: shellRoot.changeVolume(5) }
                        Tile { stacked: true; width: (parent.width - parent.spacing * (parent.columns - 1)) / parent.columns; shellRoot: panel.shellRoot; title: "Volume down"; onActivated: shellRoot.changeVolume(-5) }
                        Tile { stacked: true; width: (parent.width - parent.spacing * (parent.columns - 1)) / parent.columns; shellRoot: panel.shellRoot; title: "Brightness down"; subtitle: "Decrease 5%"; onActivated: shellRoot.changeBrightness(-5) }
                        Tile { stacked: true; width: (parent.width - parent.spacing * (parent.columns - 1)) / parent.columns; shellRoot: panel.shellRoot; title: "Brightness up"; subtitle: "Increase 5%"; onActivated: shellRoot.changeBrightness(5) }
                        Tile { stacked: true; width: (parent.width - parent.spacing * (parent.columns - 1)) / parent.columns; shellRoot: panel.shellRoot; title: "Network settings"; subtitle: "Connection settings"; onActivated: shellRoot.feedback = "Run nmtui in your terminal to connect securely" }
                    }
                    Column {
                        visible: shellRoot.page === "media"
                        width: parent.width
                        spacing: 6
                        Text { text: shellRoot.info.track || "Nothing playing"; color: shellRoot.foreground; font.pixelSize: 20; wrapMode: Text.Wrap; width: parent.width }
                        Tile { shellRoot: panel.shellRoot; title: "Previous"; onActivated: shellRoot.act("media", "previous") }
                        Tile { shellRoot: panel.shellRoot; title: "Play / pause"; onActivated: shellRoot.act("media", "play-pause") }
                        Tile { shellRoot: panel.shellRoot; title: "Next"; onActivated: shellRoot.act("media", "next") }
                        Text { text: "Lyrics need configured provider or local synchronized LRC files."; color: shellRoot.muted; wrapMode: Text.Wrap; width: parent.width }
                    }
                    Column {
                        visible: shellRoot.page === "power"
                        width: parent.width
                        spacing: 6
                        Tile { shellRoot: panel.shellRoot; title: "Lock screen"; subtitle: "Secure locker required; never a dismissible overlay"; onActivated: shellRoot.act("lock") }
                        Text { text: "Power off and reboot remain available through existing Hyprland shortcuts."; color: shellRoot.muted; wrapMode: Text.Wrap; width: parent.width }
                    }
                    ListView {
                        id: appList
                        visible: shellRoot.page === "launcher" && !shellRoot.launcherGrid
                        width: parent.width
                        height: visible ? Math.min(contentHeight, Math.max(120, panel.height - 160)) : 0
                        interactive: true
                        model: shellRoot.filteredApps
                        spacing: 8
                        onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)
                        delegate: Rectangle {
                            id: appRow
                            required property var modelData
                            required property int index
                            width: appList.width
                            height: 76
                            radius: 20
                            color: appList.currentIndex === index || appHover.containsMouse ? shellRoot.accentContainer : shellRoot.readableSurface
                            border.width: 0
                            border.color: shellRoot.accent
                            Behavior on color { ColorAnimation { duration: shellRoot.reduceMotion ? 0 : 140 } }
                            function launch() { shellRoot.act("launch", modelData.id); shellRoot.page = "" }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 14
                                ThemedAppIcon {
                                    shellRoot: panel.shellRoot
                                    Layout.preferredWidth: 44; Layout.preferredHeight: 44
                                    Layout.alignment: Qt.AlignVCenter
                                    source: appRow.modelData.icon ? "file://" + appRow.modelData.icon : ""
                                }
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { text: appRow.modelData.name; color: shellRoot.foreground; font.family: "Adwaita Sans"; font.pixelSize: 16; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                                    Text { visible: !!appRow.modelData.description; text: appRow.modelData.description || ""; color: shellRoot.muted; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                            }
                            MouseArea { id: appHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { appList.currentIndex = appRow.index; appRow.launch() } }
                        }
                    }
                    GridView {
                        id: appGrid
                        visible: shellRoot.page === "launcher" && shellRoot.launcherGrid
                        width: parent.width
                        height: visible ? Math.min(contentHeight, Math.max(120, panel.height - 160)) : 0
                        clip: true
                        model: shellRoot.filteredApps
                        cellWidth: width / Math.max(1, Math.floor(width / 112))
                        cellHeight: 132
                        delegate: Item {
                            id: gridCell
                            required property var modelData
                            required property int index
                            width: appGrid.cellWidth
                            height: appGrid.cellHeight
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 5
                                radius: 14
                                color: gridHover.containsMouse || appGrid.currentIndex === gridCell.index ? shellRoot.accentContainer : shellRoot.readableSurface
                                border.width: 0
                                border.color: shellRoot.accent
                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.topMargin: 17
                                    width: parent.width - 16
                                    spacing: 7
                                    ThemedAppIcon {
                                        shellRoot: panel.shellRoot
                                        width: 52; height: 52
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        source: gridCell.modelData.icon ? "file://" + gridCell.modelData.icon : ""
                                    }
                                    Text {
                                        text: gridCell.modelData.name
                                        width: parent.width
                                        color: shellRoot.foreground
                                        font.pixelSize: 12
                                        height: 28
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }
                                }
                                MouseArea {
                                    id: gridHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        appGrid.currentIndex = gridCell.index
                                        shellRoot.act("launch", gridCell.modelData.id)
                                        shellRoot.page = ""
                                    }
                                }
                            }
                        }
                    }
                    Text {
                        visible: shellRoot.page === "launcher" && shellRoot.apps.length > 0 && shellRoot.filteredApps.length === 0
                        text: "No matching applications"
                        color: shellRoot.muted
                        font.pixelSize: 13
                        leftPadding: 12
                    }
                }
            }
            Text { visible: shellRoot.feedback !== ""; text: shellRoot.feedback; color: shellRoot.accent; wrapMode: Text.Wrap; Layout.fillWidth: true; font.pixelSize: 12 }
            Rectangle {
                Layout.alignment: Qt.AlignRight
                implicitWidth: Math.min(keyboardHint.implicitWidth + 20, Math.max(0, panel.width - 48))
                implicitHeight: 30
                radius: 12
                color: shellRoot.readableSurface
                Text {
                    id: keyboardHint
                    anchors.centerIn: parent
                    width: parent.width - 20
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: "h j k l · Move    Enter · Open    / · Search    Esc · Close"
                    color: shellRoot.muted
                    font.pixelSize: 11
                }
            }
        }
        Rectangle {
            visible: shellRoot.page === "launcher"
            anchors.top: parent.top
            anchors.right: closeButton.left
            anchors.topMargin: 12
            anchors.rightMargin: 6
                width: 32
                height: 32
                radius: 16
                color: viewHover.containsMouse ? shellRoot.accentContainer : shellRoot.inset
            Text { anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: shellRoot.launcherGrid ? "\ue8ef" : "\ue9b0"; font.family: symbols.name; color: shellRoot.foreground; font.pixelSize: 22 }
            MouseArea {
                id: viewHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { shellRoot.launcherGrid = !shellRoot.launcherGrid; shellRoot.saveLauncherState(); search.forceActiveFocus() }
            }
        }
        Rectangle {
            id: closeButton
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 12
            width: 32
            height: 32
            radius: 16
            color: closeHover.containsMouse ? shellRoot.accentContainer : shellRoot.inset
            Text { anchors.centerIn: parent; text: "×"; color: shellRoot.foreground; font.pixelSize: 20 }
            MouseArea { id: closeHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.page = "" }
        }
        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 5
            width: 26
            height: 26
            color: "transparent"
            Text { anchors.centerIn: parent; text: "◢"; color: shellRoot.muted; font.pixelSize: 15 }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeBDiagCursor
                property real startX
                property real startY
                property int startWidth
                property int startHeight
                onPressed: mouse => {
                    const pointer = mapToGlobal(mouse.x, mouse.y)
                    startX = pointer.x; startY = pointer.y
                    startWidth = panel.width; startHeight = panel.height
                }
                onPositionChanged: mouse => {
                    if (!pressed) return
                    const pointer = mapToGlobal(mouse.x, mouse.y)
                    shellRoot.launcherWidth = Math.max(320, Math.min(panel.screen ? panel.screen.width - 16 : 1000, startWidth + startX - pointer.x))
                    shellRoot.launcherHeight = Math.max(280, Math.min(panel.screen ? panel.screen.height - 16 : 1400, startHeight + pointer.y - startY))
                }
                onReleased: shellRoot.saveLauncherState()
            }
        }
        VimNavigation {
            id: navigation
            window: panel
            moveHandler: shellRoot.page === "launcher" ? function(delta, vertical) {
                const stride = shellRoot.launcherGrid && vertical ? Math.max(1, Math.floor(appGrid.width / appGrid.cellWidth)) : 1
                const view = shellRoot.launcherGrid ? appGrid : appList
                view.currentIndex = Math.max(0, Math.min(shellRoot.filteredApps.length - 1, view.currentIndex + delta * stride))
                view.positionViewAtIndex(view.currentIndex, shellRoot.launcherGrid ? GridView.Contain : ListView.Contain)
            } : null
            boundaryHandler: shellRoot.page === "launcher" ? function(last) {
                const view = shellRoot.launcherGrid ? appGrid : appList
                view.currentIndex = last ? shellRoot.filteredApps.length - 1 : 0
                view.positionViewAtIndex(view.currentIndex, shellRoot.launcherGrid ? GridView.Contain : ListView.Contain)
            } : null
            activateHandler: shellRoot.page === "launcher" ? function() {
                const view = shellRoot.launcherGrid ? appGrid : appList
                if (!shellRoot.filteredApps[view.currentIndex]) return
                shellRoot.act("launch", shellRoot.filteredApps[view.currentIndex].id)
                shellRoot.page = ""
            } : null
            searchHandler: shellRoot.page === "launcher" ? function() { search.forceActiveFocus() } : null
        }
    }
