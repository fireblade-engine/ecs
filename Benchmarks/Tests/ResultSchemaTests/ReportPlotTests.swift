import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

@Suite
struct ReportPlotTests {
    private func series(_ label: String, color: Int, baseline: Bool = false, _ points: [Int: ReportPlotPoint]) -> ReportPlotSeries {
        ReportPlotSeries(label: label, colorIndex: color, isBaseline: baseline, points: points)
    }

    private func point(_ median: Double, ci: (Double, Double)? = nil, iqr: (Double, Double)? = nil, k: Int = 10) -> ReportPlotPoint {
        ReportPlotPoint(median: median, ciLow: ci?.0, ciHigh: ci?.1, coverage: ci == nil ? nil : 0.979, iqrLow: iqr?.0 ?? median * 0.9, iqrHigh: iqr?.1 ?? median * 1.1, replicates: k)
    }

    private var sample: [ReportPlotSeries] {
        [
            series("1.4.3 (class, default)", color: 0, baseline: true, [1: point(1000, ci: (950, 1050)), 16: point(2000, ci: (1900, 2100)), 256: point(8000, ci: (7500, 8600)), 4096: point(100_000, ci: (95000, 108_000))]),
            series("main (value, archetype)", color: 1, [1: point(500, ci: (400, 650)), 16: point(900), 256: point(3000, ci: (2800, 3100)), 4096: point(40000, ci: (39000, 41000))])
        ]
    }

