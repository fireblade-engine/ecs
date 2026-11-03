import Foundation
@testable import ECSBenchmarkReport
@testable import ECSBenchmarkResultSchema

/// Test-only view of the report HTML: the prose becomes Markdown-like text (headings as
/// `#`, bullets as `- `, `code`, **bold**), key/value tables become pipe rows, and workload sections become pages keyed like the old
/// files. Tables stay HTML. This keeps content assertions independent of the markup.
enum ReportHTMLSupport {
    static func decode(_ text: String) -> String {
        text.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">").replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'").replacingOccurrences(of: "&amp;", with: "&")
    }

    static func inline(_ html: String) -> String {
        var text = html
        for (tag, mark) in [("strong", "**"), ("em", "*"), ("code", "`")] {
            text = text.replacingOccurrences(of: "<\(tag)>", with: mark).replacingOccurrences(of: "</\(tag)>", with: mark)
        }
        text = text.replacing(#/<a href="([^"]*)">(.*?)<\/a>/#) { "[\($0.output.2)](\($0.output.1))" }
        text = text.replacing(#/<[^>]+>/#) { _ in "" }
        return decode(text)
    }

    /// Markdown-like text of `html` (the whole page body, or one section).
    static func text(_ html: String) -> String {
        var out: [String] = []
        var skipping = false
        var kv = false
        for line in html.components(separatedBy: "\n") {
            if line.hasPrefix("<style>") || line.hasPrefix("<script") { skipping = true }
            if skipping {
                if line.hasSuffix("</style>") || line.hasSuffix("</script>") || line == "</style>" || line == "</script>" { skipping = false }
                continue
            }
            if let heading = line.firstMatch(of: #/^<h([1-6])(?: id="[^"]*")?>(.*)<\/h[1-6]>$/#) {
                out += ["", String(repeating: "#", count: Int(heading.output.1)!) + " " + inline(String(heading.output.2)), ""]
            } else if line.hasPrefix("<li>") {
                out.append("- " + inline(line))
            } else if line.hasPrefix("<blockquote><p>") {
                out += ["", "> " + inline(line), ""]
            } else if line.hasPrefix("<p>") {
                out += ["", inline(line), ""]
            } else if line.hasPrefix("<table class=\"kv\"") {
                kv = true
                out.append(line)
            } else if line == "</table>" {
                kv = false
                out.append(line)
            } else if kv, line.hasPrefix("<tr><td>") {
                let cells = line.components(separatedBy: "</td><td>").map { inline($0) }
                out.append("| " + cells.joined(separator: " | ") + " |")
            } else {
                out.append(line)
            }
        }
        return out.joined(separator: "\n")
    }

    /// `REPORT.md` for the whole page and `workloads/<name>.md` for each workload section, as legacy-style text.
    static func pages(_ html: String) -> [String: String] {
        var pages = ["REPORT.md": text(html)]
        let lines = html.components(separatedBy: "\n")
        var start: Int?
        var name = ""
        for (index, line) in lines.enumerated() {
            if let match = line.firstMatch(of: #/^<section class="workload" id="w-([^"]*)">$/#) {
                start = index
                name = String(match.output.1)
            } else if line == "</section>", let begin = start {
                pages["workloads/\(name).md"] = text(lines[begin ... index].joined(separator: "\n"))
                start = nil
            }
        }
        return pages
    }

    /// The HTML of one workload section.
    static func section(_ html: String, _ workload: String) -> String? {
        let lines = html.components(separatedBy: "\n")
        guard let begin = lines.firstIndex(of: "<section class=\"workload\" id=\"w-\(workload)\">"),
              let end = lines[begin...].firstIndex(of: "</section>") else { return nil }
        return lines[begin ... end].joined(separator: "\n")
    }

    /// The JSON embedded in the page.
    static func embeddedJSON(_ html: String) -> Data? {
        guard let match = html.firstMatch(of: #/<script type="application\/json" id="report-data">(.*?)<\/script>/#.dotMatchesNewlines()) else { return nil }
        return Data(String(match.output.1).utf8)
    }
}

extension RenderedReport {
    /// Legacy-style text of the whole report.
    var markdown: String { ReportHTMLSupport.text(html) }
}
