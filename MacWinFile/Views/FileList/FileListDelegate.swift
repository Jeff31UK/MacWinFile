import Cocoa

protocol FileListActionDelegate: AnyObject {
    func fileListDidDoubleClick(_ item: FileSystemItem)
    func fileListSelectionDidChange(selectedItems: [FileSystemItem])
}

class FileListDelegate: NSObject, NSTableViewDataSource, NSTableViewDelegate {

    weak var actionDelegate: FileListActionDelegate?
    var items: [FileSystemItem] = []
    var sortDescriptor: (column: SortColumn, ascending: Bool) = (.name, true)

    enum SortColumn: String {
        case name, size, date, kind
    }

    func sortItems() {
        items.sort { a, b in
            if a.isDirectory != b.isDirectory {
                return a.isDirectory
            }

            let result: ComparisonResult
            switch sortDescriptor.column {
            case .name:
                result = a.name.localizedCaseInsensitiveCompare(b.name)
            case .size:
                if a.size == b.size {
                    result = a.name.localizedCaseInsensitiveCompare(b.name)
                } else {
                    result = a.size < b.size ? .orderedAscending : .orderedDescending
                }
            case .date:
                result = a.dateModified.compare(b.dateModified)
            case .kind:
                result = a.kind.localizedCaseInsensitiveCompare(b.kind)
            }

            return sortDescriptor.ascending ? result == .orderedAscending : result == .orderedDescending
        }
    }

    func selectedItems(in tableView: NSTableView) -> [FileSystemItem] {
        return tableView.selectedRowIndexes.compactMap { index in
            guard index < items.count else { return nil }
            return items[index]
        }
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let descriptor = tableView.sortDescriptors.first,
              let key = descriptor.key,
              let column = SortColumn(rawValue: key) else { return }
        sortDescriptor = (column, descriptor.ascending)
        sortItems()
        tableView.reloadData()
    }

    // MARK: - Drag Source

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> (any NSPasteboardWriting)? {
        guard row < items.count else { return nil }
        return items[row].url as NSURL
    }

    // MARK: - Drop Target

    func tableView(_ tableView: NSTableView, validateDrop info: any NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        // Accept drops on directories or on the table background
        if dropOperation == .on, row < items.count, items[row].isDirectory {
            return .copy
        }
        if dropOperation == .above || (dropOperation == .on && row >= items.count) {
            tableView.setDropRow(-1, dropOperation: .on)
            return .copy
        }
        return []
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: any NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
              !urls.isEmpty else { return false }

        // Determine destination
        let destination: URL
        if dropOperation == .on, row >= 0, row < items.count, items[row].isDirectory {
            destination = items[row].url
        } else if let delegate = actionDelegate as? DirectoryWindowView {
            destination = delegate.currentDirectoryURL
        } else {
            return false
        }

        let isOptionHeld = NSEvent.modifierFlags.contains(.option)
        let operation: FileOperation = isOptionHeld
            ? .copy(sources: urls, destination: destination)
            : .move(sources: urls, destination: destination)

        FileOperationQueue.shared.execute(operation) { result in
            if case .failure(let error) = result {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }

        return true
    }

    // MARK: - NSTableViewDelegate

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < items.count, let column = tableColumn else { return nil }
        let item = items[row]
        let identifier = column.identifier

        let cellView: NSTableCellView

        if let existing = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
            cellView = existing
        } else {
            cellView = NSTableCellView()
            cellView.identifier = identifier

            if identifier.rawValue == "name" {
                let imageView = NSImageView()
                imageView.translatesAutoresizingMaskIntoConstraints = false
                cellView.addSubview(imageView)
                cellView.imageView = imageView

                let textField = NSTextField(labelWithString: "")
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.font = WinFileFonts.fileList
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
            } else {
                let textField = NSTextField(labelWithString: "")
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.font = WinFileFonts.fileList
                textField.lineBreakMode = .byTruncatingTail
                cellView.addSubview(textField)
                cellView.textField = textField

                let isRightAligned = identifier.rawValue == "size"
                textField.alignment = isRightAligned ? .right : .left

                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 4),
                    textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -4),
                    textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                ])
            }
        }

        switch identifier.rawValue {
        case "name":
            cellView.textField?.stringValue = item.name
            cellView.imageView?.image = item.icon
        case "size":
            cellView.textField?.stringValue = item.formattedSize
        case "date":
            cellView.textField?.stringValue = item.formattedDate
        case "kind":
            cellView.textField?.stringValue = item.kind
        default:
            break
        }

        return cellView
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return WinFileTheme.rowHeight
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }
        let selectedItems = selectedItems(in: tableView)
        actionDelegate?.fileListSelectionDidChange(selectedItems: selectedItems)
    }
}
