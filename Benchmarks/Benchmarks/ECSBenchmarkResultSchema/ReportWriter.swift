// Markdown, HTML table and SVG rendering of a `ReportModel` into the files of a report directory (PLAN "Report v2 design" and
// "Statistical design v3"). Statistics come from `ReportInference`; this file only formats them.
import Benchmark
import Foundation

struct ReportWriter {
    let model: ReportModel
    let title: String
    private var lines: [String] = []

    /// Entity counts up to this value go into the small table, the rest into the large one (as upstream splits its tables).
    static let smallLimit = 1024
    static let summaryScales = [1024, 65536]

    struct Plots {
        var perEntity: String?
        var total: String?
        var relative: String?
        var linear: String?
    }

    init(model: ReportModel, title: String) {
        self.model = model
        self.title = title
    }

    /// REPORT.md first, then `workloads/<identity>.md`, then `img/<identity>-*.svg`, each group sorted.
    mutating func render() -> [RenderedFile] {
        let identities = Array(Set(model.keys.map(\.identity))).sorted()
        var names: [String: String] = [:]
        var used = Set<String>()
        for identity in identities {
            var name = Self.fileName(identity)
            while !used.insert(name).inserted { name += "_" }
            names[identity] = name
        }
        var plots: [String: Plots] = [:]
        for identity in identities {
            plots[identity] = Plots(
                perEntity: logPlot(identity, perEntity: true),
                total: logPlot(identity, perEntity: false),
                relative: relativePlot(identity),
                linear: linearPlot(identity)
            )
        }

        var files: [RenderedFile] = []
        files.append(RenderedFile(path: "REPORT.md", contents: overview(identities, names, plots)))
        for identity in identities {
            files.append(RenderedFile(path: "workloads/\(names[identity]!).md", contents: workloadPage(identity, names[identity]!, plots[identity]!)))
        }
        for identity in identities {
            let name = names[identity]!
            let plot = plots[identity]!
            for (suffix, svg) in [("per-entity", plot.perEntity), ("total", plot.total), ("relative", plot.relative), ("total-linear", plot.linear)] {
                if let svg { files.append(RenderedFile(path: "img/\(name)-\(suffix).svg", contents: svg)) }
            }
        }
        return files
    }

    /// File-system safe version of a workload identity.
    static func fileName(_ identity: String) -> String {
        String(identity.unicodeScalars.map { scalar in
            (scalar.isASCII && (CharacterSet.alphanumerics.contains(scalar) || "-_.".unicodeScalars.contains(scalar))) ? Character(scalar) : "_"
        })
    }

    // MARK: REPORT.md

    private mutating func overview(_ identities: [String], _ names: [String: String], _ plots: [String: Plots]) -> String {
        lines = []
        lines.append("# \(Self.text(title))")
        lines.append("")
        lines.append("Jump to: [How to read this report](#\(ReportGlossary.guideAnchor)) · [Glossary](#\(ReportGlossary.anchor)) · [Methods](#methods)")
        lines.append("")
        header()
        warnings()
        summary(identities, names)
        lines += ReportGuide(model: model).lines()
        lines.append("## Workloads")
        lines.append("")
        for identity in identities {
            lines.append("### `\(Self.code(identity))`")
            lines.append("")
            let name = names[identity]!
            lines.append("[All metrics, means, percentiles and the linear plot](workloads/\(name).md)")
            lines.append("")
            figures(identity, name, plots[identity]!, prefix: "")
            wallClockTables(identity, headingLevel: 4)
        }
        lines += ReportGlossary.lines()
        methods()
        provenance()
        pairing()
        parityNotes()
        return finish()
    }

    private mutating func finish() -> String {
        defer { lines = [] }
        return lines.joined(separator: "\n") + "\n"
    }

    private var replicateSummary: String {
        let counts = model.groups.map { "\(Self.text($0.label)): \($0.fileIndices.count) of \($0.expectedReplicates)" }
        return counts.joined(separator: "; ")
    }

