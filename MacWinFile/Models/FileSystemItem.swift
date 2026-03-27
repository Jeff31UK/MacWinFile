import Cocoa

class FileSystemItem: NSObject {
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
    let dateModified: Date
    let kind: String

    private var _icon: NSImage?
    var icon: NSImage {
        if let cached = _icon { return cached }
        let img = NSWorkspace.shared.icon(forFile: url.path)
        img.size = NSSize(width: 16, height: 16)
        _icon = img
        return img
    }

    private var _children: [FileSystemItem]?
    var isChildrenLoaded: Bool { _children != nil }

    var children: [FileSystemItem] {
        if let cached = _children { return cached }
        guard isDirectory else { return [] }
        let items = FileSystemStore.shared.loadChildren(for: self)
        _children = items
        return items
    }

    var directoryChildren: [FileSystemItem] {
        return children.filter { $0.isDirectory }
    }

    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent

        let resourceValues = try? url.resourceValues(forKeys: [
            .isDirectoryKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .localizedTypeDescriptionKey
        ])

        self.isDirectory = resourceValues?.isDirectory ?? false
        self.size = Int64(resourceValues?.fileSize ?? 0)
        self.dateModified = resourceValues?.contentModificationDate ?? Date.distantPast
        self.kind = resourceValues?.localizedTypeDescription ?? "Unknown"

        super.init()
    }

    func invalidateChildren() {
        _children = nil
    }

    var formattedSize: String {
        if isDirectory { return "--" }
        return FileSizeFormatter.string(fromBytes: size)
    }

    var formattedDate: String {
        return DateFormatter.winFileFormatter.string(from: dateModified)
    }

    override var hash: Int {
        return url.hashValue
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? FileSystemItem else { return false }
        return url == other.url
    }
}

extension DateFormatter {
    static let winFileFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd/yyyy hh:mm a"
        return f
    }()
}
