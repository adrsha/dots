import QtQuick
import "../components"
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: center
    property var shellRoot
    visible: shellRoot && shellRoot.page === "notifications"
    anchors { top: true; right: true }
    margins { top: 12; right: 12 }
    implicitWidth: Math.min(460, screen ? screen.width - 24 : 460)
    implicitHeight: Math.min(680, screen ? screen.height - 24 : 680)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notification-center"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    Rectangle {
        anchors.fill: parent
        radius: 23; color: shellRoot.surface
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 20; spacing: 16
            RowLayout { Layout.fillWidth: true
                Text { text: "Notifications"; color: shellRoot.foreground; font.family: "Adwaita Sans"; font.pixelSize: 23; font.weight: Font.DemiBold; Layout.fillWidth: true }
                StyledButton { text: "×"; surfaceColor: shellRoot.inset; hoverColor: shellRoot.raised; pressedColor: shellRoot.accentContainer; textColor: shellRoot.foreground; onClicked: shellRoot.page = "" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 8
                StyledButton { Layout.fillWidth: true; text: shellRoot.doNotDisturb ? "◖  Quiet on" : "◐  Quiet off"; surfaceColor: shellRoot.doNotDisturb ? shellRoot.accentContainer : shellRoot.inset; hoverColor: shellRoot.raised; pressedColor: shellRoot.accentContainer; textColor: shellRoot.foreground; onClicked: { shellRoot.doNotDisturb = !shellRoot.doNotDisturb; if (shellRoot.doNotDisturb) { shellRoot.popupEntries = []; shellRoot.popupReplyFocus = false } } }
                StyledButton { Layout.fillWidth: true; text: "⌫  Clear all"; enabled: shellRoot.notificationHistory.length > 0; surfaceColor: shellRoot.inset; hoverColor: shellRoot.raised; pressedColor: shellRoot.accentContainer; textColor: shellRoot.foreground; onClicked: { shellRoot.notificationHistory.forEach(function(n) { if (n.live) n.live.dismiss() }); shellRoot.notificationHistory = [] } }
            }
            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                contentWidth: width; contentHeight: items.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: items; width: parent.width; spacing: 10
                    Text { visible: shellRoot.notificationHistory.length === 0; text: "All caught up\nNew notifications will appear here."; color: shellRoot.muted; font.pixelSize: 15; lineHeight: 1.4 }
                    Repeater { model: shellRoot.notificationHistory
                        delegate: NotificationCard {
                            required property var modelData
                            normalModeKey: shellRoot.normalModeKey; jkTimeoutMs: shellRoot.jkTimeoutMs
                    entry: modelData; width: items.width; reduceMotion: shellRoot.reduceMotion
                            surfaceColor: "transparent"; contentColor: shellRoot.readableSurface; badgeColor: shellRoot.accentContainer; raisedColor: shellRoot.raised; textColor: shellRoot.foreground; mutedColor: shellRoot.muted; accentColor: shellRoot.accent; outlineColor: shellRoot.outline
                            onDismissed: { if (modelData.live) modelData.live.dismiss(); shellRoot.removeNotification(modelData.id) }
                        }
                    }
                }
            }
        }
    }
    VimNavigation { window: center }
}
