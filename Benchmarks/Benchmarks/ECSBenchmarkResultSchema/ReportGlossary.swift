// The glossary section of REPORT.md: a plain-language line for every abbreviation, symbol and term the generated report uses.
// Numbers that the report fixes in code (δ, the significance level, the coverage target) come from `ReportStatistics`, so the
// text cannot drift from the statistics. `covers` is what the tests use to prove that every table header and legend term is defined.
import Foundation

struct ReportGlossaryEntry {
    /// Heading of the bullet.
    let term: String
    /// Every spelling that appears in headers, legends, verdict cells or plot notes and is defined by this entry.
    let names: [String]
    let definition: String
}

enum ReportGlossary {
    static let anchor = "glossary"
    static let guideAnchor = "how-to-read-this-report"

    private static var delta: String { ReportWriter.percent(ReportStatistics.defaultDelta) }
    private static var level: String { ReportWriter.percent(ReportStatistics.significanceLevel) }
    private static var edge: String { String(format: "%g", 1 + ReportStatistics.defaultDelta) }

    static var entries: [ReportGlossaryEntry] {
        [
            ReportGlossaryEntry(term: "Baseline", names: ["baseline", "(baseline)", "baseline ÷ series"], definition: "The ref every other ref is compared with (the first input, or the one given with `--baseline`). Its speed is 1× by definition."),
            ReportGlossaryEntry(term: "Ref", names: ["ref"], definition: "A Git tag, branch or commit of FirebladeECS that was built and measured."),
            ReportGlossaryEntry(term: "Series", names: ["series"], definition: "One line in a plot and one block of table columns: a ref with one component model and one backend."),
            ReportGlossaryEntry(term: "Component model", names: ["component model", "class", "value"], definition: "How components are stored: `class` (reference types, the 1.x design) or `value` (value types, the 2.0 design)."),
            ReportGlossaryEntry(term: "Backend", names: ["backend", "sparseSet", "archetype", "default"], definition: "The storage strategy of a ref: `archetype` packs entities with the same components together, `sparseSet` keeps one sparse set per component, `default` is a ref with a single storage."),
            ReportGlossaryEntry(term: "Entities", names: ["entities", "entity count", "scale"], definition: "How many entities the workload runs with; the x axis of the plots and the rows of the tables."),
            ReportGlossaryEntry(term: "Iteration", names: ["iteration", "iterations"], definition: "One timed execution of the workload. `iterations` is the typical (median over replicates) number of iterations measured per replicate; it differs between series because sampling is time-based."),
            ReportGlossaryEntry(term: "Replicate, k", names: ["replicate", "replicates", "k", "round"], definition: "One independent process run of a ref. `k` is how many replicates a ref has. The replicate is the unit of analysis: iterations of one run are not independent samples. A round runs every ref once; replicates are interleaved over rounds."),
            ReportGlossaryEntry(term: "Median", names: ["median"], definition: "The middle value: half of the values are smaller, half larger. Per replicate it is the median of its iterations; the table and the plot line show the median over replicates of those."),
            ReportGlossaryEntry(term: "Mean", names: ["mean"], definition: "The average of the iterations of a replicate (median over replicates). Descriptive only; outliers pull it."),
            ReportGlossaryEntry(term: "Percentiles p0 … p100", names: ["p0", "p1", "p5", "p10", "p25", "p50", "p75", "p90", "p99", "p100", "percentile", "percentiles"], definition: "`pN` is the value below which N% of the iterations fall (median over replicates). p50 is the median, p25 and p75 the quartiles. For metrics where larger is better (throughput) p0 is the largest value."),
            ReportGlossaryEntry(term: "IQR, within-run spread", names: ["IQR", "within-run IQR", "within-run spread", "light band", "band"], definition: "Interquartile range: the spread from p25 to p75 of the iterations inside one run (median over replicates). It shows how much single iterations vary, not how sure we are about the median, and is drawn as a light band in the plots."),
            ReportGlossaryEntry(term: "CI, confidence interval", names: ["CI", "confidence interval", "error bar", "error bars", "ribbon"], definition: "A range that, with the stated probability (95% nominal; the exact coverage of each interval is printed under Methods, never less than 95%), contains the true value of what it estimates. Narrow means precise, wide means uncertain. Error bars show it for medians, the ribbon for speeds."),
            ReportGlossaryEntry(term: "CI low, CI high", names: ["CI low", "CI high", "CI low (×)", "CI high (×)", "lower bound", "upper bound"], definition: "The lower and upper bound of the CI. Same unit as the column they belong to; `(×)` columns are ratios."),
            ReportGlossaryEntry(term: "Largest CI", names: ["largest CI"], definition: "In a plot legend, the biggest half-width of any error bar or ribbon shown, relative to its centre; it tells whether bars too small to see are really that small."),
            ReportGlossaryEntry(term: "Speed (×)", names: ["speed", "speed (×)", "×"], definition: "baseline ÷ series, so above 1 the series is faster and below 1 slower than the baseline (2× means twice as fast). Estimated with Hodges–Lehmann."),
            ReportGlossaryEntry(term: "Change (%)", names: ["change", "change (%)"], definition: "The same effect as a percentage of the baseline time: (1 ÷ speed − 1) × 100. Negative means the series needs less time."),
            ReportGlossaryEntry(term: "Hodges–Lehmann, HL", names: ["Hodges–Lehmann", "HL"], definition: "A robust estimate of the typical ratio between two sets of replicate medians: the median of all pairwise ratios (baseline ÷ series). Few outliers can not move it much."),
            ReportGlossaryEntry(term: "Mann–Whitney U", names: ["Mann–Whitney", "Mann–Whitney U", "U"], definition: "A rank test that asks whether replicate medians of one ref tend to be larger than those of the other, without assuming a bell-shaped distribution. Computed exactly (no approximation)."),
            ReportGlossaryEntry(term: "p", names: ["p", "p-value"], definition: "The probability of seeing a difference at least this large if the two refs were in truth equal. Small p suggests a real difference; it does not say how large."),
            ReportGlossaryEntry(term: "q, BH", names: ["q", "BH", "Benjamini–Hochberg"], definition: "p adjusted by the Benjamini–Hochberg procedure (BH) for the many comparisons in this report, so that among everything flagged at q < \(level) only about \(level) are expected to be false alarms. Use q, not p, to judge a row."),
            ReportGlossaryEntry(term: "δ, equivalence zone", names: ["δ", "delta", "equivalence zone", "zone", "shaded zone"], definition: "The band of differences we call \"the same\": ±\(delta), that is speeds from 1/\(edge) to \(edge). Shaded in the relative plot."),
            ReportGlossaryEntry(term: "Verdict", names: ["verdict", "verdicts"], definition: "The classification of a wall-clock comparison; one of `faster`, `slower`, `equivalent`, `inconclusive` or `n/a`."),
            ReportGlossaryEntry(term: "faster, slower", names: ["faster", "slower"], definition: "q < \(level) and the whole CI of the speed lies outside the ±\(delta) zone: above \(edge) for faster, below 1/\(edge) for slower."),
            ReportGlossaryEntry(term: "equivalent", names: ["equivalent"], definition: "The whole CI of the speed lies inside the ±\(delta) zone: any difference is smaller than we care about."),
            ReportGlossaryEntry(term: "inconclusive", names: ["inconclusive"], definition: "Neither: the data allow a difference larger than the zone as well as none (for example the CI crosses the zone edge, or q is not below \(level))."),
            ReportGlossaryEntry(term: "n/a (k replicates)", names: ["n/a", "n/a (1 replicate)", "n/a (0 replicates)", "unavailable"], definition: "Not available. `n/a (k replicates)` means a side has fewer than 2 replicates, too few for an interval, test or verdict. `unavailable` marks a missing or non-comparable value (hover for the reason: not measured, no measurements, incompatible units, zero median, no estimate). It is never zero."),
            ReportGlossaryEntry(term: "Kendall τ, drift", names: ["Kendall τ", "τ", "drift"], definition: "Kendall's rank correlation between round and replicate median. A significant τ means results moved over the course of the session (warm-up, thermal throttling, a background job); the Methods section lists the cells where that happened."),
            ReportGlossaryEntry(term: "Wall clock", names: ["wall clock", "Time (wall clock)"], definition: "Elapsed real time per iteration. The only metric that is plotted and tested."),
            ReportGlossaryEntry(term: "CPU total", names: ["cpu total", "Time (total CPU)", "total CPU"], definition: "CPU time (user plus system) used per iteration; can exceed wall clock when several threads run."),
            ReportGlossaryEntry(term: "Throughput", names: ["throughput", "Throughput (# / s)", "ops/s"], definition: "Iterations per second; larger is better. Units: ops/s, Kops/s (thousands), Mops/s (millions)."),
            ReportGlossaryEntry(term: "Peak RSS", names: ["peak RSS", "RSS", "Memory (resident peak)", "resident peak"], definition: "Resident set size: the largest amount of physical memory the process held (kB, MB, GB)."),
            ReportGlossaryEntry(term: "Malloc count", names: ["malloc count", "Malloc (total)", "malloc"], definition: "How many heap allocations an iteration made; fewer is better."),
            ReportGlossaryEntry(term: "Per entity, total", names: ["per-entity", "per entity", "total"], definition: "`per-entity` divides the time by the entity count (cost of one entity); `total` is the time of the whole iteration."),
            ReportGlossaryEntry(term: "Log and linear axes", names: ["log axis", "log scale", "log2 scale", "log10 scale", "linear scale", "linear axes", "log-log"], definition: "On a log axis equal distances mean equal ratios and a straight line is a power law whose slope is the growth rate; log2 doubles per step, log10 multiplies by ten. A linear axis shows absolute differences and also entity count 0."),
            ReportGlossaryEntry(term: "Markers", names: ["filled marker", "hollow marker", "marker"], definition: "In the time plots a hollow marker has no CI at that point. In the relative plot a filled marker is a significant `faster` or `slower`, a hollow one anything else."),
            ReportGlossaryEntry(term: "Units", names: ["ns", "μs", "ms", "s", "B", "kB", "MB", "GB", "K", "M", "G", "Kops/s", "Mops/s", "Gops/s"], definition: "ns, μs, ms, s are nanoseconds, microseconds, milliseconds and seconds; B, kB, MB, GB bytes; K, M, G thousand, million and billion (counts); each column states its unit in the header.")
        ]
    }

    /// True when `label` (a table column header, legend term or verdict cell) is defined by an entry. Unit suffixes in parentheses
    /// ("median (ms)") are ignored; the whole label and the label without the suffix are both tried.
    static func covers(_ label: String) -> Bool {
        let all = Set(entries.flatMap(\.names).map { $0.lowercased() })
        let lowered = label.lowercased()
        if all.contains(lowered) { return true }
        if let open = lowered.range(of: " (", options: .backwards), lowered.hasSuffix(")"), all.contains(String(lowered[..<open.lowerBound])) { return true }
        if lowered.range(of: #"^p\d+$"#, options: .regularExpression) != nil { return all.contains("p0") }
        if lowered.hasPrefix("n/a (") { return all.contains("n/a") }
        return false
    }

    static func lines() -> [String] {
        var lines = ["## Glossary", ""]
        lines.append("Every abbreviation and term of this report, in plain language. Column units are stated in each table header.")
        lines.append("")
        for entry in entries {
            lines.append("- **\(ReportWriter.text(entry.term))**: \(entry.definition)")
        }
        lines.append("")
        return lines
    }
}
