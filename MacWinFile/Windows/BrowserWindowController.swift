import Cocoa

protocol BrowserWindowDelegate: AnyObject {
    func browserWindowDidBecomeKey(_ controller: BrowserWindowController)
    func browserWindowWillClose(_ controller: BrowserWindowController)
    func browserWindowRequestNewWindow(at url: URL)
}

class BrowserWindowController: NSWindowController, NSWindowDelegate, DriveToolbarDelegate {

    weak var browserDelegate: BrowserWindowDelegate?
    let driveToolbar = DriveToolbar()
    let directoryView: DirectoryWindowView
    private var driveToolbarVisible = true

    convenience init(url: URL) {
        let windowRect = NSRect(x: 0, y: 0, width: 900, height: 600)
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        window.title = "MacWinFile - \(url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent)"
        window.minSize = NSSize(width: 500, height: 350)

        let dirView = DirectoryWindowView(url: url)

        self.init(window: window, directoryView: dirView)

        setupUI()
        dirView.loadDirectory(url: url)
        window.delegate = self

        // Restore last window size/position (shared across all browser windows)
        window.setFrameAutosaveName("BrowserWindow")
    }

    init(window: NSWindow, directoryView: DirectoryWindowView) {
        self.directoryView = directoryView
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        driveToolbar.translatesAutoresizingMaskIntoConstraints = false
        driveToolbar.delegate = self
        contentView.addSubview(driveToolbar)

        directoryView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(directoryView)

        layoutUI()
    }

    private func layoutUI() {
        guard let contentView = window?.contentView else { return }
        contentView.constraints.forEach { contentView.removeConstraint($0) }

        if driveToolbarVisible {
            driveToolbar.isHidden = false
            NSLayoutConstraint.activate([
                driveToolbar.topAnchor.constraint(equalTo: contentView.topAnchor),
                driveToolbar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                driveToolbar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                driveToolbar.heightAnchor.constraint(equalToConstant: 28),

                directoryView.topAnchor.constraint(equalTo: driveToolbar.bottomAnchor),
                directoryView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                directoryView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                directoryView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        } else {
            driveToolbar.isHidden = true
            NSLayoutConstraint.activate([
                directoryView.topAnchor.constraint(equalTo: contentView.topAnchor),
                directoryView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                directoryView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                directoryView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        }
    }

    // MARK: - Public

    func navigateTo(url: URL) {
        directoryView.navigateTo(url: url)
        window?.title = "MacWinFile - \(url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent)"
    }

    func toggleDriveToolbar() {
        driveToolbarVisible.toggle()
        layoutUI()
    }

    var isDriveToolbarVisible: Bool { driveToolbarVisible }

    // MARK: - DriveToolbarDelegate

    func driveToolbarDidSelectVolume(_ url: URL) {
        navigateTo(url: url)
    }

    func driveToolbarDidSelectHome() {
        navigateTo(url: FileManager.default.homeDirectoryForCurrentUser)
    }

    func driveToolbarDidOpenNewWindow(_ url: URL) {
        browserDelegate?.browserWindowRequestNewWindow(at: url)
    }

    // MARK: - NSWindowDelegate

    func windowDidBecomeKey(_ notification: Notification) {
        browserDelegate?.browserWindowDidBecomeKey(self)
    }

    func windowWillClose(_ notification: Notification) {
        browserDelegate?.browserWindowWillClose(self)
    }
}
