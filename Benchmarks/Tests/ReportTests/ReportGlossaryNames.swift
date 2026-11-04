import Foundation
@testable import ECSBenchmarkReport

extension ReportGlossary {
    // Test-only: every spelling that appears in headers, legends, verdict cells or plot notes and is defined by the glossary entry of that term.
    // The tests use it to prove that every table header and legend term is defined; the production report only prints the entries.
    static let names: [String: [String]] = [
        "Baseline": ["baseline", "(baseline)", "baseline ÷ series"],
        "Ref": ["ref"],
        "Series": ["series"],
        "Component model": ["component model", "class", "value"],
        "Backend": ["backend", "sparseSet", "archetype", "default"],
        "Entities": ["entities", "entity count", "scale"],
        "Iteration": ["iteration", "iterations"],
        "Replicate, k": ["replicate", "replicates", "k", "round"],
        "Median": ["median"],
        "Mean": ["mean"],
        "Percentiles p0 … p100": ["p0", "p1", "p5", "p10", "p25", "p50", "p75", "p90", "p99", "p100", "percentile", "percentiles"],
        "IQR, within-run spread": ["IQR", "within-run IQR", "within-run spread", "light band", "band"],
        "CI, confidence interval": ["CI", "confidence interval", "error bar", "error bars", "ribbon"],
        "CI low, CI high": ["CI low", "CI high", "CI low (×)", "CI high (×)", "lower bound", "upper bound"],
        "Largest CI": ["largest CI"],
        "Speed (×)": ["speed", "speed (×)", "×"],
        "Change (%)": ["change", "change (%)"],
        "Hodges–Lehmann, HL": ["Hodges–Lehmann", "HL"],
        "Mann–Whitney U": ["Mann–Whitney", "Mann–Whitney U", "U"],
        "p": ["p", "p-value"],
        "q, BH": ["q", "BH", "Benjamini–Hochberg"],
        "δ, equivalence zone": ["δ", "delta", "equivalence zone", "zone", "shaded zone"],
        "Verdict": ["verdict", "verdicts"],
        "faster, slower": ["faster", "slower"],
        "equivalent": ["equivalent"],
        "inconclusive": ["inconclusive"],
        "n/a (k replicates)": ["n/a", "n/a (1 replicate)", "n/a (0 replicates)", "unavailable"],
        "Kendall τ, drift": ["Kendall τ", "τ", "drift"],
        "Wall clock": ["wall clock", "Time (wall clock)"],
        "CPU total": ["cpu total", "Time (total CPU)", "total CPU"],
        "Throughput": ["throughput", "Throughput (# / s)", "ops/s"],
        "Peak RSS": ["peak RSS", "RSS", "Memory (resident peak)", "resident peak"],
        "Malloc count": ["malloc count", "Malloc (total)", "malloc"],
        "Per entity, total": ["per-entity", "per entity", "total"],
        "Log and linear axes": ["log axis", "log scale", "log2 scale", "log10 scale", "linear scale", "linear axes", "log-log"],
        "Markers": ["filled marker", "hollow marker", "marker"],
        "Units": ["ns", "μs", "ms", "s", "B", "kB", "MB", "GB", "K", "M", "G", "Kops/s", "Mops/s", "Gops/s"]
    ]
}
