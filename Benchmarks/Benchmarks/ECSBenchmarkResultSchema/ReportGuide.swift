// The "How to read this report" section of REPORT.md: plain-language explanations for readers who are not statisticians, with
// worked examples whose numbers are taken from the comparisons and cells of the report being rendered (never hardcoded). Without
// replicates the examples say that inference is unavailable instead of inventing numbers.
import Foundation

struct ReportGuide {
    let model: ReportModel

    private struct Example {
        let series: Int
        let key: ReportKey
        let comparison: ReportComparison

        /// Relative half-width of the speed CI.
        var halfWidth: Double? {
            guard let low = comparison.ciLow, let high = comparison.ciHigh, let speed = comparison.speed, speed > 0 else { return nil }
            return (high - low) / 2 / speed
        }
    }

    private var delta: Double { ReportStatistics.defaultDelta }
    private var level: String { ReportWriter.percent(ReportStatistics.significanceLevel) }
    private var zone: String { ReportWriter.percent(delta) }
    private var upperEdge: String { String(format: "%g", 1 + delta) }

    /// Every wall-clock comparison with an estimate, in a fixed order (series, then the sorted keys).
    private var examples: [Example] {
        guard let wall = model.wallClockMetric else { return [] }
        var result: [Example] = []
        for index in model.series.indices where !model.isBaseline(index) {
            for key in model.keys where key.metric == wall {
                if let item = model.comparisons[ReportComparisonKey(series: index, key: key)], item.speed != nil, item.reason == nil {
                    result.append(Example(series: index, key: key, comparison: item))
                }
            }
        }
        return result
    }

    private func ratio(_ value: Double, decimals: Int = 2) -> String {
        ReportFormat.text(value, columnDecimals: decimals)
    }

    private func place(_ example: Example) -> String {
        "`\(ReportWriter.code(example.key.identity))` at \(ReportFormat.grouped(example.key.scale)) entities, `\(ReportWriter.code(model.series[example.series].label))`"
    }

    private func interval(_ comparison: ReportComparison) -> String? {
        guard let low = comparison.ciLow, let high = comparison.ciHigh, let speed = comparison.speed else { return nil }
        let decimals = ReportFormat.columnDecimals([speed, low, high], divisor: 1)
        return "speed \(ratio(speed, decimals: decimals))×, CI \(ratio(low, decimals: decimals))–\(ratio(high, decimals: decimals))×"
    }

    func lines() -> [String] {
        let all = examples
        let withInterval = all.filter { $0.halfWidth != nil }
        var lines = ["## How to read this report", ""]
        lines.append("Short version: look at `speed (×)` (above 1 the series is faster than the baseline), check that its CI is narrow, and read the `verdict`. Words in `code` style are defined in the [glossary](#\(ReportGlossary.anchor)).")
        lines.append("")
        if withInterval.isEmpty {
            lines.append("> **Inference is unavailable in this report.** \(unavailableReason()) Examples with numbers appear here when every ref has enough replicates.")
            lines.append("")
        }
        lines += confidenceInterval(withInterval, all)
        lines += verdicts(all)
        lines += uncertaintyVersusSpread(withInterval)
        lines += plots()
        lines += adjustedP(all)
        lines += replicates()
        return lines
    }

    private func unavailableReason() -> String {
        let counts = model.groups.map { "\(ReportWriter.text($0.label)): \($0.fileIndices.count)" }.joined(separator: ", ")
        return "Intervals, tests and verdicts need at least 2 replicates per ref and this report has (\(counts)), so there are no confidence intervals, `q` or verdicts."
    }

    // MARK: 1. Confidence interval

    private func confidenceInterval(_ withInterval: [Example], _ all: [Example]) -> [String] {
        var lines = ["### 1. What a confidence interval is", ""]
        lines.append("- Every number here is measured with noise, so a single speed such as 2.0× could have come out 1.9× or 2.1× in another session. The **confidence interval (CI)** is the range that, with 95% confidence (nominal; the exact coverage is in the methods), contains the true value.")
        lines.append("- `CI low` and `CI high` are its two ends. Read the pair as \"the truth is very likely between these\".")
        lines.append("- **Narrow** CI: the estimate is precise, you can trust the digits you see. **Wide** CI: the data cannot pin the value down; look for more replicates before drawing a conclusion.")
        if let first = withInterval.first, let text = interval(first.comparison) {
            let low = ratio(first.comparison.ciLow!), high = ratio(first.comparison.ciHigh!)
            lines.append("- **Example from this report:** \(place(first)): \(text) → the true speedup is very likely between \(low)× and \(high)×.")
            let ordered = withInterval.sorted { $0.halfWidth! < $1.halfWidth! }
            if let narrow = ordered.first, let wide = ordered.last, ordered.count > 1 {
                lines.append("- Narrowest CI in this report: \(place(narrow)), ±\(String(format: "%.1f", narrow.halfWidth! * 100))% around the speed (\(interval(narrow.comparison)!)). Widest: \(place(wide)), ±\(String(format: "%.1f", wide.halfWidth! * 100))% (\(interval(wide.comparison)!)).")
            }
        } else if let any = all.first, let speed = any.comparison.speed {
            lines.append("- **Example from this report:** \(place(any)): speed \(ratio(speed))× is a single ratio of two numbers; with one replicate on a side there is no CI, so inference is unavailable and it cannot be called an improvement or a regression.")
        } else {
            lines.append("- **Example:** inference is unavailable here, there is no comparison with a speed.")
        }
        lines.append("")
        return lines
    }

