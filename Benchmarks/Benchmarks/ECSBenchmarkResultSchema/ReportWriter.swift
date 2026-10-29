// Markdown and Mermaid rendering of a `ReportModel`.
import Benchmark
import Foundation

struct ReportWriter {
    let model: ReportModel
    let title: String
    private var lines: [String] = []

    init(model: ReportModel, title: String) {
        self.model = model
        self.title = title
    }

    mutating func render() -> String {
        lines.append("# \(Self.text(title))")
        lines.append("")
        header()
        warnings()
        provenance()
        pairing()
        workloads()
        results()
        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: Sections

    private mutating func header() {
        let baselineFile = model.files[model.baselineIndex]
        lines.append("- Baseline: `\(Self.text(model.fileLabels[model.baselineIndex]))` (\(Self.text(baselineFile.ref.sha)))")
        lines.append("- Inputs: \(model.files.count) result files, \(model.series.count) series")
        let filters = Set(model.files.map(\.suite.filter)).sorted()
        lines.append("- Selection filter: " + filters.map { "`\(Self.code($0))`" }.joined(separator: ", "))
        lines.append("- Values are per iteration. Deltas are series minus baseline; ratio is series / baseline. Anything missing or not comparable is `unavailable`, never zero.")
        lines.append("- Percentiles follow the Benchmark package: for metrics where larger is better, p0 is the largest value.")
        lines.append("")
    }

    private mutating func warnings() {
        guard !model.warnings.isEmpty else { return }
        lines.append("## Warnings")
        lines.append("")
        for warning in model.warnings { lines.append("- \(Self.text(warning))") }
        lines.append("")
    }

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
            for (name, value) in rows { lines.append("| \(name) | \(Self.cell(value)) |") }
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
            let target: String
            if series.fileIndex == model.baselineIndex {
                target = "baseline"
            } else if let paired = model.pairedSeries(for: index) {
                target = Self.cell(model.series[paired].label)
            } else {
                target = "unavailable (the baseline has several backends and none is `\(Self.code(series.backend))`)"
            }
            lines.append("| \(Self.cell(series.label)) | \(target) |")
        }
        lines.append("")
    }

    private mutating func workloads() {
        lines.append("## Workloads")
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

    private mutating func results() {
        lines.append("## Results")
        lines.append("")
        var current: (String, Int)?
        for key in model.keys {
            if current?.0 != key.identity || current?.1 != key.scale {
                current = (key.identity, key.scale)
                lines.append("### `\(Self.code(key.identity))` / \(key.scale)")
                lines.append("")
            }
            metricSection(key)
        }
    }

    private mutating func metricSection(_ key: ReportKey) {
        let reference = referenceSample(key)
        let comparable = model.series.map { series -> ReportSample? in
            guard let sample = series.samples[key], let reference, sample.isCompatible(with: reference) else { return nil }
            return sample
        }
        let polarity = reference?.prefersLarger == true ? "larger is better" : "smaller is better"
        lines.append("#### \(Self.text(key.metric)) (\(polarity))")
        lines.append("")
        lines.append("| Statistic | " + model.series.indices.map { index in
            Self.cell(model.series[index].label) + (model.series[index].fileIndex == model.baselineIndex ? " (baseline)" : "")
        }.joined(separator: " | ") + " |")
        lines.append("| --- |" + String(repeating: " --- |", count: model.series.count))

        for statistic in ReportStatistic.tableRows {
            var unit = ReportUnit("", 1)
            if statistic != .count, let reference {
                unit = reference.dimension.unit(fitting: comparable.compactMap { $0?.value(statistic) })
            }
            var cells: [String] = []
            for index in model.series.indices {
                cells.append(Self.cell(self.cell(index, key, statistic, unit, reference, comparable[index])))
            }
            lines.append("| \(statistic.label) | " + cells.joined(separator: " | ") + " |")
        }
        lines.append("")
        chart(key, reference, comparable)
    }

    /// The sample every other sample of this row must be compatible with: the baseline input's, else the first available.
    private func referenceSample(_ key: ReportKey) -> ReportSample? {
        model.series.first { $0.fileIndex == model.baselineIndex && $0.samples[key] != nil }?.samples[key]
            ?? model.series.compactMap { $0.samples[key] }.first
    }

    private func cell(_ index: Int, _ key: ReportKey, _ statistic: ReportStatistic, _ unit: ReportUnit, _ reference: ReportSample?, _ sample: ReportSample?) -> String {
        guard model.series[index].samples[key] != nil else { return "unavailable" }
        guard let sample else { return "unavailable (incompatible units)" }
        if statistic == .count { return "\(sample.measurementCount)" }
        let value = sample.value(statistic)
        let text = ReportFormat.quantity(value, unit)
        guard model.series[index].fileIndex != model.baselineIndex else { return text }
        guard let pair = model.pairedSeries(for: index), let base = model.series[pair].samples[key], base.isCompatible(with: sample) else {
            return "\(text) (delta unavailable)"
        }
        let baseValue = base.value(statistic)
        let delta = value - baseValue
        let absolute = ReportFormat.signed(delta / unit.divisor) + (unit.label.isEmpty ? "" : " \(unit.label)")
        let verdict: String
        if delta == 0 {
            verdict = "unchanged"
        } else {
            verdict = (delta > 0) == sample.prefersLarger ? "better" : "worse"
        }
        if baseValue == 0 {
            return "\(text) (Δ \(absolute), ratio and change unavailable: zero baseline, \(verdict))"
        }
        let ratio = ReportFormat.number(value / baseValue)
        let percent = ReportFormat.signed(delta / baseValue * 100)
        return "\(text) (Δ \(absolute), ×\(ratio), \(percent)%, \(verdict))"
    }

    private mutating func chart(_ key: ReportKey, _ reference: ReportSample?, _ comparable: [ReportSample?]) {
        guard let reference else { return }
        let p50 = ReportStatistic.percentile(50)
        let unit = reference.dimension.unit(fitting: comparable.compactMap { $0?.value(p50) })
        var labels: [String] = []
        var values: [String] = []
        for index in model.series.indices {
            guard let sample = comparable[index] else { continue }
            labels.append("\"\(Self.quoted(model.series[index].label))\"")
            values.append(ReportFormat.number(sample.value(p50) / unit.divisor))
        }
        guard !values.isEmpty else { return }
        let axis = unit.label.isEmpty ? "p50" : "p50 (\(unit.label))"
        lines.append("```mermaid")
        lines.append("xychart-beta")
        lines.append("    title \"\(Self.quoted("\(key.identity) / \(key.scale) - \(key.metric)"))\"")
        lines.append("    x-axis [\(labels.joined(separator: ", "))]")
        lines.append("    y-axis \"\(Self.quoted(axis))\"")
        lines.append("    bar [\(values.joined(separator: ", "))]")
        lines.append("```")
        lines.append("")
    }

    // MARK: Escaping

    /// Table cell: single line, pipes escaped.
    static func cell(_ value: String) -> String {
        value.replacingOccurrences(of: "\n", with: "; ").replacingOccurrences(of: "|", with: "\\|")
    }

    static func text(_ value: String) -> String {
        value.replacingOccurrences(of: "\n", with: " ")
    }

    /// Inside a code span: no backticks.
    static func code(_ value: String) -> String {
        value.replacingOccurrences(of: "`", with: "'").replacingOccurrences(of: "\n", with: " ")
    }

    /// Inside a double-quoted Mermaid string.
    static func quoted(_ value: String) -> String {
        value.replacingOccurrences(of: "\"", with: "'").replacingOccurrences(of: "\n", with: " ")
    }
}
