// Units, number formatting and statistic extraction for the comparison report. Everything here reads native `Statistics`
// through non-mutating paths: percentiles come from a copy of the histogram, never from `percentiles()` or `units()`, which
// write the shared caches described in PLAN Step 2.
import Benchmark
import Foundation

/// What a metric measures. Values of different dimensions are never converted into each other.
enum ReportDimension: String {
    case time, bytes, count, rate

    init(_ metric: BenchmarkMetric) {
        switch metric {
        case .cpuUser, .cpuSystem, .cpuTotal, .wallClock:
            self = .time
        case .throughput:
            self = .rate
        case .peakMemoryResident, .peakMemoryResidentDelta, .peakMemoryVirtual, .mallocBytesCount, .allocatedResidentMemory,
             .memoryLeakedBytes, .readBytesLogical, .writeBytesLogical, .readBytesPhysical, .writeBytesPhysical:
            self = .bytes
        default:
            self = .count
        }
    }

    /// Display units, smallest first. `divisor` converts from the base unit (ns, B, 1, ops/s).
    var units: [ReportUnit] {
        switch self {
        case .time: [ReportUnit("ns", 1), ReportUnit("μs", 1e3), ReportUnit("ms", 1e6), ReportUnit("s", 1e9)]
        case .bytes: [ReportUnit("B", 1), ReportUnit("kB", 1e3), ReportUnit("MB", 1e6), ReportUnit("GB", 1e9)]
        case .count: [ReportUnit("", 1), ReportUnit("K", 1e3), ReportUnit("M", 1e6), ReportUnit("G", 1e9)]
        case .rate: [ReportUnit("ops/s", 1), ReportUnit("Kops/s", 1e3), ReportUnit("Mops/s", 1e6), ReportUnit("Gops/s", 1e9)]
        }
    }

    /// Largest unit not exceeding the smallest nonzero magnitude, so no shown value drops below 1 except zero itself.
    func unit(fitting values: [Double]) -> ReportUnit {
        let smallest = values.map(abs).filter { $0 > 0 }.min()
        guard let smallest else { return units[0] }
        return units.last { $0.divisor <= smallest } ?? units[0]
    }
}

struct ReportUnit {
    let label: String
    let divisor: Double
    init(_ label: String, _ divisor: Double) {
        self.label = label
        self.divisor = divisor
    }
}

/// One statistic row of the report tables.
enum ReportStatistic: Hashable {
    case count
    case mean
    case standardDeviation
    case percentile(Int)

    static let tableRows: [ReportStatistic] = [.count, .mean, .standardDeviation] + Statistics.defaultPercentilesToCalculate.map { .percentile(Int($0)) }

    var label: String {
        switch self {
        case .count: "measurements"
        case .mean: "mean"
        case .standardDeviation: "std dev"
        case let .percentile(p): "p\(p)"
        }
    }
}

/// The statistics of one native result, converted to base units (ns, B, plain counts, ops/s) per iteration.
struct ReportSample {
    let dimension: ReportDimension
    let prefersLarger: Bool
    let measurementCount: Int
    let mean: Double
    let standardDeviation: Double
    /// Values at `Statistics.defaultPercentilesToCalculate`, in that order.
    let percentiles: [Double]

    init(_ result: BenchmarkResult) {
        let metric = result.metric
        dimension = ReportDimension(metric)
        let statistics = result.statistics
        prefersLarger = statistics.prefersLarger
        measurementCount = statistics.measurementCount

        // Raw measurements of scaling-factor metrics cover `scalingFactor` iterations; throughput is stored per scaled
        // iteration (BenchmarkResult.convertScalingFactor). Normalising to one iteration makes differently scaled results comparable.
        let scaling = Double(result.scalingFactor.rawValue)
        let factor: Double = if metric == .throughput {
            scaling
        } else if metric.useScalingFactor {
            1 / scaling
        } else {
            1
        }

        // `histogram` is a value type: this copy is read-only and leaves the statistics caches untouched.
        let histogram = statistics.histogram
        // A metric that recorded nothing has no mean or percentiles; the report prints it as unavailable.
        guard measurementCount > 0 else {
            mean = 0
            standardDeviation = 0
            percentiles = Statistics.defaultPercentilesToCalculate.map { _ in 0 }
            return
        }
        mean = histogram.mean * factor
        standardDeviation = histogram.stdDeviation * factor
        percentiles = Statistics.defaultPercentilesToCalculate.map { percentile in
            // Same polarity convention as Statistics.percentiles(for:).
            let p = statistics.prefersLarger ? 100.0 - percentile : percentile
            return Double(histogram.valueAtPercentile(p)) * factor
        }
    }

