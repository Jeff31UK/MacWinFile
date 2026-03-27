import Cocoa

protocol DriveToolbarDelegate: AnyObject {
    func driveToolbarDidSelectVolume(_ url: URL)
    func driveToolbarDidSelectHome()
    func driveToolbarDidOpenNewWindow(_ url: URL)
}

class DriveToolbar: NSView, VolumeManagerDelegate {

    weak var delegate: DriveToolbarDelegate?
    private var buttons: [NSButton] = []
    private let newWindowButton = NSButton(frame: .zero)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        VolumeManager.shared.delegate = self
        rebuildButtons()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        wantsLayer = true

        // New Window button - pinned to the right
        newWindowButton.bezelStyle = .texturedRounded
        newWindowButton.isBordered = true
        newWindowButton.image = NSImage(systemSymbolName: "plus.rectangle", accessibilityDescription: "New Window")
        newWindowButton.imagePosition = .imageOnly
        newWindowButton.toolTip = "New Window"
        newWindowButton.target = self
        newWindowButton.action = #selector(newWindowClicked(_:))
        addSubview(newWindowButton)
    }

    func rebuildButtons() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()

        // Home button
        let homeButton = makeButton(title: "Home", icon: NSImage(systemSymbolName: "house", accessibilityDescription: "Home"), tag: -1)
        homeButton.action = #selector(buttonClicked(_:))
        homeButton.target = self
        homeButton.toolTip = "Home — double-click for new window"
        buttons.append(homeButton)
        addSubview(homeButton)

        // Volume buttons
        for (index, volume) in VolumeManager.shared.volumes.enumerated() {
            let button = makeButton(title: volume.name, icon: volume.icon, tag: index)
            button.action = #selector(buttonClicked(_:))
            button.target = self
            button.toolTip = "\(volume.url.path) — double-click for new window"
            buttons.append(button)
            addSubview(button)
        }

        layoutButtons()
    }

    private func makeButton(title: String, icon: NSImage?, tag: Int) -> NSButton {
        let button = DoubleClickButton(frame: .zero)
        button.bezelStyle = .texturedRounded
        button.isBordered = true
        button.image = icon
        button.imagePosition = icon != nil ? .imageLeft : .noImage
        button.title = title
        button.font = NSFont.systemFont(ofSize: 10)
        button.tag = tag
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.onDoubleClick = { [weak self] in
            self?.handleDoubleClick(tag: tag)
        }
        return button
    }

    private func layoutButtons() {
        let y: CGFloat = 2
        let height: CGFloat = bounds.height - 4
        let spacing: CGFloat = 2

        // New window button on the right
        let nwWidth: CGFloat = 30
        newWindowButton.frame = NSRect(x: bounds.width - nwWidth - 4, y: y, width: nwWidth, height: height)

        // Drive buttons on the left
        var x: CGFloat = 4
        for button in buttons {
            button.sizeToFit()
            let width = max(button.frame.width + 8, 60)
            button.frame = NSRect(x: x, y: y, width: width, height: height)
            x += width + spacing
        }
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        layoutButtons()
    }

    // MARK: - Actions

    @objc private func newWindowClicked(_ sender: NSButton) {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        delegate?.driveToolbarDidOpenNewWindow(homeURL)
    }

    @objc private func buttonClicked(_ sender: NSButton) {
        let url = urlForTag(sender.tag)
        delegate?.driveToolbarDidSelectVolume(url)
    }

    private func handleDoubleClick(tag: Int) {
        let url = urlForTag(tag)
        delegate?.driveToolbarDidOpenNewWindow(url)
    }

    private func urlForTag(_ tag: Int) -> URL {
        if tag == -1 {
            return FileManager.default.homeDirectoryForCurrentUser
        }
        if tag >= 0, tag < VolumeManager.shared.volumes.count {
            return VolumeManager.shared.volumes[tag].url
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }

    // MARK: - VolumeManagerDelegate

    func volumesDidChange() {
        rebuildButtons()
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: 28)
    }
}

// MARK: - Button that detects double-click

class DoubleClickButton: NSButton {
    var onDoubleClick: (() -> Void)?
    private var clickCount = 0
    private var clickTimer: Timer?

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            clickTimer?.invalidate()
            clickCount = 0
            onDoubleClick?()
        } else {
            clickCount = 1
            clickTimer?.invalidate()
            clickTimer = Timer.scheduledTimer(withTimeInterval: NSEvent.doubleClickInterval, repeats: false) { [weak self] _ in
                guard let self, self.clickCount == 1 else { return }
                self.clickCount = 0
                // Perform normal single-click action
                self.sendAction(self.action, to: self.target)
            }
        }
    }
}
