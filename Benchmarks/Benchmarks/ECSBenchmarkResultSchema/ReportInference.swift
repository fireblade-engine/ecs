// Per-cell aggregation over replicates and the report-wide inference of PLAN "Statistical design v3": replicate medians,
// median CI, Hodges-Lehmann speed with exact CI, exact Mann-Whitney p, Benjamini-Hochberg q over every wall-clock comparison,
// verdicts, and the Kendall drift diagnostic. All numerics live in ReportStatistics; this file only arranges inputs and outputs.
import Benchmark
import Foundation

/// One series at one cell, summarised over its replicates. The replicate is the unit of analysis; iterations are never pooled.
struct ReportCell {
    let dimension: ReportDimension
    let prefersLarger: Bool
    /// Replicates with at least one measurement.
    let replicates: Int
    /// Replicate medians ordered by replicate index, and the round each ran in.
    let replicateMedians: [Double]
    let replicateRounds: [Int]
    /// Median of the replicate medians; the centre of the series.
    let median: Double
    /// Distribution-free CI of the median over replicates; nil with too few replicates for 95%.
    let interval: ReportStatistics.MedianCI?
    /// Within-run IQR: median over replicates of each replicate's p25 and p75. Spread of the measurements, not uncertainty.
    let iqrLow: Double
    let iqrHigh: Double
    /// Median over replicates of each replicate's mean (descriptive).
    let mean: Double
    /// Median over replicates of each replicate's measurement count.
    let iterations: Double
    /// Median over replicates of each replicate's value at `Statistics.defaultPercentilesToCalculate`.
    let percentiles: [Double]

    /// nil when no replicate has a measurement for this cell.
    init?(_ samples: [ReportReplicateSample]) {
        guard let first = samples.first(where: { !$0.sample.isEmpty }) else { return nil }
        let usable = samples.filter { !$0.sample.isEmpty && $0.sample.isCompatible(with: first.sample) }
        func centre(_ values: [Double]) -> Double { (try? ReportStatistics.median(values)) ?? 0 }
        dimension = first.sample.dimension
        prefersLarger = first.sample.prefersLarger
        replicates = usable.count
        replicateMedians = usable.map(\.sample.median)
        replicateRounds = usable.map(\.round)
        median = centre(replicateMedians)
        interval = (try? ReportStatistics.medianConfidenceInterval(replicateMedians)) ?? nil
        iqrLow = centre(usable.map(\.sample.firstQuartile))
        iqrHigh = centre(usable.map(\.sample.thirdQuartile))
        mean = centre(usable.map(\.sample.mean))
        iterations = centre(usable.map { Double($0.sample.measurementCount) })
        percentiles = Statistics.defaultPercentilesToCalculate.indices.map { index in centre(usable.map { $0.sample.percentiles[index] }) }
    }

    func isCompatible(with other: ReportCell) -> Bool {
        dimension == other.dimension && prefersLarger == other.prefersLarger
    }

    func percentile(_ p: Int) -> Double {
        percentiles[Statistics.defaultPercentilesToCalculate.firstIndex(of: Double(p)) ?? 0]
    }
}

struct ReportComparisonKey: Hashable {
    let series: Int
    let key: ReportKey
}

/// Wall-clock comparison of one non-baseline series with its paired baseline series at one scale.
struct ReportComparison {
    var speed: Double?
    var ciLow: Double?
    var ciHigh: Double?
    var coverage: Double?
    /// (1 / speed - 1) * 100.
    var change: Double?
    /// Exact two-sided Mann-Whitney p; nil with fewer than two replicates on a side.
    var p: Double?
    /// Benjamini-Hochberg adjusted p across every wall-clock comparison in the report.
    var q: Double?
    var verdict: ReportStatistics.Verdict?
    var baselineReplicates = 0
    var seriesReplicates = 0
    /// Why there is no comparison at all.
    var reason: String?
}

/// Kendall trend of one series and cell over the rounds, when it has at least three replicates.
struct ReportDriftCell {
    let series: Int
    let key: ReportKey
    let tau: Double?
    let p: Double
    var q: Double?
    let replicates: Int
    let isApproximate: Bool

