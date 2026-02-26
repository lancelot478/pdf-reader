import SwiftUI

struct EmptyStateView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 90, height: 90)
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)

                Image(systemName: "note.text")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse.byLayer, options: .repeating, isActive: isAnimating)
            }

            VStack(spacing: 8) {
                Text("选择或创建一个便签")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.8))

                Text("点击左上角按钮或按 ⌘N 创建新便签")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}