    private mutating func header() {
        let baseline = model.groups[model.baselineGroup]
        lines.append("- Baseline: `\(Self.code(baseline.label))` (\(Self.text(baseline.sha)))")
        lines.append("- Inputs: \(model.files.count) result files, \(model.groups.count) refs, \(model.series.count) series (ref, component model, backend)")
        lines.append("- Replicates per ref: \(replicateSummary)")
        let filters = Set(model.files.map(\.suite.filter)).sorted()
        lines.append("- Selection filter: " + filters.map { "`\(Self.code($0))`" }.joined(separator: ", "))
        lines.append("- Every replicate is an independent process; the replicate is the unit of analysis. `median` is the median over replicates of each replicate's median per iteration. `CI low` and `CI high` bound the 95% distribution-free confidence interval of that median (exact coverage in the methods section). `replicates` is the number of replicates behind the value, `iterations` the median number of measurements per replicate (time-based sampling, so it differs between series by design).")
        lines.append("- Non-baseline series add, for wall clock only, `speed (×)` = baseline ÷ series (above 1 is faster) with its exact 95% CI, `change (%)` = (1 ÷ speed − 1) × 100, `q` (Benjamini–Hochberg adjusted p of an exact Mann–Whitney test across every wall-clock comparison of this report) and a `verdict`: `faster`/`slower` need q < \(Self.percent(ReportStatistics.significanceLevel)) and a CI entirely outside the ±\(Self.percent(ReportStatistics.defaultDelta)) zone, `equivalent` needs the CI entirely inside it. Other metrics are descriptive only.")
        lines.append("- Every unit is in its column header and applies to the whole column of that table. Values keep at most the \(ReportFormat.significantDigits) significant digits the package measured. Anything missing or not comparable is `unavailable` (hover for the reason), never zero. `n/a (k replicates)` means the statistic needs more replicates.")
        lines.append("- Plots show the wall-clock median per iteration on log-log axes with CI error bars and a light within-run IQR band (spread of the measurements inside a run, not uncertainty); entity count 0 cannot sit on a log axis and appears in the tables only.")
        lines.append("")
    }

    private mutating func warnings() {
        guard !model.warnings.isEmpty else { return }
        lines.append("## Warnings")
        lines.append("")
        for warning in model.warnings {
            lines.append("- \(Self.text(warning))")
        }
        lines.append("")
    }

    static func percent(_ value: Double) -> String {
        String(format: "%g%%", value * 100)
    }

    // MARK: Cell resolution

    /// The series' cell for `key`, or the reason it cannot be used.
    private func resolve(_ series: Int, _ key: ReportKey) -> (cell: ReportCell?, reason: String?) {
        guard let cell = model.series[series].cells[key] else {
            return (nil, model.series[series].replicates[key] == nil ? "not measured for this series" : "no measurements")
        }
        guard let reference = referenceCell(key), cell.isCompatible(with: reference) else { return (nil, "incompatible units or polarity") }
        return (cell, nil)
    }

    /// The cell every other cell of this row must be compatible with: the baseline input's, else the first available.
    private func referenceCell(_ key: ReportKey) -> ReportCell? {
        model.series.first { $0.groupIndex == model.baselineGroup && $0.cells[key] != nil }?.cells[key]
            ?? model.series.compactMap { $0.cells[key] }.first
    }

    private func dimension(_ identity: String, _ metric: String, _ scales: [Int]) -> ReportDimension {
        for scale in scales {
            if let reference = referenceCell(ReportKey(identity: identity, scale: scale, metric: metric)) { return reference.dimension }
        }
        return .count
    }

    private func groupLabel(_ series: Int) -> String {
        let group = model.groups[model.series[series].groupIndex]
        return "\(group.label) (\(group.componentModel))" + (model.series[series].groupIndex == model.baselineGroup ? " - baseline" : "")
    }

    // MARK: Summary

    private mutating func summary(_ identities: [String], _ names: [String: String]) {
        guard let wall = model.wallClockMetric else { return }
        lines.append("## Summary")
        lines.append("")
        lines.append("Wall clock, `speed (×)` against the paired baseline series (above 1 is faster) with its exact 95% CI and the verdict (δ = \(Self.percent(ReportStatistics.defaultDelta)), q across all comparisons). The last block of each series is the largest entity count for which the comparison exists (its count in the `entities` column).")
        lines.append("")
        var blocks: [HTMLColumnBlock] = []
        for index in model.series.indices where !model.isBaseline(index) {
            for scale in Self.summaryScales {
                let items = identities.map { model.comparisons[ReportComparisonKey(series: index, key: ReportKey(identity: $0, scale: scale, metric: wall))] }
                blocks.append(summaryBlock(index, subgroup: "\(model.series[index].backend) @ \(ReportFormat.grouped(scale))", items: items, entities: nil))
            }
            var largest: [ReportComparison?] = []
            var scales: [Int?] = []
            for identity in identities {
                let available = Set(model.keys.filter { $0.identity == identity && $0.metric == wall }.map(\.scale)).sorted(by: >)
                let scale = available.first { model.comparisons[ReportComparisonKey(series: index, key: ReportKey(identity: identity, scale: $0, metric: wall))]?.speed != nil }
                scales.append(scale)
                largest.append(scale.flatMap { model.comparisons[ReportComparisonKey(series: index, key: ReportKey(identity: identity, scale: $0, metric: wall))] })
            }
            blocks.append(summaryBlock(index, subgroup: "\(model.series[index].backend) @ largest", items: largest, entities: scales))
        }
        guard !blocks.isEmpty else { return }
        lines += HTMLTable(rowHeader: "Workload", rowLabels: identities, rowHrefs: identities.map { "workloads/\(names[$0]!).md" }, blocks: blocks).render()
        lines.append("")
    }

