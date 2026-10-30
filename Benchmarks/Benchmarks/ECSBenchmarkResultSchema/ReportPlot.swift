// Hand-written SVG plots for the report (PLAN "Statistical design v3"). Adapted from the look of upstream's plotly figures: log10
// time axis with decade ticks, log2 entity-count axis, one line per series. Layers: the median line, distribution-free CI error
// bars of the median over replicates, and a light band for the typical within-run IQR (spread of the measurements, not
// uncertainty). A relative plot shows speed against the baseline with a CI ribbon and the ±delta zone. Light/dark theme inside the
// SVG. Pure string building: deterministic, no dependencies, no file access.
import Foundation

/// One cell of a series: the median over replicates of the wall-clock median per iteration, its CI and the within-run IQR, in
/// base units (ns).
struct ReportPlotPoint: Equatable {
    let median: Double
    /// Distribution-free CI of the median over replicates; nil when there are too few replicates.
    let ciLow: Double?
    let ciHigh: Double?
    /// Exact coverage of that CI.
    let coverage: Double?
    /// Median over replicates of each replicate's p25 and p75.
    let iqrLow: Double
    let iqrHigh: Double
    let replicates: Int

    var hasInterval: Bool { ciLow != nil && ciHigh != nil }
}

struct ReportPlotSeries {
    let label: String
    /// Index into the fixed palette; stable per series so all plots of a workload agree.
    let colorIndex: Int
    let isBaseline: Bool
    /// Points by entity count. A missing entity count is a gap in the line, never a zero.
    let points: [Int: ReportPlotPoint]
}

/// One cell of a relative plot: speed (baseline ÷ series) with its CI.
struct ReportRelativePoint: Equatable {
    let speed: Double
    let ciLow: Double?
    let ciHigh: Double?
    /// True for the verdicts faster and slower: drawn as a filled marker.
    let isSignificant: Bool
}

struct ReportRelativeSeries {
    let label: String
    let colorIndex: Int
    let points: [Int: ReportRelativePoint]
}

enum ReportPlot {
    static let width = 960.0
    static let height = 540.0
    static let left = 80.0
    static let right = 668.0
    static let top = 58.0
    static let bottom = 462.0

    /// Okabe-Ito based, colour-blind safe; the dark variants are lighter to keep contrast on a dark background.
    static let lightPalette = ["#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9", "#6E6E6E"]
    static let darkPalette = ["#5AB4F0", "#F28C42", "#2FD0A0", "#E69BC4", "#F2B83A", "#8FD0F5", "#B4B4B4"]

    /// Error bars use a high-contrast shade of the series hue: darker than the line in the light theme, lighter in the dark theme.
    static let lightErrorPalette = lightPalette.map { shade($0, toward: 0, amount: 0.5) }
    static let darkErrorPalette = darkPalette.map { shade($0, toward: 255, amount: 0.45) }

    /// Mixes a `#RRGGBB` colour with black (`toward` 0) or white (255) by `amount`.
    static func shade(_ hex: String, toward: Int, amount: Double) -> String {
        let value = Int(hex.dropFirst(), radix: 16) ?? 0
        let channels = [(value >> 16) & 255, (value >> 8) & 255, value & 255].map { channel in
            Int((Double(channel) + (Double(toward) - Double(channel)) * amount).rounded())
        }
        return "#" + channels.map { String(format: "%02X", $0) }.joined()
    }

    // MARK: Axis helpers (internal for tests)

    /// Decade bounds (as exponents of ten) for a log10 axis holding `lower...upper`, which must be positive.
    static func decadeRange(lower: Double, upper: Double) -> (low: Int, high: Int) {
        let low = Int(floor(log10(lower) + 1e-12))
        var high = Int(ceil(log10(upper) - 1e-12))
        if high <= low { high = low + 1 }
        return (low, high)
    }

    /// Major ticks at every power of ten and minor ticks at 2...9 times it, within the decade range.
    static func decadeTicks(_ range: (low: Int, high: Int)) -> (major: [Double], minor: [Double]) {
        let major = (range.low ... range.high).map { pow(10, Double($0)) }
        var minor: [Double] = []
        if range.high - range.low <= 12 {
            for exponent in range.low ..< range.high {
                for factor in 2 ... 9 { minor.append(Double(factor) * pow(10, Double(exponent))) }
            }
        }
        return (major, minor)
    }

    /// Plain decimal label of a decade tick: 0.001, 1, 10, 1000.
    static func decadeLabel(_ exponent: Int) -> String {
        if exponent >= 0 { return String(Int(pow(10, Double(exponent)))) }
        return exponent >= -9 ? String(format: "%.\(-exponent)f", pow(10, Double(exponent))) : "1e\(exponent)"
    }

