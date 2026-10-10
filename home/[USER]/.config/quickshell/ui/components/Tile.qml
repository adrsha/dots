import QtQuick

Rectangle {
    id: tile
    property var shellRoot
    property bool vimNavigable: true
    property bool stacked: false
    property bool selected: false
    property string title: ""
    property string subtitle: ""
    property string iconGlyph: {
        const label = title.toLowerCase()
        return label.includes("wi-fi") ? "\ue63e"
            : label.includes("bluetooth") ? "\ue1a7"
            : label.includes("volume down") ? "\ue04d"
            : label.includes("volume") ? "\ue050"
            : label.includes("brightness down") ? "\ue1ad"
            : label.includes("brightness") ? "\ue1ac"
            : label.includes("network") ? "\ue1ba"
            : label.includes("applications") ? "\ue5c3"
            : label.includes("controls") ? "\ue429"
            : label.includes("wallpaper") ? "\ue1bc"
            : label.includes("music") ? "\ue405"
            : label.includes("notifications") ? "\ue7f4"
            : label.includes("lock") ? "\ue897"
            : label.includes("session") ? "\ue8ac"
            : label.includes("previous") ? "\ue045"
            : label.includes("next") ? "\ue044"
            : label.includes("play") ? "\ue034"
            : "\ue8ef"
    }
    signal activated()
    function vimActivate() { activated() }
    activeFocusOnTab: true
    implicitWidth: stacked ? 160 : (parent ? parent.width : 480)
    implicitHeight: stacked ? 116 : (subtitle ? 68 : 52)
    radius: 17
    color: activeFocus || hover.containsMouse ? shellRoot.raised : selected ? shellRoot.accentContainer : shellRoot.readableSurface
    border.width: activeFocus ? 2 : 0
    border.color: shellRoot.accent
    FontLoader { id: symbols; source: Qt.resolvedUrl("../../assets/fonts/MaterialSymbolsRounded.ttf") }
    Text {
        id: glyph
        x: tile.stacked ? (tile.width - width) / 2 : 14
        y: tile.stacked ? 14 : (tile.height - height) / 2
        width: 30; height: 30
        text: tile.iconGlyph
        font.family: symbols.name; font.pixelSize: 28
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        color: tile.selected ? shellRoot.accent : shellRoot.foreground
    }
    Column {
        x: tile.stacked ? 10 : 56
        y: tile.stacked ? 53 : (tile.height - height) / 2
        width: tile.width - x - (tile.stacked ? 10 : 14)
        spacing: 5
        Text { text: tile.title; color: shellRoot.foreground; font.pixelSize: tile.stacked ? 13 : 15; font.weight: Font.Medium; elide: Text.ElideRight; width: parent.width; horizontalAlignment: tile.stacked ? Text.AlignHCenter : Text.AlignLeft }
        Text { visible: tile.subtitle !== ""; text: tile.subtitle; color: shellRoot.muted; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width; horizontalAlignment: tile.stacked ? Text.AlignHCenter : Text.AlignLeft }
    }
    MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tile.activated() }
}
