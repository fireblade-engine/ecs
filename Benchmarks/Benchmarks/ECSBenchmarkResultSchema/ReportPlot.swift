// Hand-written SVG line plots for the report (PLAN "Report v2 design"). Adapted from the look of upstream's plotly figures:
// log10 time axis with decade ticks, log2 entity-count axis, one line per series. Added here: a shaded +-1 sd band, hollow
// markers for single-sample points, and a light/dark theme inside the SVG. Pure string building: deterministic, no
// dependencies, no file access.
import Foundation

/// One measured point of a series: the wall-clock mean per iteration and its dispersion, in base units (ns).
struct ReportPlotPoint: Equatable {
    let mean: Double
    let standardDeviation: Double
    /// Number of measurements behind mean and deviation.
    let samples: Int
}

struct ReportPlotSeries {
    let label: String
    /// Index into the fixed palette; stable per series so both plots of a workload agree.
    let colorIndex: Int
    let isBaseline: Bool
    /// Points by entity count. A missing entity count is a gap in the line, never a zero.
    let points: [Int: ReportPlotPoint]
}

enum ReportPlot {
    static let width = 960.0
    static let height = 540.0
    static let left = 80.0
    static let right = 668.0
    static let top = 58.0
    static let bottom = 462.0
    /// A point with fewer measurements than this is flagged in the legend.
    static let lowSampleThreshold = 5

    /// Okabe-Ito based, colour-blind safe; the dark variants are lighter to keep contrast on a dark background.
    static let lightPalette = ["#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9", "#6E6E6E"]
    static let darkPalette = ["#5AB4F0", "#F28C42", "#2FD0A0", "#E69BC4", "#F2B83A", "#8FD0F5", "#B4B4B4"]

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

    /// Bounds of the y axis in display units. The floor may sit one decade below the smallest mean to keep a positive lower
    /// band edge visible; everything below it is clipped.
    static func yRange(values: [ReportPlotPoint], divisor: Double, perEntityDivisors: [Double]) -> (low: Int, high: Int)? {
        var means: [Double] = []
        var lowers: [Double] = []
        var uppers: [Double] = []
        for (point, scale) in zip(values, perEntityDivisors) where point.mean > 0 {
            let mean = point.mean / scale / divisor
            let spread = point.samples >= 2 ? point.standardDeviation / scale / divisor : 0
            means.append(mean)
            uppers.append(mean + spread)
            if mean - spread > 0 { lowers.append(mean - spread) }
        }
        guard let smallest = means.min(), let largest = uppers.max() else { return nil }
        let candidate = min(smallest, max(lowers.min() ?? smallest, smallest / 10))
        return decadeRange(lower: candidate, upper: largest)
    }

    // MARK: Rendering

