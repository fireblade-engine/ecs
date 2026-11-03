// Typed construction of the report's prose as escaped HTML. The literal parts of an `HTMLText` are trusted markup written in the
// source (`<code>`, `<strong>`, `<em>`, `<a href="#...">`; a literal `<`, `>` or `&` is written as an entity); every interpolated
// value is HTML-escaped, so text from result files cannot inject markup. Links are built only by `HTMLText.StringInterpolation.appendInterpolation(anchor:_:)`
// and always point at an in-page `#` target.
import Foundation

/// HTML text: trusted literal markup plus escaped interpolations.
struct HTMLText: ExpressibleByStringInterpolation, Equatable {
    let html: String

    init(html: String) {
        self.html = html
    }

    init(stringLiteral value: String) {
        html = value
    }

    init(stringInterpolation: StringInterpolation) {
        html = stringInterpolation.html
    }

    /// `values` as escaped text, separated by the (trusted) `separator`.
    static func joined(_ values: [HTMLText], separator: String = "") -> HTMLText {
        HTMLText(html: values.map(\.html).joined(separator: separator))
    }

    struct StringInterpolation: StringInterpolationProtocol {
        fileprivate(set) var html = ""

        init(literalCapacity: Int, interpolationCount: Int) {
            html.reserveCapacity(literalCapacity)
        }

        mutating func appendLiteral(_ literal: String) {
            html += literal
        }

        /// Any value, escaped.
        mutating func appendInterpolation(_ value: some CustomStringConvertible) {
            html += ReportHTML.escape(value.description)
        }

        /// Already-built markup.
        mutating func appendInterpolation(_ value: HTMLText) {
            html += value.html
        }

        /// A link to the in-page target `#anchor` (an `anchor` that is not a plain name is dropped and only the label is shown).
        mutating func appendInterpolation(anchor: String, _ label: String) {
            let plain = !anchor.isEmpty && anchor.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") }
            html += plain ? "<a href=\"#\(anchor)\">\(ReportHTML.escape(label))</a>" : ReportHTML.escape(label)
        }
    }
}

/// A block of the page body.
enum ReportBlock {
    case heading(Int, HTMLText, id: String? = nil)
    case paragraph(HTMLText)
    case list([HTMLText])

    var html: String {
        switch self {
        case let .heading(level, text, id):
            let attribute = id.map { " id=\"\(ReportHTML.escape($0))\"" } ?? ""
            return "<h\(level)\(attribute)>\(text.html)</h\(level)>"
        case let .paragraph(text):
            return "<p>\(text.html)</p>"
        case let .list(items):
            return "<ul>\n" + items.map { "<li>\($0.html)</li>" }.joined(separator: "\n") + "\n</ul>"
        }
    }
}

enum ReportHTML {
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

    /// `<code>` span with escaped content.
    static func code(_ value: String) -> HTMLText {
        "<code>\(value)</code>"
    }
}
