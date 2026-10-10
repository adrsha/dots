import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../components"

PanelWindow {
    id: editor
    required property var shellRoot
    visible: shellRoot.page === "screenshot-editor"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-screenshot-editor"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    property string tool: "Brush"
    property color ink: "#ff4040"
    property var marks: []
    property var history: [[]]
    property int historyIndex: 0
    property var draft: null
    property string exportData: ""
    property bool imageReady: false
    property bool exporting: false
    property bool busy: false
    property string error: ""
    readonly property string imageUrl: shellRoot.editorSource ? "file://" + shellRoot.editorSource : ""
    onImageUrlChanged: {
        imageReady = false; marks = []; history = [[]]; historyIndex = 0; draft = null; error = ""
        if (imageUrl) canvas.loadImage(imageUrl)
        canvas.requestPaint()
    }
    onVisibleChanged: {
        if (visible) contentItem.forceActiveFocus()
        else if (shellRoot.editorSource && !busy) cancel()
    }
    function commit(next) {
        marks = next
        history = history.slice(0, historyIndex + 1).concat([JSON.parse(JSON.stringify(next))])
        historyIndex++; canvas.requestPaint()
    }
    function undo() {
        if (historyIndex > 0 && !busy) { marks = history[--historyIndex]; draft = null; canvas.requestPaint() }
    }
    function redo() {
        if (historyIndex + 1 < history.length && !busy) { marks = history[++historyIndex]; draft = null; canvas.requestPaint() }
    }
    function cancel() {
        if (busy) return
        if (shellRoot.editorSource) {
            cleanup.command = ["python3", shellRoot.backend, "screenshot-discard", shellRoot.editorSource]
            cleanup.running = true
        }
        shellRoot.editorSource = ""; shellRoot.editorOutput = ""; shellRoot.page = ""
    }
    function finish() {
        if (busy || !canvas.isImageLoaded(imageUrl) || sourceImage.status !== Image.Ready) return
        draft = null; error = ""; busy = true; exporting = true
        canvas.requestPaint()
    }
    // All coordinates and sizes are source pixels. Only the presentation is scaled.
    function drawMark(ctx, m) {
        ctx.save(); ctx.strokeStyle = m.color; ctx.fillStyle = m.color
        ctx.lineWidth = m.size; ctx.lineCap = "round"; ctx.lineJoin = "round"; ctx.globalAlpha = m.opacity
        if (m.tool === "Text") {
            ctx.font = m.size + 'px "' + m.font.replace(/"/g, '') + '"'
            ctx.textBaseline = "top"
            const lines = m.text.split("\n")
            for (let i = 0; i < lines.length; i++) ctx.fillText(lines[i], m.x, m.y + i * m.size * 1.2)
        } else if (m.tool === "Brush") {
            const p = m.points
            if (p.length === 1) { ctx.beginPath(); ctx.arc(p[0].x, p[0].y, m.size / 2, 0, Math.PI * 2); ctx.fill() }
            else {
                // Quadratic midpoint interpolation smooths motion, not brush texture.
                ctx.beginPath(); ctx.moveTo(p[0].x, p[0].y)
                for (let i = 1; i < p.length - 1; i++) {
                    ctx.quadraticCurveTo(p[i].x, p[i].y, (p[i].x + p[i+1].x) / 2, (p[i].y + p[i+1].y) / 2)
                }
                const last = p[p.length-1]; ctx.lineTo(last.x, last.y); ctx.stroke()
            }
        } else {
            const x = Math.min(m.x, m.endX), y = Math.min(m.y, m.endY)
            const w = Math.abs(m.endX - m.x), h = Math.abs(m.endY - m.y)
            ctx.beginPath()
            if (m.tool === "Rectangle") ctx.rect(x, y, w, h)
            else if (m.tool === "Circle") {
                const r = Math.sqrt(w*w + h*h)
                ctx.arc(m.x, m.y, r, 0, Math.PI*2)
            } else if (m.tool === "Arrow") {
                ctx.moveTo(m.x, m.y); ctx.lineTo(m.endX, m.endY)
                const a = Math.atan2(m.endY-m.y, m.endX-m.x), len = Math.max(12, m.size*4)
                ctx.moveTo(m.endX-len*Math.cos(a-0.5), m.endY-len*Math.sin(a-0.5)); ctx.lineTo(m.endX, m.endY)
                ctx.lineTo(m.endX-len*Math.cos(a+0.5), m.endY-len*Math.sin(a+0.5))
            }
            ctx.stroke()
        }
        ctx.restore()
    }
    Process { id: cleanup }
    Process {
        id: delivery
        stdinEnabled: true
        onStarted: { write(editor.exportData); stdinEnabled = false; editor.exportData = "" }
        stdout: StdioCollector { onStreamFinished: {
            editor.busy = false
            try {
                const result = JSON.parse(this.text)
                if (result.error) { editor.error = result.error; return }
                editor.shellRoot.editorSource = ""; editor.shellRoot.editorOutput = ""
                editor.shellRoot.page = ""
                editor.shellRoot.showOsd("screenshot", result.path ? "Saved: " + result.path : result.message)
            } catch (e) { editor.error = "Could not finish screenshot; try again." }
        } }
        stderr: StdioCollector { onStreamFinished: if (this.text.trim()) { editor.error = this.text.trim(); editor.busy = false } }
    }
    Image { id: sourceImage; visible: false; source: editor.imageUrl; onStatusChanged: { if (status === Image.Error) editor.error = "Could not load screenshot"; canvas.requestPaint() } }
    Rectangle { anchors.fill: parent; anchors.margins: 12; radius: 22; color: shellRoot.surface }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 28; spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Annotate screenshot"; color: shellRoot.foreground; font.family: "Adwaita Sans"; font.pixelSize: 22; font.weight: Font.DemiBold; Layout.fillWidth: true }
            StyledButton { surfaceColor: shellRoot.readableSurface; hoverColor: shellRoot.raised; pressedColor: shellRoot.accentContainer; textColor: shellRoot.foreground; reduceMotion: shellRoot.reduceMotion; text: "Undo"; enabled: editor.historyIndex > 0 && !editor.busy; onClicked: editor.undo() }
            StyledButton { surfaceColor: shellRoot.readableSurface; hoverColor: shellRoot.raised; pressedColor: shellRoot.accentContainer; textColor: shellRoot.foreground; reduceMotion: shellRoot.reduceMotion; text: "Redo"; enabled: editor.historyIndex + 1 < editor.history.length && !editor.busy; onClicked: editor.redo() }
            StyledButton { surfaceColor: shellRoot.readableSurface; hoverColor: shellRoot.raised; pressedColor: shellRoot.accentContainer; textColor: shellRoot.foreground; reduceMotion: shellRoot.reduceMotion; text: "Clear all"; enabled: editor.marks.length > 0 && !editor.busy; onClicked: editor.commit([]) }
            StyledButton { surfaceColor: shellRoot.readableSurface; hoverColor: shellRoot.raised; pressedColor: shellRoot.accentContainer; textColor: shellRoot.foreground; reduceMotion: shellRoot.reduceMotion; text: "Cancel"; enabled: !editor.busy; onClicked: editor.cancel() }
            StyledButton {
                text: editor.busy ? "Finishing…" : shellRoot.editorDestination === "save" ? "Save PNG" : shellRoot.editorDestination === "lens" ? "Copy & open Lens" : "Copy PNG"
                enabled: !editor.busy && sourceImage.status === Image.Ready && editor.imageReady
                surfaceColor: shellRoot.accentContainer; textColor: shellRoot.foreground
                onClicked: editor.finish()
            }
        }
        Flow {
            Layout.fillWidth: true; Layout.preferredHeight: childrenRect.height; spacing: 8
            Repeater {
                model: ["Rectangle", "Circle", "Brush", "Arrow", "Text"]
                Tile {
                    shellRoot: editor.shellRoot
                    stacked: true; width: 100; height: 88
                    iconGlyph: ({Rectangle: "\ue3c6", Circle: "\uef4a", Brush: "\ue3ae", Arrow: "\ue5c8", Text: "\ue264"})[modelData]
                    selected: editor.tool === modelData
                    required property string modelData
                    title: modelData; enabled: !editor.busy
                    onActivated: editor.tool = modelData
                }
            }
            Text { text: "Color"; color: shellRoot.foreground; height: 42; verticalAlignment: Text.AlignVCenter }
            Repeater {
                model: ["#ff4040", "#ffcc00", "#44dd88", "#3399ff", "#ffffff", "#111111"]
                Rectangle {
                    required property string modelData
                    width: 32; height: 42; color: modelData; radius: 8
                    border.width: editor.ink.toString() === modelData ? 3 : 1; border.color: shellRoot.foreground
                    MouseArea { anchors.fill: parent; enabled: !editor.busy; onClicked: { editor.ink = parent.modelData; colorField.text = parent.modelData } }
                }
            }
            StudioField { inkColor: shellRoot.foreground; hintColor: shellRoot.muted; surfaceColor: shellRoot.readableSurface; focusColor: shellRoot.raised; reduceMotion: shellRoot.reduceMotion; normalModeKey: shellRoot.normalModeKey; jkTimeoutMs: shellRoot.jkTimeoutMs;
                id: colorField; width: 120; text: "#ff4040"; placeholderText: "#RRGGBB"
                validator: RegularExpressionValidator { regularExpression: /#[0-9a-fA-F]{6}/ }
                onTextEdited: if (acceptableInput) editor.ink = text
            }
            Text { text: editor.tool === "Text" ? "Text size (px)" : "Stroke (px)"; color: shellRoot.foreground; height: 42; verticalAlignment: Text.AlignVCenter }
            SpinBox { id: strokeSize; from: 1; to: 1000; value: 6; editable: true; visible: editor.tool !== "Text"; enabled: !editor.busy }
            SpinBox { id: textSize; from: 1; to: 4096; value: 32; editable: true; visible: editor.tool === "Text"; enabled: !editor.busy }
            Text { text: "Opacity"; color: shellRoot.foreground; height: 42; verticalAlignment: Text.AlignVCenter }
            Slider { id: opacityControl; width: 130; height: 42; from: 0.05; to: 1; value: 1; enabled: !editor.busy }
        }
        RowLayout {
            Layout.fillWidth: true; visible: editor.tool === "Text"
            StudioField { inkColor: shellRoot.foreground; hintColor: shellRoot.muted; surfaceColor: shellRoot.readableSurface; focusColor: shellRoot.raised; reduceMotion: shellRoot.reduceMotion; normalModeKey: shellRoot.normalModeKey; jkTimeoutMs: shellRoot.jkTimeoutMs; id: textValue; Layout.fillWidth: true; placeholderText: "Text to place — then click the image"; enabled: !editor.busy }
            ComboBox { id: fontFamily; Layout.preferredWidth: 250; model: Qt.fontFamilies(); editable: true; currentIndex: Math.max(0, Qt.fontFamilies().indexOf("Adwaita Sans")); enabled: !editor.busy }
        }
        StudioField { inkColor: shellRoot.foreground; hintColor: shellRoot.muted; surfaceColor: shellRoot.readableSurface; focusColor: shellRoot.raised; reduceMotion: shellRoot.reduceMotion; normalModeKey: shellRoot.normalModeKey; jkTimeoutMs: shellRoot.jkTimeoutMs;
            Layout.fillWidth: true; visible: shellRoot.editorDestination === "save"
            text: shellRoot.editorFilename; placeholderText: "Filename (blank = timestamp, .png added)"
            onTextEdited: shellRoot.editorFilename = text
            enabled: !editor.busy
        }
        Text {
            Layout.fillWidth: true; color: editor.error ? "#ff7777" : shellRoot.muted; wrapMode: Text.WordWrap
            text: editor.error || "Drag to draw; circles start at their center. Choose low opacity to highlight. Text: enter content, then click to place. Ctrl+Z / Ctrl+Shift+Z undo / redo."
        }
        Rectangle {
            id: stage
            Layout.fillWidth: true; Layout.fillHeight: true; radius: 17; color: shellRoot.readableSurface; clip: true
            Item {
                id: frame
                anchors.centerIn: parent
                width: sourceImage.sourceSize.width; height: sourceImage.sourceSize.height
                scale: width > 0 && height > 0 ? Math.min((stage.width - 24) / width, (stage.height - 24) / height, 1) : 1
                Canvas {
                    id: canvas; anchors.fill: parent
                    renderTarget: Canvas.Image
                    onImageLoaded: { editor.imageReady = isImageLoaded(editor.imageUrl); requestPaint() }
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset(); ctx.clearRect(0, 0, width, height)
                        if (!editor.imageUrl || !isImageLoaded(editor.imageUrl)) return
                        ctx.drawImage(editor.imageUrl, 0, 0, width, height)
                        for (let i = 0; i < editor.marks.length; i++) editor.drawMark(ctx, editor.marks[i])
                        if (editor.draft) editor.drawMark(ctx, editor.draft)
                    }
                    onPainted: {
                        if (!editor.exporting) return
                        editor.exporting = false
                        // Qt 6.11 Canvas.save resolves paths against Quickshell's
                        // custom URL scheme. Transfer PNG over stdin instead.
                        editor.exportData = toDataURL("image/png")
                        if (!editor.exportData.startsWith("data:image/png;base64,")) { editor.error = "Could not export PNG"; editor.busy = false; return }
                        delivery.command = ["python3", shellRoot.backend, "screenshot-finish", shellRoot.editorOutput, shellRoot.editorDestination, shellRoot.editorFilename]
                        delivery.stdinEnabled = true
                        delivery.running = true
                    }
                }
                MouseArea {
                    anchors.fill: parent; enabled: !editor.busy && sourceImage.status === Image.Ready
                    cursorShape: Qt.CrossCursor
                    function point(mouse) { return {x: Math.max(0, Math.min(width, mouse.x)), y: Math.max(0, Math.min(height, mouse.y))} }
                    onPressed: mouse => {
                        const p = point(mouse)
                        editor.draft = {tool: editor.tool, color: editor.ink.toString(), size: editor.tool === "Text" ? textSize.value : strokeSize.value,
                            opacity: opacityControl.value, x: p.x, y: p.y, endX: p.x, endY: p.y, points: [p], text: textValue.text, font: fontFamily.editText || fontFamily.currentText}
                        canvas.requestPaint()
                    }
                    onPositionChanged: mouse => {
                        if (!pressed || !editor.draft) return
                        const p = point(mouse), m = editor.draft
                        m.endX = p.x; m.endY = p.y
                        if (m.tool === "Brush") m.points.push(p)
                        canvas.requestPaint()
                    }
                    onReleased: mouse => {
                        if (!editor.draft) return
                        const p = point(mouse), m = editor.draft
                        m.endX = p.x; m.endY = p.y
                        if (m.tool === "Brush") m.points.push(p)
                        if (m.tool !== "Text" || m.text.trim()) editor.commit(editor.marks.concat([m]))
                        editor.draft = null; canvas.requestPaint()
                    }
                    onCanceled: { editor.draft = null; canvas.requestPaint() }
                }
            }
        }
    }
    Shortcut { sequence: "Ctrl+Z"; enabled: editor.visible && !textValue.activeFocus; onActivated: editor.undo() }
    Shortcut { sequence: "Ctrl+Shift+Z"; enabled: editor.visible && !textValue.activeFocus; onActivated: editor.redo() }
    Shortcut { sequence: "Ctrl+Y"; enabled: editor.visible && !textValue.activeFocus; onActivated: editor.redo() }
    Shortcut { sequence: "Escape"; enabled: editor.visible && !editor.busy; onActivated: editor.cancel() }
}
