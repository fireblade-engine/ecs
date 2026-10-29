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
    /// Five significant digits, trailing zeros trimmed, no exponent and no locale.
    static func number(_ value: Double) -> String {
        guard value != 0, value.isFinite else { return value.isFinite ? "0" : "unavailable" }
        let magnitude = Int(floor(log10(abs(value))))
        let decimals = min(9, max(0, 4 - magnitude))
        var text = String(format: "%.\(decimals)f", value)
        if text.contains(".") {
            while text.hasSuffix("0") {
                text.removeLast()
            }
            if text.hasSuffix(".") {
                text.removeLast()
            }
        }
        return text == "-0" ? "0" : text
    }

    static func signed(_ value: Double) -> String {
        let text = number(value)
        return value > 0 && !text.hasPrefix("-") ? "+\(text)" : text
    }

    static func quantity(_ value: Double, _ unit: ReportUnit) -> String {
        let text = number(value / unit.divisor)
        return unit.label.isEmpty ? text : "\(text) \(unit.label)"
    }
}
