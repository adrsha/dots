import QtQuick 2.15
import QtTest 1.3
import "../../ui/components"
Item {
    width: 400; height: 100
    StudioField { id: field; width: 300; normalModeKey: "jk"; jkTimeoutMs: 100 }
    TestCase {
        name: "InsertChord"
        when: windowShown
        function init() { field.text = ""; field.normalModeKey = "jk"; field.forceActiveFocus(); wait(5) }
        function test_quick() {
            keyClick(Qt.Key_J); compare(field.text, "j")
            keyClick(Qt.Key_K); compare(field.text, ""); verify(!field.activeFocus)
        }
        function test_slow() {
            keyClick(Qt.Key_J); wait(150); keyClick(Qt.Key_K)
            compare(field.text, "jk"); verify(field.activeFocus)
        }
        function test_intervening() {
            keyClick(Qt.Key_J); keyClick(Qt.Key_A); keyClick(Qt.Key_K)
            compare(field.text, "jak"); verify(field.activeFocus)
        }
        function test_disabled() {
            field.normalModeKey = "escape"
            keyClick(Qt.Key_J); keyClick(Qt.Key_K)
            compare(field.text, "jk"); verify(field.activeFocus)
        }
        function test_middle() {
            field.text = "abc"; field.cursorPosition = 1
            keyClick(Qt.Key_J); keyClick(Qt.Key_K)
            compare(field.text, "abc"); verify(!field.activeFocus)
        }
    }
}
