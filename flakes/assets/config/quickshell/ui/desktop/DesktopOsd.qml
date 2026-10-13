import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: osd
    required property var shellRoot
    readonly property bool showing: shellRoot.osdKind !== "" && shellRoot.page !== "screenshot"
    // Retain content while fading out, rather than briefly displaying an empty card.
    property string kind: ""
    property string message: ""
    property real value: -1
    readonly property bool levelOsd: kind === "volume" || kind === "brightness"
    readonly property bool hasLevel: levelOsd && value >= 0
    readonly property bool motion: !shellRoot.reduceMotion
    function updateContent() {
        if (!showing) return
        kind = shellRoot.osdKind
        message = shellRoot.osdMessage
        value = shellRoot.osdValue
    }
    Component.onCompleted: updateContent()
    Connections {
        target: osd.shellRoot
        function onOsdKindChanged() { osd.updateContent() }
        function onOsdMessageChanged() { osd.updateContent() }
        function onOsdValueChanged() { osd.updateContent() }
        function onPageChanged() { osd.updateContent() }
    }
    screen: Quickshell.screens.find(s => s.name === (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "")) || Quickshell.screens[0]
    visible: showing || card.opacity > 0
    anchors { bottom: true; left: true }
    margins { bottom: 42; left: Math.max(0, ((screen ? screen.width : 1920) - implicitWidth) / 2) }
    implicitWidth: Math.min(360, (screen ? screen.width : 1920) - 32)
    implicitHeight: 124
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    FontLoader { id: symbols; source: Qt.resolvedUrl("../../assets/fonts/MaterialSymbolsRounded.ttf") }
    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 4
        radius: 28
        color: shellRoot.surface
        opacity: osd.showing ? 1 : 0
        scale: osd.showing ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: osd.motion ? 160 : 0; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: osd.motion ? 220 : 0; easing.type: Easing.OutCubic } }
        RowLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 16
            Rectangle {
                Layout.preferredWidth: 52; Layout.preferredHeight: 52
                Layout.alignment: Qt.AlignVCenter
                radius: 18
                color: shellRoot.accentContainer
                Text {
                    anchors.centerIn: parent
                    text: osd.kind === "brightness" ? "\ue1ac" : osd.kind === "volume" ? (osd.value === 0 ? "\ue04f" : "\ue050") : "\ue3b0"
                    font.family: symbols.name; font.pixelSize: 28
                    color: shellRoot.foreground
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Text {
                        Layout.fillWidth: true
                        text: osd.levelOsd ? (osd.kind === "volume" ? "Volume" : "Brightness") : "Screenshot"
                        color: shellRoot.foreground
                        font.family: "Adwaita Sans"; font.pixelSize: 16; font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Text {
                        visible: osd.hasLevel
                        text: Math.round(osd.value) + "%"
                        color: shellRoot.foreground
                        font.family: "Adwaita Sans"; font.pixelSize: 16; font.weight: Font.Medium
                    }
                }
                Rectangle {
                    visible: osd.hasLevel
                    Layout.fillWidth: true; Layout.preferredHeight: 10
                    radius: 5; color: shellRoot.inset
                    Rectangle {
                        width: Math.max(0, Math.min(1, osd.value / 100)) * parent.width
                        height: parent.height; radius: 5; color: shellRoot.accent
                        Behavior on width { NumberAnimation { duration: osd.motion ? 180 : 0; easing.type: Easing.OutCubic } }
                    }
                }
                Text {
                    visible: !osd.hasLevel
                    Layout.fillWidth: true
                    text: osd.message
                    color: shellRoot.muted
                    font.family: "Adwaita Sans"; font.pixelSize: 12
                    wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                }
            }
        }
    }
}
