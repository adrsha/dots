import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets

import "../components"

    PanelWindow {
        id: notificationPopup
        property var shellRoot
        visible: shellRoot.popupEntries.length > 0 && shellRoot.page === ""
        anchors { top: true; right: true }
        margins { top: 14; right: 14 }
        implicitWidth: Math.min(440, screen ? screen.width - 28 : 440)
        implicitHeight: Math.min(screen ? screen.height - 28 : 900, popupStack.implicitHeight)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-notification-popup"
        // Passive arrivals never request keyboard focus; reply requests it on user click.
        WlrLayershell.keyboardFocus: shellRoot.popupReplyFocus ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        mask: Region { item: popupStack }
        Column {
            id: popupStack
            width: parent.width
            spacing: 10
            clip: true
            Repeater {
                model: shellRoot.popupEntries
                delegate: NotificationCard {
                    id: popupCard
                    required property var modelData
                    width: popupStack.width
                    normalModeKey: shellRoot.normalModeKey; jkTimeoutMs: shellRoot.jkTimeoutMs
                    entry: modelData
                    compact: true
                    property bool paused: popupHover.hovered
                    HoverHandler { id: popupHover }
                    Timer { interval: 5500; running: !popupCard.paused && notificationPopup.visible && !popupCard.modelData.persistent; onTriggered: notificationPopup.shellRoot.hidePopup(popupCard.modelData.id) }
                    surfaceColor: notificationPopup.shellRoot.surface
                    contentColor: notificationPopup.shellRoot.readableSurface
                    badgeColor: notificationPopup.shellRoot.accentContainer
                    reduceMotion: notificationPopup.shellRoot.reduceMotion
                    raisedColor: notificationPopup.shellRoot.raised
                    textColor: notificationPopup.shellRoot.foreground
                    mutedColor: notificationPopup.shellRoot.muted
                    accentColor: notificationPopup.shellRoot.accent
                    outlineColor: notificationPopup.shellRoot.outline
                    onReplyRequested: notificationPopup.shellRoot.popupReplyFocus = true
                    onReplySent: notificationPopup.shellRoot.popupReplyFocus = false
                    onDismissed: {
                        if (modelData.live) modelData.live.dismiss()
                        notificationPopup.shellRoot.hidePopup(modelData.id)
                    }
                    onOpenCenter: notificationPopup.shellRoot.show("notifications")
                }
            }
        }
        VimNavigation { window: notificationPopup; enabled: notificationPopup.shellRoot.popupReplyFocus }
}