    /// The SVG document, or nil when no series has a point at a positive entity count (scale 0 cannot sit on a log axis).
    static func render(title: String, yTitle: String, perEntity: Bool, series: [ReportPlotSeries]) -> String? {
        let scales = Set(series.flatMap { $0.points.keys }).filter { $0 > 0 }.sorted()
        guard let minScale = scales.first, let maxScale = scales.last else { return nil }
        let flat = scales.flatMap { scale in series.compactMap { $0.points[scale] }.map { (point: $0, scale: perEntity ? Double(scale) : 1.0) } }
        let medianMean = flat.map { $0.point.mean / $0.scale }.filter { $0 > 0 }.sorted()
        guard !medianMean.isEmpty else { return nil }
        let unit = ReportDimension.time.unit(fitting: [medianMean[medianMean.count / 2]])
        guard let yRange = yRange(values: flat.map(\.point), divisor: unit.divisor, perEntityDivisors: flat.map(\.scale)) else { return nil }
        let exponents = powerOfTwoExponents(minimum: minScale, maximum: maxScale)
        let xLow = Double(exponents.first!) - 0.5
        let xHigh = Double(exponents.last!) + 0.5
        let yLow = Double(yRange.low)
        let yHigh = Double(yRange.high)

        func xPosition(_ scale: Int) -> Double { left + (log2(Double(scale)) - xLow) / (xHigh - xLow) * (right - left) }
        func xPosition(exponent: Int) -> Double { left + (Double(exponent) - xLow) / (xHigh - xLow) * (right - left) }
        func yPosition(_ displayed: Double) -> Double { bottom - (log10(displayed) - yLow) / (yHigh - yLow) * (bottom - top) }
        let floorValue = pow(10, yLow)

        var out: [String] = []
        out.append(#"<?xml version="1.0" encoding="UTF-8"?>"#)
        out.append(#"<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \#(Int(width)) \#(Int(height))" width="\#(Int(width))" height="\#(Int(height))" role="img" aria-label="\#(escape(title))">"#)
        out.append("<title>\(escape(title))</title>")
        out.append(style())
        out.append(#"<clipPath id="plot-area"><rect x="\#(fmt(left))" y="\#(fmt(top))" width="\#(fmt(right - left))" height="\#(fmt(bottom - top))"/></clipPath>"#)
        out.append(#"<text class="title" x="\#(fmt(left))" y="30">\#(escape(title))</text>"#)

        // Grid and tick labels.
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
        let labelled = labelledExponents(exponents)
        for exponent in exponents {
            let x = fmt(xPosition(exponent: exponent))
            let isLabelled = labelled.contains(exponent)
            out.append(#"<line class="\#(isLabelled ? "grid" : "minor")" x1="\#(x)" x2="\#(x)" y1="\#(fmt(top))" y2="\#(fmt(bottom))"/>"#)
            out.append(#"<line class="axis" x1="\#(x)" x2="\#(x)" y1="\#(fmt(bottom))" y2="\#(fmt(bottom + (isLabelled ? 6 : 3)))"/>"#)
            if isLabelled {
                out.append(#"<text class="tick" text-anchor="middle" x="\#(x)" y="\#(fmt(bottom + 20))">\#(compactCount(1 << exponent))</text>"#)
            }
        }
        out.append(#"<rect class="frame" x="\#(fmt(left))" y="\#(fmt(top))" width="\#(fmt(right - left))" height="\#(fmt(bottom - top))"/>"#)
        out.append(#"<text class="axis-title" text-anchor="middle" x="\#(fmt((left + right) / 2))" y="\#(fmt(bottom + 46))">Entities (log2 scale)</text>"#)
        let yLabel = "\(yTitle)\(unit.label.isEmpty ? "" : " (\(unit.label))"), log10 scale"
        out.append(#"<text class="axis-title" text-anchor="middle" transform="translate(22 \#(fmt((top + bottom) / 2))) rotate(-90)">\#(escape(yLabel))</text>"#)

        // Bands first, then lines, then markers, so the lines stay readable on top of every band.
        out.append(#"<g clip-path="url(#plot-area)">"#)
        for entry in series {
            let runs = connectedRuns(of: entry, scales: scales)
            let color = "c\(entry.colorIndex % lightPalette.count)"
            for run in runs {
                for band in bandRuns(run, of: entry) where band.count >= 2 {
                    let upper = band.map { scale -> String in
                        let (mean, spread) = displayed(entry.points[scale]!, scale: scale, perEntity: perEntity, divisor: unit.divisor)
                        return "\(fmt(xPosition(scale))),\(fmt(yPosition(mean + spread)))"
                    }
                    let lower = band.reversed().map { scale -> String in
                        let (mean, spread) = displayed(entry.points[scale]!, scale: scale, perEntity: perEntity, divisor: unit.divisor)
                        // Clipped to the plot floor when mean - sd is not above it (a log axis cannot show zero or less).
                        return "\(fmt(xPosition(scale))),\(fmt(yPosition(max(mean - spread, floorValue))))"
                    }
                    out.append(#"<polygon class="band \#(color)" points="\#((upper + lower).joined(separator: " "))"/>"#)
                }
            }
        }
        for entry in series {
            let color = "c\(entry.colorIndex % lightPalette.count)"
            for run in connectedRuns(of: entry, scales: scales) where run.count >= 2 {
                let points = run.map { scale -> String in
                    let (mean, _) = displayed(entry.points[scale]!, scale: scale, perEntity: perEntity, divisor: unit.divisor)
                    return "\(fmt(xPosition(scale))),\(fmt(yPosition(mean)))"
                }
                out.append(#"<polyline class="line \#(color)\#(entry.isBaseline ? " baseline" : "")" points="\#(points.joined(separator: " "))"/>"#)
            }
        }
        for entry in series {
            let color = "c\(entry.colorIndex % lightPalette.count)"
            for scale in scales {
                guard let point = entry.points[scale], point.mean > 0 else { continue }
                let (mean, _) = displayed(point, scale: scale, perEntity: perEntity, divisor: unit.divisor)
                out.append(marker(shape: entry.colorIndex, x: xPosition(scale), y: yPosition(mean), hollow: point.samples < 2, color: color))
            }
        }
        out.append("</g>")

        legend(&out, series: series)
        out.append("</svg>")
        return out.joined(separator: "\n") + "\n"
    }

    // MARK: Pieces

    /// Mean and deviation of a point in display units, divided by the entity count for the per-entity plot.
    private static func displayed(_ point: ReportPlotPoint, scale: Int, perEntity: Bool, divisor: Double) -> (mean: Double, spread: Double) {
        let per = perEntity ? Double(scale) : 1
        return (point.mean / per / divisor, point.samples >= 2 ? point.standardDeviation / per / divisor : 0)
    }

    /// Consecutive scales of the union axis for which the series has a point with a positive mean; any missing scale is a gap.
    static func connectedRuns(of series: ReportPlotSeries, scales: [Int]) -> [[Int]] {
        var runs: [[Int]] = []
        var current: [Int] = []
        for scale in scales {
            if let point = series.points[scale], point.mean > 0 {
                current.append(scale)
            } else if !current.isEmpty {
                runs.append(current)
                current = []
            }
        }
        if !current.isEmpty { runs.append(current) }
        return runs
    }

    /// Splits a run where a point has fewer than two samples: such a point has no deviation, hence no band.
    static func bandRuns(_ run: [Int], of series: ReportPlotSeries) -> [[Int]] {
        var runs: [[Int]] = []
        var current: [Int] = []
        for scale in run {
            if (series.points[scale]?.samples ?? 0) >= 2 {
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
        let r = 4.0
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

    private static func legend(_ out: inout [String], series: [ReportPlotSeries]) {
        let x = right + 24
        var y = top + 8
        out.append(#"<text class="legend-title" x="\#(fmt(x))" y="\#(fmt(y))">Series</text>"#)
        y += 20
        var anyLowSample = false
        var anyHollow = false
        for entry in series {
            let color = "c\(entry.colorIndex % lightPalette.count)"
            let low = entry.points.values.contains { $0.samples < lowSampleThreshold }
            anyLowSample = anyLowSample || low
            anyHollow = anyHollow || entry.points.values.contains { $0.samples < 2 }
            out.append(#"<line class="line \#(color)\#(entry.isBaseline ? " baseline" : "")" x1="\#(fmt(x))" x2="\#(fmt(x + 26))" y1="\#(fmt(y - 4))" y2="\#(fmt(y - 4))"/>"#)
            out.append(marker(shape: entry.colorIndex, x: x + 13, y: y - 4, hollow: false, color: color))
            let name = entry.label + (entry.isBaseline ? " (baseline)" : "") + (low ? " †" : "")
            out.append(#"<text class="legend" x="\#(fmt(x + 34))" y="\#(fmt(y))">\#(escape(truncated(name, 34)))<title>\#(escape(name))</title></text>"#)
            y += 22
        }
        y += 8
        var notes = ["Line: mean per iteration", "Shaded band: mean ± 1 sd", "Dashed line: baseline", "Entity count 0 is omitted (log axis)"]
        if anyHollow { notes.append("Hollow marker: 1 sample, no band") }
        if anyLowSample { notes.append("† some points have fewer than \(lowSampleThreshold) samples") }
        for note in notes {
            out.append(#"<text class="note" x="\#(fmt(x))" y="\#(fmt(y))">\#(escape(note))</text>"#)
            y += 17
        }
    }

    private static func style() -> String {
        var css = [
            "text{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;fill:#1f2328}",
            ".title{font-size:17px;font-weight:600}.axis-title{font-size:13px}.tick{font-size:12px}.legend{font-size:12px}.legend-title{font-size:13px;font-weight:600}.note{font-size:11px;fill:#59636e}",
            ".grid{stroke:#c3cad2;stroke-width:1}.minor{stroke:#e6e9ed;stroke-width:1}.axis{stroke:#59636e;stroke-width:1}.frame{fill:none;stroke:#59636e;stroke-width:1}",
            ".line{fill:none;stroke:currentColor;stroke-width:2;stroke-linejoin:round}.baseline{stroke-dasharray:7 4}",
            ".band{fill:currentColor;fill-opacity:.16;stroke:none}.marker{fill:currentColor;stroke:currentColor;stroke-width:1.6}.marker.hollow{fill:none}"
        ]
        css += lightPalette.enumerated().map { ".c\($0.offset){color:\($0.element)}" }
        var dark = [
            "text{fill:#e6edf3}.note{fill:#9198a1}",
            ".grid{stroke:#4a525c}.minor{stroke:#2d333b}.axis,.frame{stroke:#9198a1}"
        ]
        dark += darkPalette.enumerated().map { ".c\($0.offset){color:\($0.element)}" }
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
