import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components"

PanelWindow {
    id: capturePanel
    required property var shellRoot
    visible: shellRoot.page === "screenshot"
    anchors { top: true; right: true }
    margins { top: 16; right: 16 }
    implicitWidth: Math.min(460, screen ? screen.width - 32 : 460)
    implicitHeight: Math.min(body.implicitHeight + 40, screen ? screen.height - 32 : 600)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-screenshot"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    onVisibleChanged: if (visible) Qt.callLater(() => regionButton.forceActiveFocus())
    Rectangle { anchors.fill: parent; radius: 22; color: shellRoot.surface }
    ColumnLayout {
        id: body
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
        spacing: 16
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Screenshot"; color: shellRoot.foreground; font.family: "Adwaita Sans"; font.pixelSize: 22; font.weight: Font.DemiBold; Layout.fillWidth: true }
            StyledButton { text: "×"; surfaceColor: shellRoot.inset; hoverColor: shellRoot.raised; textColor: shellRoot.foreground; onClicked: shellRoot.page = "" }
        }
        Text { text: "What to capture"; color: shellRoot.muted; font.pixelSize: 13 }
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Tile { id: regionButton; shellRoot: capturePanel.shellRoot; Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.preferredHeight: 88; stacked: true; title: "Region"; iconGlyph: "\ue3be"; selected: shellRoot.captureScope === "region"; onActivated: shellRoot.captureScope = "region" }
            Tile { shellRoot: capturePanel.shellRoot; Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.preferredHeight: 88; stacked: true; title: "Window"; iconGlyph: "\ue8ef"; selected: shellRoot.captureScope === "window"; onActivated: shellRoot.captureScope = "window" }
            Tile { shellRoot: capturePanel.shellRoot; Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.preferredHeight: 88; stacked: true; title: "Display"; iconGlyph: "\ue30a"; selected: shellRoot.captureScope === "output"; onActivated: shellRoot.captureScope = "output" }
        }
        Text { text: "Send to"; color: shellRoot.muted; font.pixelSize: 13 }
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Repeater {
                model: ["save", "clipboard", "lens"]
                Tile {
                    required property string modelData
                    shellRoot: capturePanel.shellRoot
                    Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.preferredHeight: 88
                    stacked: true
                    title: modelData === "save" ? "File" : modelData === "clipboard" ? "Clipboard" : "Lens"
                    iconGlyph: modelData === "save" ? "\ue161" : modelData === "clipboard" ? "\ue14d" : "\ue3f5"
                    selected: shellRoot.captureDestination === modelData
                    onActivated: shellRoot.captureDestination = modelData
                }
            }
        }
        StudioField { normalModeKey: shellRoot.normalModeKey; jkTimeoutMs: shellRoot.jkTimeoutMs;
            Layout.fillWidth: true
            visible: shellRoot.captureDestination === "save"
            placeholderText: "Filename (blank = timestamp, .png added)"
            text: shellRoot.captureFilename
            onTextEdited: shellRoot.captureFilename = text
            inkColor: shellRoot.foreground; hintColor: shellRoot.muted; surfaceColor: shellRoot.readableSurface; focusColor: shellRoot.raised; reduceMotion: shellRoot.reduceMotion
        }
        CheckBox {
            id: editToggle
            property bool vimNavigable: true
            function vimActivate() { toggle(); shellRoot.editAfterScreenshot = checked }
            text: "Edit after screenshot"
            checked: shellRoot.editAfterScreenshot
            onToggled: shellRoot.editAfterScreenshot = checked
            Layout.fillWidth: true
            implicitHeight: 46
            padding: 10
            spacing: 10
            hoverEnabled: true
            indicator: Rectangle {
                x: editToggle.leftPadding
                y: (editToggle.height - height) / 2
                implicitWidth: 22
                implicitHeight: 22
                width: 22
                height: 22
                radius: 7
                color: editToggle.checked ? shellRoot.accentContainer : shellRoot.inset
                border.width: editToggle.checked ? 0 : 1
                border.color: editToggle.hovered ? shellRoot.foreground : shellRoot.outline
                Text {
                    anchors.centerIn: parent
                    text: "✓"
                    visible: editToggle.checked
                    color: shellRoot.foreground
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }
            }
            contentItem: Text {
                text: editToggle.text
                color: shellRoot.foreground
                leftPadding: editToggle.indicator.width + editToggle.spacing
                verticalAlignment: Text.AlignVCenter
                font.family: "Adwaita Sans"
                font.pixelSize: 14
            }
            background: Rectangle {
                radius: 12
                color: editToggle.down ? shellRoot.raised : editToggle.hovered ? shellRoot.raised : shellRoot.readableSurface
                border.width: editToggle.activeFocus ? 2 : 0
                border.color: shellRoot.foreground
            }
        }
        Text {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: shellRoot.muted; font.pixelSize: 13; lineHeight: 1.3
            text: (shellRoot.captureScope === "window" ? "Hover a window and click to capture it; Escape cancels. " : "") + (shellRoot.captureDestination === "save" ? "Saved to Pictures/Screenshots. The chooser hides before capture." : shellRoot.captureDestination === "clipboard" ? "Copy a PNG, ready to paste. Escape cancels region selection." : "Copies the image and opens Google Images. Choose the Lens camera and paste; no automatic upload.")
        }
        StyledButton {
            Layout.fillWidth: true; implicitHeight: 46
            text: "Capture " + ({region: "region", window: "window", output: "display"})[shellRoot.captureScope]
            surfaceColor: shellRoot.accentContainer; hoverColor: shellRoot.raised; textColor: shellRoot.foreground
            onClicked: shellRoot.screenshot(shellRoot.captureScope, shellRoot.captureDestination)
        }
        Text { text: "h j k l  move   ·   Enter  select   ·   Esc  close"; color: shellRoot.muted; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
    }
    VimNavigation { window: capturePanel }
}
