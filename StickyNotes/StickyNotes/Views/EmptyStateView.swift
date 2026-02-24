import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("选择或创建一个便签")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("点击左上角按钮或按 ⌘N 创建新便签")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