    private func summaryBlock(_ series: Int, subgroup: String, items: [ReportComparison?], entities: [Int?]?) -> HTMLColumnBlock {
        let columns = comparisonColumns(items, includeChange: false, includeQ: false)
        var headers = columns.headers
        var cells = columns.cells
        if let entities {
            headers.insert("entities", at: 0)
            cells.insert(entities.map { $0.map { HTMLCell(ReportFormat.grouped($0)) } ?? .unavailable("no entity count with a comparison") }, at: 0)
        }
        return HTMLColumnBlock(group: groupLabel(series), subgroup: subgroup, headers: headers, columns: cells)
    }

    // MARK: Comparison columns

    static func replicatesText(_ count: Int) -> String {
        "n/a (\(count) replicate\(count == 1 ? "" : "s"))"
    }

    static func verdictText(_ verdict: ReportStatistics.Verdict) -> String {
        switch verdict {
        case .faster: "faster"
        case .slower: "slower"
        case .equivalent: "equivalent"
        case .inconclusive: "inconclusive"
        case let .notAvailable(replicates): replicatesText(replicates)
        }
    }

    /// `speed (×)`, `CI low (×)`, `CI high (×)`, optionally `change (%)` and `q`, then `verdict`, for one row per item.
    private func comparisonColumns(_ items: [ReportComparison?], includeChange: Bool, includeQ: Bool) -> (headers: [String], cells: [[HTMLCell]]) {
        func unavailable(_ item: ReportComparison?) -> HTMLCell {
            .unavailable(item?.reason ?? "no comparison")
        }
        /// Cell for a statistic that needs at least two replicates per side, or a CI-capable sample size.
        func missing(_ item: ReportComparison, what: String) -> HTMLCell {
            let fewest = min(item.baselineReplicates, item.seriesReplicates)
            if fewest < 2 { return HTMLCell(Self.replicatesText(fewest), title: "\(what) needs at least two replicates on each side") }
            return HTMLCell("n/a", title: "\(what) needs more replicates: \(item.baselineReplicates) against \(item.seriesReplicates) are too few for a 95% interval")
        }
        func ratioColumn(_ value: (ReportComparison) -> Double?, signed: Bool = false, _ fallback: (ReportComparison) -> HTMLCell) -> [HTMLCell] {
            let decimals = ReportFormat.columnDecimals(items.compactMap { $0.flatMap(value) }, divisor: 1)
            return items.map { item in
                guard let item, item.reason == nil, item.speed != nil else { return unavailable(item) }
                guard let number = value(item) else { return fallback(item) }
                return HTMLCell(ReportFormat.text(number, columnDecimals: decimals, signed: signed))
            }
        }
        var headers = ["speed (×)", "CI low (×)", "CI high (×)"]
        var cells = [
            ratioColumn(\.speed) { _ in .unavailable("no estimate") },
            ratioColumn(\.ciLow) { missing($0, what: "the confidence interval") },
            ratioColumn(\.ciHigh) { missing($0, what: "the confidence interval") }
        ]
        if includeChange {
            headers.append("change (%)")
            cells.append(ratioColumn(\.change, signed: true) { _ in .unavailable("no estimate") })
        }
        if includeQ {
            headers.append("q")
            cells.append(items.map { item in
                guard let item, item.reason == nil, item.speed != nil else { return unavailable(item) }
                guard let q = item.q else { return missing(item, what: "the test") }
                return HTMLCell(ReportFormat.qValue(q))
            })
        }
        headers.append("verdict")
        cells.append(items.map { item in
            guard let item, item.reason == nil, item.speed != nil else { return unavailable(item) }
            return HTMLCell(item.verdict.map(Self.verdictText) ?? "unavailable")
        })
        return (headers, cells)
    }

    // MARK: Workload sections

    private mutating func figures(_ identity: String, _ name: String, _ plots: Plots, prefix: String) {
        let entries: [(String?, String, String)] = [
            (plots.perEntity, "per-entity", "wall-clock cost per entity"),
            (plots.total, "total", "wall-clock time per iteration"),
            (plots.linear, "total-linear", "wall-clock time per iteration, linear axes"),
            (plots.relative, "relative", "speed against the baseline")
        ]
        for (svg, suffix, caption) in entries where svg != nil {
            lines.append("![\(Self.text(identity)): \(caption)](\(prefix)img/\(name)-\(suffix).svg)")
            lines.append("")
        }
    }

