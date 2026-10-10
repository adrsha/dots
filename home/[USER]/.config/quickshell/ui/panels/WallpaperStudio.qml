import QtQuick
import "../components"
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: studio
    property var shellRoot
    visible: shellRoot && shellRoot.page === "wallpapers"
    anchors { left: true; right: true; top: true; bottom: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-wallpaper-studio"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    readonly property var selected: shellRoot ? shellRoot.walls.find(function(w) { return w.path === shellRoot.selectedWall }) : null
    readonly property string previewSource: !selected || selected.video && selected.preview === selected.path ? "" : "file://" + selected.preview
    readonly property bool videoSelected: !!selected && selected.video
    readonly property real imageRatio: preview.status === Image.Ready && preview.implicitHeight > 0 ? preview.implicitWidth / preview.implicitHeight : selected && selected.width > 0 && selected.height > 0 ? selected.width / selected.height : 16 / 9
    property string displayedPreview: ""
    function fadePreview() {
        if (preview.status !== Image.Ready || String(preview.source) !== studio.previewSource) return
        if (studio.reduceMotion || !studio.displayedPreview) { preview.opacity = 1; studio.displayedPreview = String(preview.source) }
        else previewFade.start()
    }
    property var previewPalette: ({})
    readonly property string paletteSource: shellRoot.webMode ? (shellRoot.selectedWebWall ? shellRoot.selectedWebWall.preview : "") : (selected ? selected.preview : "")
    readonly property string paletteKey: paletteSource + "|" + shellRoot.themeVariant
    onPaletteKeyChanged: { previewPalette = ({}); paletteDelay.restart() }
    onVisibleChanged: if (visible) paletteDelay.restart()
    function previewColor(key, fallback) { return previewPalette[key] || fallback }
    readonly property var colors: QtObject {
        readonly property color surface: {
            const c = Qt.color(studio.previewColor("BASE01", shellRoot.surface))
            return Qt.rgba(c.r, c.g, c.b, shellRoot.themeOpacity)
        }
        readonly property color readableSurface: {
            const c = Qt.color(studio.previewColor("BASE02", shellRoot.readableSurface))
            return Qt.rgba(c.r, c.g, c.b, Math.max(0.88, shellRoot.themeOpacity))
        }
        readonly property color inset: studio.previewColor("BASE02", shellRoot.inset)
        readonly property color raised: studio.previewColor("BASE03", shellRoot.raised)
        readonly property color foreground: studio.previewColor(shellRoot.lightTheme ? "BASE07" : "BASE06", shellRoot.foreground)
        readonly property color muted: studio.previewColor("BASE04", shellRoot.muted)
        readonly property color accent: studio.previewColor(shellRoot.lightTheme ? "BASE0D" : "BASE0E", shellRoot.accent)
        readonly property color accentContainer: studio.previewColor(shellRoot.lightTheme ? "BASE02" : "BASE03", shellRoot.accentContainer)
        readonly property color outline: studio.previewColor("BASE03", shellRoot.outline)
    }
    Timer {
        id: paletteDelay; interval: 180
        onTriggered: {
            if (!studio.visible || !studio.paletteSource) return
            if (paletteRequest.running) { restart(); return }
            paletteRequest.requestKey = studio.paletteKey
            paletteRequest.command = ["python3", shellRoot.backend, "wall-palette", studio.paletteSource, shellRoot.themeVariant]
            paletteRequest.running = true
        }
    }
    Process {
        id: paletteRequest
        property string requestKey: ""
        stdout: StdioCollector {
            onStreamFinished: {
                if (paletteRequest.requestKey !== studio.paletteKey) return
                try { const response = JSON.parse(text); studio.previewPalette = response.palette || ({}) }
                catch (error) { console.warn("Wallpaper palette:", error) }
            }
        }
    }
    readonly property int dockHeight: Math.min(420, Math.max(320, height * 0.40))
    readonly property int discoverWidth: Math.min(390, Math.max(310, width * 0.28))
    property bool reduceMotion: shellRoot ? shellRoot.reduceMotion : false
    function capture(path) { (shellRoot.webMode ? discoverPanel : dock).grabToImage(function(result) { result.saveToFile(path + "-dock.png") }); (shellRoot.webMode ? discoverResults : stage).grabToImage(function(result) { result.saveToFile(path + "-stage.png") }) }
    function doSearch() { shellRoot.searchWalls(shellRoot.webMode ? discoverSearch.text : searchText.text) }
    function stepGallery(direction) {
        if (shellRoot.webMode) {
            if (!shellRoot.webWalls.length) return
            const selectedIndex = shellRoot.webWalls.findIndex(function(w) { return shellRoot.selectedWebWall && w.id === shellRoot.selectedWebWall.id })
            shellRoot.selectedWebWall = shellRoot.webWalls[Math.max(0, Math.min(shellRoot.webWalls.length - 1, selectedIndex + direction))]
            return
        }
        if (!gallery.sourceWalls.length) return
        selectionSettler.stop()
        const middle = Math.floor(gallery.cycleCount / 2) * gallery.sourceWalls.length
        const from = gallery.selectedIndex >= 0 ? gallery.selectedIndex : middle
        const next = gallery.sourceWalls.length === 1 ? from : Math.max(0, Math.min(gallery.loopedWalls.length - 1, from + direction))
        gallery.keyboardNavigating = true
        gallery.currentIndex = next
        choose(next)
        Qt.callLater(function() {
            if (!gallery.keyboardNavigating || !gallery.currentItem) return
            galleryScroll.stop()
            galleryScroll.from = gallery.contentX
            galleryScroll.to = Math.max(0, Math.min(gallery.contentWidth - gallery.width, gallery.currentItem.x + gallery.currentItem.width / 2 - gallery.width / 2))
            gallery.contentX = galleryScroll.to
            gallery.keyboardNavigating = false
        })
    }
    function choose(index) {
        if (index < 0 || !gallery.sourceWalls.length) return
        const logical = index % gallery.sourceWalls.length
        const item = gallery.sourceWalls[logical]
        if (!item) return
        gallery.selectedIndex = index
        if (shellRoot.webMode) shellRoot.selectedWebWall = item
        else shellRoot.selectedWall = item.path
        // Recenter near either end only; wrapping must not interrupt ordinary scrolling.
        const count = gallery.sourceWalls.length
        if (count > 1 && !gallery.keyboardNavigating && (index < count || index >= (gallery.cycleCount - 1) * count)) {
            const middle = Math.floor(gallery.cycleCount / 2) * count + logical
            gallery.currentIndex = middle
            gallery.selectedIndex = middle
            gallery.positionViewAtIndex(middle, ListView.Center)
        }
    }

    Item {
        id: stage
        visible: !shellRoot.webMode
        x: shellRoot.webMode ? (shellRoot.studioDiscoverRight ? -studio.width : studio.width) : 0
        y: shellRoot.studioDockTop ? studio.dockHeight : 0
        width: studio.width
        height: Math.max(0, studio.height - studio.dockHeight)
        clip: true
        Rectangle { anchors.fill: parent; color: "transparent" }
        Image {
            id: backdrop
            anchors.fill: parent
            source: studio.previewSource
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 1200
            asynchronous: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: backdrop
            blurEnabled: true
            blurMax: 48
            blur: 1
            visible: backdrop.status === Image.Ready
        }
        Rectangle { anchors.fill: parent; color: colors.surface }
        Item {
            id: imageArea
            anchors.centerIn: parent
            height: Math.max(0, Math.min(stage.height - 90, (stage.width - 64) / studio.imageRatio))
            width: height * studio.imageRatio
            layer.enabled: true
            layer.effect: MultiEffect { maskEnabled: true; maskSource: previewMask; maskThresholdMin: 0.5; maskSpreadAtMin: 0 }
            Rectangle { id: previewMask; anchors.fill: parent; radius: 18; color: "white"; visible: false; layer.enabled: true }
            Image {
                anchors.fill: parent
                source: studio.displayedPreview
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                sourceSize.width: 1600
                visible: !studio.videoSelected && source !== ""
            }
            Image {
                id: preview
                anchors.fill: parent
                source: studio.previewSource
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                sourceSize.width: 1600
                opacity: 0
                visible: !studio.videoSelected && status === Image.Ready
                onSourceChanged: { previewFade.stop(); opacity = 0; Qt.callLater(studio.fadePreview) }
                onStatusChanged: if (status === Image.Ready) Qt.callLater(studio.fadePreview)
                NumberAnimation { id: previewFade; target: preview; property: "opacity"; from: 0; to: 1; duration: studio.reduceMotion ? 0 : 120; easing.type: Easing.OutCubic; onFinished: if (String(preview.source) === studio.previewSource) studio.displayedPreview = String(preview.source) }
            }
            Video {
                anchors.fill: parent
                visible: studio.videoSelected && studio.visible
                source: visible ? "file://" + studio.selected.path : ""
                fillMode: VideoOutput.PreserveAspectFit
                loops: MediaPlayer.Infinite
                muted: true
                onVisibleChanged: { if (visible) play(); else stop() }
                onSourceChanged: if (visible) play()
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            text: studio.selected ? "Local preview  ·  Assign to apply" : "Choose a wallpaper below"
            color: "#e8e7ee"; font.family: "Adwaita Sans"; font.pixelSize: 12
        }
    }

    Rectangle {
        id: dock
        visible: !shellRoot.webMode
        x: shellRoot.webMode ? (shellRoot.studioDiscoverRight ? -studio.width : studio.width) : 0
        y: shellRoot.studioDockTop ? 0 : studio.height - studio.dockHeight
        width: studio.width
        height: studio.dockHeight
        color: "transparent"
        // One backing layer avoids doubled alpha at the dock edges.
        Rectangle {
            anchors.fill: parent
            color: colors.surface
            topLeftRadius: shellRoot.studioDockTop ? 0 : 28
            topRightRadius: shellRoot.studioDockTop ? 0 : 28
            bottomLeftRadius: shellRoot.studioDockTop ? 28 : 0
            bottomRightRadius: shellRoot.studioDockTop ? 28 : 0
        }
        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 24; anchors.rightMargin: 24
            anchors.topMargin: 14; anchors.bottomMargin: 14
            spacing: 9
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 1
                    Text { text: "Wallpaper studio"; color: colors.foreground; font.family: "Adwaita Sans"; font.pixelSize: 21; font.weight: Font.DemiBold }
                    Text { text: shellRoot.webMode ? "Discover · preview before downloading" : "Local collection · preview before applying"; color: colors.muted; font.family: "Adwaita Sans"; font.pixelSize: 12 }
                }
                StyledButton { borderless: true; text: shellRoot.studioDockTop ? "↓" : "↑"; ToolTip.visible: hovered; ToolTip.text: shellRoot.studioDockTop ? "Move dock to bottom" : "Move dock to top"; reduceMotion: studio.reduceMotion; surfaceColor: colors.inset; hoverColor: colors.raised; pressedColor: colors.accentContainer; textColor: colors.foreground; onClicked: shellRoot.toggleStudioDock() }
                StyledButton { borderless: true; text: "Close ×"; surfaceColor: colors.inset; hoverColor: colors.raised; pressedColor: colors.accentContainer; textColor: colors.foreground; onClicked: shellRoot.page = "" }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                StyledButton { borderless: true; text: "Discover →"; surfaceColor: colors.inset; hoverColor: colors.raised; pressedColor: colors.accentContainer; textColor: colors.foreground; onClicked: { shellRoot.webMode = true; shellRoot.pendingWallDelete = "" } }
                StudioField { normalModeKey: shellRoot.normalModeKey; jkTimeoutMs: shellRoot.jkTimeoutMs; borderless: true; id: searchText; reduceMotion: studio.reduceMotion; Layout.fillWidth: true; placeholderText: shellRoot.webMode ? "Search landscapes, illustration, architecture…" : "Filter local wallpapers…"; text: shellRoot.webMode ? "" : shellRoot.wallFilter; onTextChanged: if (!shellRoot.webMode) shellRoot.wallFilter = text; onAccepted: if (shellRoot.webMode) studio.doSearch(); Keys.onEscapePressed: event => { studio.contentItem.forceActiveFocus(); event.accepted = true }; surfaceColor: colors.inset; focusColor: colors.raised; inkColor: colors.foreground; hintColor: colors.muted }
                StudioPicker { borderless: true; visible: shellRoot.webMode; Layout.preferredWidth: 142; model: ["wallhaven", "unsplash", "pexels", "pexels-video"]; surfaceColor: colors.inset; hoverColor: colors.raised; inkColor: colors.foreground; hintColor: colors.muted; onActivated: { shellRoot.webProvider = currentText; shellRoot.webWalls = []; shellRoot.selectedWebWall = null; shellRoot.webError = "" } }
                StudioPicker { borderless: true; visible: !shellRoot.webMode; Layout.preferredWidth: 135; model: ["All"].concat(shellRoot.wallCategories); surfaceColor: colors.inset; hoverColor: colors.raised; inkColor: colors.foreground; hintColor: colors.muted; onCurrentTextChanged: shellRoot.selectedCategory = currentText }
                StyledButton { borderless: true; visible: shellRoot.webMode; text: "Search"; enabled: !shellRoot.searchRunning; surfaceColor: colors.accentContainer; hoverColor: colors.raised; pressedColor: colors.inset; textColor: colors.foreground; onClicked: studio.doSearch() }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                ColumnLayout {
                    Layout.fillWidth: true; Layout.alignment: Qt.AlignBottom; spacing: 1
                    Text { text: studio.selected ? (shellRoot.webMode ? studio.selected.title : studio.selected.name) : "No wallpaper selected"; color: colors.foreground; font.family: "Adwaita Sans"; font.pixelSize: 16; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                    Text { text: !studio.selected ? "Search or browse the collection" : shellRoot.webMode ? studio.selected.author + "  ·  " + studio.selected.width + " × " + studio.selected.height + "  ·  " + studio.selected.license : studio.selected.category + (studio.selected.video ? "  ·  Video" : "  ·  Image"); color: colors.muted; font.family: "Adwaita Sans"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                }
                ColumnLayout { visible: shellRoot.webMode; Layout.alignment: Qt.AlignBottom; spacing: 2
                    Text { text: "SAVE TO"; color: colors.muted; font.pixelSize: 10; font.letterSpacing: 1 }
                    StudioPicker { borderless: true; id: downloadCategory; Layout.preferredWidth: 135; model: shellRoot.wallCategories; surfaceColor: colors.inset; hoverColor: colors.raised; inkColor: colors.foreground; hintColor: colors.muted }
                }
                ColumnLayout { Layout.alignment: Qt.AlignBottom; spacing: 2
                    Text { text: "APPLY WITH THEME"; color: colors.muted; font.pixelSize: 10; font.letterSpacing: 1 }
                    StudioPicker { borderless: true; id: themePicker; reduceMotion: studio.reduceMotion; Layout.preferredWidth: 160; model: shellRoot.wallThemes.map(function(t) { return t.name }); surfaceColor: colors.inset; hoverColor: colors.raised; inkColor: colors.foreground; hintColor: colors.muted; onActivated: shellRoot.selectedTheme = currentText
                        Connections { target: shellRoot; function onSelectedThemeChanged() { const i = themePicker.model.indexOf(shellRoot.selectedTheme); if (i >= 0) themePicker.currentIndex = i } }
                    }
                }
                StyledButton { borderless: true; Layout.alignment: Qt.AlignBottom; visible: shellRoot.webMode; text: "Source ↗"; enabled: !!studio.selected; surfaceColor: colors.inset; hoverColor: colors.raised; pressedColor: colors.accentContainer; textColor: colors.foreground; onClicked: Qt.openUrlExternally(studio.selected.source) }
                StyledButton { borderless: true; Layout.alignment: Qt.AlignBottom; visible: shellRoot.webMode; text: "Set saved"; enabled: !!studio.selected && shellRoot.savedWebId === studio.selected.id && shellRoot.savedWebWall !== "" && !!shellRoot.selectedTheme && !shellRoot.actionRunning; surfaceColor: colors.inset; hoverColor: colors.raised; pressedColor: colors.accentContainer; textColor: colors.foreground; onClicked: shellRoot.act("wall", shellRoot.selectedTheme, shellRoot.savedWebWall) }
                StyledButton { borderless: true; Layout.alignment: Qt.AlignBottom; visible: shellRoot.webMode; text: "Save wallpaper"; enabled: !!studio.selected && downloadCategory.currentText !== "" && !shellRoot.actionRunning; surfaceColor: colors.accentContainer; hoverColor: colors.raised; pressedColor: colors.inset; textColor: colors.foreground; onClicked: { shellRoot.savedWebWall = ""; shellRoot.feedback = "Downloading…"; shellRoot.act("wall-download", shellRoot.webProvider, studio.selected.id, downloadCategory.currentText) } }
                StyledButton { borderless: true; id: manageButton; Layout.alignment: Qt.AlignBottom; visible: !shellRoot.webMode; text: "Manage ···"; ToolTip.visible: hovered; ToolTip.text: "Move, delete or import wallpapers"; surfaceColor: colors.inset; hoverColor: colors.raised; pressedColor: colors.accentContainer; textColor: colors.foreground; onClicked: options.open() }
                StyledButton { borderless: true; Layout.alignment: Qt.AlignBottom; visible: !shellRoot.webMode; text: "Set wallpaper"; enabled: !!studio.selected && !!shellRoot.selectedTheme; surfaceColor: colors.accentContainer; hoverColor: colors.raised; pressedColor: colors.inset; textColor: colors.foreground; onClicked: shellRoot.act("wall", shellRoot.selectedTheme, shellRoot.selectedWall) }
                Popup {
                    id: options; parent: dock; x: Math.max(8, Math.min(dock.width - width - 8, manageButton.mapToItem(dock, 0, 0).x)); y: Math.max(8, manageButton.mapToItem(dock, 0, 0).y - height - 6); width: 410; padding: 14; closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                    background: Rectangle { color: colors.surface; radius: 24; border.width: 0 }
                    ColumnLayout {
                        width: parent.width; spacing: 10
                        Text { text: "Manage collection"; color: colors.foreground; font.family: "Adwaita Sans"; font.pixelSize: 16; font.weight: Font.DemiBold }
                        Text { Layout.fillWidth: true; text: "Move selected wallpaper to another category, remove its file, or import new media."; wrapMode: Text.WordWrap; color: colors.muted; font.pixelSize: 12 }
                        Text { text: "MOVE SELECTED TO"; color: colors.muted; font.pixelSize: 10; font.letterSpacing: 1 }
                        RowLayout { Layout.fillWidth: true
                            StudioPicker { borderless: true; id: movePicker; Layout.fillWidth: true; model: shellRoot.wallCategories; surfaceColor: "#292832"; hoverColor: "#35333e"; inkColor: "#f1eff5"; hintColor: "#bcb8c6" }
                            StyledButton { borderless: true; text: "Move"; enabled: !!studio.selected && movePicker.currentText !== studio.selected.category; surfaceColor: colors.inset; hoverColor: colors.raised; pressedColor: colors.accentContainer; textColor: colors.foreground; onClicked: { shellRoot.act("wall-move", shellRoot.selectedWall, movePicker.currentText); options.close() } }
                            StyledButton { borderless: true; text: "Delete…"; enabled: !!studio.selected; surfaceColor: colors.inset; hoverColor: colors.raised; pressedColor: colors.accentContainer; textColor: colors.foreground; onClicked: shellRoot.pendingWallDelete = shellRoot.selectedWall }
                        }
                        RowLayout { visible: shellRoot.pendingWallDelete !== ""; Layout.fillWidth: true
                            Text { text: "Delete selected file? Cannot undo."; color: colors.foreground; font.pixelSize: 12; Layout.fillWidth: true }
                            StyledButton { borderless: true; text: "Cancel"; surfaceColor: colors.inset; hoverColor: colors.raised; pressedColor: colors.accentContainer; textColor: colors.foreground; onClicked: shellRoot.pendingWallDelete = "" }
                            StyledButton { borderless: true; text: "Delete"; surfaceColor: colors.inset; hoverColor: colors.raised; pressedColor: colors.accentContainer; textColor: colors.foreground; onClicked: { const target = shellRoot.pendingWallDelete; shellRoot.pendingWallDelete = ""; shellRoot.act("wall-delete", target); options.close() } }
                        }
                        Text { text: "IMPORT FILE"; color: colors.muted; font.pixelSize: 10; font.letterSpacing: 1 }
                        RowLayout { Layout.fillWidth: true
                            StudioField { normalModeKey: shellRoot.normalModeKey; jkTimeoutMs: shellRoot.jkTimeoutMs; borderless: true; id: importPath; Layout.fillWidth: true; placeholderText: "/absolute/path/to/media"; surfaceColor: "#292832"; focusColor: "#35333e"; inkColor: "#f1eff5"; hintColor: "#bcb8c6" }
                            StudioPicker { borderless: true; id: importCategory; Layout.preferredWidth: 110; model: shellRoot.wallCategories; surfaceColor: "#292832"; hoverColor: "#35333e"; inkColor: "#f1eff5"; hintColor: "#bcb8c6" }
                            StyledButton { borderless: true; text: "Import"; enabled: importPath.text.length > 0 && importCategory.currentText !== ""; surfaceColor: colors.inset; hoverColor: colors.raised; pressedColor: colors.accentContainer; textColor: colors.foreground; onClicked: { shellRoot.act("wall-import", importPath.text, importCategory.currentText); options.close() } }
                        }
                    }
                }
            }
            ListView {
                id: gallery
                property var sourceWalls: shellRoot.walls.filter(function(w) { return (shellRoot.selectedCategory === "All" || w.category === shellRoot.selectedCategory) && w.name.toLowerCase().includes(shellRoot.wallFilter.toLowerCase()) })
                readonly property int cycleCount: sourceWalls.length > 1 ? Math.max(5, Math.ceil(width * 5 / (sourceWalls.length * 205))) : 1
                property var loopedWalls: {
                    const result = []
                    for (let cycle = 0; cycle < cycleCount; cycle++) result.push.apply(result, sourceWalls)
                    return result
                }
                property int selectedIndex: -1
                property bool keyboardNavigating: false
                NumberAnimation { id: galleryScroll; target: gallery; property: "contentX"; duration: 120; easing.type: Easing.InOutCubic; onFinished: gallery.keyboardNavigating = false }
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 68
                orientation: ListView.Horizontal; spacing: 6; clip: true
                boundsBehavior: Flickable.StopAtBounds
                preferredHighlightBegin: width / 2 - (currentItem ? currentItem.width / 2 : 100)
                preferredHighlightEnd: preferredHighlightBegin
                highlightRangeMode: keyboardNavigating ? ListView.NoHighlightRange : ListView.StrictlyEnforceRange
                highlightMoveDuration: studio.reduceMotion ? 0 : 240
                model: loopedWalls
                onCurrentIndexChanged: if (!keyboardNavigating && !moving && !flicking && !dragging && currentIndex >= 0) selectionSettler.restart()
                onMovementStarted: { if (!keyboardNavigating) { galleryScroll.stop(); selectionSettler.stop() } }
                onMovementEnded: selectionSettler.restart()
                Timer { id: selectionSettler; interval: 230; onTriggered: if (!gallery.moving && !gallery.flicking) studio.choose(gallery.currentIndex) }
                onLoopedWallsChanged: {
                    selectionSettler.stop()
                    Qt.callLater(function() {
                        if (!gallery.sourceWalls.length) { gallery.selectedIndex = -1; return }
                        const key = shellRoot.selectedWall
                        const found = gallery.sourceWalls.findIndex(function(w) { return w.path === key })
                        const index = Math.floor(gallery.cycleCount / 2) * gallery.sourceWalls.length + Math.max(0, found)
                        gallery.currentIndex = index
                        gallery.positionViewAtIndex(index, ListView.Center)
                        studio.choose(index)
                    })
                }
                delegate: Item {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool selectedTile: gallery.selectedIndex === index
                    readonly property real ratio: modelData.width > 0 && modelData.height > 0 ? modelData.width / modelData.height : thumbnail.status === Image.Ready && thumbnail.implicitHeight > 0 ? thumbnail.implicitWidth / thumbnail.implicitHeight : 16 / 9
                    readonly property real boxHeight: Math.max(44, height - 24)
                    readonly property real squareSide: Math.min(190, boxHeight)
                    readonly property real expandedWidth: squareSide * ratio
                    width: Math.max(squareSide + 8, expandedWidth)
                    height: gallery.height
                    Rectangle {
                        id: tileArt
                        anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top
                        width: tile.expandedWidth
                        height: tile.squareSide
                        color: selectedTile ? colors.raised : colors.inset
                        layer.enabled: true
                        layer.effect: MultiEffect { maskEnabled: true; maskSource: tileMask; maskThresholdMin: 0.5; maskSpreadAtMin: 0 }
                        Rectangle { id: tileMask; anchors.fill: parent; radius: 13; color: "white"; visible: false; layer.enabled: true }
                        Image { id: thumbnail; anchors.fill: parent; source: modelData.video && modelData.preview === modelData.path ? "" : "file://" + modelData.preview; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 340 }
                    }
                    Text {
                        anchors.left: tileArt.left; anchors.right: tileArt.right; anchors.top: tileArt.bottom; anchors.topMargin: 4
                        text: (modelData.video ? "▶  " : "") + modelData.name
                        color: selectedTile ? colors.foreground : colors.muted
                        font.family: "Adwaita Sans"; font.pixelSize: 11; font.weight: selectedTile ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { gallery.currentIndex = tile.index; selectionSettler.stop(); studio.choose(tile.index) } }
                }
            }
            Text { text: shellRoot.webMode ? (shellRoot.webError || shellRoot.feedback) : shellRoot.feedback; visible: !!text; color: colors.accent; font.family: "Adwaita Sans"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
        }
    }
    Rectangle {
        id: discoverResults
        visible: shellRoot.webMode
        x: shellRoot.webMode ? (shellRoot.studioDiscoverRight ? 0 : studio.discoverWidth) : (shellRoot.studioDiscoverRight ? -studio.width : studio.width)
        y: 0; width: Math.max(0, studio.width - studio.discoverWidth); height: studio.height
        color: colors.surface
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 26; spacing: 16
            ColumnLayout { Layout.fillWidth: true; spacing: 3
                Text { text: "Discover wallpapers"; color: colors.foreground; font.family: "Adwaita Sans"; font.pixelSize: 24; font.weight: Font.DemiBold }
                Text { text: shellRoot.webWalls.length ? shellRoot.webWalls.length + " results  ·  Select to save to collection" : "Search to find wallpapers"; color: colors.muted; font.pixelSize: 13 }
            }
            GridView {
                id: discoverGrid
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; boundsBehavior: Flickable.StopAtBounds
                cellWidth: Math.max(270, Math.floor(width / Math.max(1, Math.floor(width / 290))))
                cellHeight: 220
                model: shellRoot.webWalls
                delegate: Item {
                    required property var modelData
                    required property int index
                    readonly property bool selectedCard: shellRoot.selectedWebWall && shellRoot.selectedWebWall.id === modelData.id
                    width: discoverGrid.cellWidth; height: discoverGrid.cellHeight
                    Rectangle {
                        id: resultCard
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 6, 256)
                        height: 202
                        radius: 24; color: selectedCard ? colors.raised : colors.surface
                        Item {
                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                            anchors.margins: 7; height: parent.height - 32
                            clip: true
                            Image { anchors.fill: parent; source: modelData.preview; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 500 }
                        }
                        Text { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.leftMargin: 10; anchors.rightMargin: 10; anchors.bottomMargin: 7; text: modelData.title || "Untitled"; color: colors.foreground; elide: Text.ElideRight; font.pixelSize: 12; font.weight: selectedCard ? Font.DemiBold : Font.Normal }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.selectedWebWall = modelData }
                    }
                }
            }
        }
    }
    Rectangle {
        id: discoverPanel
        visible: shellRoot.webMode
        x: shellRoot.webMode ? (shellRoot.studioDiscoverRight ? studio.width - width : 0) : (shellRoot.studioDiscoverRight ? studio.width : -width)
        y: 0; width: studio.discoverWidth; height: studio.height
        color: colors.surface
        Flickable {
            id: discoverScroll
            anchors.fill: parent; anchors.margins: 24
            clip: true; boundsBehavior: Flickable.StopAtBounds
            contentHeight: discoverControls.implicitHeight
            ColumnLayout {
                id: discoverControls
                width: discoverScroll.width; spacing: 14
            RowLayout { Layout.fillWidth: true
                Text { text: "Discover"; Layout.fillWidth: true; color: colors.foreground; font.family: "Adwaita Sans"; font.pixelSize: 21; font.weight: Font.DemiBold }
                StyledButton { borderless: true; text: "×"; surfaceColor: colors.inset; hoverColor: colors.raised; textColor: colors.foreground; onClicked: shellRoot.page = "" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 8
                StyledButton { borderless: true; Layout.fillWidth: true; text: "← Local"; ToolTip.visible: hovered; ToolTip.text: "Return to local collection"; surfaceColor: colors.inset; hoverColor: colors.raised; textColor: colors.foreground; onClicked: shellRoot.webMode = false }
                StyledButton { borderless: true; text: shellRoot.studioDiscoverRight ? "←" : "→"; ToolTip.visible: hovered; ToolTip.text: shellRoot.studioDiscoverRight ? "Move panel left" : "Move panel right"; surfaceColor: colors.inset; hoverColor: colors.raised; textColor: colors.foreground; onClicked: shellRoot.toggleDiscoverSide() }
            }
            StudioField { normalModeKey: shellRoot.normalModeKey; jkTimeoutMs: shellRoot.jkTimeoutMs; borderless: true; id: discoverSearch; Layout.fillWidth: true; placeholderText: "Search wallpapers…"; reduceMotion: studio.reduceMotion; surfaceColor: colors.inset; focusColor: colors.raised; inkColor: colors.foreground; hintColor: colors.muted; onAccepted: studio.doSearch(); Keys.onEscapePressed: event => { studio.contentItem.forceActiveFocus(); event.accepted = true } }
            StudioPicker { borderless: true; id: discoverProvider; Layout.fillWidth: true; model: ["wallhaven", "unsplash", "pexels", "pexels-video"]; surfaceColor: colors.inset; hoverColor: colors.raised; inkColor: colors.foreground; hintColor: colors.muted; onActivated: { shellRoot.webProvider = currentText; shellRoot.webWalls = []; shellRoot.selectedWebWall = null; shellRoot.webError = "" } }
            StyledButton { borderless: true; Layout.fillWidth: true; text: shellRoot.searchRunning ? "Searching…" : "Search"; enabled: !shellRoot.searchRunning; surfaceColor: colors.accentContainer; hoverColor: colors.raised; textColor: colors.foreground; onClicked: studio.doSearch() }
            Rectangle { Layout.fillWidth: true; height: 1; color: colors.outline }
            Text { Layout.fillWidth: true; text: shellRoot.selectedWebWall ? shellRoot.selectedWebWall.title : "Select a result"; color: colors.foreground; font.pixelSize: 17; font.weight: Font.DemiBold; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight }
            Text { Layout.fillWidth: true; text: shellRoot.selectedWebWall ? shellRoot.selectedWebWall.author + "  ·  " + shellRoot.selectedWebWall.width + " × " + shellRoot.selectedWebWall.height + "\n" + shellRoot.selectedWebWall.license : "Results appear beside this panel"; color: colors.muted; font.pixelSize: 12; wrapMode: Text.WordWrap }
            Text { text: "SAVE TO CATEGORY"; color: colors.muted; font.pixelSize: 10; font.letterSpacing: 1 }
            StudioPicker { borderless: true; id: discoverCategory; Layout.fillWidth: true; model: shellRoot.wallCategories; surfaceColor: colors.inset; hoverColor: colors.raised; inkColor: colors.foreground; hintColor: colors.muted }
            StyledButton { borderless: true; Layout.fillWidth: true; text: "Save wallpaper"; enabled: !!shellRoot.selectedWebWall && !!discoverCategory.currentText && !shellRoot.actionRunning; surfaceColor: colors.accentContainer; hoverColor: colors.raised; textColor: colors.foreground; onClicked: { shellRoot.savedWebWall = ""; shellRoot.feedback = "Downloading…"; shellRoot.act("wall-download", shellRoot.webProvider, shellRoot.selectedWebWall.id, discoverCategory.currentText) } }
            Text { text: "APPLY WITH THEME"; color: colors.muted; font.pixelSize: 10; font.letterSpacing: 1 }
            StudioPicker { borderless: true; id: discoverTheme; Layout.fillWidth: true; model: shellRoot.wallThemes.map(function(t) { return t.name }); surfaceColor: colors.inset; hoverColor: colors.raised; inkColor: colors.foreground; hintColor: colors.muted; onActivated: shellRoot.selectedTheme = currentText
                Connections { target: shellRoot; function onSelectedThemeChanged() { const i = discoverTheme.model.indexOf(shellRoot.selectedTheme); if (i >= 0) discoverTheme.currentIndex = i } }
            }
            StyledButton { borderless: true; Layout.fillWidth: true; text: "Set saved wallpaper"; enabled: !!shellRoot.selectedWebWall && shellRoot.savedWebId === shellRoot.selectedWebWall.id && !!shellRoot.savedWebWall && !!shellRoot.selectedTheme && !shellRoot.actionRunning; surfaceColor: colors.inset; hoverColor: colors.raised; textColor: colors.foreground; onClicked: shellRoot.act("wall", shellRoot.selectedTheme, shellRoot.savedWebWall) }
            StyledButton { borderless: true; Layout.fillWidth: true; text: "Source ↗"; enabled: !!shellRoot.selectedWebWall; surfaceColor: colors.inset; hoverColor: colors.raised; textColor: colors.foreground; onClicked: Qt.openUrlExternally(shellRoot.selectedWebWall.source) }
            Text { Layout.fillWidth: true; text: shellRoot.webError || shellRoot.feedback; visible: !!text; wrapMode: Text.WordWrap; color: colors.accent; font.pixelSize: 12 }
            }
        }
    }
    readonly property bool browseKeysEnabled: studio.visible && !options.visible && !(shellRoot.webMode ? discoverSearch.activeFocus : searchText.activeFocus) && !importPath.activeFocus && !themePicker.popup.visible && !movePicker.popup.visible && !importCategory.popup.visible && !downloadCategory.popup.visible && !discoverProvider.popup.visible && !discoverTheme.popup.visible && !discoverCategory.popup.visible
    property bool controlsMode: false
    VimNavigation {
        id: studioNav
        window: studio
        rootItem: options.visible ? options.contentItem : studio.contentItem
        moveHandler: (studio.controlsMode || options.visible) ? null : function(delta) { studio.stepGallery(delta) }
        boundaryHandler: (studio.controlsMode || options.visible) ? null : function(last) {
            if (shellRoot.webMode) {
                if (shellRoot.webWalls.length) shellRoot.selectedWebWall = shellRoot.webWalls[last ? shellRoot.webWalls.length - 1 : 0]
            } else if (gallery.sourceWalls.length) {
                const middle = Math.floor(gallery.cycleCount / 2) * gallery.sourceWalls.length
                studio.choose(middle + (last ? gallery.sourceWalls.length - 1 : 0))
                gallery.positionViewAtIndex(gallery.selectedIndex, ListView.Center)
            }
        }
        searchHandler: function() { (shellRoot.webMode ? discoverSearch : searchText).forceActiveFocus() }
        activateHandler: (studio.controlsMode || options.visible) ? null : function() { studio.controlsMode = true; studioNav.move(1) }
        escapeHandler: function() {
            if (options.visible) { options.close(); return }
            if (studioNav.editing || studio.controlsMode) { studio.controlsMode = false; studio.contentItem.forceActiveFocus() }
            else shellRoot.page = ""
        }
    }
    Shortcut { sequence: "Tab"; enabled: studioNav.normal; onActivated: { studio.controlsMode = !studio.controlsMode; if (studio.controlsMode) studioNav.move(1); else studio.contentItem.forceActiveFocus() } }
    Shortcut { sequence: "Ctrl+Return"; enabled: studioNav.normal && !shellRoot.webMode && !!studio.selected && !!shellRoot.selectedTheme; onActivated: shellRoot.act("wall", shellRoot.selectedTheme, shellRoot.selectedWall) }
    Shortcut { sequence: "Ctrl+J"; enabled: studioNav.normal; onActivated: { shellRoot.webMode = true; shellRoot.pendingWallDelete = "" } }
    Shortcut { sequence: "Ctrl+K"; enabled: studioNav.normal; onActivated: { shellRoot.webMode = false; shellRoot.pendingWallDelete = "" } }
}
