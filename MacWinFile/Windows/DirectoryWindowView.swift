import Cocoa
import SwiftUI

enum ViewMode {
    case treeAndDirectory
    case treeOnly
    case directoryOnly
}

enum DisplayMode {
    case name
    case details
}

class DirectoryWindowView: NSView, TreeSelectionDelegate, FileListActionDelegate {

    private let splitView = NSSplitView()
    private let treeScrollView = NSScrollView()
    private let fileListScrollView = NSScrollView()
    private let outlineView = TreeOutlineView()
    private let tableView = FileListTableView()
    private var statusBarHostingView: NSHostingView<StatusBarView>?

    private let treeDelegate = TreeOutlineDelegate()
    let fileListDelegate = FileListDelegate()

    private var currentURL: URL
    private var rootItem: FileSystemItem
    private(set) var viewMode: ViewMode = .treeAndDirectory
    private(set) var displayMode: DisplayMode = .details
    private(set) var statusBarVisible = true

    // FSEvents watcher
    private var directoryWatcher: DirectoryWatcher?

    // Status bar state
    private var fileCount = 0
    private var selectedCount = 0
    private var totalSizeString = "0 B"
    private var freeSpaceString = "0 B"

    init(url: URL) {
        self.currentURL = url
        self.rootItem = FileSystemStore.shared.rootItem(for: url)
        super.init(frame: .zero)
        setupViews()
        loadDirectory(url: url)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        directoryWatcher?.stop()
    }

    // MARK: - Setup

    private func setupViews() {
        wantsLayer = true

        setupSplitView()
        setupTreeView()
        setupFileListView()
        setupStatusBar()
        layoutSubviews()
    }

    private func setupSplitView() {
        splitView.translatesAutoresizingMaskIntoConstraints = false
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.delegate = self
        addSubview(splitView)

        treeScrollView.translatesAutoresizingMaskIntoConstraints = false
        treeScrollView.hasVerticalScroller = true
        treeScrollView.hasHorizontalScroller = true
        treeScrollView.scrollerStyle = .legacy
        treeScrollView.autohidesScrollers = false
        treeScrollView.borderType = .bezelBorder
        treeScrollView.documentView = outlineView
        splitView.addArrangedSubview(treeScrollView)

        fileListScrollView.translatesAutoresizingMaskIntoConstraints = false
        fileListScrollView.hasVerticalScroller = true
        fileListScrollView.hasHorizontalScroller = true
        fileListScrollView.scrollerStyle = .legacy
        fileListScrollView.autohidesScrollers = false
        fileListScrollView.borderType = .bezelBorder
        fileListScrollView.documentView = tableView
        splitView.addArrangedSubview(fileListScrollView)
    }

    private func setupTreeView() {
        outlineView.headerView = nil
        outlineView.rowHeight = WinFileTheme.rowHeight
        outlineView.indentationPerLevel = WinFileTheme.treeIndentation
        outlineView.autoresizesOutlineColumn = true

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("TreeColumn"))
        column.title = "Directory"
        column.minWidth = 200
        column.width = 400
        column.resizingMask = .autoresizingMask
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.columnAutoresizingStyle = .noColumnAutoresizing

        treeDelegate.selectionDelegate = self
        outlineView.dataSource = treeDelegate
        outlineView.delegate = treeDelegate

        outlineView.target = self
        outlineView.doubleAction = #selector(treeDoubleClicked(_:))

        // Enable drag and drop on tree
        outlineView.setDraggingSourceOperationMask(.copy, forLocal: false)
        outlineView.setDraggingSourceOperationMask([.copy, .move], forLocal: true)
        outlineView.registerForDraggedTypes([.fileURL])