    private mutating func wallClockTables(_ identity: String, headingLevel: Int) {
        guard let wall = model.wallClockMetric else { return }
        let scales = Set(model.keys.filter { $0.identity == identity && $0.metric == wall }.map(\.scale)).sorted()
        statisticsTables(identity, wall, scales, headingLevel: headingLevel, detail: false)
    }

    private mutating func statisticsTables(_ identity: String, _ metric: String, _ scales: [Int], headingLevel: Int, detail: Bool) {
        let hashes = String(repeating: "#", count: headingLevel)
        let small = scales.filter { $0 <= Self.smallLimit }
        let large = scales.filter { $0 > Self.smallLimit }
        for (label, part) in [("Entity counts up to \(ReportFormat.grouped(Self.smallLimit))", small), ("Entity counts above \(ReportFormat.grouped(Self.smallLimit))", large)] where !part.isEmpty {
            lines.append("\(hashes) \(Self.text(metric)): \(label)")
            lines.append("")
            lines += statisticsTable(identity, metric, part, detail: detail).render()
            lines.append("")
        }
    }

    private mutating func workloadPage(_ identity: String, _ name: String, _ plots: Plots) -> String {
        lines = []
        lines.append("# `\(Self.code(identity))`")
        lines.append("")
        lines.append("[Back to the report](../REPORT.md) · [Glossary](../REPORT.md#\(ReportGlossary.anchor)). \(Self.text(title)).")
        lines.append("")
        var parity: [String: [String]] = [:]
        for group in model.groups {
            for workload in model.files[group.fileIndices[0]].workloads where workload.identity == identity {
                let text = workload.parityKind == "equivalent" ? "equivalent" : "adapted: \(workload.parityReason ?? "")"
                parity[text, default: []].append(group.label)
            }
        }
        for text in parity.keys.sorted() {
            lines.append("- Parity (\(Self.text(parity[text]!.joined(separator: ", ")))): \(Self.text(text))")
        }
        if !parity.isEmpty { lines.append("") }
        lines.append("`median`, `CI low`, `CI high`, `replicates` and `iterations` are defined in the [report](../REPORT.md). `mean` is the median over replicates of each replicate's mean per iteration; it is descriptive (upstream parity), not an inference input. Percentile columns are the median over replicates of each replicate's percentile.")
        lines.append("")
        figures(identity, name, plots, prefix: "../")
        let metrics = model.keys.filter { $0.identity == identity }.map(\.metric).uniqued()
        for metric in metrics {
            let scales = Set(model.keys.filter { $0.identity == identity && $0.metric == metric }.map(\.scale)).sorted()
            let polarity = referenceCell(ReportKey(identity: identity, scale: scales[0], metric: metric))?.prefersLarger == true ? "larger is better" : "smaller is better"
            lines.append("## \(Self.text(metric)) (\(polarity))")
            lines.append("")
            statisticsTables(identity, metric, scales, headingLevel: 3, detail: true)
            let small = scales.filter { $0 <= Self.smallLimit }
            let large = scales.filter { $0 > Self.smallLimit }
            for (label, part) in [("up to \(ReportFormat.grouped(Self.smallLimit))", small), ("above \(ReportFormat.grouped(Self.smallLimit))", large)] where !part.isEmpty {
                lines.append("### Percentiles, entity counts \(label)")
                lines.append("")
                lines += percentileTable(identity, metric, part).render()
                lines.append("")
            }
        }
        return finish()
    }

    // MARK: Table construction

    private func header(_ name: String, _ unit: ReportUnit) -> String {
        unit.label.isEmpty ? name : "\(name) (\(unit.label))"
    }

    /// One column of quantities in a single unit with consistent decimals. `fallback` makes the cell of a missing value. `unit`
    /// overrides the unit choice (the CI columns use the median column's unit). Whole numbers of the base unit (integer
    /// nanoseconds, bytes, counts) show no decimals: the package measures nothing finer.
    private func quantityColumn(_ name: String, _ values: [Double?], _ dimension: ReportDimension, unit forced: ReportUnit? = nil, _ fallback: (Int) -> HTMLCell) -> (header: String, unit: ReportUnit, cells: [HTMLCell]) {
        let present = values.compactMap { $0 }
        let unit = forced ?? dimension.unit(fitting: present)
        var decimals = ReportFormat.columnDecimals(present, divisor: unit.divisor)
        if unit.divisor == 1, present.allSatisfy({ $0 == $0.rounded() }) { decimals = 0 }
        return (header(name, unit), unit, values.indices.map { row in
            values[row].map { HTMLCell(ReportFormat.text($0, divisor: unit.divisor, columnDecimals: decimals)) } ?? fallback(row)
        })
    }

