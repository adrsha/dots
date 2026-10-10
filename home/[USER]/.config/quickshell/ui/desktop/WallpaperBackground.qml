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

Variants {
        property var shellRoot
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { left: true; right: true; top: true; bottom: true }
            exclusionMode: ExclusionMode.Ignore
            // Keep the transparent desktop input surface above mpvpaper, but below apps.
            WlrLayershell.layer: shellRoot.videoRunning ? WlrLayer.Bottom : WlrLayer.Background
            WlrLayershell.namespace: "quickshell-wallpaper"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            visible: true
            color: shellRoot.videoRunning ? "transparent" : "#141524"
            Process {
                id: workspaceSwitch
                stdout: StdioCollector { onStreamFinished: if (text.includes("error")) console.warn("Desktop workspace dispatch:", text.trim()) }
                stderr: StdioCollector { onStreamFinished: if (text.trim()) console.warn("Desktop workspace dispatch:", text.trim()) }
            }
            Timer { id: scrollCooldown; interval: 180 }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                property real wheelTravel: 0
                property int lastDirection: 0
                onWheel: event => {
                    // Horizontal scrolling belongs to neither workspace direction.
                    const delta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y
                    if (delta === 0) { event.accepted = false; return }
                    event.accepted = true
                    if (scrollCooldown.running || workspaceSwitch.running) return
                    const direction = delta > 0 ? 1 : -1
                    if (direction !== lastDirection) wheelTravel = 0
                    lastDirection = direction
                    wheelTravel += delta
                    const threshold = event.pixelDelta.y !== 0 ? 40 : 120
                    if (Math.abs(wheelTravel) < threshold) return
                    wheelTravel = 0
                    // Focus the pointer's monitor, then select the adjacent numeric workspace.
                    // This Hyprland installation uses Lua dispatcher expressions.
                    workspaceSwitch.command = ["hyprctl", "--batch",
                        "dispatch hl.dsp.focus({ monitor = " + JSON.stringify(modelData.name) + " }); " +
                        "dispatch hl.dsp.focus({ workspace = " + JSON.stringify(direction < 0 ? "+1" : "-1") + " })"]
                    workspaceSwitch.running = true
                    scrollCooldown.restart()
                }
            }
            Image {
                anchors.fill: parent
                visible: !shellRoot.videoRunning
                source: shellRoot.activeVideoPath ? (shellRoot.activeVideoStill ? "file://" + shellRoot.activeVideoStill : "") : (shellRoot.wallpaperPath ? "file://" + shellRoot.wallpaperPath : "")
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }
        }
    }

