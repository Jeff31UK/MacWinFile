import Cocoa

class TreeOutlineView: NSOutlineView {
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 51, 117: // Backspace, Forward Delete
            NSApp.sendAction(#selector(DirectoryWindowView.deleteSelectedItems), to: nil, from: self)
        case 36: // Return/Enter - open selected
            NSApp.sendAction(#selector(DirectoryWindowView.openSelectedItem), to: nil, from: self)
        default:
            super.keyDown(with: event)
        }
    }
}