    // MARK: 2. Verdicts

    private func verdicts(_ all: [Example]) -> [String] {
        var lines = ["### 2. How the verdict is decided", ""]
        lines.append("A verdict is given only for wall clock and only when both refs have at least 2 replicates. We call differences smaller than ±\(zone) \"the same\" (the **equivalence zone**, speeds from 1/\(upperEdge) to \(upperEdge)).")
        lines.append("- `faster` / `slower`: the test is significant (`q` < \(level)) **and** the whole CI is outside the zone (above \(upperEdge), or below 1/\(upperEdge)).")
        lines.append("- `equivalent`: the whole CI is inside the zone, so any real difference is smaller than ±\(zone).")
        lines.append("- `inconclusive`: everything else. A significant test is not enough: if the CI still overlaps the zone, the effect could be smaller than \(zone) and not worth acting on, so the honest answer is \"cannot tell yet\".")
        lines.append("- `n/a (k replicates)`: a side has fewer than 2 replicates.")
        let counted = all.compactMap(\.comparison.verdict)
        func count(_ test: (ReportStatistics.Verdict) -> Bool) -> Int { counted.filter(test).count }
        if !counted.isEmpty {
            lines.append("- **In this report:** \(count { $0 == .faster }) faster, \(count { $0 == .slower }) slower, \(count { $0 == .equivalent }) equivalent, \(count { $0 == .inconclusive }) inconclusive, \(count { if case .notAvailable = $0 { true } else { false } }) n/a.")
            func line(_ label: String, _ verdict: ReportStatistics.Verdict) -> String? {
                guard let example = all.first(where: { $0.comparison.verdict == verdict }), let text = interval(example.comparison) else { return nil }
                let q = example.comparison.q.map { ", q \(ReportFormat.qValue($0))" } ?? ""
                return "- Example `\(label)`: \(place(example)): \(text)\(q)."
            }
            lines += [line("faster", .faster), line("slower", .slower), line("equivalent", .equivalent)].compactMap { $0 }
            if let tricky = all.first(where: { item in
                guard item.comparison.verdict == .inconclusive, let q = item.comparison.q, q < ReportStatistics.significanceLevel else { return false }
                return true
            }), let text = interval(tricky.comparison) {
                lines.append("- Example of \"significant but `inconclusive`\": \(place(tricky)): \(text), q \(ReportFormat.qValue(tricky.comparison.q!)). The difference is real (q < \(level)) but the CI reaches into the ±\(zone) zone, so it may be negligible.")
            }
        } else {
            lines.append("- **In this report:** no verdicts, because inference is unavailable (fewer than 2 replicates per ref).")
        }
        lines.append("")
        return lines
    }

    // MARK: 3. Error bars versus the band

    private func uncertaintyVersusSpread(_ withInterval: [Example]) -> [String] {
        var lines = ["### 3. Error bars are not the light band", ""]
        lines.append("- **Error bars** (and the CI columns) show the uncertainty of the *median across runs*: how much it would move if you repeated the whole measurement. More replicates make them shorter.")
        lines.append("- The **light band** shows the *spread of single iterations inside one run* (p25 to p75, the IQR). It says how steady one iteration is, and more replicates do not make it narrower.")
        lines.append("- They answer different questions: a workload can be very jittery (wide band) and still have a precisely known median (short bars), or the other way round.")
        if let example = withInterval.first(where: { model.series[$0.series].cells[$0.key]?.interval != nil }),
           let cell = model.series[example.series].cells[example.key], let ci = cell.interval {
            let unit = cell.dimension.unit(fitting: [cell.median])
            let values = [cell.median, ci.low, ci.high, cell.iqrLow, cell.iqrHigh]
            let decimals = ReportFormat.columnDecimals(values, divisor: unit.divisor)
            func shown(_ value: Double) -> String { ReportFormat.text(value, divisor: unit.divisor, columnDecimals: decimals) }
            let suffix = unit.label.isEmpty ? "" : " \(unit.label)"
            lines.append("- **Example from this report:** \(place(example)) (wall clock): median \(shown(cell.median))\(suffix); error bar (CI of the median over \(cell.replicates) replicates) \(shown(ci.low))–\(shown(ci.high))\(suffix); light band (IQR of single iterations) \(shown(cell.iqrLow))–\(shown(cell.iqrHigh))\(suffix).")
        } else {
            lines.append("- **Example:** no series has enough replicates for an error bar, so only the band (spread within a run) is drawn; inference is unavailable.")
        }
        lines.append("")
        return lines
    }