    /// Exponents of two for the x axis: every power of two between the smallest and the largest entity count.
    static func powerOfTwoExponents(minimum: Int, maximum: Int) -> [Int] {
        let low = Int(floor(log2(Double(minimum)) + 1e-12))
        let high = Int(ceil(log2(Double(maximum)) - 1e-12))
        return Array(low ... max(low, high))
    }

    /// Exponents that get a text label: every fourth power of two and the last one, as in "1, 16, 256, 4K, 64K, 1M, 2M".
    static func labelledExponents(_ exponents: [Int]) -> Set<Int> {
        var labelled = Set(exponents.filter { $0 % 4 == 0 })
        if let last = exponents.last { labelled.insert(last) }
        return labelled
    }

    /// Compact entity-count label: 1, 512, 1K, 4K, 64K, 1M, 2M. Counts that are not whole K or M multiples stay plain.
    static func compactCount(_ value: Int) -> String {
        if value >= 1 << 20, value % (1 << 20) == 0 { return "\(value >> 20)M" }
        if value >= 1 << 10, value % (1 << 10) == 0 { return "\(value >> 10)K" }
        return String(value)
    }

    /// Bounds of the y axis as decade exponents for display-unit values: the decade of the smallest to the decade above the largest.
    static func yRange(lows: [Double], highs: [Double]) -> (low: Int, high: Int)? {
        guard let smallest = lows.filter({ $0 > 0 }).min(), let largest = highs.max(), largest > 0 else { return nil }
        return decadeRange(lower: smallest, upper: largest)
    }

    // MARK: Shared pieces

