import SwiftUI

struct NoteRowView: View {
    let note: Note
    var isSelected: Bool = false

    @State private var isHovering = false

    private var preview: String {
        let lines = note.content.split(separator: "\n", maxSplits: 2, omittingEmptySubsequences: true)
        if lines.count > 1 {
            return String(lines[1]).trimmingCharacters(in: .whitespaces)
        }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(note.title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .foregroundColor(isSelected ? .white : .primary)

            if !preview.isEmpty {
                Text(preview)
                    .font(.system(size: 11))
                    .lineLimit(2)
                    .foregroundColor(isSelected ? Color.white.opacity(0.75) : .secondary)
            }

            Text(note.updatedAt, style: .relative)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isSelected ? Color.white.opacity(0.6) : Color.secondary.opacity(0.7))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
