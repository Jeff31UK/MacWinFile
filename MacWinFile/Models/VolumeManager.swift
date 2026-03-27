import Cocoa

protocol VolumeManagerDelegate: AnyObject {
    func volumesDidChange()
}

class VolumeManager {
    static let shared = VolumeManager()

    weak var delegate: VolumeManagerDelegate?

    struct Volume {
        let url: URL
        let name: String
        let icon: NSImage
        let isRemovable: Bool
    }

    private(set) var volumes: [Volume] = []

    private init() {
        refreshVolumes()
        setupNotifications()
    }

    func refreshVolumes() {
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeIsRemovableKey,
            .effectiveIconKey
        ]

        let volumeURLs = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) ?? []

        volumes = volumeURLs.compactMap { url -> Volume? in
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { return nil }
            let name = values.volumeName ?? url.lastPathComponent
            let icon = values.effectiveIcon as? NSImage ?? NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 16, height: 16)
            let isRemovable = values.volumeIsRemovable ?? false
            return Volume(url: url, name: name, icon: icon, isRemovable: isRemovable)
        }
    }

    private func setupNotifications() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(volumesChanged(_:)),
                          name: NSWorkspace.didMountNotification, object: nil)
        center.addObserver(self, selector: #selector(volumesChanged(_:)),
                          name: NSWorkspace.didUnmountNotification, object: nil)
    }

    @objc private func volumesChanged(_ notification: Notification) {
        refreshVolumes()
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.volumesDidChange()
        }
    }
}
