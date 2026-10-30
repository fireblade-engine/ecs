import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

@Suite
struct ReportPlotTests {
    private func series(_ label: String, color: Int, baseline: Bool = false, _ points: [Int: ReportPlotPoint]) -> ReportPlotSeries {
        ReportPlotSeries(label: label, colorIndex: color, isBaseline: baseline, points: points)
    }

    private func point(_ mean: Double, _ sd: Double = 0, n: Int = 10) -> ReportPlotPoint {
        ReportPlotPoint(mean: mean, standardDeviation: sd, samples: n)
    }

    private var sample: [ReportPlotSeries] {
        [
            series("1.4.3 (class, default)", color: 0, baseline: true, [1: point(1000, 100), 16: point(2000, 200), 256: point(8000, 500), 4096: point(100_000, 9000)]),
            series("main (value, archetype)", color: 1, [1: point(500, 600), 16: point(900, 100, n: 1), 256: point(3000, 100, n: 3), 4096: point(40000, 2000)])
        ]
    }

    private final class WellFormedness: NSObject, XMLParserDelegate {
        var elements: [String: Int] = [:]
        var error: Error?
        func parser(_: XMLParser, didStartElement name: String, namespaceURI _: String?, qualifiedName _: String?, attributes _: [String: String] = [:]) {
            elements[name, default: 0] += 1
        }

        func parser(_: XMLParser, parseErrorOccurred parseError: Error) { error = parseError }
    }

    private func parse(_ svg: String) -> WellFormedness {
        let delegate = WellFormedness()
        let parser = XMLParser(data: Data(svg.utf8))
        parser.delegate = delegate
        #expect(parser.parse(), "\(delegate.error.map { "\($0)" } ?? "")")
        return delegate
    }

    @Test
    func svgIsWellFormedAndHasTheExpectedParts() throws {
        let svg = try #require(ReportPlot.render(title: "w", yTitle: "Time per entity", perEntity: true, series: sample))
        let parsed = parse(svg)
        #expect(parsed.elements["svg"] == 1)
        #expect(parsed.elements["style"] == 1)
        #expect(parsed.elements["polyline"] == 2)
        #expect(svg.contains(#"viewBox="0 0 960 540""#))
        #expect(svg.contains("@media (prefers-color-scheme: dark)"))
        #expect(svg.contains("Time per entity (ns), log10 scale") || svg.contains("Time per entity (μs), log10 scale"))
        #expect(svg.contains("Entities (log2 scale)"))
        #expect(svg.contains("Dashed line: baseline") && svg.contains("(baseline)"))
    }

    @Test
    func textIsEscapedForXML() throws {
        let nasty = series("a <b> & \"c\" 'd' \u{1}", color: 0, [1: point(10, 1), 2: point(20, 1)])
        let svg = try #require(ReportPlot.render(title: "x & <y> \"z\"", yTitle: "t", perEntity: false, series: [nasty]))
        _ = parse(svg)
        #expect(!svg.contains("<b>") && svg.contains("&lt;b&gt; &amp;"))
        #expect(!svg.contains("\u{1}"))
        #expect(ReportPlot.escape("a&b") == "a&amp;b")
    }

    @Test
    func outputIsDeterministic() {
        let first = ReportPlot.render(title: "w", yTitle: "t", perEntity: false, series: sample)
        #expect(first != nil)
        #expect(first == ReportPlot.render(title: "w", yTitle: "t", perEntity: false, series: sample))
    }

    @Test
    func logAxisTicks() {
        let range = ReportPlot.decadeRange(lower: 0.37, upper: 4200)
        #expect(range.low == -1 && range.high == 4)
        let ticks = ReportPlot.decadeTicks(range)
        #expect(ticks.major == [0.1, 1, 10, 100, 1000, 10000])
        #expect(ticks.minor.count == 8 * 5)
        #expect(ticks.minor.prefix(3).map { ($0 * 100).rounded() / 100 } == [0.2, 0.3, 0.4])
        // Exact powers of ten stay on their decade; a degenerate range still spans one decade.
        let exact = ReportPlot.decadeRange(lower: 10, upper: 1000)
        #expect(exact.low == 1 && exact.high == 3)
        let flat = ReportPlot.decadeRange(lower: 10, upper: 10)
        #expect(flat.low == 1 && flat.high == 2)
        #expect(ReportPlot.decadeLabel(-3) == "0.001" && ReportPlot.decadeLabel(0) == "1" && ReportPlot.decadeLabel(4) == "10000")
    }

