import QtQuick
import QtTest
import "../../ui/components"
Item {
    width: 400; height: 200
    ContrastText { id: label; width: 300; font.pixelSize: 15; text: "Short text" }
    TestCase {
        name: "ContrastText"
        when: windowShown
        function test_background_hugs_text() {
            wait(10)
            verify(label.contentWidth < label.width)
            compare(label.children[0].width, label.contentWidth + label.backingPadding * 2)
            verify(label.children[0].width < label.width)
        }
        function test_wrapped_text_stays_within_layout() {
            label.text = "A longer notification message that wraps over several lines and keeps its backing within the available layout."
            label.wrapMode = Text.Wrap
            wait(10)
            verify(label.contentHeight > 20)
            verify(label.children[0].width <= label.width + label.backingPadding * 2)
        }
    }
}
