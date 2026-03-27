import Cocoa

protocol TreeSelectionDelegate: AnyObject {
    func treeDidSelectDirectory(_ url: URL)
}

class TreeOutlineDelegate: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {

    weak var selectionDelegate: TreeSelectionDelegate?
    var rootItem: FileSystemItem?

    // MARK: - NSOutlineViewDataSource

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return rootItem?.directoryChildren.count ?? 0
        }
        guard let fsItem = item as? FileSystemItem else { return 0 }
        return fsItem.directoryChildren.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            guard let root = rootItem, index < root.directoryChildren.count else { return NSObject() }
            return root.directoryChildren[index]
        }
        guard let fsItem = item as? FileSystemItem, index < fsItem.directoryChildren.count else { return NSObject() }
        return fsItem.directoryChildren[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let fsItem = item as? FileSystemItem else { return false }
        return fsItem.isDirectory && !fsItem.directoryChildren.isEmpty
    }

    // MARK: - Drag Source

    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> (any NSPasteboardWriting)? {
        guard let fsItem = item as? FileSystemItem else { return nil }
        return fsItem.url as NSURL
    }

    // MARK: - Drop Target

    func outlineView(_ outlineView: NSOutlineView, validateDrop info: any NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        // Only accept drops onto directories
        guard let targetItem = item as? FileSystemItem, targetItem.isDirectory else {
            return []
        }

        // Don't allow dropping onto itself or into a child of the dragged item
        if let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
            for url in urls {
                let sourceStd = url.standardizedFileURL
                let targetStd = targetItem.url.standardizedFileURL
                if sourceStd == targetStd { return [] }
                if sourceStd.deletingLastPathComponent().standardizedFileURL == targetStd { return [] }
                if targetStd.path.hasPrefix(sourceStd.path + "/") { return [] }
            }
        }

        return NSEvent.modifierFlags.contains(.option) ? .copy : .move
    }

    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: any NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        guard let targetItem = item as? FileSystemItem, targetItem.isDirectory,
              let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
              !urls.isEmpty else { return false }

        let isOption = NSEvent.modifierFlags.contains(.option)
        let operation: FileOperation = isOption
            ? .copy(sources: urls, destination: targetItem.url)
            : .move(sources: urls, destination: targetItem.url)

        FileOperationQueue.shared.execute(operation) { result in
            if case .failure(let error) = result {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }

        return true
    }

    // MARK: - NSOutlineViewDelegate

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let fsItem = item as? FileSystemItem else { return nil }

        let identifier = NSUserInterfaceItemIdentifier("TreeCell")
        let cellView: NSTableCellView

        if let existing = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
            cellView = existing
        } else {
            cellView = NSTableCellView()
            cellView.identifier = identifier

            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            cellView.addSubview(imageView)
            cellView.imageView = imageView

            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.font = WinFileFonts.treeView
            textField.lineBreakMode = .byTruncatingTail
            cellView.addSubview(textField)
            cellView.textField = textField

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 2),
                imageView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 16),
                imageView.heightAnchor.constraint(equalToConstant: 16),
                textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -2),
                textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
            ])
        }

        cellView.textField?.stringValue = fsItem.name
        cellView.imageView?.image = fsItem.icon

        return cellView
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return WinFileTheme.rowHeight
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let outlineView = notification.object as? NSOutlineView else { return }
        let selectedRow = outlineView.selectedRow
        guard selectedRow >= 0,
              let item = outlineView.item(atRow: selectedRow) as? FileSystemItem else { return }
        selectionDelegate?.treeDidSelectDirectory(item.url)
    }
}
