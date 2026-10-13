import QtQuick
import QtQuick.Controls

ComboBox {
    id: picker
    property bool vimNavigable: true
    property bool borderless: false
    property bool vimEditing: popup.visible
    function vimActivate() { popup.open() }
    property color surfaceColor: "#292832"
    property color hoverColor: "#35333e"
    property color inkColor: "#f1eff5"
    property color hintColor: "#bcb8c6"
    property bool reduceMotion: false // Set true to disable spatial and color transitions.
    implicitHeight: 42
    leftPadding: 14
    rightPadding: 34
    font.family: "Adwaita Sans"
    font.pixelSize: 13
    delegate: ItemDelegate {
        required property int index
        required property var modelData
        width: picker.popup.width - 8
        height: 38
        x: 4
        text: String(modelData)
        font.family: picker.font.family
        font.pixelSize: 13
        contentItem: Text { text: parent.text; color: picker.inkColor; font: parent.font; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; leftPadding: 10 }
        background: Rectangle { radius: 10; color: parent.highlighted ? picker.hoverColor : "transparent"; Behavior on color { ColorAnimation { duration: picker.reduceMotion ? 0 : 140 } } }
    }
    FontLoader { id: symbols; source: Qt.resolvedUrl("../../assets/fonts/MaterialSymbolsRounded.ttf") }
    indicator: Text {
        x: picker.width - width - 12; anchors.verticalCenter: parent.verticalCenter
        text: "\ue5cf"; color: picker.hintColor; font.family: symbols.name; font.pixelSize: 22
        rotation: picker.popup.visible ? 180 : 0
        
    }
    contentItem: Text {
        text: picker.displayText
        font: picker.font
        color: picker.inkColor
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        leftPadding: picker.leftPadding
        rightPadding: picker.rightPadding
    }
    background: Rectangle {
        border.width: !picker.borderless && picker.activeFocus ? 3 : 0
        border.color: picker.inkColor
        radius: picker.borderless ? 16 : 12; color: picker.hovered || picker.activeFocus || picker.popup.visible ? picker.hoverColor : picker.surfaceColor
        Behavior on color { ColorAnimation { duration: picker.reduceMotion ? 0 : 170; easing.type: Easing.OutCubic } }
    }
    Keys.onPressed: event => {
        if (popup.visible && (event.key === Qt.Key_J || event.key === Qt.Key_K)) {
            const next = Math.max(0, Math.min(count - 1, highlightedIndex + (event.key === Qt.Key_J ? 1 : -1)))
            currentIndex = next
            event.accepted = true
        }
    }
    popup: Popup {
        y: picker.height + 5
        width: picker.width
        implicitHeight: Math.min(300, contentItem.implicitHeight + 8)
        padding: 4
        background: Rectangle { radius: 14; color: picker.surfaceColor; border.width: picker.borderless ? 0 : 2; border.color: picker.inkColor }
        contentItem: ListView { clip: true; implicitHeight: contentHeight; model: picker.delegateModel; currentIndex: picker.highlightedIndex; boundsBehavior: Flickable.StopAtBounds }
    }
}
