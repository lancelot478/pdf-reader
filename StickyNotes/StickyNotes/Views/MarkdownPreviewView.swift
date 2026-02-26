import SwiftUI

struct MarkdownPreviewView: View {
    let content: String

    var body: some View {
        let _ = print("[Preview] body evaluated, content length=\(content.count)")
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                    renderBlock(block)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
        }
    }

    // MARK: - Rendering

    @ViewBuilder
    private func renderBlock(_ block: Block) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(inlineMarkdown(text))
                .font(headingFont(level))
                .fontWeight(level <= 2 ? .bold : .semibold)
                .padding(.top, level <= 2 ? 8 : 4)

        case .paragraph(let text):
            Text(inlineMarkdown(text))
                .font(.body)

        case .codeBlock(_, let code):
            Text(code)
                .font(.system(.callout, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))

        case .unorderedList(let items):
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("•").foregroundStyle(.secondary)
                        Text(inlineMarkdown(item))
                    }
                }
            }
            .padding(.leading, 4)

        case .orderedList(let items):
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(index + 1).")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        Text(inlineMarkdown(item))
                    }
                }
            }
            .padding(.leading, 4)

        case .blockquote(let text):
            HStack(alignment: .top, spacing: 0) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.secondary.opacity(0.4))
                    .frame(width: 3)
                Text(inlineMarkdown(text))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 12)
            }
            .padding(.vertical, 2)

        case .horizontalRule:
            Divider().padding(.vertical, 4)
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title
        case 2: return .title2
        case 3: return .title3
        case 4: return .headline
        default: return .subheadline
        }
    }

    private func inlineMarkdown(_ text: String) -> AttributedString {
        print("[Preview] inlineMarkdown called, text='\(text.prefix(30))'")
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        let result = (try? AttributedString(markdown: text, options: options))
            ?? AttributedString(text)
        print("[Preview] inlineMarkdown done")
        return result
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
        print("[Preview] parseBlocks start, content='\(content.prefix(50))'")
        guard !content.isEmpty else { print("[Preview] content empty"); return [] }

        let lines = content.components(separatedBy: "\n")
        var blocks: [Block] = []
        var i = 0

        while i < lines.count {
            let startI = i
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty { i += 1; continue }

            // Fenced code block
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

            // Heading: requires `# ` (hash + space + content)
            if trimmed.range(of: #"^#{1,6}\s+.+"#, options: .regularExpression) != nil {
                let level = trimmed.prefix(while: { $0 == "#" }).count
                let text = String(trimmed.dropFirst(level)).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(level: level, text: text))
                i += 1; continue
            }

            // Horizontal rule
            if trimmed.range(of: #"^(-{3,}|\*{3,}|_{3,})$"#, options: .regularExpression) != nil {
                blocks.append(.horizontalRule)
                i += 1; continue
            }

            // Blockquote
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

            // Unordered list
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

            // Ordered list
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

            // Paragraph (fallback) — uses exact same checks as block handlers above
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

            // Safety net: if nothing advanced i, force skip this line as plain text
            if i == startI {
                blocks.append(.paragraph(text: lines[i]))
                i += 1
            }
        }

        print("[Preview] parseBlocks done, \(blocks.count) blocks")
        return blocks
    }
}
