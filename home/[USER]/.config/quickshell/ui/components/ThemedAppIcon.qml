import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

// Two-tone theme tile. Preserve artwork luminance so opaque legacy icons
// retain internal detail instead of becoming a solid, tinted square.
Rectangle {
    id: tile
    required property var shellRoot
    property string source: ""
    property real insetRatio: 0.18
    radius: width * 0.30
    color: shellRoot.accentContainer
    Image {
        anchors.fill: parent
        anchors.margins: parent.width * tile.insetRatio
        source: Qt.resolvedUrl("../../assets/icons/application-fallback.svg")
        visible: artwork.status !== Image.Ready
        layer.enabled: true
        layer.effect: MultiEffect { colorization: 1; colorizationColor: tile.shellRoot.foreground }
    }
    IconImage {
        id: artwork
        anchors.fill: parent
        anchors.margins: parent.width * tile.insetRatio
        source: tile.source || Qt.resolvedUrl("../../assets/icons/application-fallback.svg")
        visible: status === Image.Ready
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1
            colorizationColor: tile.shellRoot.foreground
            saturation: -1
        }
    }
}
