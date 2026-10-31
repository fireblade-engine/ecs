// The data behind the plots of the HTML report (Methodology.md "Statistical design v3"). The browser draws the plots from this
// JSON: the median line, distribution-free CI error bars of the median over replicates, a light band for the typical within-run IQR
// (spread of the measurements, not uncertainty) and, for non-baseline series, speed against the baseline with its CI. Numbers used for
// geometry stay numeric (base units, ns); everything shown to a reader (tooltip text) is formatted here with the table rules.
import Foundation

struct ReportPlotPayload: Encodable {
    var title: String
    /// Label of the baseline ref.
    var baseline: String
    /// Half-width of the equivalence zone (fraction).
    var delta: Double
    var workloads: [Workload]

    struct Workload: Encodable {
        /// Section id, also the `data-w` of the workload's tables.
        var id: String
        var identity: String
        var series: [Series]
        /// Speed against the baseline per non-baseline series.
        var rel: [Relative]
    }

    struct Series: Encodable {
        /// Index of the series in the report; `data-s` of its table cells.
        var idx: Int
        var color: Int
        var label: String
        var ref: String
        var backend: String
        var baseline: Bool
        /// Points by ascending entity count. A missing entity count is a gap in the line, never a zero.
        var points: [Point]
    }

    struct Point: Encodable {
        var n: Int
        var median: Double
        var ciLow: Double?
        var ciHigh: Double?
        /// Exact coverage of the CI.
        var cov: Double?
        var iqrLow: Double
        var iqrHigh: Double
        var k: Int
        var tMedian: String
        var tCI: String?
        var tPer: String?
        var tSpeed: String?
        var verdict: String?
        var sym: String?
    }

    struct Relative: Encodable {
        var idx: Int
        var color: Int
        var label: String
        var ref: String
        var backend: String
        var points: [RelativePoint]
    }

    struct RelativePoint: Encodable {
        var n: Int
        var speed: Double
        var ciLow: Double?
        var ciHigh: Double?
        /// True for the verdicts faster and slower: drawn as a filled marker.
        var sig: Bool
        var text: String
        var verdict: String?
        var sym: String?
    }

    /// JSON for a `<script type="application/json">` element: `<` is written `<`, so neither `</script>` nor `<!--` can occur.
    func json() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let text = String(decoding: try encoder.encode(self), as: UTF8.self)
        return text
            .replacingOccurrences(of: "<", with: "\\u003c")
            .replacingOccurrences(of: ">", with: "\\u003e")
            .replacingOccurrences(of: "&", with: "\\u0026")
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
    }
}
