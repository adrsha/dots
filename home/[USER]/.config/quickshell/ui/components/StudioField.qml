import QtQuick
import QtQuick.Controls

TextField {
    id: field
    property bool vimNavigable: true
    property bool borderless: false
    property string normalModeKey: "escape"
    property int jkTimeoutMs: 250
    property int chordPosition: -1
    function leaveInsert() {
        chordTimer.stop()
        chordPosition = -1
        let root = field
        while (root.parent) root = root.parent
        field.focus = false
        root.forceActiveFocus()
    }
    onActiveFocusChanged: { chordTimer.stop(); chordPosition = -1 }
    Timer { id: chordTimer; interval: field.jkTimeoutMs; onTriggered: field.chordPosition = -1 }
    Keys.forwardTo: [chordReceiver]
    Item {
        id: chordReceiver
        Keys.onPressed: event => {
            if (field.normalModeKey !== "jk" || event.modifiers !== Qt.NoModifier || event.isAutoRepeat) {
                chordTimer.stop(); field.chordPosition = -1; return
            }
            if (event.key === Qt.Key_K && chordTimer.running && field.cursorPosition === field.chordPosition + 1
                && field.selectedText === "" && field.text.charAt(field.chordPosition) === "j") {
                field.remove(field.chordPosition, field.chordPosition + 1)
                field.leaveInsert()
                event.accepted = true
            } else if (event.key === Qt.Key_J && field.selectedText === "") {
                field.chordPosition = field.cursorPosition
                chordTimer.restart()
            } else {
                chordTimer.stop(); field.chordPosition = -1
            }
        }
    }
    function vimActivate() { forceActiveFocus() }
    property color surfaceColor: "#292832"
    property color focusColor: "#35333e"
    property color inkColor: "#f1eff5"
    property color hintColor: "#bcb8c6"
    property bool reduceMotion: false // Set true to disable focus color transition.
    property int cornerRadius: 12
    property string leadingIcon: ""
    implicitHeight: 42
    color: inkColor
    placeholderTextColor: hintColor
    font.family: "Adwaita Sans"
    font.pixelSize: 14
    selectByMouse: true
    leftPadding: leadingIcon ? 40 : 14
    rightPadding: 14
    // Escape belongs to the editor before window-level normal-mode shortcuts.
    Keys.onShortcutOverride: event => {
        if (event.key === Qt.Key_Escape || (field.activeFocus && field.normalModeKey === "jk"
            && event.modifiers === Qt.NoModifier && (event.key === Qt.Key_J || event.key === Qt.Key_K))) event.accepted = true
    }
    Keys.onEscapePressed: event => {
        let root = field
        while (root.parent) root = root.parent
        field.focus = false
        root.forceActiveFocus()
        event.accepted = true
    }
    background: Rectangle {
        border.width: !field.borderless && field.activeFocus ? 3 : 0
        border.color: field.inkColor
        radius: field.cornerRadius
        color: field.activeFocus ? field.focusColor : field.surfaceColor
        Behavior on color { ColorAnimation { duration: field.reduceMotion ? 0 : 180; easing.type: Easing.OutCubic } }
        Text { visible: !!field.leadingIcon; anchors.left: parent.left; anchors.leftMargin: 13; anchors.verticalCenter: parent.verticalCenter; text: field.leadingIcon; color: field.hintColor; font.pixelSize: 24 }
    }
}
