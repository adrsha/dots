import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: card
    required property var entry
    property string normalModeKey: "escape"
    property int jkTimeoutMs: 250
    property bool compact: false
    property bool reduceMotion: false
    property color surfaceColor: "#292832"
    property color contentColor: "#292832"
    property color badgeColor: "#49405b"
    property color raisedColor: "#35333e"
    property color textColor: "#f1eff5"
    property color mutedColor: "#bcb8c6"
    property color accentColor: "#d4c4f4"
    property color outlineColor: "#494652"
    signal dismissed()
    signal openCenter()
    signal replyRequested()
    signal replySent()

    readonly property var live: entry ? entry.live : null
    readonly property var actions: live ? live.actions : []
    readonly property var progress: live ? live.hints.value : (entry ? entry.progress : undefined)
    readonly property bool hasProgress: typeof progress === "number" && isFinite(progress) && progress >= 0
    readonly property string icon: live ? live.appIcon : (entry ? entry.icon : "")
    readonly property string picture: live ? live.image : (entry ? entry.picture : "")
    function imageSource(value) {
        if (!value) return ""
        if (/^(image:|file:|data:|qrc:|https?:)/.test(value)) return value
        if (value[0] === "/") return "file://" + value
        return Quickshell.iconPath(value, true)
    }

    readonly property string resolvedIcon: imageSource(icon)

    implicitHeight: content.implicitHeight + 48
    radius: 22
    color: surfaceColor
    border.width: 0

    Rectangle {
        anchors.fill: parent
        anchors.margins: 10
        radius: 16
        color: card.contentColor
    }
    Rectangle {
        visible: card.entry && card.entry.urgency === 2
        x: 10; y: 24; width: 3; height: 28; radius: 1.5
        color: card.accentColor
    }
    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 24
        spacing: 12
        Row {
            width: parent.width
            spacing: 10
            Item {
                width: 48; height: 48
                Rectangle { anchors.fill: parent; radius: 16; color: card.badgeColor }
                IconImage { anchors.fill: parent; anchors.margins: 6; visible: !!card.resolvedIcon; source: card.resolvedIcon; asynchronous: true }
                Text { anchors.centerIn: parent; visible: !card.resolvedIcon; text: (card.entry && card.entry.app ? card.entry.app[0] : "•").toUpperCase(); color: card.accentColor; font.pixelSize: 18; font.weight: Font.DemiBold }
            }
            Column {
                width: parent.width - 48 - 10 - 32 - 10
                spacing: 3
                Text { text: card.entry ? (card.entry.app || "Application") : ""; color: card.textColor; opacity: 0.82; font.pixelSize: 13; font.weight: Font.Medium; width: parent.width; elide: Text.ElideRight; textFormat: Text.PlainText }
                Text { text: card.entry ? card.entry.title : ""; color: card.textColor; font.pixelSize: 17; font.weight: Font.DemiBold; width: parent.width; wrapMode: Text.Wrap; maximumLineCount: card.compact ? 2 : 5; elide: Text.ElideRight; textFormat: Text.PlainText }
            }
            Rectangle {
                width: 32; height: 32; radius: 16; color: closeHover.containsMouse ? card.raisedColor : card.contentColor
                Text { anchors.centerIn: parent; text: "×"; color: card.textColor; font.pixelSize: 22 }
                MouseArea { id: closeHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: card.dismissed() }
            }
        }
        Text {
            visible: !!text
            text: card.entry ? card.entry.body : ""
            width: parent.width
            color: card.textColor
            font.family: "Adwaita Sans"
            font.pixelSize: 15
            lineHeight: 1.25
            wrapMode: Text.Wrap
            maximumLineCount: card.compact ? 4 : 12
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
        Image {
            visible: !!card.picture && status === Image.Ready
            source: card.imageSource(card.picture)
            width: parent.width
            height: visible ? Math.min(card.compact ? 110 : 200, implicitHeight * width / Math.max(1, implicitWidth)) : 0
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
        Column {
            visible: card.hasProgress
            width: parent.width
            spacing: 4
            Text { text: Math.round(Math.max(0, Math.min(100, card.progress))) + "%"; color: card.textColor; font.pixelSize: 13 }
            Rectangle {
                width: parent.width; height: 8; radius: 4; color: card.raisedColor
                Rectangle { width: parent.width * Math.max(0, Math.min(100, card.progress)) / 100; height: parent.height; radius: parent.radius; color: card.accentColor }
            }
        }
        Flow {
            visible: card.actions.length > 0
            width: parent.width
            spacing: 6
            Repeater {
                model: card.actions
                delegate: StyledButton {
                    required property var modelData
                    text: modelData.text
                    reduceMotion: card.reduceMotion
                    iconSource: card.live && card.live.hasActionIcons && modelData.identifier ? card.imageSource(modelData.identifier) : ""
                    width: Math.min(implicitWidth, content.width)
                    height: 40
                    surfaceColor: card.raisedColor; hoverColor: card.badgeColor; pressedColor: card.badgeColor; textColor: card.textColor
                    onClicked: if (card.live) modelData.invoke()
                }
            }
        }
        Row {
            visible: !!card.live && card.live.hasInlineReply
            width: parent.width
            spacing: 6
            StudioField {
                id: reply
                normalModeKey: card.normalModeKey
                jkTimeoutMs: card.jkTimeoutMs
                width: parent.width - 65
                height: 34
                placeholderText: card.live ? (card.live.inlineReplyPlaceholder || "Reply…") : "Reply…"
                reduceMotion: card.reduceMotion; inkColor: card.textColor
                hintColor: card.mutedColor
                surfaceColor: card.raisedColor
                focusColor: card.surfaceColor
                TapHandler { onTapped: card.replyRequested() }
                onAccepted: sendReply()
                function sendReply() { if (card.live && text.trim()) { card.live.sendInlineReply(text); text = ""; card.replySent() } }
            }
            StyledButton {
                width: 59; height: 34; text: "Send"; reduceMotion: card.reduceMotion
                surfaceColor: card.raisedColor; hoverColor: card.badgeColor; pressedColor: card.badgeColor; textColor: card.textColor
                onClicked: reply.sendReply()
            }
        }
        Text {
            visible: card.compact
            text: "View all notifications  →"
            color: card.textColor
            font.pixelSize: 13
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: card.openCenter() }
        }
    }
}
