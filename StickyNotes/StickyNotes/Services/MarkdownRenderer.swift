import Foundation

enum MarkdownRenderer {

    static func renderHTML(from markdown: String, isDarkMode: Bool) -> String {
        let body = markdownToHTML(markdown)
        return htmlTemplate(body: body, isDarkMode: isDarkMode)
    }

    // MARK: - Block-level parsing

    private static func markdownToHTML(_ input: String) -> String {
        guard !input.isEmpty else { return "" }

        let lines = input.components(separatedBy: "\n")
        var result: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                i += 1
                continue
            }

            // Fenced code block
            if trimmed.hasPrefix("```") {
                let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var code: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    code.append(escapeHTML(lines[i]))
                    i += 1
                }
                if i < lines.count { i += 1 }
                let cls = lang.isEmpty ? "" : " class=\"language-\(escapeHTML(lang))\""
                result.append("<pre><code\(cls)>\(code.joined(separator: "\n"))</code></pre>")
                continue
            }

            // Heading
            if trimmed.range(of: #"^#{1,6}\s+.+"#, options: .regularExpression) != nil {
                let level = trimmed.prefix(while: { $0 == "#" }).count
                let text = String(trimmed.dropFirst(level)).trimmingCharacters(in: .whitespaces)
                result.append("<h\(level)>\(processInline(text))</h\(level)>")
                i += 1
                continue
            }

            // Horizontal rule
            if trimmed.range(of: #"^(-{3,}|\*{3,}|_{3,})$"#, options: .regularExpression) != nil {
                result.append("<hr>")
                i += 1
                continue
            }

            // Blockquote
            if trimmed.hasPrefix(">") {
                var quoteLines: [String] = []
                while i < lines.count {
                    let l = lines[i]
                    if l.hasPrefix("> ") {
                        quoteLines.append(String(l.dropFirst(2)))
                    } else if l.hasPrefix(">") {
                        quoteLines.append(String(l.dropFirst(1)))
                    } else {
                        break
                    }
                    i += 1
                }
                result.append("<blockquote>\(markdownToHTML(quoteLines.joined(separator: "\n")))</blockquote>")
                continue
            }

            // Unordered list
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                var items: [String] = []
                while i < lines.count {
                    let l = lines[i].trimmingCharacters(in: .whitespaces)
                    if l.hasPrefix("- ") {
                        items.append("<li>\(processInline(String(l.dropFirst(2))))</li>")
                    } else if l.hasPrefix("* ") {
                        items.append("<li>\(processInline(String(l.dropFirst(2))))</li>")
                    } else if l.isEmpty {
                        i += 1
                        continue
                    } else {
                        break
                    }
                    i += 1
                }
                result.append("<ul>\(items.joined(separator: "\n"))</ul>")
                continue
            }

            // Ordered list
            if trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil {
                var items: [String] = []
                while i < lines.count {
                    let l = lines[i].trimmingCharacters(in: .whitespaces)
                    if let r = l.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                        items.append("<li>\(processInline(String(l[r.upperBound...])))</li>")
                    } else if l.isEmpty {
                        i += 1
                        continue
                    } else {
                        break
                    }
                    i += 1
                }
                result.append("<ol>\(items.joined(separator: "\n"))</ol>")
                continue
            }

            // Paragraph
            var paraLines: [String] = []
            while i < lines.count {
                let l = lines[i]
                let lt = l.trimmingCharacters(in: .whitespaces)
                if lt.isEmpty || lt.hasPrefix("#") || lt.hasPrefix("```") ||
                    lt.hasPrefix("- ") || lt.hasPrefix("* ") || lt.hasPrefix(">") ||
                    lt.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil ||
                    lt.range(of: #"^(-{3,}|\*{3,}|_{3,})$"#, options: .regularExpression) != nil {
                    break
                }
                paraLines.append(l)
                i += 1
            }
            if !paraLines.isEmpty {
                result.append("<p>\(processInline(paraLines.joined(separator: "<br>")))</p>")
            }
        }

        return result.joined(separator: "\n")
    }

    // MARK: - Inline processing

    private static func processInline(_ text: String) -> String {
        var s = escapeHTML(text)
        s = s.replacingOccurrences(of: #"\*\*\*(.+?)\*\*\*"#, with: "<strong><em>$1</em></strong>", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\*(.+?)\*"#, with: "<em>$1</em>", options: .regularExpression)
        s = s.replacingOccurrences(of: #"~~(.+?)~~"#, with: "<del>$1</del>", options: .regularExpression)
        s = s.replacingOccurrences(of: #"`(.+?)`"#, with: "<code>$1</code>", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\[(.+?)\]\((.+?)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)
        return s
    }

    // MARK: - Helpers

    private static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func htmlTemplate(body: String, isDarkMode: Bool) -> String {
        let text = isDarkMode ? "#e0e0e0" : "#1d1d1f"
        let codeBg = isDarkMode ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.05)"
        let preBg = isDarkMode ? "rgba(255,255,255,0.06)" : "rgba(0,0,0,0.03)"
        let qBorder = isDarkMode ? "#555" : "#ccc"
        let qColor = isDarkMode ? "#aaa" : "#666"
        let link = isDarkMode ? "#6cb4ee" : "#0066cc"
        let hr = isDarkMode ? "#444" : "#ddd"

        return """
        <!DOCTYPE html>
        <html><head><meta charset="utf-8">
        <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif;
            font-size: 14px; line-height: 1.7; color: \(text);
            margin: 0; padding: 16px; background: transparent;
            -webkit-font-smoothing: antialiased;
        }
        h1 { font-size: 1.8em; margin: 0.6em 0 0.4em; font-weight: 700; }
        h2 { font-size: 1.5em; margin: 0.6em 0 0.4em; font-weight: 600; }
        h3 { font-size: 1.25em; margin: 0.6em 0 0.4em; font-weight: 600; }
        h4,h5,h6 { font-size: 1.05em; margin: 0.6em 0 0.4em; font-weight: 600; }
        p { margin: 0.5em 0; }
        code {
            font-family: Menlo, Monaco, "SF Mono", monospace;
            font-size: 0.88em; background: \(codeBg);
            padding: 2px 5px; border-radius: 4px;
        }
        pre {
            background: \(preBg); padding: 14px;
            border-radius: 8px; overflow-x: auto; margin: 0.6em 0;
        }
        pre code { background: transparent; padding: 0; font-size: 0.85em; }
        blockquote {
            border-left: 3px solid \(qBorder); margin: 0.5em 0;
            padding: 2px 14px; color: \(qColor);
        }
        a { color: \(link); text-decoration: none; }
        a:hover { text-decoration: underline; }
        hr { border: none; border-top: 1px solid \(hr); margin: 1.2em 0; }
        ul, ol { padding-left: 24px; margin: 0.5em 0; }
        li { margin: 0.2em 0; }
        del { opacity: 0.6; }
        </style></head>
        <body>\(body)</body></html>
        """
    }
}
