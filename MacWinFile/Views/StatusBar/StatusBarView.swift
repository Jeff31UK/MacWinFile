import SwiftUI

struct StatusBarView: View {
    var fileCount: Int
    var selectedCount: Int
    var totalSize: String
    var freeSpace: String
    var currentPath: String

    var body: some View {
        HStack(spacing: 0) {
            // Left: current path
            Text(currentPath)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)

            Divider()
                .frame(height: 14)

            // Center: file count info
            HStack(spacing: 4) {
                if selectedCount > 0 {
                    Text("\(selectedCount) of \(fileCount) selected")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.primary)
                } else {
                    Text("\(fileCount) file(s)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.primary)
                }
                Text("(\(totalSize))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)

            Divider()
                .frame(height: 14)

            // Right: free space
            Text("Free: \(freeSpace)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
        }
        .frame(height: 22)
        .background(.bar)
    }
}