    /// Per series: median, CI low, CI high, [mean], replicates, iterations; for non-baseline series and wall clock also the
    /// comparison columns.
    private func statisticsTable(_ identity: String, _ metric: String, _ scales: [Int], detail: Bool) -> HTMLTable {
        let dimension = dimension(identity, metric, scales)
        let isWall = metric == model.wallClockMetric
        var blocks: [HTMLColumnBlock] = []
        for index in model.series.indices {
            let resolved = scales.map { resolve(index, ReportKey(identity: identity, scale: $0, metric: metric)) }
            let cells = resolved.map(\.cell)
            func unavailable(_ row: Int) -> HTMLCell { .unavailable(resolved[row].reason ?? "unavailable") }
            func intervalFallback(_ row: Int) -> HTMLCell {
                guard let cell = cells[row] else { return unavailable(row) }
                if cell.replicates < 2 { return HTMLCell(Self.replicatesText(cell.replicates), title: "an interval of the median needs replicates") }
                return HTMLCell("n/a", title: "\(cell.replicates) replicates are too few for a 95% interval of the median")
            }
            var headers: [String] = []
            var columns: [[HTMLCell]] = []
            func add(_ column: (header: String, unit: ReportUnit, cells: [HTMLCell])) {
                headers.append(column.header)
                columns.append(column.cells)
            }
            let median = quantityColumn("median", cells.map { $0?.median }, dimension, unavailable)
            add(median)
            add(quantityColumn("CI low", cells.map { $0?.interval?.low }, dimension, unit: median.unit, intervalFallback))
            add(quantityColumn("CI high", cells.map { $0?.interval?.high }, dimension, unit: median.unit, intervalFallback))
            if detail {
                add(quantityColumn("mean", cells.map { $0?.mean }, dimension, unavailable))
            }
            headers.append("replicates")
            columns.append(cells.indices.map { row in cells[row].map { HTMLCell(String($0.replicates)) } ?? unavailable(row) })
            headers.append("iterations")
            columns.append(cells.indices.map { row in cells[row].map { HTMLCell(ReportFormat.grouped(Int($0.iterations.rounded()))) } ?? unavailable(row) })
            if isWall, !model.isBaseline(index) {
                let items: [ReportComparison?] = scales.map { model.comparisons[ReportComparisonKey(series: index, key: ReportKey(identity: identity, scale: $0, metric: metric))] }
                let comparison = comparisonColumns(items, includeChange: true, includeQ: true)
                headers += comparison.headers
                columns += comparison.cells
            }
            blocks.append(HTMLColumnBlock(group: groupLabel(index), subgroup: model.series[index].backend, headers: headers, columns: columns))
        }
        return HTMLTable(rowHeader: "Entities", rowLabels: scales.map(ReportFormat.grouped), blocks: blocks)
    }

    private func percentileTable(_ identity: String, _ metric: String, _ scales: [Int]) -> HTMLTable {
        let dimension = dimension(identity, metric, scales)
        let percentiles = Statistics.defaultPercentilesToCalculate.map { Int($0) }
        var blocks: [HTMLColumnBlock] = []
        for index in model.series.indices {
            var block = HTMLColumnBlock(group: groupLabel(index), subgroup: model.series[index].backend, headers: [], columns: [])
            let resolved = scales.map { resolve(index, ReportKey(identity: identity, scale: $0, metric: metric)) }
            for percentile in percentiles {
                let column = quantityColumn("p\(percentile)", resolved.map { $0.cell?.percentile(percentile) }, dimension) { row in
                    .unavailable(resolved[row].reason ?? "unavailable")
                }
                block.headers.append(column.header)
                block.columns.append(column.cells)
            }
            blocks.append(block)
        }
        return HTMLTable(rowHeader: "Entities", rowLabels: scales.map(ReportFormat.grouped), blocks: blocks)
    }

    // MARK: Plots

