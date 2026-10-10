import QtQuick
import QtQuick.Window
import QtTest
import "../../ui/components"

Item {
    id: root
    width: 400; height: 300
    QtObject {
        id: fakeWindow
        property var contentItem: root
        property var _backingWindow: root.Window.window
        property bool visible: true
    }
    Repeater {
        model: 6
        Rectangle {
            required property int index
            property bool vimNavigable: true
            x: (index % 3) * 100; y: Math.floor(index / 3) * 100
            width: 80; height: 80
            objectName: "tile" + index
        }
    }
    StudioField { id: input; y: 230; width: 300; normalModeKey: "jk" }
    VimNavigation { id: nav; window: fakeWindow }
    TestCase {
        name: "DirectionalNavigation"
        when: windowShown
        function tile(index) { return findChild(root, "tile" + index) }
        function init() { tile(0).forceActiveFocus(); wait(5) }
        function test_grid() {
            keyClick(Qt.Key_L); verify(tile(1).activeFocus)
            keyClick(Qt.Key_J); verify(tile(4).activeFocus)
            keyClick(Qt.Key_H); verify(tile(3).activeFocus)
            keyClick(Qt.Key_K); verify(tile(0).activeFocus)
        }
        function test_edges_do_not_wrap() {
            keyClick(Qt.Key_H); verify(tile(0).activeFocus)
            keyClick(Qt.Key_K); verify(tile(0).activeFocus)
            tile(2).forceActiveFocus()
            keyClick(Qt.Key_L); verify(tile(2).activeFocus)
        }
        function test_insert_chord_with_navigation() {
            input.text = ""; input.forceActiveFocus(); wait(5)
            keyClick(Qt.Key_J); compare(input.text, "j")
            keyClick(Qt.Key_K); compare(input.text, ""); verify(!input.activeFocus)
            verify(nav.normal)
        }
        function test_slow_jk_remains_text() {
            input.text = ""; input.forceActiveFocus(); wait(5)
            keyClick(Qt.Key_J); wait(300); keyClick(Qt.Key_K)
            compare(input.text, "jk"); verify(input.activeFocus)
        }
    }
}