    /// True when the metric has no measurements; only `measurementCount` is meaningful then.
    var isEmpty: Bool {
        measurementCount == 0
    }

    /// Compatible samples share the dimension and the polarity.
    func isCompatible(with other: ReportSample) -> Bool {
        dimension == other.dimension && prefersLarger == other.prefersLarger
    }

    func value(_ statistic: ReportStatistic) -> Double {
        switch statistic {
        case .count: Double(measurementCount)
        case .mean: mean
        case .standardDeviation: standardDeviation
        case let .percentile(p): percentiles[Statistics.defaultPercentilesToCalculate.firstIndex(of: Double(p)) ?? 0]
        }
    }
}

enum ReportFormat {
    /// Significant digits the pinned Benchmark package measures: `Statistics` builds its HdrHistogram with
    /// `SignificantDigits.three` by default (Statistics.init, `numberOfSignificantDigits`), and the result writer keeps that
    /// default. Means and deviations are computed from histogram buckets, so digits beyond the third are quantization
    /// artefacts, not measurement. The report therefore never shows more than this many significant digits for a measured
    /// value; a result file recorded with more digits would need this constant raised (the schema does not store it).
    static let significantDigits = 3

    /// Decimals that show the smallest nonzero magnitude of a column (in the column's unit) with `significantDigits`.
    /// Larger values of the column get fewer decimals in `text`, so none exceeds the digit budget. `cap` limits the decimals
    /// where the inputs of a derived value were measured more coarsely.
    static func columnDecimals(_ values: [Double], divisor: Double, cap: Int? = nil) -> Int {
        let smallest = values.map { abs($0) / divisor }.filter { $0 > 0 && $0.isFinite }.min()
        guard let smallest else { return 0 }
        let decimals = max(0, significantDigits - 1 - Int(floor(log10(smallest) + 1e-12)))
        return min(decimals, cap ?? decimals, 9)
    }

    /// One value of a column: rounded to `significantDigits` and shown with at most `columnDecimals` decimals. No exponent, no
    /// locale, trailing zeros are kept only where the column's decimals require them.
    static func text(_ value: Double, divisor: Double = 1, columnDecimals: Int, signed: Bool = false) -> String {
        guard value.isFinite else { return "unavailable" }
        let scaled = value / divisor
        guard scaled != 0 else { return "0" }
        func decimals(for magnitude: Double) -> Int {
            min(columnDecimals, max(0, significantDigits - 1 - Int(floor(log10(abs(magnitude)) + 1e-12))))
        }
        var places = decimals(for: scaled)
        var rounded = (scaled * pow(10, Double(places))).rounded() / pow(10, Double(places))
        // Rounding can carry into the next magnitude (9.996 -> 10.00); drop the extra digit.
        if rounded != 0, decimals(for: rounded) < places {
            places = decimals(for: rounded)
            rounded = (scaled * pow(10, Double(places))).rounded() / pow(10, Double(places))
        }
        guard rounded != 0 else { return "0" }
        let body = String(format: "%.\(places)f", rounded)
        return signed && rounded > 0 ? "+\(body)" : body
    }

    /// Thousands separators for entity counts: 65,536.
    static func grouped(_ value: Int) -> String {
        let digits = Array(String(abs(value)))
        var out = ""
        for (offset, digit) in digits.enumerated() {
            if offset > 0, (digits.count - offset) % 3 == 0 { out += "," }
            out.append(digit)
        }
        return value < 0 ? "-" + out : out
    }

    /// p-value with its relation: `p=0.012`, or `p<0.001` below three decimals.
    static func probability(_ p: Double) -> String {
        p < 0.001 ? "p<0.001" : String(format: "p=%.3f", p)
    }
}
