import Foundation

class FileSystemStore {
    static let shared = FileSystemStore()

    private let fileManager = FileManager.default

    private init() {}

    func loadChildren(for item: FileSystemItem) -> [FileSystemItem] {
        return loadContents(of: item.url)
    }

    func loadContents(of url: URL) -> [FileSystemItem] {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [
                .isDirectoryKey,
                .fileSizeKey,
                .contentModificationDateKey,
                .localizedTypeDescriptionKey,
                .isHiddenKey
            ],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls.map { FileSystemItem(url: $0) }
            .sorted { a, b in
                if a.isDirectory != b.isDirectory {
                    return a.isDirectory
                }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
    }

    func rootItem(for url: URL) -> FileSystemItem {
        return FileSystemItem(url: url)
    }

    func calculateDirectoryStats(at url: URL) -> (fileCount: Int, totalSize: Int64, freeSpace: Int64) {
        let items = loadContents(of: url)
        let files = items.filter { !$0.isDirectory }
        let totalSize = files.reduce(Int64(0)) { $0 + $1.size }

        let freeSpace: Int64
        if let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityKey]) {
            freeSpace = Int64(values.volumeAvailableCapacity ?? 0)
        } else {
            freeSpace = 0
        }

        return (files.count, totalSize, freeSpace)
    }
}
