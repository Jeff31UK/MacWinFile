import Foundation

class SearchEngine {
    private var isCancelled = false

    func cancel() {
        isCancelled = true
    }

    func search(
        in rootURL: URL,
        query: String,
        includeSubdirectories: Bool = true,
        onResult: @escaping (FileSystemItem) -> Void,
        onComplete: @escaping () -> Void
    ) {
        isCancelled = false

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.searchRecursive(
                url: rootURL,
                query: query.lowercased(),
                recursive: includeSubdirectories,
                onResult: onResult
            )
            DispatchQueue.main.async {
                onComplete()
            }
        }
    }

    private func searchRecursive(
        url: URL,
        query: String,
        recursive: Bool,
        onResult: @escaping (FileSystemItem) -> Void
    ) {
        guard !isCancelled else { return }

        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .localizedTypeDescriptionKey],
            options: recursive ? [.skipsHiddenFiles] : [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else { return }

        for case let fileURL as URL in enumerator {
            if isCancelled { return }

            let name = fileURL.lastPathComponent.lowercased()

            // Support wildcards: * matches any, ? matches single char
            if matchesWildcard(name: name, pattern: query) {
                let item = FileSystemItem(url: fileURL)
                DispatchQueue.main.async {
                    onResult(item)
                }
            }
        }
    }

    private func matchesWildcard(name: String, pattern: String) -> Bool {
        // Simple wildcard support: * and ?
        if !pattern.contains("*") && !pattern.contains("?") {
            return name.contains(pattern)
        }

        let regexPattern = "^" + NSRegularExpression.escapedPattern(for: pattern)
            .replacingOccurrences(of: "\\*", with: ".*")
            .replacingOccurrences(of: "\\?", with: ".") + "$"

        return (try? NSRegularExpression(pattern: regexPattern, options: .caseInsensitive))
            .map { $0.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)) != nil }
            ?? name.contains(pattern)
    }
}
