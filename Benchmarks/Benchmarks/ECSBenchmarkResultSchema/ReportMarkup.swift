// A tiny converter from the Markdown subset the report prose uses (`##`/`###` headings, `- ` bullets, `> ` quotes, `code`, **bold**,
// *italic* and `[text](#anchor)` links) to escaped HTML. Raw HTML never passes through: every character of the input is escaped,
// so text from result files cannot inject markup. The prose generators (guide, glossary, methods) keep their plain-text form.
import Foundation

enum ReportMarkup {
    /// HTML text and attribute escaping.
    static func escape(_ text: String) -> String {
        var out = ""
        out.reserveCapacity(text.count)
        for character in text {
            switch character {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            case "'": out += "&#39;"
            case "\n", "\t": out += " "
            default: out.append(character)
            }
        }
        return out
    }

    /// Reverses the three entities the report's `text()` helper writes, so that escaping happens exactly once.
    static func decodeEntities(_ text: String) -> String {
        guard text.contains("&") else { return text }
        var out = ""
        var index = text.startIndex
        while index < text.endIndex {
            if text[index] == "&" {
                let rest = text[index...]
                if rest.hasPrefix("&amp;") { out += "&"; index = text.index(index, offsetBy: 5); continue }
                if rest.hasPrefix("&lt;") { out += "<"; index = text.index(index, offsetBy: 4); continue }
                if rest.hasPrefix("&gt;") { out += ">"; index = text.index(index, offsetBy: 4); continue }
            }
            out.append(text[index])
            index = text.index(after: index)
        }
        return out
    }

    /// Anchor name of a heading: lowercase ASCII letters and digits, other runs become one hyphen.
    static func slug(_ text: String) -> String {
        var out = ""
        var pendingHyphen = false
        for scalar in decodeEntities(text).lowercased().unicodeScalars {
            if scalar.isASCII, CharacterSet.alphanumerics.contains(scalar) {
                if pendingHyphen, !out.isEmpty { out += "-" }
                pendingHyphen = false
                out.unicodeScalars.append(scalar)
            } else {
                pendingHyphen = true
            }
        }
        return out
    }

    nonisolated(unsafe) private static let codeSpan = try! Regex(#"`([^`]*)`"#)

    /// Inline markup of one line: code spans, bold, italic, links; everything else is escaped text.
    static func inline(_ line: String) -> String {
        var out = ""
        var rest = line[...]
        while let match = rest.firstMatch(of: codeSpan) {
            out += styled(escape(decodeEntities(String(rest[..<match.range.lowerBound]))))
            out += "<code>" + escape(decodeEntities(match.output[1].substring.map(String.init) ?? "")) + "</code>"
            rest = rest[match.range.upperBound...]
        }
        return out + styled(escape(decodeEntities(String(rest))))
    }

    nonisolated(unsafe) private static let bold = try! Regex(#"\*\*(.+?)\*\*"#)
    nonisolated(unsafe) private static let italic = try! Regex(#"(^|[^*\w])\*([^*\s][^*]*?)\*($|[^*\w])"#)
    nonisolated(unsafe) private static let link = try! Regex(#"\[([^\]]+)\]\(([^)\s]+)\)"#)

    private static func styled(_ escaped: String) -> String {
        var text = escaped.replacing(bold) { "<strong>\($0.output[1].substring ?? "")</strong>" }
        text = text.replacing(italic) { "\($0.output[1].substring ?? "")<em>\($0.output[2].substring ?? "")</em>\($0.output[3].substring ?? "")" }
        text = text.replacing(link) { match in
            let label = match.output[1].substring.map(String.init) ?? ""
            let target = match.output[2].substring.map(String.init) ?? ""
            // Only in-page anchors and relative paths become links.
            guard target.hasPrefix("#") || !target.contains(":") else { return label }
            return "<a href=\"\(target)\">\(label)</a>"
        }
        return text
    }

    private enum Block { case none, paragraph, list, quote }

    /// Block structure of `lines`. `headingOffset` is added to the number of `#` (so `##` can become `<h3>`); `anchors` adds an `id` to
    /// each heading (off where the same heading repeats, as in the workload sections).
    static func html(_ lines: [String], headingOffset: Int = 0, anchors: Bool = true) -> String {
        var out: [String] = []
        var block = Block.none
        var buffer: [String] = []
        func flush() {
            switch block {
            case .none: break
            case .paragraph: out.append("<p>" + buffer.map(inline).joined(separator: " ") + "</p>")
            case .list: out.append("<ul>\n" + buffer.map { "<li>" + inline($0) + "</li>" }.joined(separator: "\n") + "\n</ul>")
            case .quote: out.append("<blockquote><p>" + buffer.map(inline).joined(separator: " ") + "</p></blockquote>")
            }
            block = .none
            buffer = []
        }
        func add(_ kind: Block, _ text: String) {
            if block != kind { flush() }
            block = kind
            buffer.append(text)
        }
        for line in lines {
            if line.isEmpty {
                flush()
            } else if let heading = headingLevel(line) {
                flush()
                let level = min(6, heading.level + headingOffset)
                let id = anchors ? " id=\"\(slug(heading.text))\"" : ""
                out.append("<h\(level)\(id)>\(inline(heading.text))</h\(level)>")
            } else if line.hasPrefix("- ") {
                add(.list, String(line.dropFirst(2)))
            } else if line.hasPrefix("> ") {
                add(.quote, String(line.dropFirst(2)))
            } else {
                add(.paragraph, line)
            }
        }
        flush()
        return out.joined(separator: "\n")
    }

    private static func headingLevel(_ line: String) -> (level: Int, text: String)? {
        let hashes = line.prefix { $0 == "#" }.count
        guard (1 ... 6).contains(hashes), line.dropFirst(hashes).first == " " else { return nil }
        return (hashes, String(line.dropFirst(hashes + 1)))
    }
}
