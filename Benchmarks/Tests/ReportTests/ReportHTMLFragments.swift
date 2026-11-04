import Foundation
@testable import ECSBenchmarkReport
@testable import ECSBenchmarkResultSchema

/// Helpers that cut fragments out of the report HTML; the tests assert on the HTML itself (headings, list items, table cells).
enum ReportHTMLFragments {
    /// Text with the five escaped characters restored.
    static func decode(_ text: String) -> String {
        text.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">").replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'").replacingOccurrences(of: "&amp;", with: "&")
    }

    /// The HTML of one workload section.
    static func section(_ html: String, _ workload: String) -> String? {
        let lines = html.components(separatedBy: "\n")
        guard let begin = lines.firstIndex(of: "<section class=\"workload\" id=\"w-\(workload)\">"),
              let end = lines[begin...].firstIndex(of: "</section>") else { return nil }
        return lines[begin ... end].joined(separator: "\n")
    }

    /// The HTML between the heading of `anchor` (`<h2 id="anchor">`) and the next `<h2`, or the end of the main content.
    static func chapter(_ html: String, _ anchor: String) -> String? {
        guard let begin = html.range(of: "<h2 id=\"\(anchor)\">") else { return nil }
        let rest = html[begin.upperBound...]
        let end = rest.range(of: "<h2")?.lowerBound ?? rest.endIndex
        return String(html[begin.lowerBound ..< end])
    }

    /// The JSON embedded in the page.
    static func embeddedJSON(_ html: String) -> Data? {
        guard let match = html.firstMatch(of: #/<script type="application\/json" id="report-data">(.*?)<\/script>/#.dotMatchesNewlines()) else { return nil }
        return Data(String(match.output.1).utf8)
    }
}
