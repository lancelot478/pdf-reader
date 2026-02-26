import SwiftUI

struct MarkdownPreviewView: View {
    let content: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                    renderBlock(block)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
        }
    }

    // MARK: - Rendering

    @ViewBuilder
    private func renderBlock(_ block: Block) -> some View {
        switch block {
        case .heading(let level, let text):
            VStack(alignment: .leading, spacing: 4) {
                Text(inlineMarkdown(text))
                    .font(headingFont(level))
                    .fontWeight(level <= 2 ? .bold : .semibold)

                if level <= 2 {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.4), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                }
            }
            .padding(.top, level <= 2 ? 10 : 6)

        case .paragraph(let text):
            Text(inlineMarkdown(text))
                .font(.body)
                .lineSpacing(3)

        case .codeBlock(_, let code):
            Text(code)
                .font(.system(size: 12, design: .monospaced))
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.quaternary, lineWidth: 0.5)
                )

        case .unorderedList(let items):
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.7))
                            .frame(width: 5, height: 5)
                            .offset(y: 1)
                        Text(inlineMarkdown(item))
                            .lineSpacing(2)
                    }
                }
            }
            .padding(.leading, 6)

        case .orderedList(let items):
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(index + 1).")
                            .foregroundColor(Color.accentColor.opacity(0.8))
                            .monospacedDigit()
                            .font(.system(size: 12, weight: .semibold))
                        Text(inlineMarkdown(item))
                            .lineSpacing(2)
                    }
                }
            }
            .padding(.leading, 6)

        case .blockquote(let text):
            HStack(alignment: .top, spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.6), Color.accentColor.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3)

                Text(inlineMarkdown(text))
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                    .italic()
                    .lineSpacing(2)
                    .padding(.leading, 14)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.quaternary.opacity(0.3))
            )

        case .horizontalRule:
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .secondary.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.vertical, 8)
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .system(size: 24, weight: .bold)
        case 2: return .system(size: 20, weight: .bold)
        case 3: return .system(size: 17, weight: .semibold)
        case 4: return .system(size: 15, weight: .semibold)
        default: return .system(size: 14, weight: .medium)
        }
    }

    private func inlineMarkdown(_ text: String) -> AttributedString {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        return (try? AttributedString(markdown: text, options: options))
            ?? AttributedString(text)
    }

    // MARK: - Block types

    private enum Block {
        case heading(level: Int, text: String)
        case paragraph(text: String)
        case codeBlock(language: String, code: String)
        case unorderedList(items: [String])
        case orderedList(items: [String])
        case blockquote(text: String)
        case horizontalRule
    }

    // MARK: - Parser

    private func parseBlocks() -> [Block] {
        guard !content.isEmpty else { return [] }

        let lines = content.components(separatedBy: "\n")
        var blocks: [Block] = []
        var i = 0

        while i < lines.count {
            let startI = i
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty { i += 1; continue }

            if trimmed.hasPrefix("```") {
                let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var code: [String] = []
                i += 1
                while i < lines.count &&
                        !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    code.append(lines[i])
                    i += 1
                }
                if i < lines.count { i += 1 }
                blocks.append(.codeBlock(language: lang, code: code.joined(separator: "\n")))
                continue
            }

            if trimmed.range(of: #"^#{1,6}\s+.+"#, options: .regularExpression) != nil {
                let level = trimmed.prefix(while: { $0 == "#" }).count
                let text = String(trimmed.dropFirst(level)).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(level: level, text: text))
                i += 1; continue
            }

            if trimmed.range(of: #"^(-{3,}|\*{3,}|_{3,})$"#, options: .regularExpression) != nil {
                blocks.append(.horizontalRule)
                i += 1; continue
            }

            if trimmed.hasPrefix("> ") || trimmed == ">" {
                var quoteLines: [String] = []
                while i < lines.count {
                    let lt = lines[i].trimmingCharacters(in: .whitespaces)
                    if lt.hasPrefix("> ") {
                        quoteLines.append(String(lt.dropFirst(2)))
                    } else if lt == ">" {
                        quoteLines.append("")
                    } else { break }
                    i += 1
                }
                blocks.append(.blockquote(text: quoteLines.joined(separator: "\n")))
                continue
            }

            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                var items: [String] = []
                while i < lines.count {
                    let lt = lines[i].trimmingCharacters(in: .whitespaces)
                    if lt.hasPrefix("- ") {
                        items.append(String(lt.dropFirst(2)))
                    } else if lt.hasPrefix("* ") {
                        items.append(String(lt.dropFirst(2)))
                    } else if lt.isEmpty {
                        i += 1; continue
                    } else { break }
                    i += 1
                }
                blocks.append(.unorderedList(items: items))
                continue
            }

            if trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil {
                var items: [String] = []
                while i < lines.count {
                    let lt = lines[i].trimmingCharacters(in: .whitespaces)
                    if let r = lt.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                        items.append(String(lt[r.upperBound...]))
                    } else if lt.isEmpty {
                        i += 1; continue
                    } else { break }
                    i += 1
                }
                blocks.append(.orderedList(items: items))
                continue
            }

            var paraLines: [String] = []
            while i < lines.count {
                let lt = lines[i].trimmingCharacters(in: .whitespaces)
                let isBlockStart = lt.isEmpty || lt.hasPrefix("```") ||
                    lt.range(of: #"^#{1,6}\s+.+"#, options: .regularExpression) != nil ||
                    lt.hasPrefix("- ") || lt.hasPrefix("* ") ||
                    (lt.hasPrefix("> ") || lt == ">") ||
                    lt.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil ||
                    lt.range(of: #"^(-{3,}|\*{3,}|_{3,})$"#, options: .regularExpression) != nil
                if isBlockStart { break }
                paraLines.append(lines[i])
                i += 1
            }
            if !paraLines.isEmpty {
                blocks.append(.paragraph(text: paraLines.joined(separator: "\n")))
            }

            if i == startI {
                blocks.append(.paragraph(text: lines[i]))
                i += 1
            }
        }

        return blocks
    }
}
