import QtQuick

// Window-local normal mode. Text inputs keep every printable key untouched.
Item {
    id: nav
    required property var window
    property var rootItem: window.contentItem
    property var moveHandler: null
    property var activateHandler: null
    property var boundaryHandler: null
    property var searchHandler: null
    property var escapeHandler: null
    readonly property var focused: window._backingWindow ? window._backingWindow.activeFocusItem : null
    readonly property bool editing: !!focused && (typeof focused.cursorPosition === "number" || focused.vimEditing === true)
    readonly property bool normal: enabled && window.visible && !editing
    function targets() {
        const result = []
        function visit(item) {
            if (!item || !item.visible || !item.enabled) return
            if (item.vimNavigable === true) result.push(item)
            for (const child of item.children || []) visit(child)
        }
        visit(rootItem)
        return result
    }
    function move(delta, vertical) {
        if (moveHandler) { moveHandler(delta, vertical); return }
        const items = targets()
        if (!items.length) return
        const current = items.indexOf(focused)
        let next = current < 0 ? (delta < 0 ? items.length - 1 : 0) : current
        if (current >= 0) {
            const origin = items[current].mapToItem(rootItem, items[current].width / 2, items[current].height / 2)
            let best = Infinity
            for (let i = 0; i < items.length; ++i) {
                if (i === current) continue
                const point = items[i].mapToItem(rootItem, items[i].width / 2, items[i].height / 2)
                const dx = point.x - origin.x, dy = point.y - origin.y
                const forward = (vertical ? dy : dx) * delta
                const cross = Math.abs(vertical ? dx : dy)
                // Only move in the requested direction, preferring the same row/column.
                if (forward <= 1 || cross > forward) continue
                const score = forward + cross * 4
                if (score < best) { best = score; next = i }
            }
        }
        items[next].forceActiveFocus()
        // Keep focus targets in view, including notification actions.
        let ancestor = items[next].parent
        while (ancestor) {
            if (typeof ancestor.contentY === "number" && typeof ancestor.contentHeight === "number") {
                const point = items[next].mapToItem(ancestor.contentItem, 0, 0)
                ancestor.contentY = Math.max(0, Math.min(ancestor.contentHeight - ancestor.height, point.y - ancestor.height / 2))
            }
            ancestor = ancestor.parent
        }
    }
    function boundary(last) {
        if (boundaryHandler) { boundaryHandler(last); return }
        const items = targets()
        if (items.length) items[last ? items.length - 1 : 0].forceActiveFocus()
    }
    function activate() {
        if (activateHandler) { activateHandler(); return }
        if (focused && typeof focused.vimActivate === "function") focused.vimActivate()
    }
    Shortcut { sequence: "H"; enabled: nav.normal; onActivated: nav.move(-1) }
    Shortcut { sequence: "K"; enabled: nav.normal; onActivated: nav.move(-1, true) }
    Shortcut { sequence: "J"; enabled: nav.normal; onActivated: nav.move(1, true) }
    Shortcut { sequence: "L"; enabled: nav.normal; onActivated: nav.move(1) }
    Shortcut { sequence: "G"; enabled: nav.normal; onActivated: nav.boundary(false) }
    Shortcut { sequence: "Shift+G"; enabled: nav.normal; onActivated: nav.boundary(true) }
    Shortcut { sequence: "Return"; enabled: nav.normal; onActivated: nav.activate() }
    Shortcut { sequence: "Enter"; enabled: nav.normal; onActivated: nav.activate() }
    Shortcut { sequence: "I"; enabled: nav.normal && !!nav.searchHandler; onActivated: nav.searchHandler() }
    Shortcut { sequence: "/"; enabled: nav.normal && !!nav.searchHandler; onActivated: nav.searchHandler() }
    Shortcut { sequence: "Escape"; enabled: nav.enabled && nav.window.visible; onActivated: {
        if (nav.escapeHandler) nav.escapeHandler()
        else if (nav.editing) nav.rootItem.forceActiveFocus()
        else nav.window.shellRoot.page = ""
    } }
}