    private func plotSeries(_ identity: String) -> [ReportPlotSeries] {
        guard let wall = model.wallClockMetric else { return [] }
        var result: [ReportPlotSeries] = []
        for (index, entry) in model.series.enumerated() {
            var points: [Int: ReportPlotPoint] = [:]
            for key in model.keys where key.identity == identity && key.metric == wall {
                if let cell = resolve(index, key).cell {
                    points[key.scale] = ReportPlotPoint(
                        median: cell.median, ciLow: cell.interval?.low, ciHigh: cell.interval?.high, coverage: cell.interval?.coverage,
                        iqrLow: cell.iqrLow, iqrHigh: cell.iqrHigh, replicates: cell.replicates
                    )
                }
            }
            result.append(ReportPlotSeries(label: entry.label, colorIndex: index, isBaseline: model.isBaseline(index), points: points))
        }
        return result
    }

    private func logPlot(_ identity: String, perEntity: Bool) -> String? {
        ReportPlot.render(
            title: perEntity ? "\(identity): wall-clock cost per entity" : "\(identity): wall-clock time per iteration",
            yTitle: perEntity ? "Median time per entity" : "Median time per iteration",
            perEntity: perEntity,
            series: plotSeries(identity)
        )
    }

    private func linearPlot(_ identity: String) -> String? {
        ReportPlot.renderLinear(
            title: "\(identity): wall-clock time per iteration, linear axes",
            yTitle: "Median time per iteration",
            series: plotSeries(identity)
        )
    }

    private func relativePlot(_ identity: String) -> String? {
        guard let wall = model.wallClockMetric else { return nil }
        var result: [ReportRelativeSeries] = []
        for index in model.series.indices where !model.isBaseline(index) {
            var points: [Int: ReportRelativePoint] = [:]
            for key in model.keys where key.identity == identity && key.metric == wall {
                guard let item = model.comparisons[ReportComparisonKey(series: index, key: key)], let speed = item.speed else { continue }
                let significant = item.verdict == .faster || item.verdict == .slower
                points[key.scale] = ReportRelativePoint(speed: speed, ciLow: item.ciLow, ciHigh: item.ciHigh, isSignificant: significant)
            }
            result.append(ReportRelativeSeries(label: model.series[index].label, colorIndex: index, points: points))
        }
        let baseline = model.groups[model.baselineGroup].label
        return ReportPlot.renderRelative(title: "\(identity): speed against \(baseline)", baselineLabel: baseline, delta: ReportStatistics.defaultDelta, series: result)
    }

    // MARK: Methods

    private mutating func methods() {
        lines.append("## Methods")
        lines.append("")
        let replicated = model.files.contains { $0.run.replicate != nil }
        if replicated {
            let seeds = Set(model.files.compactMap { $0.run.replicate?.seed }).sorted()
            let batches = Set(model.files.compactMap(\.run.batchId)).sorted()
            let counts = Set(model.groups.map(\.expectedReplicates)).sorted()
            lines.append("- **Protocol:** each ref is built once and run k = \(counts.map(String.init).joined(separator: ", ")) times as independent processes (\(replicateSummary)). Replicates run in interleaved rounds: each round runs every ref once, in an order shuffled by the recorded seed (seed \(seeds.map(String.init).joined(separator: ", ")); batch \(batches.isEmpty ? "none recorded" : batches.map { "`\(Self.code($0))`" }.joined(separator: ", "))). The suite settings are identical for all refs.")
        } else {
            lines.append("- **Protocol:** the inputs carry no replicate provenance, so each counts as replicate 1 of 1 (one process per ref). Only medians and within-run spread are reported; intervals, tests and verdicts need replicates.")
        }
        lines.append("- **Per replicate:** median, p25, p75 and mean of the iterations, read from the stored histogram. **Per series and cell:** the centre is the median of the replicate medians; the error bar is the distribution-free order-statistic confidence interval of that median, [x(l), x(k−l+1)] with the largest l such that P(Binomial(k, ½) ≤ l−1) ≤ 0.025 (omitted and marked when k < 6); the light band is the median over replicates of each replicate's p25 and p75.")
        let coverage = coverageSummary()
        lines.append("- **Coverage:** \(coverage.median) \(coverage.speed)")
        lines.append("- **Effect:** `speed (×)` = baseline ÷ series, estimated by Hodges–Lehmann on the log replicate medians (exp of the median of all pairwise log differences) with the exact Mann–Whitney-based confidence interval of those differences. `change (%)` = (1 ÷ speed − 1) × 100.")
        lines.append("- **Test:** exact two-sided Mann–Whitney U on the replicate medians (permutation distribution conditional on ties). **Multiplicity:** Benjamini–Hochberg across all \(testCount) wall-clock comparisons with a p-value in this report; `q` is the adjusted value and the threshold is q < \(Self.percent(ReportStatistics.significanceLevel)).")
        lines.append("- **Verdict:** δ = \(Self.percent(ReportStatistics.defaultDelta)), symmetric on the log scale, so the equivalence zone is [1/\(String(format: "%g", 1 + ReportStatistics.defaultDelta)), \(String(format: "%g", 1 + ReportStatistics.defaultDelta))]. `faster`: q < \(Self.percent(ReportStatistics.significanceLevel)) and CI low > \(String(format: "%g", 1 + ReportStatistics.defaultDelta)); `slower`: q < \(Self.percent(ReportStatistics.significanceLevel)) and CI high < 1/\(String(format: "%g", 1 + ReportStatistics.defaultDelta)); `equivalent`: the CI lies inside the zone; otherwise `inconclusive`; `n/a (k replicates)` when either side has fewer than 2. Only wall clock is tested; all other metrics are descriptive.")
        lines.append("- **Drift:** \(driftSummary())")
        lines.append("- **Limits:** each ref is built once, so effects of code layout between builds are not sampled. Conclusions hold for the recorded host and toolchain only. The Benchmark plugin checks and relinks the build before each replicate, identically for all refs. With k = 5 per side the smallest attainable p (0.0079) cannot pass Benjamini–Hochberg over several hundred tests; k = 10 is the practical minimum for meaningful verdicts.")
        lines.append("")
    }

