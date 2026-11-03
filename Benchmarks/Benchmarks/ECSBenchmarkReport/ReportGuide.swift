// The "How to read this report" section of the HTML report: static plain-language explanations for readers who are not
// statisticians. The worked examples use generic illustrative numbers that are clearly marked as such; none of them comes from the
// report being rendered.
import Foundation
import ECSBenchmarkResultSchema

enum ReportGuide {
    private static var delta: Double { ReportStatistics.defaultDelta }
    private static var level: String { ReportWriter.percent(ReportStatistics.significanceLevel) }
    private static var zone: String { ReportWriter.percent(delta) }

    static func blocks() -> [ReportBlock] {
        [
            .heading(2, "How to read this report", id: ReportGlossary.guideAnchor),
            .paragraph("Short version: look at <code>speed (×)</code> (above 1 the series is faster than the baseline), check that its CI is narrow, and read the <code>verdict</code>. Words in <code>code</code> style are defined in the <a href=\"#\(ReportGlossary.anchor)\">glossary</a>. All numbers in the examples below are made up for illustration; they are not taken from this report.")
        ] + confidenceInterval() + verdicts() + uncertaintyVersusSpread() + plots() + adjustedP() + replicates()
    }

    private static func confidenceInterval() -> [ReportBlock] {
        [
            .heading(3, "1. What a confidence interval is"),
            .list([
                "Every number here is measured with noise, so a single speed such as 2.0× could have come out 1.9× or 2.1× in another session. The <strong>confidence interval (CI)</strong> is the range that, with 95% confidence (nominal; the computed coverage is in the methods; speed intervals are exact only when no replicate medians tie, approximate otherwise), contains the true value.",
                "The <strong>median</strong> is the middle value of the iterations of one run; the report compares medians because a few slow outliers do not move them. <code>speed (×)</code> is the baseline median divided by the series median.",
                "<code>CI low</code> and <code>CI high</code> are the two ends of the CI. Read the pair as \"the truth is very likely between these\".",
                "<strong>Narrow</strong> CI: the estimate is precise, you can trust the digits you see. <strong>Wide</strong> CI: the data cannot pin the value down; look for more replicates before drawing a conclusion.",
                "<strong>Illustrative example (not from this report):</strong> speed 2.00×, CI 1.90–2.10× → the true speedup is very likely between 1.90× and 2.10×. A CI of 1.20–3.40× around the same speed would say much less."
            ])
        ]
    }

    private static func verdicts() -> [ReportBlock] {
        [
            .heading(3, "2. How the verdict is decided"),
            .paragraph("A verdict is given only for wall clock and only when both refs have at least 2 replicates. The exact rule for <code>faster</code>, <code>slower</code>, <code>equivalent</code>, <code>inconclusive</code> and <code>n/a (k replicates)</code> is in the \(anchor: ReportGlossary.anchor, "glossary"). In short: a significant test is not enough, the whole CI must also be clear of the equivalence zone, otherwise the honest answer is \"cannot tell yet\"."),
            .list([
                "<strong>Illustrative examples (not from this report):</strong> speed 2.00×, CI 1.90–2.10×, q 0.001 is <code>faster</code>. Speed 1.00×, CI 0.98–1.02× is <code>equivalent</code>. Speed 1.30×, CI 1.02–1.58×, q 0.01 is <code>inconclusive</code>: the difference is real (q &lt; \(level)) but the CI reaches into the ±\(zone) zone, so it may be negligible."
            ])
        ]
    }

    private static func uncertaintyVersusSpread() -> [ReportBlock] {
        [
            .heading(3, "3. Error bars are not the light band"),
            .list([
                "<strong>Error bars</strong> (and the CI columns) show the uncertainty of the <em>median across runs</em>: how much it would move if you repeated the whole measurement. More replicates make them shorter.",
                "The <strong>light band</strong> shows the <em>spread of single iterations inside one run</em> (p25 to p75, the IQR). It says how steady one iteration is, and more replicates do not make it narrower.",
                "They answer different questions: a workload can be very jittery (wide band) and still have a precisely known median (short bars), or the other way round.",
                "<strong>Illustrative example (not from this report):</strong> median 100 µs; error bar 98–102 µs; light band 80–130 µs. The median is known to about ±2%, while single iterations vary a lot."
            ])
        ]
    }

