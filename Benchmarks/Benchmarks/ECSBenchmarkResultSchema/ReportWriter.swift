// Markdown, HTML table and SVG rendering of a `ReportModel` into the files of a report directory (PLAN "Report v2 design").
import Benchmark
import Foundation

struct ReportWriter {
    let model: ReportModel
    let title: String
    private var lines: [String] = []

    /// Entity counts up to this value go into the small table, the rest into the large one (as upstream splits its tables).
    static let smallLimit = 1024
    static let summaryScales = [1024, 65536]

    init(model: ReportModel, title: String) {
        self.model = model
        self.title = title
    }

    /// REPORT.md first, then `workloads/<identity>.md`, then `img/<identity>-{per-entity,total}.svg`, each group sorted.
    mutating func render() -> [RenderedFile] {
        let identities = Array(Set(model.keys.map(\.identity))).sorted()
        var names: [String: String] = [:]
        var used = Set<String>()
        for identity in identities {
            var name = Self.fileName(identity)
            while !used.insert(name).inserted { name += "_" }
            names[identity] = name
        }
        var plots: [String: (perEntity: String?, total: String?)] = [:]
        for identity in identities {
            plots[identity] = (
                plot(identity, perEntity: true),
                plot(identity, perEntity: false)
            )
        }

        var files: [RenderedFile] = []
        files.append(RenderedFile(path: "REPORT.md", contents: overview(identities, names, plots)))
        for identity in identities {
            files.append(RenderedFile(path: "workloads/\(names[identity]!).md", contents: workloadPage(identity, names[identity]!, plots[identity]!)))
        }
        for identity in identities {
            if let svg = plots[identity]?.perEntity { files.append(RenderedFile(path: "img/\(names[identity]!)-per-entity.svg", contents: svg)) }
            if let svg = plots[identity]?.total { files.append(RenderedFile(path: "img/\(names[identity]!)-total.svg", contents: svg)) }
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

    private mutating func overview(_ identities: [String], _ names: [String: String], _ plots: [String: (perEntity: String?, total: String?)]) -> String {
        lines = []
        lines.append("# \(Self.text(title))")
        lines.append("")
        header()
        warnings()
        summary(identities, names)
        lines.append("## Workloads")
        lines.append("")
        for identity in identities {
            lines.append("### `\(Self.code(identity))`")
            lines.append("")
            let name = names[identity]!
            lines.append("[All metrics, deltas and percentiles](workloads/\(name).md)")
            lines.append("")
            figures(identity, name, plots[identity]!, prefix: "")
            wallClockTables(identity, headingLevel: 4)
        }
        provenance()
        pairing()
        parityNotes()
        return finish()
    }

    private mutating func finish() -> String {
        defer { lines = [] }
        return lines.joined(separator: "\n") + "\n"
    }

    private mutating func header() {
        let baselineFile = model.files[model.baselineIndex]
        lines.append("- Baseline: `\(Self.code(model.fileLabels[model.baselineIndex]))` (\(Self.text(baselineFile.ref.sha)))")
        lines.append("- Inputs: \(model.files.count) result files, \(model.series.count) series")
        let filters = Set(model.files.map(\.suite.filter)).sorted()
        lines.append("- Selection filter: " + filters.map { "`\(Self.code($0))`" }.joined(separator: ", "))
        lines.append("- Values are per iteration. `mean` and `±sd` are the Benchmark package's mean and standard deviation, `n` is the number of measurements. Sampling is time-based, so `n` differs between series by design and is shown in every table.")
        lines.append("- Non-baseline series add `Δ mean` (series minus baseline), `speed (×)` (how many times faster than the baseline; above 1 is better, for either polarity), `change (%)` of the value, and `sig.`.")
        lines.append("- `sig.` is a two-sided Welch t-test at α = 0.05 on mean, standard deviation and n, with the result labelled `better` or `worse`; `n/a` when either side has fewer than two measurements. Timing distributions are skewed, so treat it as an approximation, not a verdict.")
        lines.append("- Every unit is in its column header and applies to the whole column of that table. Values keep at most the \(ReportFormat.significantDigits) significant digits the package measured. Anything missing or not comparable is `unavailable` (hover for the reason), never zero.")
        lines.append("- Plots show the wall-clock mean per iteration on log-log axes with a ±1 sd band; entity count 0 cannot sit on a log axis and appears in the tables only.")
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

    // MARK: Summary

    private mutating func summary(_ identities: [String], _ names: [String: String]) {
        guard let wall = wallClockMetric() else { return }
        lines.append("## Summary")
        lines.append("")
        lines.append("Wall clock, speed (×) against the paired baseline series (above 1 is faster). `*` marks a significant difference (Welch, α = 0.05). The last column is the largest entity count for which the comparison exists (its count in parentheses).")
        lines.append("")
        let columns = ["@ \(ReportFormat.grouped(Self.summaryScales[0]))", "@ \(ReportFormat.grouped(Self.summaryScales[1]))", "@ largest"]
        var blocks: [HTMLColumnBlock] = []
        for index in model.series.indices where model.series[index].fileIndex != model.baselineIndex {
            var cells: [[HTMLCell]] = [[], [], []]
            for identity in identities {
                for (position, scale) in Self.summaryScales.enumerated() {
                    cells[position].append(summaryCell(index, ReportKey(identity: identity, scale: scale, metric: wall), withScale: false))
                }
                let available = Set(model.keys.filter { $0.identity == identity && $0.metric == wall }.map(\.scale)).sorted(by: >)
                let largest = available.first { scale in comparison(index, ReportKey(identity: identity, scale: scale, metric: wall)).speed != nil }
                if let largest {
                    cells[2].append(summaryCell(index, ReportKey(identity: identity, scale: largest, metric: wall), withScale: true))
                } else {
                    cells[2].append(.unavailable("no entity count with a comparison"))
                }
            }
            blocks.append(HTMLColumnBlock(group: groupLabel(index), subgroup: model.series[index].backend, headers: columns, columns: cells))
        }
        guard !blocks.isEmpty else { return }
        lines += HTMLTable(rowHeader: "Workload", rowLabels: identities, rowHrefs: identities.map { "workloads/\(names[$0]!).md" }, blocks: blocks).render()
        lines.append("")
    }

    private func summaryCell(_ series: Int, _ key: ReportKey, withScale: Bool) -> HTMLCell {
        let result = comparison(series, key)
        guard let speed = result.speed else { return .unavailable(result.reason ?? "unavailable") }
        let text = ReportFormat.text(speed, columnDecimals: 9) + (result.welch?.isSignificant == true ? "*" : "") + (withScale ? " (\(ReportFormat.grouped(key.scale)))" : "")
        return HTMLCell(text)
    }

    // MARK: Workload sections

    private mutating func figures(_ identity: String, _ name: String, _ plots: (perEntity: String?, total: String?), prefix: String) {
        guard plots.perEntity != nil || plots.total != nil else { return }
        if plots.perEntity != nil {
            lines.append("![\(Self.text(identity)): wall-clock cost per entity](\(prefix)img/\(name)-per-entity.svg)")
            lines.append("")
        }
        if plots.total != nil {
            lines.append("![\(Self.text(identity)): wall-clock time per iteration](\(prefix)img/\(name)-total.svg)")
            lines.append("")
        }
    }

    private mutating func wallClockTables(_ identity: String, headingLevel: Int) {
        guard let wall = wallClockMetric() else { return }
        let scales = Set(model.keys.filter { $0.identity == identity && $0.metric == wall }.map(\.scale)).sorted()
        statisticsTables(identity, wall, scales, headingLevel: headingLevel)
    }

    private mutating func statisticsTables(_ identity: String, _ metric: String, _ scales: [Int], headingLevel: Int) {
        let hashes = String(repeating: "#", count: headingLevel)
        let small = scales.filter { $0 <= Self.smallLimit }
        let large = scales.filter { $0 > Self.smallLimit }
        for (label, part) in [("Entity counts up to \(ReportFormat.grouped(Self.smallLimit))", small), ("Entity counts above \(ReportFormat.grouped(Self.smallLimit))", large)] where !part.isEmpty {
            lines.append("\(hashes) \(Self.text(metric)): \(label)")
            lines.append("")
            lines += statisticsTable(identity, metric, part).render()
            lines.append("")
        }
    }

    private mutating func workloadPage(_ identity: String, _ name: String, _ plots: (perEntity: String?, total: String?)) -> String {
        lines = []
        lines.append("# `\(Self.code(identity))`")
        lines.append("")
        lines.append("[Back to the report](../REPORT.md). \(Self.text(title)).")
        lines.append("")
        var parity: [String: [String]] = [:]
        for (index, file) in model.files.enumerated() {
            for workload in file.workloads where workload.identity == identity {
                let text = workload.parityKind == "equivalent" ? "equivalent" : "adapted: \(workload.parityReason ?? "")"
                parity[text, default: []].append(model.fileLabels[index])
            }
        }
        for text in parity.keys.sorted() {
            lines.append("- Parity (\(Self.text(parity[text]!.joined(separator: ", ")))): \(Self.text(text))")
        }
        if !parity.isEmpty { lines.append("") }
        figures(identity, name, plots, prefix: "../")
        let metrics = Array(NSOrderedSet(array: model.keys.filter { $0.identity == identity }.map(\.metric))) as! [String]
        for metric in metrics {
            let scales = Set(model.keys.filter { $0.identity == identity && $0.metric == metric }.map(\.scale)).sorted()
            let polarity = referenceSample(ReportKey(identity: identity, scale: scales[0], metric: metric))?.prefersLarger == true ? "larger is better" : "smaller is better"
            lines.append("## \(Self.text(metric)) (\(polarity))")
            lines.append("")
            statisticsTables(identity, metric, scales, headingLevel: 3)
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

    private func groupLabel(_ series: Int) -> String {
        let file = model.files[model.series[series].fileIndex]
        return "\(model.fileLabels[model.series[series].fileIndex]) (\(file.ref.componentModel))" + (model.series[series].fileIndex == model.baselineIndex ? " - baseline" : "")
    }

    private func wallClockMetric() -> String? {
        model.metrics.first { $0.value.rawDescription == "wallClock" }?.key
    }

    /// The sample every other sample of this row must be compatible with: the baseline input's, else the first available.
    private func referenceSample(_ key: ReportKey) -> ReportSample? {
        model.series.first { $0.fileIndex == model.baselineIndex && $0.samples[key] != nil }?.samples[key]
            ?? model.series.compactMap { $0.samples[key] }.first
    }

    /// The series' sample for `key`, or the reason it cannot be used.
    private func resolve(_ series: Int, _ key: ReportKey) -> (sample: ReportSample?, reason: String?) {
        guard let sample = model.series[series].samples[key] else { return (nil, "not measured for this series") }
        guard let reference = referenceSample(key), sample.isCompatible(with: reference) else { return (nil, "incompatible units or polarity") }
        return (sample, nil)
    }

    struct Comparison {
        var delta: Double?
        var speed: Double?
        var change: Double?
        var welch: WelchResult?
        var better: Bool?
        var reason: String?
    }

    /// Series minus its paired baseline series, polarity-aware. Never produces zero for missing data.
    private func comparison(_ series: Int, _ key: ReportKey) -> Comparison {
        var result = Comparison()
        let own = resolve(series, key)
        guard let sample = own.sample else { result.reason = own.reason; return result }
        guard !sample.isEmpty else { result.reason = "no measurements"; return result }
        guard let pair = model.pairedSeries(for: series) else { result.reason = "the baseline has several backends and none matches"; return result }
        let base = resolve(pair, key)
        guard let baseSample = base.sample else { result.reason = "baseline: \(base.reason ?? "unavailable")"; return result }
        guard !baseSample.isEmpty else { result.reason = "baseline: no measurements"; return result }
        result.delta = sample.mean - baseSample.mean
        if baseSample.mean == 0 {
            result.reason = "zero baseline"
        } else {
            result.change = result.delta! / baseSample.mean * 100
            // Speed above 1 is better for either polarity.
            if sample.prefersLarger {
                result.speed = sample.mean / baseSample.mean
            } else if sample.mean != 0 {
                result.speed = baseSample.mean / sample.mean
            } else {
                result.reason = "zero value"
            }
        }
        result.welch = Welch.test(mean1: sample.mean, standardDeviation1: sample.standardDeviation, count1: sample.measurementCount, mean2: baseSample.mean, standardDeviation2: baseSample.standardDeviation, count2: baseSample.measurementCount)
        if let delta = result.delta, delta != 0 { result.better = (delta > 0) == sample.prefersLarger }
        return result
    }

    private func dimension(_ identity: String, _ metric: String, _ scales: [Int]) -> ReportDimension {
        for scale in scales {
            if let reference = referenceSample(ReportKey(identity: identity, scale: scale, metric: metric)) { return reference.dimension }
        }
        return .count
    }

    /// Mean, sd and n per series, plus delta, speed, change and significance for series that have a paired baseline.
    private func statisticsTable(_ identity: String, _ metric: String, _ scales: [Int]) -> HTMLTable {
        let dimension = dimension(identity, metric, scales)
        var blocks: [HTMLColumnBlock] = []
        /// Exponent of ten of the last shown digit of each series' mean column, in base units: limits derived precision.
        var meanResolution: [Int: Int] = [:]
        // Mean columns first: deltas depend on the resolution of both mean columns.
        struct Raw { var mean: [Double?]; var sd: [Double?]; var count: [Int?]; var reasons: [String?] }
        var raws: [Raw] = []
        for index in model.series.indices {
            var raw = Raw(mean: [], sd: [], count: [], reasons: [])
            for scale in scales {
                let resolved = resolve(index, ReportKey(identity: identity, scale: scale, metric: metric))
                if let sample = resolved.sample {
                    raw.count.append(sample.measurementCount)
                    raw.mean.append(sample.isEmpty ? nil : sample.mean)
                    raw.sd.append(sample.isEmpty ? nil : sample.standardDeviation)
                    raw.reasons.append(sample.isEmpty ? "no measurements" : nil)
                } else {
                    raw.count.append(nil)
                    raw.mean.append(nil)
                    raw.sd.append(nil)
                    raw.reasons.append(resolved.reason)
                }
            }
            raws.append(raw)
        }
        for index in model.series.indices {
            let raw = raws[index]
            let meanUnit = dimension.unit(fitting: raw.mean.compactMap { $0 })
            let sdUnit = dimension.unit(fitting: raw.sd.compactMap { $0 })
            let meanDecimals = ReportFormat.columnDecimals(raw.mean.compactMap { $0 }, divisor: meanUnit.divisor)
            let sdDecimals = ReportFormat.columnDecimals(raw.sd.compactMap { $0 }, divisor: sdUnit.divisor)
            meanResolution[index] = Int(round(log10(meanUnit.divisor))) - meanDecimals
            func cells(_ values: [Double?], _ unit: ReportUnit, _ decimals: Int) -> [HTMLCell] {
                values.indices.map { row in
                    guard let value = values[row] else { return .unavailable(raw.reasons[row] ?? "unavailable") }
                    return HTMLCell(ReportFormat.text(value, divisor: unit.divisor, columnDecimals: decimals))
                }
            }
            func header(_ name: String, _ unit: ReportUnit) -> String { unit.label.isEmpty ? name : "\(name) (\(unit.label))" }
            var block = HTMLColumnBlock(
                group: groupLabel(index),
                subgroup: model.series[index].backend,
                headers: [header("mean", meanUnit), header("±sd", sdUnit), "n"],
                columns: [
                    cells(raw.mean, meanUnit, meanDecimals),
                    cells(raw.sd, sdUnit, sdDecimals),
                    raw.count.indices.map { row in raw.count[row].map { HTMLCell(String($0)) } ?? .unavailable(raw.reasons[row] ?? "unavailable") }
                ]
            )
            if model.series[index].fileIndex != model.baselineIndex {
                let compared = scales.map { comparison(index, ReportKey(identity: identity, scale: $0, metric: metric)) }
                let deltas = compared.map(\.delta)
                let deltaUnit = dimension.unit(fitting: deltas.compactMap { $0 })
                var cap: Int?
                if let pair = model.pairedSeries(for: index), let own = meanResolution[index], let other = meanResolution[pair] {
                    cap = max(0, Int(round(log10(deltaUnit.divisor))) - max(own, other))
                }
                let deltaDecimals = ReportFormat.columnDecimals(deltas.compactMap { $0 }, divisor: deltaUnit.divisor, cap: cap)
                let speeds = compared.compactMap(\.speed)
                let changes = compared.compactMap(\.change)
                let speedDecimals = ReportFormat.columnDecimals(speeds, divisor: 1)
                let changeDecimals = ReportFormat.columnDecimals(changes, divisor: 1)
                block.headers += [header("Δ mean", deltaUnit), "speed (×)", "change (%)", "sig."]
                block.columns.append(compared.map { item in
                    item.delta.map { HTMLCell(ReportFormat.text($0, divisor: deltaUnit.divisor, columnDecimals: deltaDecimals, signed: true)) } ?? .unavailable(item.reason ?? "unavailable")
                })
                block.columns.append(compared.map { item in
                    item.speed.map { HTMLCell(ReportFormat.text($0, columnDecimals: speedDecimals)) } ?? .unavailable(item.reason ?? "unavailable")
                })
                block.columns.append(compared.map { item in
                    item.change.map { HTMLCell(ReportFormat.text($0, columnDecimals: changeDecimals, signed: true)) } ?? .unavailable(item.reason ?? "unavailable")
                })
                block.columns.append(compared.map { item in
                    guard item.delta != nil else { return .unavailable(item.reason ?? "unavailable") }
                    guard let welch = item.welch else { return HTMLCell("n/a", title: "fewer than two measurements on a side") }
                    let verdict = welch.isSignificant ? (item.better == true ? "better" : (item.better == false ? "worse" : "differs")) : "no"
                    return HTMLCell("\(verdict), \(ReportFormat.probability(welch.p))")
                })
            }
            blocks.append(block)
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
                let values: [Double?] = resolved.map { item in item.sample.flatMap { $0.isEmpty ? nil : $0.value(.percentile(percentile)) } }
                let unit = dimension.unit(fitting: values.compactMap { $0 })
                let decimals = ReportFormat.columnDecimals(values.compactMap { $0 }, divisor: unit.divisor)
                block.headers.append(unit.label.isEmpty ? "p\(percentile)" : "p\(percentile) (\(unit.label))")
                block.columns.append(values.indices.map { row in
                    if let value = values[row] { return HTMLCell(ReportFormat.text(value, divisor: unit.divisor, columnDecimals: decimals)) }
                    return .unavailable(resolved[row].sample == nil ? resolved[row].reason ?? "unavailable" : "no measurements")
                })
            }
            blocks.append(block)
        }
        return HTMLTable(rowHeader: "Entities", rowLabels: scales.map(ReportFormat.grouped), blocks: blocks)
    }

    // MARK: Plots

    private func plot(_ identity: String, perEntity: Bool) -> String? {
        guard let wall = wallClockMetric() else { return nil }
        var series: [ReportPlotSeries] = []
        for (index, entry) in model.series.enumerated() {
            var points: [Int: ReportPlotPoint] = [:]
            for key in model.keys where key.identity == identity && key.metric == wall {
                let resolved = resolve(index, key)
                if let sample = resolved.sample, !sample.isEmpty {
                    points[key.scale] = ReportPlotPoint(mean: sample.mean, standardDeviation: sample.standardDeviation, samples: sample.measurementCount)
                }
            }
            series.append(ReportPlotSeries(label: entry.label, colorIndex: index, isBaseline: entry.fileIndex == model.baselineIndex, points: points))
        }
        return ReportPlot.render(
            title: perEntity ? "\(identity): wall-clock cost per entity" : "\(identity): wall-clock time per iteration",
            yTitle: perEntity ? "Mean time per entity" : "Mean time per iteration",
            perEntity: perEntity,
            series: series
        )
    }

    // MARK: Provenance, pairing, parity

    private mutating func provenance() {
        lines.append("## Provenance")
        lines.append("")
        for (index, file) in model.files.enumerated() {
            lines.append("### \(Self.text(model.fileLabels[index]))")
            lines.append("")
            lines.append("| Field | Value |")
            lines.append("| --- | --- |")
            let rows: [(String, String)] = [
                ("Requested ref", file.ref.requested),
                ("Ref SHA", file.ref.sha),
                ("Component model", file.ref.componentModel),
                ("Backends", file.ref.backends.joined(separator: ", ")),
                ("Suite SHA", file.suite.sha),
                ("Suite target", file.suite.target),
                ("Configuration hash", file.suite.configurationHash),
                ("Run", "\(file.run.id) (\(file.run.startedAt) to \(file.run.finishedAt))"),
                ("Batch", file.run.batchId ?? "none recorded"),
                ("Toolchain", "\(file.toolchain.swiftVersion) (\(file.toolchain.buildMode))"),
                ("Host", "\(file.host.osName) \(file.host.osVersion), \(file.host.architecture), \(file.host.cpuModel), \(file.host.coreCount) cores, \(file.host.physicalMemoryBytes) bytes memory"),
                ("Packages", file.packages.map { "\($0.identity) \($0.version ?? "-") \($0.revision.prefix(12))" }.joined(separator: "; "))
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
        lines.append("| Series | Compared with |")
        lines.append("| --- | --- |")
        for index in model.series.indices {
            let series = model.series[index]
            let target: String = if series.fileIndex == model.baselineIndex {
                "baseline"
            } else if let paired = model.pairedSeries(for: index) {
                Self.cell(model.series[paired].label)
            } else {
                "unavailable (the baseline has several backends and none is `\(Self.code(series.backend))`)"
            }
            lines.append("| \(Self.cell(series.label)) | \(target) |")
        }
        lines.append("")
    }

    private mutating func parityNotes() {
        lines.append("## Parity notes")
        lines.append("")
        var parity: [String: [String: [String]]] = [:]
        var unsupported: [String: [String: [String]]] = [:]
        for (index, file) in model.files.enumerated() {
            for workload in file.workloads {
                let text = workload.parityKind == "equivalent" ? "equivalent" : "adapted: \(workload.parityReason ?? "")"
                parity[workload.identity, default: [:]][text, default: []].append(model.fileLabels[index])
            }
            for entry in file.unsupported {
                unsupported[entry.identity, default: [:]][entry.reason, default: []].append(model.fileLabels[index])
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