    @Test
    func powerOfTwoAxisAndCompactLabels() {
        let exponents = ReportPlot.powerOfTwoExponents(minimum: 1, maximum: 2_097_152)
        #expect(exponents == Array(0 ... 21))
        let labelled = ReportPlot.labelledExponents(exponents).sorted().map { ReportPlot.compactCount(1 << $0) }
        #expect(labelled == ["1", "16", "256", "4K", "64K", "1M", "2M"])
        #expect(ReportPlot.compactCount(512) == "512" && ReportPlot.compactCount(1024) == "1K" && ReportPlot.compactCount(3000) == "3000")
        #expect(ReportPlot.labelledExponents(Array(0 ... 16)).sorted() == [0, 4, 8, 12, 16])
        #expect(ReportPlot.powerOfTwoExponents(minimum: 3, maximum: 100) == [1, 2, 3, 4, 5, 6, 7])
    }

    @Test
    func bandIsClippedToThePlotFloor() throws {
        // mean - sd is negative: the lower band edge sits on the floor (y = 462), never above or below, and nothing is NaN.
        let wide = series("w", color: 0, [1: point(100, 150), 2: point(100, 150)])
        let svg = try #require(ReportPlot.render(title: "w", yTitle: "t", perEntity: false, series: [wide]))
        let polygon = try #require(svg.components(separatedBy: "\n").first { $0.hasPrefix(#"<polygon class="band"#) })
        let points = try #require(polygon.components(separatedBy: #"points=""#).last?.components(separatedBy: #"""#).first)
        let ys = points.split(separator: " ").map { Double($0.split(separator: ",")[1])! }
        #expect(ys.count == 4)
        #expect(ys.suffix(2).allSatisfy { $0 == ReportPlot.bottom }, "lower edge clipped: \(ys)")
        #expect(ys.prefix(2).allSatisfy { $0 < ReportPlot.bottom && $0 >= ReportPlot.top })
        #expect(!svg.contains("nan") && !svg.contains("inf"))
    }

    @Test
    func singleSamplePointHasHollowMarkerAndNoBand() throws {
        let one = series("one", color: 0, [1: point(100, 0, n: 1), 2: point(200, 0, n: 1), 4: point(400, 20, n: 10), 8: point(800, 20, n: 10)])
        let svg = try #require(ReportPlot.render(title: "w", yTitle: "t", perEntity: false, series: [one]))
        let lines = svg.components(separatedBy: "\n")
        #expect(lines.filter { $0.hasPrefix("<circle") && $0.contains("marker c0 hollow") }.count == 2)
        #expect(lines.filter { $0.hasPrefix("<circle") && !$0.contains("hollow") }.count == 2 + 1, "two filled plot markers and one legend marker")
        #expect(lines.filter { $0.hasPrefix(#"<polygon class="band"#) }.count == 1, "only the run of points with n >= 2 has a band")
        #expect(svg.contains("Hollow marker: 1 sample, no band"))
        #expect(svg.contains("† some points have fewer than 5 samples") && svg.contains("one †"))
    }

    @Test
    func missingScalesAreGapsNotZeros() throws {
        let gap = series("gap", color: 0, [1: point(10, 1), 2: point(20, 1), 8: point(80, 1), 16: point(160, 1)])
        let other = series("full", color: 1, [1: point(10, 1), 2: point(20, 1), 4: point(40, 1), 8: point(80, 1), 16: point(160, 1)])
        let scales = [1, 2, 4, 8, 16]
        #expect(ReportPlot.connectedRuns(of: gap, scales: scales) == [[1, 2], [8, 16]])
        #expect(ReportPlot.connectedRuns(of: other, scales: scales) == [[1, 2, 4, 8, 16]])
        let svg = try #require(ReportPlot.render(title: "w", yTitle: "t", perEntity: false, series: [gap, other]))
        #expect(svg.components(separatedBy: "\n").filter { $0.hasPrefix(#"<polyline class="line c0"#) }.count == 2)
        // Zero-valued means are not plotted on a log axis.
        let zero = series("zero", color: 0, [1: point(0), 2: point(5)])
        #expect(ReportPlot.connectedRuns(of: zero, scales: [1, 2]) == [[2]])
    }

    @Test
    func scaleZeroOnlyHasNoPlot() {
        let only = series("zero", color: 0, [0: point(5, 1)])
        #expect(ReportPlot.render(title: "w", yTitle: "t", perEntity: true, series: [only]) == nil)
        #expect(ReportPlot.render(title: "w", yTitle: "t", perEntity: true, series: []) == nil)
    }

    @Test
    func perEntityDividesByTheEntityCount() throws {
        // 4096 ns total at 4096 entities is 1 ns per entity: the y axis starts at 1 ns, not at thousands.
        let flat = series("flat", color: 0, [1024: point(1024), 4096: point(4096)])
        let perEntity = try #require(ReportPlot.render(title: "w", yTitle: "t", perEntity: true, series: [flat]))
        let total = try #require(ReportPlot.render(title: "w", yTitle: "t", perEntity: false, series: [flat]))
        #expect(perEntity.contains("t (ns), log10 scale"))
        #expect(total.contains("t (μs), log10 scale"))
        #expect(perEntity != total)
    }
}