    private static func plots() -> [ReportBlock] {
        [
            .heading(3, "4. Reading the plots"),
            .list([
                "<strong>Log axes</strong> (the time plots): equal distances mean equal <em>ratios</em>, not equal differences. Going from 1 to 10 looks the same as 10 to 100. A straight line is a power law and its slope is the growth rate: slope 1 means time grows in proportion to the entity count; a flatter line grows slower.",
                "<strong>Per-entity plot</strong>: time divided by the entity count. A flat line means the cost of one entity does not change with scale.",
                "<strong>Log / Linear toggle</strong>: every plot has its own toggle, and one toggle at the top switches all plots. Linear shows absolute time on plain axes, including entity count 0 (except in the per-entity plot, which never shows it); it shows what the log plot hides: how big the differences are in absolute terms at large scale.",
                "<strong>Hover or focus</strong>: pointing at a data point (or tabbing to it) shows its ref, backend, entity count, median, CI and speed with verdict, draws lines to both axes with the values, and highlights the matching table row.",
                "<strong>Relative plot</strong>: speed against the baseline. The dotted line at 1× is \"same as the baseline\"; the shaded band is the ±\(zone) equivalence zone; the ribbon is the CI of the speed. A series whose ribbon lies entirely above the zone is faster, entirely below slower.",
                "<strong>Markers</strong>: in the time plots a <em>hollow</em> marker has no CI at that point. In the relative plot a <em>filled</em> marker is a <code>faster</code> or <code>slower</code> verdict, a hollow one anything else.",
                "<strong>Error bars</strong> are drawn in a darker (light theme) or lighter (dark theme) shade of the series colour; the plot caption states the largest CI shown (\"largest CI: ±x%\"), so tiny bars are explained rather than missing."
            ])
        ]
    }

    private static func adjustedP() -> [ReportBlock] {
        [
            .heading(3, "5. What <code>q</code> is"),
            .list([
                "<code>p</code> is the chance of seeing a difference at least this large if the refs were truly the same. A report makes hundreds of comparisons, and at a 5% threshold about one in twenty <em>equal</em> comparisons would look significant by luck alone.",
                "<code>q</code> is <code>p</code> adjusted for that (Benjamini–Hochberg): flagging everything with <code>q</code> &lt; \(level) keeps the expected share of false alarms among the flagged rows at about \(level). Judge a row by <code>q</code>, never by its raw <code>p</code>.",
                "<strong>Illustrative example (not from this report):</strong> with 200 comparisons, about 10 would pass p &lt; \(level) by chance alone, so a row with p 0.04 usually has a <code>q</code> well above \(level) and is not flagged."
            ])
        ]
    }

    private static func replicates() -> [ReportBlock] {
        [
            .heading(3, "6. Replicates (k) and interleaving"),
            .list([
                "A <strong>replicate</strong> is one complete, independent run of a ref in its own process. <code>k</code> is how many a ref has. Iterations within one run share their warm-up, memory layout and machine state, so they are not independent evidence; the replicates are.",
                "More replicates give narrower CIs and make verdicts possible: an interval of the median needs k ≥ 6, a speed interval about 4 per side, and the test can only reach q &lt; \(level) with enough of them (k = 10 is the practical minimum).",
                "Runs are <strong>interleaved</strong>: each round runs every ref once, in a shuffled order, instead of all runs of one ref and then all of the other. A slow minute on the machine (thermal throttling, a background job) then hits all refs alike instead of one, and the drift check can notice it.",
                "The replicates per ref of this report are listed in the provenance section."
            ])
        ]
    }
}