    private var testCount: Int {
        model.comparisons.values.filter { $0.p != nil }.count
    }

    private func coverageSummary() -> (median: String, speed: String) {
        func percent(_ value: Double) -> String { String(format: "%.1f%%", value * 100) }
        var medianByK: [Int: Double] = [:]
        if let wall = model.wallClockMetric {
            for entry in model.series {
                for (key, cell) in entry.cells where key.metric == wall {
                    if let interval = cell.interval { medianByK[cell.replicates] = interval.coverage }
                }
            }
        }
        var speedByPair: [String: Double] = [:]
        for item in model.comparisons.values {
            if let coverage = item.coverage { speedByPair["\(item.baselineReplicates) vs \(item.seriesReplicates)"] = coverage }
        }
        let median = medianByK.isEmpty ? "No median interval is available (k < 6 everywhere)."
            : "median CI " + medianByK.keys.sorted().map { "k = \($0): \(percent(medianByK[$0]!))" }.joined(separator: ", ") + " (nominal ≥ 95%, exact)."
        let speed = speedByPair.isEmpty ? "No speed interval is available (needs about 4 replicates per side)."
            : "Speed CI " + speedByPair.keys.sorted().map { "\($0) replicates: \(percent(speedByPair[$0]!))" }.joined(separator: ", ") + "."
        return (median, speed)
    }

    private func driftSummary() -> String {
        guard !model.drift.isEmpty else {
            return "not evaluated; it needs at least 3 replicates per series."
        }
        let flagged = model.drift.filter(\.isFlagged)
        var text = "Kendall's τ between round and replicate median per series and wall-clock cell, exact p (\(model.drift.filter(\.isApproximate).count) of \(model.drift.count) use a normal approximation because of ties), Benjamini–Hochberg adjusted across \(model.drift.count) tests. \(flagged.count) cell\(flagged.count == 1 ? "" : "s") show\(flagged.count == 1 ? "s" : "") a significant trend (q < \(Self.percent(ReportStatistics.significanceLevel)))"
        if flagged.isEmpty {
            text += "."
        } else {
            let shown = flagged.prefix(20).map { item -> String in
                let tau = item.tau.map { String(format: "τ=%+.2f", $0) } ?? "τ undefined"
                return "`\(Self.code(model.series[item.series].label))` / `\(Self.code(item.key.identity))` @ \(ReportFormat.grouped(item.key.scale)) (\(tau), q=\(ReportFormat.qValue(item.q ?? 1)))"
            }
            text += ": " + shown.joined(separator: "; ") + (flagged.count > 20 ? "; and \(flagged.count - 20) more." : ".")
        }
        return text
    }

    // MARK: Provenance, pairing, parity

