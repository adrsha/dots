import QtQuick
import QtQuick.Controls
import Quickshell.Widgets

Button {
    id: control
    property bool vimNavigable: true
    property bool borderless: false
    function vimActivate() { clicked() }
    activeFocusOnTab: true
    property color surfaceColor: "#292832"
    property color hoverColor: "#35333e"
    property color pressedColor: "#49405b"
    property color textColor: "#f1eff5"
    property bool reduceMotion: false // Set true to disable hover and press transitions.
    property string iconSource: ""
    // Bundled Material Symbols work even when the system icon theme is absent.
    property string iconGlyph: {
        const label = text.toLowerCase()
        return label.startsWith("capture") ? "\ue412"
            : label.includes("search") ? "\ue8b6"
            : label.includes("save") || label === "file" ? "\ue161"
            : label.includes("clipboard") ? "\ue14d"
            : label === "lens" ? "\ue3f5"
            : label.includes("source") ? "\ue89e"
            : label === "region" ? "\ue3be"
            : label === "window" ? "\ue8ef"
            : label === "display" ? "\ue30a"
            : label.includes("refresh") ? "\ue5d5"
            : label.includes("import") ? "\ue2c7"
            : label.includes("delete") ? "\ue872"
            : label.includes("wallpaper") || label.includes("local") ? "\ue1bc"
            : label.includes("manage") ? "\ue8b8"
            : label.includes("move") ? "\ue8d4"
            : ""
    }
    readonly property bool hasIcon: !!iconSource || !!iconGlyph
    FontLoader { id: symbols; source: Qt.resolvedUrl("../../assets/fonts/MaterialSymbolsRounded.ttf") }
    implicitHeight: 42
    implicitWidth: Math.max(48, label.implicitWidth + (hasIcon ? 55 : 28))
    font.family: "Adwaita Sans"
    background: Rectangle {
        border.width: !control.borderless && control.activeFocus ? 3 : 0
        border.color: control.textColor
        radius: 12; color: control.down ? control.pressedColor : control.hovered || control.activeFocus ? control.hoverColor : control.surfaceColor
        Behavior on color { ColorAnimation { duration: control.reduceMotion ? 0 : 100; easing.type: Easing.OutCubic } }
    }
    contentItem: Item {
        opacity: control.enabled ? 1 : 0.45
        Row {
            anchors.centerIn: parent
            spacing: 7
            height: Math.max(label.implicitHeight, control.hasIcon ? 22 : 0)
            IconImage { width: visible ? 16 : 0; height: 16; anchors.verticalCenter: parent.verticalCenter; visible: !!control.iconSource; source: control.iconSource }
            Text {
                visible: !control.iconSource && !!control.iconGlyph
                width: visible ? 22 : 0; height: 22
                anchors.verticalCenter: parent.verticalCenter
                text: control.iconGlyph; font.family: symbols.name; font.pixelSize: 22
                color: control.textColor
            }
            Text {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                text: control.text
                color: control.textColor
                font.family: control.font.family
                font.pixelSize: 13
                font.weight: Font.Medium
                width: Math.min(implicitWidth, Math.max(0, control.width - (control.hasIcon ? 55 : 28)))
                elide: Text.ElideRight
            }
        }
    }
}