    private static func open(_ out: inout [String], title: String) {
        out.append(#"<?xml version="1.0" encoding="UTF-8"?>"#)
        out.append(#"<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \#(Int(width)) \#(Int(height))" width="\#(Int(width))" height="\#(Int(height))" role="img" aria-label="\#(escape(title))">"#)
        out.append("<title>\(escape(title))</title>")
        out.append(style())
        out.append(#"<clipPath id="plot-area"><rect x="\#(fmt(left))" y="\#(fmt(top))" width="\#(fmt(right - left))" height="\#(fmt(bottom - top))"/></clipPath>"#)
        out.append(#"<text class="title" x="\#(fmt(left))" y="30">\#(escape(title))</text>"#)
    }

    private static func frame(_ out: inout [String], xTitle: String, yTitle: String) {
        out.append(#"<rect class="frame" x="\#(fmt(left))" y="\#(fmt(top))" width="\#(fmt(right - left))" height="\#(fmt(bottom - top))"/>"#)
        out.append(#"<text class="axis-title" text-anchor="middle" x="\#(fmt((left + right) / 2))" y="\#(fmt(bottom + 46))">\#(escape(xTitle))</text>"#)
        out.append(#"<text class="axis-title" text-anchor="middle" transform="translate(22 \#(fmt((top + bottom) / 2))) rotate(-90)">\#(escape(yTitle))</text>"#)
    }

    private static func log2XAxis(_ out: inout [String], exponents: [Int], xLow: Double, xHigh: Double) {
        let labelled = labelledExponents(exponents)
        for exponent in exponents {
            let x = fmt(left + (Double(exponent) - xLow) / (xHigh - xLow) * (right - left))
            let isLabelled = labelled.contains(exponent)
            out.append(#"<line class="\#(isLabelled ? "grid" : "minor")" x1="\#(x)" x2="\#(x)" y1="\#(fmt(top))" y2="\#(fmt(bottom))"/>"#)
            out.append(#"<line class="axis" x1="\#(x)" x2="\#(x)" y1="\#(fmt(bottom))" y2="\#(fmt(bottom + (isLabelled ? 6 : 3)))"/>"#)
            if isLabelled {
                out.append(#"<text class="tick" text-anchor="middle" x="\#(x)" y="\#(fmt(bottom + 20))">\#(compactCount(1 << exponent))</text>"#)
            }
        }
    }

    /// Error bar of a CI in plot coordinates, clipped to the plot floor.
    private static func errorBar(x: Double, yLow: Double, yHigh: Double, color: String) -> String {
        // Caps at least 10 px wide (half width 5) so a tiny interval still reads as an error bar.
        let cap = 5.0
        let path = "M\(fmt(x)),\(fmt(yHigh))V\(fmt(yLow))M\(fmt(x - cap)),\(fmt(yHigh))H\(fmt(x + cap))M\(fmt(x - cap)),\(fmt(yLow))H\(fmt(x + cap))"
        return #"<path class="errbar e\#(color.dropFirst())" d="\#(path)"/>"#
    }

    private static func coverageText(_ series: [ReportPlotSeries]) -> String? {
        let coverages = Set(series.flatMap { $0.points.values.compactMap(\.coverage) }).sorted()
        guard let low = coverages.first, let high = coverages.last else { return nil }
        let format = { (value: Double) in String(format: "%.1f", value * 100) }
        return low == high ? "\(format(low))%" : "\(format(low))-\(format(high))%"
    }

    // MARK: Log-log plot

    /// The SVG document, or nil when no series has a point at a positive entity count (scale 0 cannot sit on a log axis).
    static func render(title: String, yTitle: String, perEntity: Bool, series: [ReportPlotSeries]) -> String? {
        let scales = Set(series.flatMap { $0.points.keys }).filter { $0 > 0 }.sorted()
        guard let minScale = scales.first, let maxScale = scales.last else { return nil }
        func per(_ scale: Int) -> Double { perEntity ? Double(scale) : 1 }
        let present = scales.flatMap { scale in series.compactMap { $0.points[scale] }.filter { $0.median > 0 }.map { (point: $0, scale: scale) } }
        guard !present.isEmpty else { return nil }
        let typical = present.map { $0.point.median / per($0.scale) }.sorted()[present.count / 2]
        let unit = ReportDimension.time.unit(fitting: [typical])
        func shown(_ value: Double, _ scale: Int) -> Double { value / per(scale) / unit.divisor }
        let lows = present.flatMap { entry -> [Double] in
            let point = entry.point
            return [shown(point.median, entry.scale), shown(point.ciLow ?? point.median, entry.scale), shown(point.iqrLow, entry.scale)]
        }
        let highs = present.flatMap { entry -> [Double] in
            let point = entry.point
            return [shown(point.median, entry.scale), shown(point.ciHigh ?? point.median, entry.scale), shown(point.iqrHigh, entry.scale)]
        }
        guard let yRange = yRange(lows: lows, highs: highs) else { return nil }
        let exponents = powerOfTwoExponents(minimum: minScale, maximum: maxScale)
        let xLow = Double(exponents.first!) - 0.5
        let xHigh = Double(exponents.last!) + 0.5
        let yLow = Double(yRange.low)
        let yHigh = Double(yRange.high)

        func xPosition(_ scale: Int) -> Double { left + (log2(Double(scale)) - xLow) / (xHigh - xLow) * (right - left) }
        func yPosition(_ displayed: Double) -> Double { bottom - (log10(displayed) - yLow) / (yHigh - yLow) * (bottom - top) }
        let floorValue = pow(10, yLow)

        var out: [String] = []
        open(&out, title: title)

        let ticks = decadeTicks(yRange)
        for value in ticks.minor {
            let y = fmt(yPosition(value))
            out.append(#"<line class="minor" x1="\#(fmt(left))" x2="\#(fmt(right))" y1="\#(y)" y2="\#(y)"/>"#)
        }
        for (offset, value) in ticks.major.enumerated() {
            let y = fmt(yPosition(value))
            out.append(#"<line class="grid" x1="\#(fmt(left))" x2="\#(fmt(right))" y1="\#(y)" y2="\#(y)"/>"#)
            out.append(#"<text class="tick" text-anchor="end" x="\#(fmt(left - 8))" y="\#(fmt(yPosition(value) + 4))">\#(decadeLabel(yRange.low + offset))</text>"#)
        }
        log2XAxis(&out, exponents: exponents, xLow: xLow, xHigh: xHigh)
        frame(&out, xTitle: "Entities (log2 scale)", yTitle: "\(yTitle)\(unit.label.isEmpty ? "" : " (\(unit.label))"), log10 scale")

        // Bands first, then lines, markers and error bars last, so the bars stay visible on top of the markers.
        out.append(#"<g clip-path="url(#plot-area)">"#)
        for entry in series {
            let color = "c\(entry.colorIndex % lightPalette.count)"
            for run in connectedRuns(of: entry, scales: scales) where run.count >= 2 {
                let upper = run.map { scale -> String in
                    "\(fmt(xPosition(scale))),\(fmt(yPosition(max(shown(entry.points[scale]!.iqrHigh, scale), floorValue))))"
                }
                let lower = run.reversed().map { scale -> String in
                    // Clipped to the plot floor when p25 is not above it (a log axis cannot show zero or less).
                    "\(fmt(xPosition(scale))),\(fmt(yPosition(max(shown(entry.points[scale]!.iqrLow, scale), floorValue))))"
                }
                out.append(#"<polygon class="band \#(color)" points="\#((upper + lower).joined(separator: " "))"/>"#)
            }
        }
        for entry in series {
            let color = "c\(entry.colorIndex % lightPalette.count)"
            for run in connectedRuns(of: entry, scales: scales) where run.count >= 2 {
                let points = run.map { scale -> String in
                    "\(fmt(xPosition(scale))),\(fmt(yPosition(shown(entry.points[scale]!.median, scale))))"
                }
                out.append(#"<polyline class="line \#(color)\#(entry.isBaseline ? " baseline" : "")" points="\#(points.joined(separator: " "))"/>"#)
            }
        }
        for entry in series {
            let color = "c\(entry.colorIndex % lightPalette.count)"
            for scale in scales {
                guard let point = entry.points[scale], point.median > 0 else { continue }
                out.append(marker(shape: entry.colorIndex, x: xPosition(scale), y: yPosition(shown(point.median, scale)), hollow: !point.hasInterval, color: color))
            }
        }
        for entry in series {
            let color = "c\(entry.colorIndex % lightPalette.count)"
            for scale in scales {
                guard let point = entry.points[scale], point.median > 0 else { continue }
                if let low = point.ciLow, let high = point.ciHigh {
                    let lowShown = max(shown(low, scale), floorValue)
                    out.append(errorBar(x: xPosition(scale), yLow: yPosition(lowShown), yHigh: yPosition(max(shown(high, scale), lowShown)), color: color))
                }
            }
        }
        out.append("</g>")

        legend(&out, series: series.map { ($0.label, $0.colorIndex, $0.isBaseline) }, notes: notes(series, scaleZeroOmitted: true))
        out.append("</svg>")
        return out.joined(separator: "\n") + "\n"
    }

    /// "largest CI: ±1.8%" for the biggest half-width of an interval relative to its centre; explains bars too small to see.
    static func largestIntervalText(_ halfWidths: [Double]) -> String? {
        guard let largest = halfWidths.filter(\.isFinite).max() else { return nil }
        return "largest CI: ±\(String(format: "%.1f", largest * 100))%"
    }

    private static func notes(_ series: [ReportPlotSeries], scaleZeroOmitted: Bool) -> [String] {
        var notes = ["Line: median over replicates"]
        if let coverage = coverageText(series) {
            notes.append("Error bars: CI of the median, \(coverage)")
            let halves = series.flatMap { $0.points.values }.compactMap { point -> Double? in
                guard let low = point.ciLow, let high = point.ciHigh, point.median > 0 else { return nil }
                return (high - low) / 2 / point.median
            }
            if let text = largestIntervalText(halves) { notes.append("  (\(text))") }
        } else {
            notes.append("No error bars: too few replicates for a CI")
        }
        notes.append("Light band: within-run IQR (p25 to p75),")
        notes.append("  spread of one run, not uncertainty")
        if series.contains(where: { $0.isBaseline }) { notes.append("Dashed line: baseline") }
        if series.contains(where: { entry in entry.points.values.contains { !$0.hasInterval } }), coverageText(series) != nil {
            notes.append("Hollow marker: no CI at this point")
        }
        if scaleZeroOmitted { notes.append("Entity count 0 is omitted (log axis)") }
        return notes
    }

    // MARK: Linear plot

    /// Linear total-time plot with the same layers; entity count 0 is shown. Nil when there is nothing positive to draw.
    static func renderLinear(title: String, yTitle: String, series: [ReportPlotSeries]) -> String? {
        let scales = Set(series.flatMap { $0.points.keys }).sorted()
        guard let maxScale = scales.last, maxScale > 0 else { return nil }
        let present = scales.flatMap { scale in series.compactMap { $0.points[scale] }.map { (point: $0, scale: scale) } }
        guard let top = present.map({ max($0.point.median, $0.point.ciHigh ?? 0, $0.point.iqrHigh) }).max(), top > 0 else { return nil }
        let unit = ReportDimension.time.unit(fitting: [top / 2])
        let yTicks = niceTicks(maximum: top / unit.divisor)
        let xTicks = niceTicks(maximum: Double(maxScale))
        let yMax = yTicks.last!
        let xMax = xTicks.last!
        func xPosition(_ scale: Double) -> Double { left + scale / xMax * (right - left) }
        func yPosition(_ displayed: Double) -> Double { bottom - displayed / yMax * (bottom - Self.top) }

        var out: [String] = []
        open(&out, title: title)
        for value in yTicks {
            let y = fmt(yPosition(value))
            out.append(#"<line class="\#(value == 0 ? "axis" : "grid")" x1="\#(fmt(left))" x2="\#(fmt(right))" y1="\#(y)" y2="\#(y)"/>"#)
            out.append(#"<text class="tick" text-anchor="end" x="\#(fmt(left - 8))" y="\#(fmt(yPosition(value) + 4))">\#(tickLabel(value))</text>"#)
        }
        for value in xTicks {
            let x = fmt(xPosition(value))
            out.append(#"<line class="grid" x1="\#(x)" x2="\#(x)" y1="\#(fmt(Self.top))" y2="\#(fmt(bottom))"/>"#)
            out.append(#"<text class="tick" text-anchor="middle" x="\#(x)" y="\#(fmt(bottom + 20))">\#(siCount(value))</text>"#)
        }
        frame(&out, xTitle: "Entities (linear scale)", yTitle: "\(yTitle)\(unit.label.isEmpty ? "" : " (\(unit.label))")")

        out.append(#"<g clip-path="url(#plot-area)">"#)
        for entry in series {
            let color = "c\(entry.colorIndex % lightPalette.count)"
            for run in linearRuns(of: entry, scales: scales) where run.count >= 2 {
                let upper = run.map { "\(fmt(xPosition(Double($0)))),\(fmt(yPosition(entry.points[$0]!.iqrHigh / unit.divisor)))" }
                let lower = run.reversed().map { "\(fmt(xPosition(Double($0)))),\(fmt(yPosition(entry.points[$0]!.iqrLow / unit.divisor)))" }
                out.append(#"<polygon class="band \#(color)" points="\#((upper + lower).joined(separator: " "))"/>"#)
            }
        }
        for entry in series {
            let color = "c\(entry.colorIndex % lightPalette.count)"
            for run in linearRuns(of: entry, scales: scales) where run.count >= 2 {
                let points = run.map { "\(fmt(xPosition(Double($0)))),\(fmt(yPosition(entry.points[$0]!.median / unit.divisor)))" }
                out.append(#"<polyline class="line \#(color)\#(entry.isBaseline ? " baseline" : "")" points="\#(points.joined(separator: " "))"/>"#)
            }
        }
        for entry in series {
            let color = "c\(entry.colorIndex % lightPalette.count)"
            for scale in scales {
                guard let point = entry.points[scale] else { continue }
                out.append(marker(shape: entry.colorIndex, x: xPosition(Double(scale)), y: yPosition(point.median / unit.divisor), hollow: !point.hasInterval, color: color))
            }
        }
        for entry in series {
            let color = "c\(entry.colorIndex % lightPalette.count)"
            for scale in scales {
                guard let point = entry.points[scale], let low = point.ciLow, let high = point.ciHigh else { continue }
                out.append(errorBar(x: xPosition(Double(scale)), yLow: yPosition(low / unit.divisor), yHigh: yPosition(high / unit.divisor), color: color))
            }
        }
        out.append("</g>")
        legend(&out, series: series.map { ($0.label, $0.colorIndex, $0.isBaseline) }, notes: notes(series, scaleZeroOmitted: false))
        out.append("</svg>")
        return out.joined(separator: "\n") + "\n"
    }

    /// Consecutive scales of the union axis for which the series has a point (zero allowed); any missing scale is a gap.
    static func linearRuns(of series: ReportPlotSeries, scales: [Int]) -> [[Int]] {
        var runs: [[Int]] = []
        var current: [Int] = []
        for scale in scales {
            if series.points[scale] != nil {
                current.append(scale)
            } else if !current.isEmpty {
                runs.append(current)
                current = []
            }
        }
        if !current.isEmpty { runs.append(current) }
        return runs
    }

    /// Ticks 0, step, 2 step ... covering `maximum`, with the step 1, 2 or 5 times a power of ten giving about five intervals.
    static func niceTicks(maximum: Double) -> [Double] {
        guard maximum > 0, maximum.isFinite else { return [0, 1] }
        let raw = maximum / 5
        let magnitude = pow(10, floor(log10(raw)))
        let step = [1.0, 2.0, 5.0, 10.0].map { $0 * magnitude }.first { $0 >= raw - 1e-12 * raw } ?? 10 * magnitude
        let count = Int((maximum / step - 1e-9).rounded(.up))
        return (0 ... max(count, 1)).map { Double($0) * step }
    }

    /// Plain decimal tick label without exponent: 0, 0.5, 20, 1500.
    static func tickLabel(_ value: Double) -> String {
        var text = String(format: "%.6f", value)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text
    }

    /// Entity counts on a linear axis: 0, 500K, 1M, 1.5M, or plain below 1000.
    static func siCount(_ value: Double) -> String {
        if value >= 1e6 { return tickLabel(value / 1e6) + "M" }
        if value >= 1e3 { return tickLabel(value / 1e3) + "K" }
        return tickLabel(value)
    }

    // MARK: Relative plot

    /// Ticks for a log axis spanning `low...high` (ratios): 1-2-5 multiples of powers of ten for wide spans, finer linear steps
    /// for narrow ones. Always includes values inside the range only.
    static func ratioTicks(low: Double, high: Double) -> [Double] {
        let ratio = high / low
        var candidates: [Double] = []
        if ratio >= 3 {
            // Coarse to fine families of multiples of powers of ten; the first with 4 to 9 ticks in range wins.
            let families: [[Double]] = [[1, 2, 5], [1, 1.5, 2, 3, 5, 7], [1, 1.25, 1.5, 2, 2.5, 3, 4, 5, 6, 8]]
            for family in families {
                var values: [Double] = []
                for exponent in Int(floor(log10(low))) ... Int(ceil(log10(high))) {
                    for factor in family { values.append(factor * pow(10, Double(exponent))) }
                }
                values = values.filter { $0 >= low * (1 - 1e-9) && $0 <= high * (1 + 1e-9) }
                candidates = values
                if values.count >= 4, values.count <= 9 { break }
            }
        } else {
            for step in [0.05, 0.1, 0.2, 0.25, 0.5] {
                let first = Int((low / step).rounded(.up))
                let last = Int((high / step).rounded(.down))
                guard first <= last else { continue }
                let values = (first ... last).map { Double($0) * step }.filter { $0 > 0 }
                if values.count >= 3, values.count <= 9 {
                    candidates = values
                    break
                }
            }
        }
        let ticks = candidates.filter { $0 >= low * (1 - 1e-9) && $0 <= high * (1 + 1e-9) }
        return ticks.isEmpty ? [1] : ticks
    }

    /// Speed (×) against the baseline versus entity count: log y axis, CI ribbon, shaded ±delta zone, reference line at 1x,
    /// filled markers for significant verdicts, hollow otherwise. Nil when no series has a point at a positive entity count.
    static func renderRelative(title: String, baselineLabel: String, delta: Double, series: [ReportRelativeSeries]) -> String? {
        let scales = Set(series.flatMap { $0.points.keys }).filter { $0 > 0 }.sorted()
        guard let minScale = scales.first, let maxScale = scales.last else { return nil }
        let values = series.flatMap { $0.points.filter { $0.key > 0 }.values }.flatMap { [$0.speed, $0.ciLow ?? $0.speed, $0.ciHigh ?? $0.speed] }.filter { $0 > 0 }
        guard !values.isEmpty else { return nil }
        let zoneLow = 1 / (1 + delta)
        let zoneHigh = 1 + delta
        // Pad on the log scale; the axis always includes the zone and the reference line.
        let low = min(values.min()!, zoneLow) / 1.04
        let high = max(values.max()!, zoneHigh) * 1.04
        let exponents = powerOfTwoExponents(minimum: minScale, maximum: maxScale)
        let xLow = Double(exponents.first!) - 0.5
        let xHigh = Double(exponents.last!) + 0.5
        func xPosition(_ scale: Int) -> Double { left + (log2(Double(scale)) - xLow) / (xHigh - xLow) * (right - left) }
        func yPosition(_ ratio: Double) -> Double { bottom - (log(ratio) - log(low)) / (log(high) - log(low)) * (bottom - top) }

        var out: [String] = []
        open(&out, title: title)
        for value in ratioTicks(low: low, high: high) {
            let y = fmt(yPosition(value))
            out.append(#"<line class="grid" x1="\#(fmt(left))" x2="\#(fmt(right))" y1="\#(y)" y2="\#(y)"/>"#)
            out.append(#"<text class="tick" text-anchor="end" x="\#(fmt(left - 8))" y="\#(fmt(yPosition(value) + 4))">\#(tickLabel((value * 1000).rounded() / 1000))</text>"#)
        }
        log2XAxis(&out, exponents: exponents, xLow: xLow, xHigh: xHigh)
        out.append(#"<rect class="zone" x="\#(fmt(left))" y="\#(fmt(yPosition(zoneHigh)))" width="\#(fmt(right - left))" height="\#(fmt(yPosition(zoneLow) - yPosition(zoneHigh)))"/>"#)
        out.append(#"<line class="ref" x1="\#(fmt(left))" x2="\#(fmt(right))" y1="\#(fmt(yPosition(1)))" y2="\#(fmt(yPosition(1)))"/>"#)
        frame(&out, xTitle: "Entities (log2 scale)", yTitle: "Speed vs \(baselineLabel) (×, log scale; above 1 is faster)")

        out.append(#"<g clip-path="url(#plot-area)">"#)
        for entry in series {
            let color = "c\(entry.colorIndex % lightPalette.count)"
            for run in relativeRuns(entry, scales: scales) {
                // The ribbon spans consecutive points that all have a CI.
                var current: [Int] = []
                var ribbons: [[Int]] = []
                for scale in run {
                    if let point = entry.points[scale], point.ciLow != nil, point.ciHigh != nil {
                        current.append(scale)
                    } else if !current.isEmpty {
                        ribbons.append(current)
                        current = []
                    }
                }
                if !current.isEmpty { ribbons.append(current) }
                for ribbon in ribbons where ribbon.count >= 2 {
                    let upper = ribbon.map { "\(fmt(xPosition($0))),\(fmt(yPosition(entry.points[$0]!.ciHigh!)))" }
                    let lower = ribbon.reversed().map { "\(fmt(xPosition($0))),\(fmt(yPosition(entry.points[$0]!.ciLow!)))" }
                    out.append(#"<polygon class="ribbon \#(color)" points="\#((upper + lower).joined(separator: " "))"/>"#)
                }
            }
        }
        for entry in series {
            let color = "c\(entry.colorIndex % lightPalette.count)"
            for run in relativeRuns(entry, scales: scales) where run.count >= 2 {
                let points = run.map { "\(fmt(xPosition($0))),\(fmt(yPosition(entry.points[$0]!.speed)))" }
                out.append(#"<polyline class="line \#(color)" points="\#(points.joined(separator: " "))"/>"#)
            }
        }
        for entry in series {
            let color = "c\(entry.colorIndex % lightPalette.count)"
            for scale in scales {
                guard let point = entry.points[scale], point.speed > 0 else { continue }
                out.append(marker(shape: entry.colorIndex, x: xPosition(scale), y: yPosition(point.speed), hollow: !point.isSignificant, color: color))
            }
        }
        out.append("</g>")

        let anyInterval = series.contains { $0.points.values.contains { $0.ciLow != nil } }
        let relativeNotes: [String?] = [
            "Line: speed = baseline / series (Hodges–Lehmann)",
            anyInterval ? "Ribbon: 95% CI of the speed" : "No ribbon: too few replicates for a CI",
            largestIntervalText(series.flatMap { $0.points.values }.compactMap { point -> Double? in
                guard let low = point.ciLow, let high = point.ciHigh, point.speed > 0 else { return nil }
                return (high - low) / 2 / point.speed
            }).map { "  (\($0))" },
            "Shaded zone: ±\(String(format: "%g", delta * 100))% (equivalence zone)",
            "Reference line: 1×, equal to the baseline",
            "Filled marker: significant faster or slower",
            "Hollow marker: not significant or n/a",
            "Entity count 0 is omitted (log axis)"
        ]
        let notes = series.isEmpty ? [] : relativeNotes.compactMap { $0 }
        legend(&out, series: series.map { ($0.label, $0.colorIndex, false) }, notes: notes)
        out.append("</svg>")
        return out.joined(separator: "\n") + "\n"
    }

    private static func relativeRuns(_ series: ReportRelativeSeries, scales: [Int]) -> [[Int]] {
        var runs: [[Int]] = []
        var current: [Int] = []
        for scale in scales {
            if let point = series.points[scale], point.speed > 0 {
                current.append(scale)
            } else if !current.isEmpty {
                runs.append(current)
                current = []
            }
        }
        if !current.isEmpty { runs.append(current) }
        return runs
    }

    // MARK: Pieces

    /// Consecutive scales of the union axis for which the series has a point with a positive median; any missing scale is a gap.
    static func connectedRuns(of series: ReportPlotSeries, scales: [Int]) -> [[Int]] {
        var runs: [[Int]] = []
        var current: [Int] = []
        for scale in scales {
            if let point = series.points[scale], point.median > 0 {
                current.append(scale)
            } else if !current.isEmpty {
                runs.append(current)
                current = []
            }
        }
        if !current.isEmpty { runs.append(current) }
        return runs
    }

    private static func marker(shape: Int, x: Double, y: Double, hollow: Bool, color: String) -> String {
        let attributes = #"class="marker \#(color)\#(hollow ? " hollow" : "")""#
        let r = 3.0
        switch shape % 4 {
        case 0:
            return #"<circle \#(attributes) cx="\#(fmt(x))" cy="\#(fmt(y))" r="\#(fmt(r))"/>"#
        case 1:
            return #"<rect \#(attributes) x="\#(fmt(x - r))" y="\#(fmt(y - r))" width="\#(fmt(2 * r))" height="\#(fmt(2 * r))"/>"#
        case 2:
            return #"<polygon \#(attributes) points="\#(fmt(x)),\#(fmt(y - r - 1)) \#(fmt(x + r + 1)),\#(fmt(y + r)) \#(fmt(x - r - 1)),\#(fmt(y + r))"/>"#
        default:
            return #"<polygon \#(attributes) points="\#(fmt(x)),\#(fmt(y - r - 1.5)) \#(fmt(x + r + 1.5)),\#(fmt(y)) \#(fmt(x)),\#(fmt(y + r + 1.5)) \#(fmt(x - r - 1.5)),\#(fmt(y))"/>"#
        }
    }

    private static func legend(_ out: inout [String], series: [(label: String, colorIndex: Int, isBaseline: Bool)], notes: [String]) {
        let x = right + 24
        var y = top + 8
        out.append(#"<text class="legend-title" x="\#(fmt(x))" y="\#(fmt(y))">Series</text>"#)
        y += 20
        for entry in series {
            let color = "c\(entry.colorIndex % lightPalette.count)"
            out.append(#"<line class="line \#(color)\#(entry.isBaseline ? " baseline" : "")" x1="\#(fmt(x))" x2="\#(fmt(x + 26))" y1="\#(fmt(y - 4))" y2="\#(fmt(y - 4))"/>"#)
            out.append(marker(shape: entry.colorIndex, x: x + 13, y: y - 4, hollow: false, color: color))
            let name = entry.label + (entry.isBaseline ? " (baseline)" : "")
            out.append(#"<text class="legend" x="\#(fmt(x + 34))" y="\#(fmt(y))">\#(escape(truncated(name, 34)))<title>\#(escape(name))</title></text>"#)
            y += 22
        }
        y += 8
        for note in notes {
            out.append(#"<text class="note" x="\#(fmt(x))" y="\#(fmt(y))" xml:space="preserve">\#(escape(note))</text>"#)
            y += 17
        }
    }

    private static func style() -> String {
        var css = [
            "text{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;fill:#1f2328}",
            ".title{font-size:17px;font-weight:600}.axis-title{font-size:13px}.tick{font-size:12px}.legend{font-size:12px}.legend-title{font-size:13px;font-weight:600}.note{font-size:11px;fill:#59636e}",
            ".grid{stroke:#c3cad2;stroke-width:1}.minor{stroke:#e6e9ed;stroke-width:1}.axis{stroke:#59636e;stroke-width:1}.frame{fill:none;stroke:#59636e;stroke-width:1}",
            ".line{fill:none;stroke:currentColor;stroke-width:2;stroke-linejoin:round}.baseline{stroke-dasharray:7 4}",
            ".band{fill:currentColor;fill-opacity:.16;stroke:currentColor;stroke-opacity:.4;stroke-width:1;stroke-linejoin:round}.ribbon{fill:currentColor;fill-opacity:.2;stroke:none}.errbar{fill:none;stroke:currentColor;stroke-width:2.4;stroke-linecap:butt}",
            ".zone{fill:#59636e;fill-opacity:.14;stroke:none}.ref{stroke:#1f2328;stroke-width:1;stroke-dasharray:2 3}",
            ".marker{fill:currentColor;stroke:currentColor;stroke-width:1.4}.marker.hollow{fill:none}"
        ]
        css += lightPalette.enumerated().map { ".c\($0.offset){color:\($0.element)}" }
        css += lightErrorPalette.enumerated().map { ".errbar.e\($0.offset){color:\($0.element)}" }
        var dark = [
            "text{fill:#e6edf3}.note{fill:#9198a1}",
            ".grid{stroke:#4a525c}.minor{stroke:#2d333b}.axis,.frame{stroke:#9198a1}.zone{fill:#9198a1}.ref{stroke:#e6edf3}"
        ]
        dark += darkPalette.enumerated().map { ".c\($0.offset){color:\($0.element)}" }
        dark += darkErrorPalette.enumerated().map { ".errbar.e\($0.offset){color:\($0.element)}" }
        return "<style>\n" + css.joined(separator: "\n") + "\n@media (prefers-color-scheme: dark){\n" + dark.joined(separator: "\n") + "\n}\n</style>"
    }

    // MARK: Text

    static func truncated(_ text: String, _ limit: Int) -> String {
        text.count <= limit ? text : String(text.prefix(limit - 1)) + "…"
    }

    /// XML text and attribute escaping, including the characters XML 1.0 forbids (dropped).
    static func escape(_ text: String) -> String {
        var out = ""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            case "'": out += "&apos;"
            case "\u{9}", "\u{A}", "\u{D}": out += " "
            default:
                if scalar.value >= 0x20, !(0xD800 ... 0xDFFF).contains(scalar.value), scalar.value != 0xFFFE, scalar.value != 0xFFFF {
                    out.unicodeScalars.append(scalar)
                }
            }
        }
        return out
    }

    /// Two decimals, trailing zeros trimmed, no exponent and no locale.
    static func fmt(_ value: Double) -> String {
        var text = String(format: "%.2f", value)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text == "-0" || text.isEmpty ? "0" : text
    }
}
