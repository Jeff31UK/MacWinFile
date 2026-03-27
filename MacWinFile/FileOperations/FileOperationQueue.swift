import Cocoa

enum FileOperation {
    case copy(sources: [URL], destination: URL)
    case move(sources: [URL], destination: URL)
    case delete(sources: [URL])
    case rename(source: URL, newName: String)
}

class FileOperationQueue {
    static let shared = FileOperationQueue()

    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.macwinfile.fileops", qos: .userInitiated)

    private init() {}

    func execute(_ operation: FileOperation, completion: @escaping (Result<Void, Error>) -> Void) {
        queue.async {
            let result = self.performOperation(operation)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    private func performOperation(_ operation: FileOperation) -> Result<Void, Error> {
        do {
            switch operation {
            case .copy(let sources, let destination):
                for source in sources {
                    // Skip if already in destination
                    if source.deletingLastPathComponent().standardizedFileURL == destination.standardizedFileURL { continue }
                    let destURL = destination.appendingPathComponent(source.lastPathComponent)
                    let finalURL = uniqueURL(for: destURL)
                    try fileManager.copyItem(at: source, to: finalURL)
                }

            case .move(let sources, let destination):
                for source in sources {
                    // Skip if already in destination
                    if source.deletingLastPathComponent().standardizedFileURL == destination.standardizedFileURL { continue }
                    // Don't move a folder into itself
                    if destination.standardizedFileURL.path.hasPrefix(source.standardizedFileURL.path + "/") { continue }
                    let destURL = destination.appendingPathComponent(source.lastPathComponent)
                    let finalURL = uniqueURL(for: destURL)
                    try fileManager.moveItem(at: source, to: finalURL)
                }

            case .delete(let sources):
                for source in sources {
                    // Use async recycle on a background-safe semaphore
                    let semaphore = DispatchSemaphore(value: 0)
                    var recycleError: Error?
                    // Dispatch to main for NSWorkspace (which needs it), but we wait on this bg thread
                    DispatchQueue.main.async {
                        NSWorkspace.shared.recycle([source]) { _, error in
                            recycleError = error
                            semaphore.signal()
                        }
                    }
                    semaphore.wait()
                    if let error = recycleError { throw error }
                }

            case .rename(let source, let newName):
                let newURL = source.deletingLastPathComponent().appendingPathComponent(newName)
                try fileManager.moveItem(at: source, to: newURL)
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func uniqueURL(for url: URL) -> URL {
        guard fileManager.fileExists(atPath: url.path) else { return url }
        let dir = url.deletingLastPathComponent()
        let name = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension

        for counter in 2...9999 {
            let newName = ext.isEmpty ? "\(name) \(counter)" : "\(name) \(counter).\(ext)"
            let newURL = dir.appendingPathComponent(newName)
            if !fileManager.fileExists(atPath: newURL.path) {
                return newURL
            }
        }
        // Fallback: use timestamp
        let ts = Int(Date().timeIntervalSince1970)
        let fallbackName = ext.isEmpty ? "\(name) \(ts)" : "\(name) \(ts).\(ext)"
        return dir.appendingPathComponent(fallbackName)
    }
}
