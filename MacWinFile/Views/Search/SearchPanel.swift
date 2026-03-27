import Cocoa

class SearchPanelController {
    private let searchEngine = SearchEngine()
    private var results: [FileSystemItem] = []
    private var searchWindow: NSPanel?

    func showSearch(relativeTo parentWindow: NSWindow, startingAt url: URL, onNavigate: @escaping (URL) -> Void) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "Search"
        panel.minSize = NSSize(width: 400, height: 300)
        searchWindow = panel

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = contentView

        // Search field
        let searchField = NSSearchField()
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholderString = "Search (supports * and ? wildcards)..."
        searchField.sendsSearchStringImmediately = false
        searchField.sendsWholeSearchString = true
        contentView.addSubview(searchField)

        // Scope label
        let scopeLabel = NSTextField(labelWithString: "Searching in: \(url.path)")
        scopeLabel.translatesAutoresizingMaskIntoConstraints = false
        scopeLabel.font = NSFont.systemFont(ofSize: 11)
        scopeLabel.textColor = .secondaryLabelColor
        scopeLabel.lineBreakMode = .byTruncatingMiddle
        contentView.addSubview(scopeLabel)

        // Results table
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        contentView.addSubview(scrollView)

        let tableView = NSTableView()
        tableView.rowHeight = 20
        tableView.allowsMultipleSelection = false
        tableView.usesAlternatingRowBackgroundColors = true

        let nameCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameCol.title = "Name"
        nameCol.width = 200
        tableView.addTableColumn(nameCol)

        let pathCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("path"))
        pathCol.title = "Path"
        pathCol.width = 350
        tableView.addTableColumn(pathCol)

        scrollView.documentView = tableView

        // Status label
        let statusLabel = NSTextField(labelWithString: "Enter a search term")
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        contentView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            searchField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            searchField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            scopeLabel.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 4),
            scopeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            scopeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            scrollView.topAnchor.constraint(equalTo: scopeLabel.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -4),

            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])

        let delegate = SearchTableDelegate(results: results, onNavigate: onNavigate, statusLabel: statusLabel)

        tableView.dataSource = delegate
        tableView.delegate = delegate
        tableView.target = delegate
        tableView.doubleAction = #selector(SearchTableDelegate.doubleClicked(_:))

        // Search action
        searchField.target = delegate
        searchField.action = #selector(SearchTableDelegate.performSearch(_:))
        delegate.searchEngine = searchEngine
        delegate.searchURL = url
        delegate.tableView = tableView

        // Keep delegate alive
        objc_setAssociatedObject(panel, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)

        parentWindow.addChildWindow(panel, ordered: .above)
        panel.center()
        panel.makeKeyAndOrderFront(nil)
    }
}

class SearchTableDelegate: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    var results: [FileSystemItem] = []
    var onNavigate: (URL) -> Void
    var searchEngine: SearchEngine?
    var searchURL: URL?
    weak var tableView: NSTableView?
    weak var statusLabel: NSTextField?

    init(results: [FileSystemItem], onNavigate: @escaping (URL) -> Void, statusLabel: NSTextField) {
        self.results = results
        self.onNavigate = onNavigate
        self.statusLabel = statusLabel
    }

    @objc func performSearch(_ sender: NSSearchField) {
        let query = sender.stringValue
        guard !query.isEmpty else {
            results.removeAll()
            tableView?.reloadData()
            statusLabel?.stringValue = "Enter a search term"
            return
        }

        results.removeAll()
        tableView?.reloadData()
        statusLabel?.stringValue = "Searching..."

        searchEngine?.cancel()
        searchEngine?.search(
            in: searchURL ?? FileManager.default.homeDirectoryForCurrentUser,
            query: query,
            onResult: { [weak self] item in
                self?.results.append(item)
                self?.tableView?.reloadData()
                self?.statusLabel?.stringValue = "\(self?.results.count ?? 0) result(s) found"
            },
            onComplete: { [weak self] in
                let count = self?.results.count ?? 0
                self?.statusLabel?.stringValue = "Search complete: \(count) result(s)"
            }
        )
    }

    @objc func doubleClicked(_ sender: NSTableView) {
        let row = sender.clickedRow
        guard row >= 0, row < results.count else { return }
        let item = results[row]
        if item.isDirectory {
            onNavigate(item.url)
        } else {
            onNavigate(item.url.deletingLastPathComponent())
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return results.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < results.count, let col = tableColumn else { return nil }
        let item = results[row]
        let id = col.identifier

        let cell: NSTableCellView
        if let existing = tableView.makeView(withIdentifier: id, owner: self) as? NSTableCellView {
            cell = existing
        } else {
            cell = NSTableCellView()
            cell.identifier = id
            let tf = NSTextField(labelWithString: "")
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.font = NSFont.systemFont(ofSize: 11)
            tf.lineBreakMode = .byTruncatingMiddle
            cell.addSubview(tf)
            cell.textField = tf

            if id.rawValue == "name" {
                let iv = NSImageView()
                iv.translatesAutoresizingMaskIntoConstraints = false
                cell.addSubview(iv)
                cell.imageView = iv
                NSLayoutConstraint.activate([
                    iv.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                    iv.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                    iv.widthAnchor.constraint(equalToConstant: 16),
                    iv.heightAnchor.constraint(equalToConstant: 16),
                    tf.leadingAnchor.constraint(equalTo: iv.trailingAnchor, constant: 4),
                    tf.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
                    tf.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                ])
            } else {
                NSLayoutConstraint.activate([
                    tf.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                    tf.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
                    tf.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                ])
            }
        }

        switch id.rawValue {
        case "name":
            cell.textField?.stringValue = item.name
            cell.imageView?.image = item.icon
        case "path":
            cell.textField?.stringValue = item.url.deletingLastPathComponent().path
        default: break
        }

        return cell
    }
}