    private mutating func provenance() {
        lines.append("## Provenance")
        lines.append("")
        for group in model.groups {
            let files = group.fileIndices.map { model.files[$0] }
            let first = files[0]
            lines.append("### \(Self.text(group.label))")
            lines.append("")
            lines.append("| Field | Value |")
            lines.append("| --- | --- |")
            func distinct(_ values: [String]) -> String { values.uniqued().joined(separator: "; ") }
            let rounds = files.compactMap { $0.run.replicate.map { "\($0.round)" } }
            let rows: [(String, String)] = [
                ("Requested ref", first.ref.requested),
                ("Ref SHA", first.ref.sha),
                ("Component model", first.ref.componentModel),
                ("Backends", group.backends.joined(separator: ", ")),
                ("Suite SHA", distinct(files.map(\.suite.sha))),
                ("Suite target", first.suite.target),
                ("Configuration hash", first.suite.configurationHash),
                ("Replicates", "\(files.count) of \(group.expectedReplicates) (indices \(group.replicateIndices.map(String.init).joined(separator: ", ")))"),
                ("Rounds", rounds.isEmpty ? "none recorded" : rounds.joined(separator: ", ")),
                ("Seed", distinct(files.compactMap { $0.run.replicate.map { "\($0.seed)" } }).isEmpty ? "none recorded" : distinct(files.compactMap { $0.run.replicate.map { "\($0.seed)" } })),
                ("Batch", distinct(files.map { $0.run.batchId ?? "none recorded" })),
                ("Runs", "\(files.count) (\(files.map(\.run.startedAt).min()!) to \(files.map(\.run.finishedAt).max()!))"),
                ("Run ids", files.map(\.run.id).joined(separator: ", ")),
                ("Toolchain", distinct(files.map { "\($0.toolchain.swiftVersion) (\($0.toolchain.buildMode))" })),
                ("Host", distinct(files.map { "\($0.host.osName) \($0.host.osVersion), \($0.host.architecture), \($0.host.cpuModel), \($0.host.coreCount) cores, \($0.host.physicalMemoryBytes) bytes memory" })),
                ("Packages", distinct(files.map { $0.packages.map { "\($0.identity) \($0.version ?? "-") \($0.revision.prefix(12))" }.joined(separator: "; ") }))
            ]
            for (name, value) in rows {
                lines.append("| \(name) | \(Self.cell(value)) |")
            }
            lines.append("")
        }
    }

    private mutating func pairing() {
        lines.append("## Series and pairing")
        lines.append("")
        lines.append("| Series | Replicates | Compared with |")
        lines.append("| --- | --- | --- |")
        for index in model.series.indices {
            let series = model.series[index]
            let group = model.groups[series.groupIndex]
            let target: String = if model.isBaseline(index) {
                "baseline"
            } else if let paired = model.pairedSeries(for: index) {
                Self.cell(model.series[paired].label)
            } else {
                "unavailable (the baseline has several backends and none is `\(Self.code(series.backend))`)"
            }
            lines.append("| \(Self.cell(series.label)) | \(group.fileIndices.count) of \(group.expectedReplicates) | \(target) |")
        }
        lines.append("")
    }

    private mutating func parityNotes() {
        lines.append("## Parity notes")
        lines.append("")
        var parity: [String: [String: [String]]] = [:]
        var unsupported: [String: [String: [String]]] = [:]
        for group in model.groups {
            let file = model.files[group.fileIndices[0]]
            for workload in file.workloads {
                let text = workload.parityKind == "equivalent" ? "equivalent" : "adapted: \(workload.parityReason ?? "")"
                parity[workload.identity, default: [:]][text, default: []].append(group.label)
            }
            for entry in file.unsupported {
                unsupported[entry.identity, default: [:]][entry.reason, default: []].append(group.label)
            }
        }
        lines.append("| Workload | Parity | Refs |")
        lines.append("| --- | --- | --- |")
        for identity in parity.keys.sorted() {
            for text in parity[identity]!.keys.sorted() {
                lines.append("| `\(Self.code(identity))` | \(Self.cell(text)) | \(Self.cell(parity[identity]![text]!.joined(separator: ", "))) |")
            }
        }
        lines.append("")
        lines.append("## Unsupported workloads")
        lines.append("")
        lines.append("Unsupported workloads are not measured and not approximated.")
        lines.append("")
        lines.append("| Workload | Reason | Refs |")
        lines.append("| --- | --- | --- |")
        for identity in unsupported.keys.sorted() {
            for reason in unsupported[identity]!.keys.sorted() {
                lines.append("| `\(Self.code(identity))` | \(Self.cell(reason)) | \(Self.cell(unsupported[identity]![reason]!.joined(separator: ", "))) |")
            }
        }
        lines.append("")
    }

    // MARK: Escaping

    /// Table cell: single line, pipes escaped, HTML-significant characters written as entities (Markdown passes raw HTML through).
    static func cell(_ value: String) -> String {
        entities(value).replacingOccurrences(of: "\n", with: "; ").replacingOccurrences(of: "|", with: "\\|")
    }

    static func text(_ value: String) -> String {
        entities(value).replacingOccurrences(of: "\n", with: " ")
    }

    private static func entities(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
    }

    /// Inside a code span: no backticks.
    static func code(_ value: String) -> String {
        value.replacingOccurrences(of: "`", with: "'").replacingOccurrences(of: "\n", with: " ")
    }
}
