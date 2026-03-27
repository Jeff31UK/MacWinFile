import Cocoa

class WindowManager: BrowserWindowDelegate {

    private var windows: [BrowserWindowController] = []
    private(set) var activeWindow: BrowserWindowController?
    private var cascadePoint: NSPoint = .zero

    var directoryView: DirectoryWindowView? {
        return activeWindow?.directoryView
    }

    @discardableResult
    func openNewWindow(at url: URL) -> BrowserWindowController {
        let controller = BrowserWindowController(url: url)
        controller.browserDelegate = self

        // Cascade from the last position
        if let window = controller.window {
            cascadePoint = window.cascadeTopLeft(from: cascadePoint)
        }

        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)

        windows.append(controller)
        activeWindow = controller

        return controller
    }

    func navigateTo(url: URL) {
        if let active = activeWindow {
            active.navigateTo(url: url)
        } else {
            openNewWindow(at: url)
        }
    }

    func createDirectory() {
        guard let dirView = activeWindow?.directoryView,
              let window = activeWindow?.window else { return }

        let alert = NSAlert()
        alert.messageText = "Create Directory"
        alert.informativeText = "Enter the name for the new directory:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 250, height: 24))
        textField.placeholderString = "New Folder"
        alert.accessoryView = textField

        alert.beginSheetModal(for: window) { response in
            if response == .alertFirstButtonReturn {
                let name = textField.stringValue.isEmpty ? "New Folder" : textField.stringValue
                let newURL = dirView.currentDirectoryURL.appendingPathComponent(name)
                do {
                    try FileManager.default.createDirectory(at: newURL, withIntermediateDirectories: false)
                    dirView.refreshAndExpandNewItem(at: newURL)
                } catch {
                    let errorAlert = NSAlert(error: error)
                    errorAlert.runModal()
                }
            }
        }
    }

    func toggleDriveToolbar() {
        activeWindow?.toggleDriveToolbar()
    }

    var isDriveToolbarVisible: Bool {
        activeWindow?.isDriveToolbarVisible ?? true
    }

    // MARK: - BrowserWindowDelegate

    func browserWindowDidBecomeKey(_ controller: BrowserWindowController) {
        activeWindow = controller
    }

    func browserWindowWillClose(_ controller: BrowserWindowController) {
        windows.removeAll { $0 === controller }
        if activeWindow === controller {
            activeWindow = windows.last
        }
        // Quit when last window closes
        if windows.isEmpty {
            NSApp.terminate(nil)
        }
    }

    func browserWindowRequestNewWindow(at url: URL) {
        openNewWindow(at: url)
    }
}
