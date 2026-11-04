// The glossary section of the HTML report: a plain-language line for every abbreviation, symbol and term the generated report uses.
// Numbers that the report fixes in code (δ, the significance level, the coverage target) come from `ReportStatistics`, so the
// text cannot drift from the statistics.
import Foundation
import ECSBenchmarkResultSchema

struct ReportGlossaryEntry {
    /// Heading of the bullet.
    let term: String
    let definition: HTMLText
}

enum ReportGlossary {
    static let anchor = "glossary"
    static let guideAnchor = "how-to-read-this-report"

    private static var delta: String { ReportWriter.percent(ReportStatistics.defaultDelta) }
    private static var level: String { ReportWriter.percent(ReportStatistics.significanceLevel) }
    private static var edge: String { ReportWriter.zoneEdge }

    static var entries: [ReportGlossaryEntry] {
        [
            ReportGlossaryEntry(term: "Baseline", definition: "The ref every other ref is compared with (the first input, or the one given with <code>--baseline</code>). Its speed is 1× by definition."),
            ReportGlossaryEntry(term: "Ref", definition: "A Git tag, branch or commit of FirebladeECS that was built and measured."),
            ReportGlossaryEntry(term: "Series", definition: "One line in a plot and one block of table columns: a ref with one component model and one backend."),
            ReportGlossaryEntry(term: "Component model", definition: "How components are stored: <code>class</code> (reference types, the 1.x design) or <code>value</code> (value types, the 2.0 design)."),
            ReportGlossaryEntry(term: "Backend", definition: "The storage strategy of a ref: <code>archetype</code> packs entities with the same components together, <code>sparseSet</code> keeps one sparse set per component, <code>default</code> is a ref with a single storage."),
            ReportGlossaryEntry(term: "Entities", definition: "How many entities the workload runs with; the x axis of the plots and the rows of the tables."),
            ReportGlossaryEntry(term: "Iteration", definition: "One timed execution of the workload. <code>iterations</code> is the typical (median over replicates) number of iterations measured per replicate; it differs between series because sampling is time-based."),
            ReportGlossaryEntry(term: "Replicate, k", definition: "One independent process run of a ref. <code>k</code> is how many replicates a ref has. The replicate is the unit of analysis: iterations of one run are not independent samples. A round runs every ref once; replicates are interleaved over rounds."),
            ReportGlossaryEntry(term: "Median", definition: "The middle value: half of the values are smaller, half larger. Per replicate it is the median of its iterations; the table and the plot line show the median over replicates of those."),
            ReportGlossaryEntry(term: "Mean", definition: "The average of the iterations of a replicate (median over replicates). Descriptive only; outliers pull it."),
            ReportGlossaryEntry(term: "Percentiles p0 … p100", definition: "<code>pN</code> is the value below which N% of the iterations fall (median over replicates). p50 is the median, p25 and p75 the quartiles. For metrics where larger is better (throughput) p0 is the largest value."),
            ReportGlossaryEntry(term: "IQR, within-run spread", definition: "Interquartile range: the spread from p25 to p75 of the iterations inside one run (median over replicates). It shows how much single iterations vary, not how sure we are about the median, and is drawn as a light band in the plots."),
            ReportGlossaryEntry(term: "CI, confidence interval", definition: "A range that, with the stated probability (95% nominal; the computed coverage of each interval is printed under Methods; it is exact for medians, and for speeds exact only when no replicate medians tie, approximate otherwise), contains the true value of what it estimates. Narrow means precise, wide means uncertain. Error bars show it for medians, the ribbon for speeds."),
            ReportGlossaryEntry(term: "CI low, CI high", definition: "The lower and upper bound of the CI. Same unit as the column they belong to; <code>(×)</code> columns are ratios."),
            ReportGlossaryEntry(term: "Largest CI", definition: "In a plot legend, the biggest half-width of any error bar or ribbon shown, relative to its centre; it tells whether bars too small to see are really that small."),
            ReportGlossaryEntry(term: "Speed (×)", definition: "baseline ÷ series, so above 1 the series is faster and below 1 slower than the baseline (2× means twice as fast). Estimated with Hodges–Lehmann."),
            ReportGlossaryEntry(term: "Change (%)", definition: "The same effect as a percentage of the baseline time: (1 ÷ speed − 1) × 100. Negative means the series needs less time."),
            ReportGlossaryEntry(term: "Hodges–Lehmann, HL", definition: "A robust estimate of the typical ratio between two sets of replicate medians: the median of all pairwise ratios (baseline ÷ series). Few outliers can not move it much."),
            ReportGlossaryEntry(term: "Mann–Whitney U", definition: "A rank test that asks whether replicate medians of one ref tend to be larger than those of the other, without assuming a bell-shaped distribution. Computed exactly (no approximation)."),
            ReportGlossaryEntry(term: "p", definition: "The probability of seeing a difference at least this large if the two refs were in truth equal. Small p suggests a real difference; it does not say how large."),
            ReportGlossaryEntry(term: "q, BH", definition: "p adjusted by the Benjamini–Hochberg procedure (BH) for the many comparisons in this report, so that among everything flagged at q &lt; \(level) only about \(level) are expected to be false alarms. Use q, not p, to judge a row."),
            ReportGlossaryEntry(term: "δ, equivalence zone", definition: "The band of differences we call \"the same\": ±\(delta), that is speeds from 1/\(edge) to \(edge). Shaded in the relative plot."),
            ReportGlossaryEntry(term: "Verdict", definition: "The classification of a wall-clock comparison; one of <code>faster</code>, <code>slower</code>, <code>equivalent</code>, <code>inconclusive</code> or <code>n/a</code>."),
            ReportGlossaryEntry(term: "faster, slower", definition: "q &lt; \(level) and the whole CI of the speed lies outside the ±\(delta) zone: above \(edge) for faster, below 1/\(edge) for slower."),
            ReportGlossaryEntry(term: "equivalent", definition: "The whole CI of the speed lies inside the ±\(delta) zone: any difference is smaller than we care about."),
            ReportGlossaryEntry(term: "inconclusive", definition: "Neither: the data allow a difference larger than the zone as well as none (for example the CI crosses the zone edge, or q is not below \(level))."),
            ReportGlossaryEntry(term: "n/a (k replicates)", definition: "Not available. <code>n/a (k replicates)</code> means a side has fewer than 2 replicates, too few for an interval, test or verdict. <code>n/a</code> in a throughput cell means the benchmark package did not record the metric: Benchmark 1.38.1 records throughput only above 0 operations per second, so an iteration of about 2 s or longer has none (hover for the reason stated by the result file). <code>unavailable</code> marks a missing or non-comparable value (hover for the reason: not measured, no measurements, incompatible units, zero median, no estimate). It is never zero."),
            ReportGlossaryEntry(term: "Kendall τ, drift", definition: "Kendall's rank correlation between round and replicate median. A significant τ means results moved over the course of the session (warm-up, thermal throttling, a background job); the Methods section lists the cells where that happened."),
            ReportGlossaryEntry(term: "Wall clock", definition: "Elapsed real time per iteration. The only metric that is plotted and tested."),
            ReportGlossaryEntry(term: "CPU total", definition: "CPU time (user plus system) used per iteration; can exceed wall clock when several threads run."),
            ReportGlossaryEntry(term: "Throughput", definition: "Iterations per second; larger is better. Units: ops/s, Kops/s (thousands), Mops/s (millions)."),
            ReportGlossaryEntry(term: "Peak RSS", definition: "Resident set size: the largest amount of physical memory the process held (kB, MB, GB)."),
            ReportGlossaryEntry(term: "Malloc count", definition: "How many heap allocations an iteration made; fewer is better."),
            ReportGlossaryEntry(term: "Per entity, total", definition: "<code>per-entity</code> divides the time by the entity count (cost of one entity); <code>total</code> is the time of the whole iteration."),
            ReportGlossaryEntry(term: "Log and linear axes", definition: "On a log axis equal distances mean equal ratios and a straight line is a power law whose slope is the growth rate; log2 doubles per step, log10 multiplies by ten. A linear axis shows absolute differences and also entity count 0 (except in the per-entity plot, which never shows it)."),
            ReportGlossaryEntry(term: "Markers", definition: "In the time plots a hollow marker has no CI at that point. In the relative plot a filled marker is a significant <code>faster</code> or <code>slower</code>, a hollow one anything else."),
            ReportGlossaryEntry(term: "Units", definition: "ns, μs, ms, s are nanoseconds, microseconds, milliseconds and seconds; B, kB, MB, GB bytes; K, M, G thousand, million and billion (counts); each column states its unit in the header.")
        ]
    }

    static func blocks() -> [ReportBlock] {
        [
            .heading(2, "Glossary", id: anchor),
            .paragraph("Every abbreviation and term of this report, in plain language. Column units are stated in each table header."),
            .list(entries.map { "<strong>\($0.term)</strong>: \($0.definition)" })
        ]
    }
}
