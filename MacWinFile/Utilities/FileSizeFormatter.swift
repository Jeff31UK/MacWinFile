import Foundation

enum FileSizeFormatter {
    static func string(fromBytes bytes: Int64) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", Double(bytes) / (1024.0 * 1024.0))
        } else {
            return String(format: "%.2f GB", Double(bytes) / (1024.0 * 1024.0 * 1024.0))
        }
    }
}