        // Context menu for tree
        let treeMenu = NSMenu()
        treeMenu.addItem(withTitle: "Open in New Window", action: #selector(openInNewWindow(_:)), keyEquivalent: "")
        treeMenu.addItem(NSMenuItem.separator())
        treeMenu.addItem(withTitle: "Rename…", action: #selector(contextRename(_:)), keyEquivalent: "")
        treeMenu.addItem(withTitle: "Move to Trash", action: #selector(contextDelete(_:)), keyEquivalent: "")
        treeMenu.addItem(NSMenuItem.separator())
        treeMenu.addItem(withTitle: "Properties", action: #selector(contextProperties(_:)), keyEquivalent: "")
        treeMenu.addItem(NSMenuItem.separator())
        treeMenu.addItem(withTitle: "Reveal in Finder", action: #selector(revealInFinder(_:)), keyEquivalent: "")
        for item in treeMenu.items { item.target = self }
        outlineView.menu = treeMenu
    }

    private func setupFileListView() {
        tableView.rowHeight = WinFileTheme.rowHeight
        tableView.allowsMultipleSelection = true
        tableView.allowsColumnReordering = true
        tableView.allowsColumnResizing = true
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        tableView.style = .plain

        let nameCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameCol.title = "Name"
        nameCol.width = 250
        nameCol.minWidth = 100
        nameCol.sortDescriptorPrototype = NSSortDescriptor(key: "name", ascending: true)
        tableView.addTableColumn(nameCol)

        let sizeCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("size"))
        sizeCol.title = "Size"
        sizeCol.width = 80
        sizeCol.minWidth = 60
        sizeCol.sortDescriptorPrototype = NSSortDescriptor(key: "size", ascending: true)
        tableView.addTableColumn(sizeCol)

        let dateCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("date"))
        dateCol.title = "Date Modified"
        dateCol.width = 140
        dateCol.minWidth = 100
        dateCol.sortDescriptorPrototype = NSSortDescriptor(key: "date", ascending: true)
        tableView.addTableColumn(dateCol)

        let kindCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("kind"))
        kindCol.title = "Kind"
        kindCol.width = 120
        kindCol.minWidth = 80
        kindCol.sortDescriptorPrototype = NSSortDescriptor(key: "kind", ascending: true)
        tableView.addTableColumn(kindCol)

        fileListDelegate.actionDelegate = self
        tableView.dataSource = fileListDelegate
        tableView.delegate = fileListDelegate

        tableView.target = self
        tableView.doubleAction = #selector(fileListDoubleClicked(_:))

        // Enable drag and drop
        tableView.setDraggingSourceOperationMask(.copy, forLocal: false)
        tableView.setDraggingSourceOperationMask([.copy, .move], forLocal: true)
        tableView.registerForDraggedTypes([.fileURL])

        // Context menu for file list
        let fileMenu = NSMenu()
        fileMenu.delegate = self
        tableView.menu = fileMenu
    }

    private func setupStatusBar() {
        let statusView = StatusBarView(
            fileCount: 0, selectedCount: 0, totalSize: "0 B", freeSpace: "0 B", currentPath: currentURL.path
        )
        let hostingView = NSHostingView(rootView: statusView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)
        statusBarHostingView = hostingView
    }

    private func layoutSubviews() {
        guard let statusBar = statusBarHostingView else { return }

        for constraint in constraints { removeConstraint(constraint) }

        var allConstraints = [
            splitView.topAnchor.constraint(equalTo: topAnchor),
            splitView.leadingAnchor.constraint(equalTo: leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ]

        if statusBarVisible {
            statusBar.isHidden = false
            allConstraints += [
                splitView.bottomAnchor.constraint(equalTo: statusBar.topAnchor),
                statusBar.leadingAnchor.constraint(equalTo: leadingAnchor),
                statusBar.trailingAnchor.constraint(equalTo: trailingAnchor),
                statusBar.bottomAnchor.constraint(equalTo: bottomAnchor),
                statusBar.heightAnchor.constraint(equalToConstant: WinFileTheme.statusBarHeight),
            ]
        } else {
            statusBar.isHidden = true
            allConstraints += [splitView.bottomAnchor.constraint(equalTo: bottomAnchor)]
        }

        NSLayoutConstraint.activate(allConstraints)
    }

    // MARK: - Public API

    var currentDirectoryURL: URL { return currentURL }

    func refreshCurrentDirectory() {
        rootItem.invalidateChildren()
        treeDelegate.rootItem = rootItem
        outlineView.reloadData()
        loadFileList(url: currentURL)
    }

    func refreshAndExpandNewItem(at url: URL) {
        refreshCurrentDirectory()
        // Find and expand the new item in the tree
        for row in 0..<outlineView.numberOfRows {
            if let item = outlineView.item(atRow: row) as? FileSystemItem, item.url == url {
                outlineView.expandItem(item)
                outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                outlineView.scrollRowToVisible(row)
                break
            }
        }
    }

    func navigateTo(url: URL) {
        currentURL = url
        rootItem = FileSystemStore.shared.rootItem(for: url)
        treeDelegate.rootItem = rootItem
        outlineView.reloadData()
        loadFileList(url: url)
        updateWindowTitle()
        startWatching(url: url)
    }

    func setViewMode(_ mode: ViewMode) {
        viewMode = mode
        switch mode {
        case .treeAndDirectory:
            treeScrollView.isHidden = false
            fileListScrollView.isHidden = false
            splitView.adjustSubviews()
        case .treeOnly:
            fileListScrollView.isHidden = true
            treeScrollView.isHidden = false
        case .directoryOnly:
            treeScrollView.isHidden = true
            fileListScrollView.isHidden = false
        }
    }

    func setDisplayMode(_ mode: DisplayMode) {
        displayMode = mode
        switch mode {
        case .name:
            for col in tableView.tableColumns { col.isHidden = col.identifier.rawValue != "name" }
        case .details:
            for col in tableView.tableColumns { col.isHidden = false }
        }
    }

    func sortBy(_ column: FileListDelegate.SortColumn) {
        fileListDelegate.sortDescriptor = (column, fileListDelegate.sortDescriptor.ascending)
        fileListDelegate.sortItems()
        tableView.reloadData()
    }

    func toggleStatusBar() {
        statusBarVisible.toggle()
        layoutSubviews()
    }

    // MARK: - Tree operations

    func expandOneLevel() {
        let row = outlineView.selectedRow
        guard row >= 0, let item = outlineView.item(atRow: row) else { return }
        outlineView.expandItem(item)
    }

    func expandBranch() {
        let row = outlineView.selectedRow
        guard row >= 0, let item = outlineView.item(atRow: row) else { return }
        outlineView.expandItem(item, expandChildren: true)
    }

    func expandAll() {
        outlineView.expandItem(nil, expandChildren: true)
    }

    func collapseBranch() {
        let row = outlineView.selectedRow
        guard row >= 0, let item = outlineView.item(atRow: row) else { return }
        outlineView.collapseItem(item, collapseChildren: true)
    }

    // MARK: - Selection Helpers

    /// Returns the selected tree item if the tree has focus, nil otherwise
    var selectedTreeItem: FileSystemItem? {
        let row = outlineView.selectedRow
        guard row >= 0 else { return nil }
        return outlineView.item(atRow: row) as? FileSystemItem
    }

    /// Returns effective selection: file list items if any selected, else the tree-selected directory
    func effectiveSelection() -> [FileSystemItem] {
        let fileSelection = fileListDelegate.selectedItems(in: tableView)
        if !fileSelection.isEmpty { return fileSelection }
        if let treeItem = selectedTreeItem { return [treeItem] }
        return []
    }

    // MARK: - File Operations

    @objc func deleteSelectedItems() {
        let selected = effectiveSelection()
        guard !selected.isEmpty else { return }

        let alert = NSAlert()
        alert.messageText = "Move to Trash"
        alert.informativeText = "Are you sure you want to move \(selected.count) item(s) to the Trash?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Move to Trash")
        alert.addButton(withTitle: "Cancel")

        if let w = window {
            alert.beginSheetModal(for: w) { response in
                if response == .alertFirstButtonReturn {
                    self.performDelete(items: selected)
                }
            }
        }
    }

    private func performDelete(items: [FileSystemItem]) {
        let urls = items.map { $0.url }
        FileOperationQueue.shared.execute(.delete(sources: urls)) { [weak self] result in
            switch result {
            case .success:
                self?.refreshCurrentDirectory()
            case .failure(let error):
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
    }

    func copySelectedItems() {
        let selected = effectiveSelection()
        guard !selected.isEmpty else { return }
        let urls = selected.map { $0.url as NSURL }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects(urls)
    }

    @objc func pasteItems() {
        guard let urls = NSPasteboard.general.readObjects(forClasses: [NSURL.self]) as? [URL],
              !urls.isEmpty else { return }

        let destination = currentURL
        FileOperationQueue.shared.execute(.copy(sources: urls, destination: destination)) { [weak self] result in
            switch result {
            case .success:
                self?.refreshCurrentDirectory()
            case .failure(let error):
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
    }

    func renameSelectedItem() {
        let selected = effectiveSelection()
        guard let item = selected.first else { return }

        let alert = NSAlert()
        alert.messageText = "Rename"
        alert.informativeText = "Enter new name:"
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.stringValue = item.name
        alert.accessoryView = textField

        if let w = window {
            alert.beginSheetModal(for: w) { response in
                if response == .alertFirstButtonReturn, !textField.stringValue.isEmpty {
                    FileOperationQueue.shared.execute(.rename(source: item.url, newName: textField.stringValue)) { [weak self] result in
                        switch result {
                        case .success:
                            self?.refreshCurrentDirectory()
                        case .failure(let error):
                            let a = NSAlert(error: error)
                            a.runModal()
                        }
                    }
                }
            }
        }
    }

    func showProperties() {
        let selected = effectiveSelection()
        guard let item = selected.first else { return }

        let alert = NSAlert()
        alert.messageText = item.name
        var info = "Kind: \(item.kind)\n"
        info += "Size: \(item.formattedSize)\n"
        info += "Modified: \(item.formattedDate)\n"
        info += "Path: \(item.url.path)"
        alert.informativeText = info
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.icon = item.icon
        if let w = window {
            alert.beginSheetModal(for: w) { _ in }
        }
    }

    // MARK: - FSEvents

    private func startWatching(url: URL) {
        directoryWatcher?.stop()
        directoryWatcher = DirectoryWatcher(path: url.path) { [weak self] in
            self?.refreshCurrentDirectory()
        }
        directoryWatcher?.start()
    }

    // MARK: - Loading

    func loadDirectory(url: URL) {
        currentURL = url
        rootItem = FileSystemStore.shared.rootItem(for: url)
        treeDelegate.rootItem = rootItem
        outlineView.reloadData()
        loadFileList(url: url)
        startWatching(url: url)
    }

    private func loadFileList(url: URL) {
        let items = FileSystemStore.shared.loadContents(of: url)
        fileListDelegate.items = items
        fileListDelegate.sortItems()
        tableView.reloadData()
        updateStatusBar(items: items)
    }

    private func updateStatusBar(items: [FileSystemItem]) {
        let files = items.filter { !$0.isDirectory }
        fileCount = files.count
        selectedCount = 0
        let totalSize = files.reduce(Int64(0)) { $0 + $1.size }
        totalSizeString = FileSizeFormatter.string(fromBytes: totalSize)

        if let values = try? currentURL.resourceValues(forKeys: [.volumeAvailableCapacityKey]) {
            freeSpaceString = FileSizeFormatter.string(fromBytes: Int64(values.volumeAvailableCapacity ?? 0))
        }

        statusBarHostingView?.rootView = StatusBarView(
            fileCount: fileCount, selectedCount: selectedCount,
            totalSize: totalSizeString, freeSpace: freeSpaceString,
            currentPath: currentURL.path
        )
    }

    private func updateWindowTitle() {
        let name = currentURL.lastPathComponent.isEmpty ? currentURL.path : currentURL.lastPathComponent
        window?.title = "MacWinFile - \(name)"
    }

    // MARK: - Keyboard actions (called from FileListTableView / TreeOutlineView)

    @objc func openSelectedItem() {
        let selected = effectiveSelection()
        if let item = selected.first {
            fileListDidDoubleClick(item)
        }
    }

    // MARK: - TreeSelectionDelegate

    func treeDidSelectDirectory(_ url: URL) {
        loadFileList(url: url)
        currentURL = url
        updateWindowTitle()
        startWatching(url: url)
    }

    // MARK: - FileListActionDelegate

    func fileListDidDoubleClick(_ item: FileSystemItem) {
        if item.isDirectory {
            navigateTo(url: item.url)
        } else {
            NSWorkspace.shared.open(item.url)
        }
    }

    func fileListSelectionDidChange(selectedItems: [FileSystemItem]) {
        selectedCount = selectedItems.count
        let selectedSize = selectedItems.filter { !$0.isDirectory }.reduce(Int64(0)) { $0 + $1.size }

        statusBarHostingView?.rootView = StatusBarView(
            fileCount: fileCount, selectedCount: selectedCount,
            totalSize: selectedCount > 0 ? FileSizeFormatter.string(fromBytes: selectedSize) : totalSizeString,
            freeSpace: freeSpaceString, currentPath: currentURL.path
        )
    }

    // MARK: - Context Menu Actions

    @objc private func openInNewWindow(_ sender: Any?) {
        let row = outlineView.clickedRow
        guard row >= 0, let item = outlineView.item(atRow: row) as? FileSystemItem else { return }
        // Post notification that AppDelegate picks up
        NotificationCenter.default.post(name: .openNewWindow, object: item.url)
    }

    @objc private func revealInFinder(_ sender: Any?) {
        let items = fileListDelegate.selectedItems(in: tableView)
        let urls = items.isEmpty ? [currentURL] : items.map { $0.url }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    @objc private func contextOpen(_ sender: Any?) {
        let items = fileListDelegate.selectedItems(in: tableView)
        for item in items {
            if item.isDirectory {
                navigateTo(url: item.url)
            } else {
                NSWorkspace.shared.open(item.url)
            }
        }
    }

    @objc private func contextCopy(_ sender: Any?) { copySelectedItems() }
    @objc private func contextDelete(_ sender: Any?) { deleteSelectedItems() }
    @objc private func contextRename(_ sender: Any?) { renameSelectedItem() }
    @objc private func contextProperties(_ sender: Any?) { showProperties() }

    @objc private func contextRevealInFinder(_ sender: Any?) { revealInFinder(sender) }

    @objc private func contextNewFolder(_ sender: Any?) {
        NotificationCenter.default.post(name: .createDirectory, object: nil)
    }

    // MARK: - Actions

    @objc private func treeDoubleClicked(_ sender: Any?) {
        let row = outlineView.clickedRow
        guard row >= 0, let item = outlineView.item(atRow: row) as? FileSystemItem else { return }
        if outlineView.isItemExpanded(item) {
            outlineView.collapseItem(item)
        } else {
            outlineView.expandItem(item)
        }
    }

    @objc private func fileListDoubleClicked(_ sender: Any?) {
        let row = tableView.clickedRow
        guard row >= 0, row < fileListDelegate.items.count else { return }
        let item = fileListDelegate.items[row]
        fileListDidDoubleClick(item)
    }
}

// MARK: - NSSplitViewDelegate

extension DirectoryWindowView: NSSplitViewDelegate {
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 120
    }

    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return splitView.bounds.width - 200
    }

    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return true
    }
}

// MARK: - Context Menu Delegate

extension DirectoryWindowView: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let selected = fileListDelegate.selectedItems(in: tableView)

        if !selected.isEmpty {
            menu.addItem(withTitle: "Open", action: #selector(contextOpen(_:)), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Copy", action: #selector(contextCopy(_:)), keyEquivalent: "")
            menu.addItem(withTitle: "Rename…", action: #selector(contextRename(_:)), keyEquivalent: "")
            menu.addItem(withTitle: "Move to Trash", action: #selector(contextDelete(_:)), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Properties", action: #selector(contextProperties(_:)), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Reveal in Finder", action: #selector(contextRevealInFinder(_:)), keyEquivalent: "")
        } else {
            menu.addItem(withTitle: "Paste", action: #selector(pasteItems), keyEquivalent: "")
            menu.addItem(withTitle: "New Folder…", action: #selector(contextNewFolder(_:)), keyEquivalent: "")
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Reveal in Finder", action: #selector(contextRevealInFinder(_:)), keyEquivalent: "")
        }

        for item in menu.items {
            item.target = self
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let openNewWindow = Notification.Name("openNewWindow")
    static let createDirectory = Notification.Name("createDirectory")
}