    private var relative: [ReportRelativeSeries] {
        [
            ReportRelativeSeries(label: "main (value, archetype)", colorIndex: 1, points: [
                1: ReportRelativePoint(speed: 0.7, ciLow: 0.6, ciHigh: 0.8, isSignificant: true),
                16: ReportRelativePoint(speed: 1.01, ciLow: 0.98, ciHigh: 1.03, isSignificant: false),
                256: ReportRelativePoint(speed: 2.2, ciLow: 2.0, ciHigh: 2.4, isSignificant: true),
                4096: ReportRelativePoint(speed: 2.5, ciLow: nil, ciHigh: nil, isSignificant: false)
            ])
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
        #expect(parsed.elements["polygon"] ?? 0 >= 2, "one IQR band per series")
        #expect(parsed.elements["path"] == 7, "an error bar per point that has a CI")
        #expect(svg.contains(#"viewBox="0 0 960 540""#))
        #expect(svg.contains("@media (prefers-color-scheme: dark)"))
        #expect(svg.contains("Time per entity (ns), log10 scale") || svg.contains("Time per entity (μs), log10 scale"))
        #expect(svg.contains("Entities (log2 scale)"))
        #expect(svg.contains("Dashed line: baseline") && svg.contains("(baseline)"))
        #expect(svg.contains("Error bars: CI of the median, 97.9%"))
        #expect(svg.contains("within-run IQR") && svg.contains("not uncertainty"))
        #expect(svg.contains("Hollow marker: no CI at this point"))
    }

    @Test
    func missingIntervalsAreMarkedNotDrawn() throws {
        let plain = series("k1", color: 0, [1: point(100, k: 1), 2: point(200, k: 1), 4: point(400, k: 1)])
        let svg = try #require(ReportPlot.render(title: "w", yTitle: "t", perEntity: false, series: [plain]))
        _ = parse(svg)
        #expect(!svg.contains("<path class=\"errbar"))
        #expect(svg.contains("No error bars: too few replicates for a CI"))
        let lines = svg.components(separatedBy: "\n")
        #expect(lines.filter { $0.hasPrefix("<circle") && $0.contains("hollow") }.count == 3)
        #expect(lines.contains { $0.hasPrefix("<polygon class=\"band") }, "the within-run IQR band is drawn with one replicate")
    }

    @Test
    func relativePlotHasZoneReferenceRibbonAndMarkerFill() throws {
        let svg = try #require(ReportPlot.renderRelative(title: "w", baselineLabel: "1.4.3", delta: 0.05, series: relative))
        let parsed = parse(svg)
        #expect(parsed.elements["svg"] == 1 && parsed.elements["polyline"] == 1)
        let lines = svg.components(separatedBy: "\n")
        #expect(lines.filter { $0.hasPrefix(#"<rect class="zone""#) }.count == 1)
        #expect(lines.filter { $0.hasPrefix(#"<line class="ref""#) }.count == 1)
        // Markers of series 1 are squares: filled for significant points (1, 256), hollow otherwise (16, 4096).
        let squares = lines.filter { $0.hasPrefix(#"<rect class="marker c1"#) }
        #expect(squares.count == 5, "four plotted points and the legend marker")
        #expect(squares.filter { $0.contains("hollow") }.count == 2)
        // The ribbon spans the first three points only; the fourth has no CI.
        #expect(lines.filter { $0.hasPrefix(#"<polygon class="ribbon"#) }.count == 1)
        #expect(svg.contains("Shaded zone: +-5% (equivalence zone)") && svg.contains("Reference line: 1x"))
        #expect(svg.contains("Speed vs 1.4.3"))
        #expect(!svg.contains("nan") && !svg.contains("inf"))
        #expect(ReportPlot.renderRelative(title: "w", baselineLabel: "b", delta: 0.05, series: []) == nil)
    }

    @Test
    func linearPlotShowsScaleZeroAndStartsAtZero() throws {
        let zero = series("z", color: 0, [0: point(50, k: 3), 1000: point(1000, ci: (900, 1100)), 2000: point(2100, ci: (2000, 2200))])
        let svg = try #require(ReportPlot.renderLinear(title: "w", yTitle: "t", series: [zero]))
        let parsed = parse(svg)
        #expect(parsed.elements["polyline"] == 1)
        #expect(svg.contains("Entities (linear scale)") && svg.contains("t (μs)") || svg.contains("t (ns)"))
        #expect(ReportPlot.niceTicks(maximum: 7.3) == [0, 2, 4, 6, 8])
        #expect(ReportPlot.niceTicks(maximum: 65536).last == 80000)
        #expect(ReportPlot.siCount(1_500_000) == "1.5M" && ReportPlot.siCount(20000) == "20K" && ReportPlot.siCount(0) == "0")
        #expect(ReportPlot.renderLinear(title: "w", yTitle: "t", series: []) == nil)
    }

    @Test
    func ratioTicksStayInsideTheRange() {
        for (low, high) in [(0.55, 3.0), (0.9, 1.2), (0.05, 30.0), (0.3, 1.4)] {
            let ticks = ReportPlot.ratioTicks(low: low, high: high)
            #expect(!ticks.isEmpty)
            #expect(ticks.allSatisfy { $0 >= low * 0.999 && $0 <= high * 1.001 }, "\(low)...\(high): \(ticks)")
            #expect(ticks == ticks.sorted())
        }
        #expect(ReportPlot.ratioTicks(low: 0.55, high: 3.0).count >= 4)
    }

    @Test
    func textIsEscapedForXML() throws {
        let nasty = series("a <b> & \"c\" 'd' \u{1}", color: 0, [1: point(10, ci: (9, 11)), 2: point(20, ci: (19, 21))])
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
        #expect(ReportPlot.renderRelative(title: "w", baselineLabel: "b", delta: 0.05, series: relative) == ReportPlot.renderRelative(title: "w", baselineLabel: "b", delta: 0.05, series: relative))
        #expect(ReportPlot.renderLinear(title: "w", yTitle: "t", series: sample) == ReportPlot.renderLinear(title: "w", yTitle: "t", series: sample))
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
        // p25 is zero: the lower band edge sits on the floor (y = 462), never above or below, and nothing is NaN.
        let wide = series("w", color: 0, [1: point(100, iqr: (0, 150)), 2: point(100, iqr: (0, 150))])
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
    func missingScalesAreGapsNotZeros() throws {
        let gap = series("gap", color: 0, [1: point(10), 2: point(20), 8: point(80), 16: point(160)])
        let other = series("full", color: 1, [1: point(10), 2: point(20), 4: point(40), 8: point(80), 16: point(160)])
        let scales = [1, 2, 4, 8, 16]
        #expect(ReportPlot.connectedRuns(of: gap, scales: scales) == [[1, 2], [8, 16]])
        #expect(ReportPlot.connectedRuns(of: other, scales: scales) == [[1, 2, 4, 8, 16]])
        let svg = try #require(ReportPlot.render(title: "w", yTitle: "t", perEntity: false, series: [gap, other]))
        #expect(svg.components(separatedBy: "\n").filter { $0.hasPrefix(#"<polyline class="line c0"#) }.count == 2)
        // Zero-valued means are not plotted on a log axis.
        let zero = series("zero", color: 0, [1: point(0, iqr: (0, 0)), 2: point(5)])
        #expect(ReportPlot.connectedRuns(of: zero, scales: [1, 2]) == [[2]])
    }

    @Test
    func scaleZeroOnlyHasNoPlot() {
        let only = series("zero", color: 0, [0: point(5)])
        #expect(ReportPlot.render(title: "w", yTitle: "t", perEntity: true, series: [only]) == nil)
        #expect(ReportPlot.render(title: "w", yTitle: "t", perEntity: true, series: []) == nil)
    }

    @Test
    func perEntityDividesByTheEntityCount() throws {
        // 4096 ns total at 4096 entities is 1 ns per entity: the y axis starts at 1 ns, not at thousands.
        let flat = series("flat", color: 0, [1024: point(1024, iqr: (1024, 1024)), 4096: point(4096, iqr: (4096, 4096))])
        let perEntity = try #require(ReportPlot.render(title: "w", yTitle: "t", perEntity: true, series: [flat]))
        let total = try #require(ReportPlot.render(title: "w", yTitle: "t", perEntity: false, series: [flat]))
        #expect(perEntity.contains("t (ns), log10 scale"))
        #expect(total.contains("t (μs), log10 scale"))
        #expect(perEntity != total)
    }
}
