import QtQuick

// Keep the layout's wrap width, but paint contrast only behind actual text bounds.
Text {
    id: label
    property color backingColor: "#292832"
    property int backingPadding: 6
    Rectangle {
        z: -1
        x: -label.backingPadding
        y: -3
        width: Math.min(label.width, label.contentWidth) + label.backingPadding * 2
        height: label.contentHeight + 6
        radius: 8
        color: label.backingColor
        visible: label.text.length > 0
    }
}