    var isFlagged: Bool { q.map { $0 < ReportStatistics.significanceLevel } ?? false }
}

enum ReportInference {
    static func analyse(_ model: ReportModel) -> (comparisons: [ReportComparisonKey: ReportComparison], drift: [ReportDriftCell]) {
        guard let wall = model.wallClockMetric else { return ([:], []) }
        let wallKeys = model.keys.filter { $0.metric == wall }

        // Comparisons, in a fixed order (series index, then the sorted keys).
        var order: [ReportComparisonKey] = []
        var comparisons: [ReportComparisonKey: ReportComparison] = [:]
        for index in model.series.indices where !model.isBaseline(index) {
            for key in wallKeys {
                let id = ReportComparisonKey(series: index, key: key)
                order.append(id)
                comparisons[id] = compare(model, index, key)
            }
        }
        let adjusted = ReportStatistics.benjaminiHochberg(order.map { comparisons[$0]?.p })
        for (offset, id) in order.enumerated() {
            guard var item = comparisons[id] else { continue }
            item.q = adjusted[offset]
            if item.speed != nil, item.reason == nil {
                item.verdict = ReportStatistics.classify(
                    ciLow: item.ciLow, ciHigh: item.ciHigh, q: item.q,
                    baselineReplicates: item.baselineReplicates, seriesReplicates: item.seriesReplicates
                )
            }
            comparisons[id] = item
        }

        // Drift: a trend of replicate medians over the rounds, per series and cell.
        var drift: [ReportDriftCell] = []
        for index in model.series.indices {
            for key in wallKeys {
                guard let cell = model.series[index].cells[key], cell.replicates >= 3 else { continue }
                let ordered = zip(cell.replicateRounds, cell.replicateMedians).enumerated()
                    .sorted { ($0.element.0, $0.offset) < ($1.element.0, $1.offset) }.map(\.element.1)
                guard let result = try? ReportStatistics.kendallTrend(ordered) else { continue }
                drift.append(ReportDriftCell(series: index, key: key, tau: result.tau, p: result.p, q: nil, replicates: cell.replicates, isApproximate: result.isApproximate))
            }
        }
        let driftQ = ReportStatistics.benjaminiHochberg(drift.map { Optional($0.p) })
        for index in drift.indices { drift[index].q = driftQ[index] }
        return (comparisons, drift)
    }

    private static func compare(_ model: ReportModel, _ index: Int, _ key: ReportKey) -> ReportComparison {
        var result = ReportComparison()
        guard let own = model.series[index].cells[key] else {
            result.reason = model.series[index].replicates[key] == nil ? "not measured for this series" : "no measurements"
            return result
        }
        guard let pair = model.pairedSeries(for: index) else {
            result.reason = "the baseline has several backends and none matches"
            return result
        }
        guard let base = model.series[pair].cells[key] else {
            result.reason = model.series[pair].replicates[key] == nil ? "baseline: not measured" : "baseline: no measurements"
            return result
        }
        guard own.isCompatible(with: base) else {
            result.reason = "incompatible units or polarity"
            return result
        }
        result.baselineReplicates = base.replicates
        result.seriesReplicates = own.replicates
        guard own.replicateMedians.allSatisfy({ $0 > 0 }), base.replicateMedians.allSatisfy({ $0 > 0 }) else {
            result.reason = "zero median: the ratio is undefined"
            return result
        }
        guard let estimate = try? ReportStatistics.hodgesLehmannSpeed(baseline: base.replicateMedians, series: own.replicateMedians) else {
            result.reason = "no estimate"
            return result
        }
        result.speed = estimate.speed
        result.change = estimate.changePercent
        // With a single replicate on a side the speed is a ratio of two numbers, not an estimate with uncertainty.
        guard min(own.replicates, base.replicates) >= 2 else { return result }
        result.ciLow = estimate.ciLow
        result.ciHigh = estimate.ciHigh
        result.coverage = estimate.coverage
        result.p = (try? ReportStatistics.mannWhitney(base.replicateMedians, own.replicateMedians))?.p
        return result
    }
}
