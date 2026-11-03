// The "How to read this report" section of the HTML report: static plain-language explanations for readers who are not
// statisticians. The worked examples use generic illustrative numbers that are clearly marked as such; none of them comes from the
// report being rendered.
import Foundation

enum ReportGuide {
    private static var delta: Double { ReportStatistics.defaultDelta }
    private static var level: String { ReportWriter.percent(ReportStatistics.significanceLevel) }
    private static var zone: String { ReportWriter.percent(delta) }
    private static var upperEdge: String { String(format: "%g", 1 + delta) }

    static func lines() -> [String] {
        var lines = ["## How to read this report", ""]
        lines.append("Short version: look at `speed (×)` (above 1 the series is faster than the baseline), check that its CI is narrow, and read the `verdict`. Words in `code` style are defined in the [glossary](#\(ReportGlossary.anchor)). All numbers in the examples below are made up for illustration; they are not taken from this report.")
        lines.append("")
        lines += confidenceInterval()
        lines += verdicts()
        lines += uncertaintyVersusSpread()
        lines += plots()
        lines += adjustedP()
        lines += replicates()
        return lines
    }

    private static func confidenceInterval() -> [String] {
        [
            "### 1. What a confidence interval is",
            "",
            "- Every number here is measured with noise, so a single speed such as 2.0× could have come out 1.9× or 2.1× in another session. The **confidence interval (CI)** is the range that, with 95% confidence (nominal; the computed coverage is in the methods; speed intervals are exact only when no replicate medians tie, approximate otherwise), contains the true value.",
            "- The **median** is the middle value of the iterations of one run; the report compares medians because a few slow outliers do not move them. `speed (×)` is the baseline median divided by the series median.",
            "- `CI low` and `CI high` are the two ends of the CI. Read the pair as \"the truth is very likely between these\".",
            "- **Narrow** CI: the estimate is precise, you can trust the digits you see. **Wide** CI: the data cannot pin the value down; look for more replicates before drawing a conclusion.",
            "- **Illustrative example (not from this report):** speed 2.00×, CI 1.90–2.10× → the true speedup is very likely between 1.90× and 2.10×. A CI of 1.20–3.40× around the same speed would say much less.",
            ""
        ]
    }

    private static func verdicts() -> [String] {
        [
            "### 2. How the verdict is decided",
            "",
            "A verdict is given only for wall clock and only when both refs have at least 2 replicates. We call differences smaller than ±\(zone) \"the same\" (the **equivalence zone**, speeds from 1/\(upperEdge) to \(upperEdge)).",
            "- `faster` / `slower`: the test is significant (`q` < \(level)) **and** the whole CI is outside the zone (above \(upperEdge), or below 1/\(upperEdge)).",
            "- `equivalent`: the whole CI is inside the zone, so any real difference is smaller than ±\(zone).",
            "- `inconclusive`: everything else. A significant test is not enough: if the CI still overlaps the zone, the effect could be smaller than \(zone) and not worth acting on, so the honest answer is \"cannot tell yet\".",
            "- `n/a (k replicates)`: a side has fewer than 2 replicates, so there is no CI, `q` or verdict.",
            "- **Illustrative examples (not from this report):** speed 2.00×, CI 1.90–2.10×, q 0.001 is `faster`. Speed 1.00×, CI 0.98–1.02× is `equivalent`. Speed 1.30×, CI 1.02–1.58×, q 0.01 is `inconclusive`: the difference is real (q < \(level)) but the CI reaches into the ±\(zone) zone, so it may be negligible.",
            ""
        ]
    }

    private static func uncertaintyVersusSpread() -> [String] {
        [
            "### 3. Error bars are not the light band",
            "",
            "- **Error bars** (and the CI columns) show the uncertainty of the *median across runs*: how much it would move if you repeated the whole measurement. More replicates make them shorter.",
            "- The **light band** shows the *spread of single iterations inside one run* (p25 to p75, the IQR). It says how steady one iteration is, and more replicates do not make it narrower.",
            "- They answer different questions: a workload can be very jittery (wide band) and still have a precisely known median (short bars), or the other way round.",
            "- **Illustrative example (not from this report):** median 100 µs; error bar 98–102 µs; light band 80–130 µs. The median is known to about ±2%, while single iterations vary a lot.",
            ""
        ]
    }

    private static func plots() -> [String] {
        [
            "### 4. Reading the plots",
            "",
            "- **Log axes** (the time plots): equal distances mean equal *ratios*, not equal differences. Going from 1 to 10 looks the same as 10 to 100. A straight line is a power law and its slope is the growth rate: slope 1 means time grows in proportion to the entity count; a flatter line grows slower.",
            "- **Per-entity plot**: time divided by the entity count. A flat line means the cost of one entity does not change with scale.",
            "- **Log / Linear toggle**: every plot has its own toggle, and one toggle at the top switches all plots. Linear shows absolute time on plain axes, including entity count 0; it shows what the log plot hides: how big the differences are in absolute terms at large scale.",
            "- **Hover or focus**: pointing at a data point (or tabbing to it) shows its ref, backend, entity count, median, CI and speed with verdict, draws lines to both axes with the values, and highlights the matching table row.",
            "- **Relative plot**: speed against the baseline. The dotted line at 1× is \"same as the baseline\"; the shaded band is the ±\(zone) equivalence zone; the ribbon is the CI of the speed. A series whose ribbon lies entirely above the zone is faster, entirely below slower.",
            "- **Markers**: in the time plots a *hollow* marker has no CI at that point. In the relative plot a *filled* marker is a `faster` or `slower` verdict, a hollow one anything else.",
            "- **Error bars** are drawn in a darker (light theme) or lighter (dark theme) shade of the series colour; the plot caption states the largest CI shown (\"largest CI: ±x%\"), so tiny bars are explained rather than missing.",
            ""
        ]
    }

    private static func adjustedP() -> [String] {
        [
            "### 5. What `q` is",
            "",
            "- `p` is the chance of seeing a difference at least this large if the refs were truly the same. A report makes hundreds of comparisons, and at a 5% threshold about one in twenty *equal* comparisons would look significant by luck alone.",
            "- `q` is `p` adjusted for that (Benjamini–Hochberg): flagging everything with `q` < \(level) keeps the expected share of false alarms among the flagged rows at about \(level). Judge a row by `q`, never by its raw `p`.",
            "- **Illustrative example (not from this report):** with 200 comparisons, about 10 would pass p < \(level) by chance alone, so a row with p 0.04 usually has a `q` well above \(level) and is not flagged.",
            ""
        ]
    }

    private static func replicates() -> [String] {
        [
            "### 6. Replicates (k) and interleaving",
            "",
            "- A **replicate** is one complete, independent run of a ref in its own process. `k` is how many a ref has. Iterations within one run share their warm-up, memory layout and machine state, so they are not independent evidence; the replicates are.",
            "- More replicates give narrower CIs and make verdicts possible: an interval of the median needs k ≥ 6, a speed interval about 4 per side, and the test can only reach q < \(level) with enough of them (k = 10 is the practical minimum).",
            "- Runs are **interleaved**: each round runs every ref once, in a shuffled order, instead of all runs of one ref and then all of the other. A slow minute on the machine (thermal throttling, a background job) then hits all refs alike instead of one, and the drift check can notice it.",
            "- The replicates per ref of this report are listed in the provenance section.",
            ""
        ]
    }
}