    // MARK: 4. Plots

    private func plots() -> [String] {
        [
            "### 4. Reading the plots",
            "",
            "- **Log axes** (the time plots): equal distances mean equal *ratios*, not equal differences. Going from 1 to 10 looks the same as 10 to 100. A straight line is a power law and its slope is the growth rate: slope 1 means time grows in proportion to the entity count; a flatter line grows slower.",
            "- **Per-entity plot**: time divided by the entity count. A flat line means the cost of one entity does not change with scale.",
            "- **Linear plot**: absolute time on plain axes, including entity count 0. It shows what the log plot hides: how big the differences are in absolute terms at large scale.",
            "- **Relative plot**: speed against the baseline. The dotted line at 1× is \"same as the baseline\"; the shaded band is the ±\(zone) equivalence zone; the ribbon is the CI of the speed. A series whose ribbon lies entirely above the zone is faster, entirely below slower.",
            "- **Markers**: in the time plots a *hollow* marker has no CI at that point. In the relative plot a *filled* marker is a `faster` or `slower` verdict, a hollow one anything else.",
            "- **Error bars** are drawn in a darker (light theme) or lighter (dark theme) shade of the series colour; the plot caption states the largest CI shown (\"largest CI: ±x%\"), so tiny bars are explained rather than missing.",
            ""
        ]
    }

    // MARK: 5. q

    private func adjustedP(_ all: [Example]) -> [String] {
        var lines = ["### 5. What `q` is", ""]
        let tested = all.filter { $0.comparison.p != nil }
        lines.append("- `p` is the chance of seeing a difference at least this large if the refs were truly the same. A report makes hundreds of comparisons, and at a 5% threshold about one in twenty *equal* comparisons would look significant by luck alone.")
        lines.append("- `q` is `p` adjusted for that (Benjamini–Hochberg): flagging everything with `q` < \(level) keeps the expected share of false alarms among the flagged rows at about \(level). Judge a row by `q`, never by its raw `p`.")
        if let smallest = tested.min(by: { $0.comparison.p! < $1.comparison.p! }), let q = smallest.comparison.q {
            let count = tested.count
            let luck = String(format: "%.0f", Double(count) * ReportStatistics.significanceLevel)
            lines.append("- **Example from this report:** \(count) wall-clock comparisons were tested, so unadjusted about \(luck) would pass p < \(level) by chance alone. The strongest, \(place(smallest)), has p \(ReportFormat.probability(smallest.comparison.p!).dropFirst(2)) and q \(ReportFormat.qValue(q)).")
        } else {
            lines.append("- **Example:** no test was run (fewer than 2 replicates per ref), so there is no `p` or `q` in this report; inference is unavailable.")
        }
        lines.append("")
        return lines
    }

    // MARK: 6. Replicates

    private func replicates() -> [String] {
        var lines = ["### 6. Replicates (k) and interleaving", ""]
        lines.append("- A **replicate** is one complete, independent run of a ref in its own process. `k` is how many a ref has. Iterations within one run share their warm-up, memory layout and machine state, so they are not independent evidence; the replicates are.")
        lines.append("- More replicates give narrower CIs and make verdicts possible: an interval of the median needs k ≥ 6, a speed interval about 4 per side, and the test can only reach q < \(level) with enough of them (k = 10 is the practical minimum).")
        lines.append("- Runs are **interleaved**: each round runs every ref once, in a shuffled order, instead of all runs of one ref and then all of the other. A slow minute on the machine (thermal throttling, a background job) then hits all refs alike instead of one, and the drift check can notice it.")
        let counts = model.groups.map { "\(ReportWriter.text($0.label)): \($0.fileIndices.count) of \($0.expectedReplicates)" }.joined(separator: "; ")
        lines.append("- **In this report:** replicates per ref: \(counts).")
        lines.append("")
        return lines
    }
}
