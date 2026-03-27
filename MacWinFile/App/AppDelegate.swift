import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {

    var windowManager: WindowManager!
    private let searchController = SearchPanelController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        setupMenuBar()
        setupNotifications()

        windowManager = WindowManager()
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        windowManager.openNewWindow(at: homeURL)

        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // MARK: - Notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleOpenNewWindow(_:)), name: .openNewWindow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleCreateDirectory(_:)), name: .createDirectory, object: nil)
    }

    @objc private func handleOpenNewWindow(_ notification: Notification) {
        guard let url = notification.object as? URL else { return }
        windowManager.openNewWindow(at: url)
    }

    @objc private func handleCreateDirectory(_ notification: Notification) {
        createDirectory(nil)
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        let mainMenu = NSMenu()

        // Application menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About MacWinFile", action: #selector(showAbout(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit MacWinFile", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu

        // Edit menu
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy", action: #selector(copyFiles(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(pasteFiles(_:)), keyEquivalent: "v")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Select All", action: #selector(selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu

        // File menu
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "New Window", action: #selector(newWindow(_:)), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "Open Directory…", action: #selector(openDirectory(_:)), keyEquivalent: "o")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Create Folder…", action: #selector(createDirectory(_:)), keyEquivalent: "N")
        fileMenu.items.last?.keyEquivalentModifierMask = [.command, .shift]
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Rename…", action: #selector(renameFile(_:)), keyEquivalent: "")
        fileMenu.addItem(withTitle: "Move to Trash", action: #selector(deleteFiles(_:)), keyEquivalent: "\u{8}")
        fileMenu.items.last?.keyEquivalentModifierMask = [.command]
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Properties", action: #selector(showProperties(_:)), keyEquivalent: "i")
        fileMenu.items.last?.keyEquivalentModifierMask = [.command]
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Search…", action: #selector(showSearch(_:)), keyEquivalent: "f")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Reveal in Finder", action: #selector(revealInFinder(_:)), keyEquivalent: "r")
        fileMenu.items.last?.keyEquivalentModifierMask = [.command, .shift]
        fileMenuItem.submenu = fileMenu

        // Tree menu
        let treeMenuItem = NSMenuItem()
        mainMenu.addItem(treeMenuItem)
        let treeMenu = NSMenu(title: "Tree")
        treeMenu.addItem(withTitle: "Expand One Level", action: #selector(expandOneLevel(_:)), keyEquivalent: "")
        treeMenu.addItem(withTitle: "Expand Branch", action: #selector(expandBranch(_:)), keyEquivalent: "")
        treeMenu.addItem(withTitle: "Expand All", action: #selector(expandAll(_:)), keyEquivalent: "")
        treeMenu.addItem(withTitle: "Collapse Branch", action: #selector(collapseBranch(_:)), keyEquivalent: "")
        treeMenuItem.submenu = treeMenu

        // View menu
        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(withTitle: "Tree and Directory", action: #selector(viewTreeAndDirectory(_:)), keyEquivalent: "")
        viewMenu.addItem(withTitle: "Tree Only", action: #selector(viewTreeOnly(_:)), keyEquivalent: "")
        viewMenu.addItem(withTitle: "Directory Only", action: #selector(viewDirectoryOnly(_:)), keyEquivalent: "")
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Name", action: #selector(viewByName(_:)), keyEquivalent: "")
        viewMenu.addItem(withTitle: "Details", action: #selector(viewByDetails(_:)), keyEquivalent: "")
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Sort by Name", action: #selector(sortByName(_:)), keyEquivalent: "")
        viewMenu.addItem(withTitle: "Sort by Size", action: #selector(sortBySize(_:)), keyEquivalent: "")
        viewMenu.addItem(withTitle: "Sort by Date", action: #selector(sortByDate(_:)), keyEquivalent: "")
        viewMenu.addItem(withTitle: "Sort by Kind", action: #selector(sortByKind(_:)), keyEquivalent: "")
        viewMenuItem.submenu = viewMenu

        // Options menu
        let optionsMenuItem = NSMenuItem()
        mainMenu.addItem(optionsMenuItem)
        let optionsMenu = NSMenu(title: "Options")
        optionsMenu.addItem(withTitle: "Drivebar", action: #selector(toggleDrivebar(_:)), keyEquivalent: "")
        optionsMenu.addItem(withTitle: "Status Bar", action: #selector(toggleStatusBar(_:)), keyEquivalent: "")
        optionsMenuItem.submenu = optionsMenu

        // Window menu
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        NSApp.windowsMenu = windowMenu

        // Help menu
        let helpMenuItem = NSMenuItem()
        mainMenu.addItem(helpMenuItem)
        let helpMenu = NSMenu(title: "Help")
        helpMenu.addItem(withTitle: "About MacWinFile", action: #selector(showAbout(_:)), keyEquivalent: "")
        helpMenuItem.submenu = helpMenu

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Menu Actions

    @objc func showAbout(_ sender: Any?) {
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc func newWindow(_ sender: Any?) {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        windowManager.openNewWindow(at: homeURL)
    }

    @objc func openDirectory(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            windowManager.navigateTo(url: url)
        }
    }

    @objc func createDirectory(_ sender: Any?) {
        windowManager.createDirectory()
    }

    @objc func deleteFiles(_ sender: Any?) {
        windowManager.directoryView?.deleteSelectedItems()
    }

    @objc func renameFile(_ sender: Any?) {
        windowManager.directoryView?.renameSelectedItem()
    }

    @objc func copyFiles(_ sender: Any?) {
        windowManager.directoryView?.copySelectedItems()
    }

    @objc func pasteFiles(_ sender: Any?) {
        windowManager.directoryView?.pasteItems()
    }

    @objc func showProperties(_ sender: Any?) {
        windowManager.directoryView?.showProperties()
    }

    @objc func showSearch(_ sender: Any?) {
        guard let window = windowManager.activeWindow?.window,
              let dirView = windowManager.directoryView else { return }
        searchController.showSearch(relativeTo: window, startingAt: dirView.currentDirectoryURL) { [weak self] url in
            self?.windowManager.navigateTo(url: url)
        }
    }

    @objc func revealInFinder(_ sender: Any?) {
        guard let url = windowManager.directoryView?.currentDirectoryURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    @objc func selectAll(_ sender: Any?) {
        NSApp.sendAction(#selector(NSTableView.selectAll(_:)), to: nil, from: sender)
    }

    @objc func expandOneLevel(_ sender: Any?) { windowManager.directoryView?.expandOneLevel() }
    @objc func expandBranch(_ sender: Any?) { windowManager.directoryView?.expandBranch() }
    @objc func expandAll(_ sender: Any?) { windowManager.directoryView?.expandAll() }
    @objc func collapseBranch(_ sender: Any?) { windowManager.directoryView?.collapseBranch() }

    @objc func viewTreeAndDirectory(_ sender: Any?) { windowManager.directoryView?.setViewMode(.treeAndDirectory) }
    @objc func viewTreeOnly(_ sender: Any?) { windowManager.directoryView?.setViewMode(.treeOnly) }
    @objc func viewDirectoryOnly(_ sender: Any?) { windowManager.directoryView?.setViewMode(.directoryOnly) }

    @objc func viewByName(_ sender: Any?) { windowManager.directoryView?.setDisplayMode(.name) }
    @objc func viewByDetails(_ sender: Any?) { windowManager.directoryView?.setDisplayMode(.details) }

    @objc func sortByName(_ sender: Any?) { windowManager.directoryView?.sortBy(.name) }
    @objc func sortBySize(_ sender: Any?) { windowManager.directoryView?.sortBy(.size) }
    @objc func sortByDate(_ sender: Any?) { windowManager.directoryView?.sortBy(.date) }
    @objc func sortByKind(_ sender: Any?) { windowManager.directoryView?.sortBy(.kind) }

    @objc func toggleDrivebar(_ sender: Any?) {
        windowManager.toggleDriveToolbar()
    }

    @objc func toggleStatusBar(_ sender: Any?) {
        windowManager.directoryView?.toggleStatusBar()
    }

    // MARK: - Menu Validation

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let dirView = windowManager.directoryView

        switch menuItem.action {
        case #selector(viewTreeAndDirectory(_:)):
            menuItem.state = dirView?.viewMode == .treeAndDirectory ? .on : .off
        case #selector(viewTreeOnly(_:)):
            menuItem.state = dirView?.viewMode == .treeOnly ? .on : .off
        case #selector(viewDirectoryOnly(_:)):
            menuItem.state = dirView?.viewMode == .directoryOnly ? .on : .off
        case #selector(viewByName(_:)):
            menuItem.state = dirView?.displayMode == .name ? .on : .off
        case #selector(viewByDetails(_:)):
            menuItem.state = dirView?.displayMode == .details ? .on : .off
        case #selector(toggleDrivebar(_:)):
            menuItem.state = windowManager.isDriveToolbarVisible ? .on : .off
        case #selector(toggleStatusBar(_:)):
            menuItem.state = (dirView?.statusBarVisible ?? true) ? .on : .off
        default:
            break
        }
        return true
    }
}
