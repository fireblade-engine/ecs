// HTML rendering of a `ReportModel` into the single self-contained file `BenchmarkReport.html` (Methodology.md "Report v2 design"
// and "Statistical design v3"). Statistics come from `ReportInference`; this file only formats them. The page holds inline CSS and
// script, the tables as static HTML, and the plot data as embedded JSON; the script draws the plots in the browser.
import Benchmark
import Foundation

struct ReportWriter {
    let model: ReportModel
    let title: String
    /// Pending prose in the Markdown subset of `ReportMarkup`; flushed into `body` whenever a table or raw HTML is emitted.
    private var lines: [String] = []
    private var body: [String] = []
    private var anchors = true
    private var ids: [String: String] = [:]

    /// Entity counts up to this value go into the small table, the rest into the large one (as upstream splits its tables).
    static let smallLimit = 1024
    static let summaryScales = [1024, 65536]

    init(model: ReportModel, title: String) {
        self.model = model
        self.title = title
    }

    /// The complete HTML document.
    mutating func render() throws -> String {
        let identities = Array(Set(model.keys.map(\.identity))).sorted()
        var ids: [String: String] = [:]
        var used = Set<String>()
        for identity in identities {
            var name = "w-" + Self.fileName(identity)
            while !used.insert(name).inserted { name += "_" }
            ids[identity] = name
        }
        self.ids = ids
        body = []
        lines = []
        header()
        warnings()
        summary(identities, ids)
        lines += ReportGuide(model: model).lines()
        workloads(identities, ids)
        lines += ReportGlossary.lines()
        methods()
        provenance()
        pairing()
        parityNotes()
        flush()

        let payload = ReportPlotPayload(title: title, baseline: model.groups[model.baselineGroup].label, delta: ReportStatistics.defaultDelta, workloads: identities.map { plotWorkload($0, ids[$0]!) })
        return try document(identities, ids, payload)
    }

    /// File-system safe version of a workload identity.
    static func fileName(_ identity: String) -> String {
        String(identity.unicodeScalars.map { scalar in
            (scalar.isASCII && (CharacterSet.alphanumerics.contains(scalar) || "-_.".unicodeScalars.contains(scalar))) ? Character(scalar) : "_"
        })
    }

    // MARK: Document

    private func document(_ identities: [String], _ ids: [String: String], _ payload: ReportPlotPayload) throws -> String {
        let e = ReportMarkup.escape
        var out: [String] = []
        out.append("<!doctype html>")
        out.append("<html lang=\"en\">")
        out.append("<head>")
        out.append("<meta charset=\"utf-8\">")
        out.append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">")
        out.append("<meta name=\"color-scheme\" content=\"light dark\">")
        out.append("<title>\(e(title))</title>")
        out.append("<style>")
        out.append(ReportStyle.css)
        out.append("</style>")
        out.append("</head>")
        out.append("<body>")
        out.append("<div class=\"bar\"><div class=\"bar-inner\"><div id=\"global-toggle\" hidden></div><span class=\"muted\">Hover or focus a point for its values; the matching table row is highlighted.</span></div></div>")
        out.append("<header class=\"top\">")
        out.append("<h1>\(e(title))</h1>")
        out.append(facts())
        out.append("</header>")
        out.append("<nav class=\"toc\" aria-label=\"Contents\">")
        out.append("<p class=\"jump\">Jump to: " + [("summary", "Summary"), (ReportGlossary.guideAnchor, "How to read this report"), ("workloads", "Workloads"), (ReportGlossary.anchor, "Glossary"), ("methods", "Methods"), ("provenance", "Provenance")]
            .map { "<a href=\"#\($0.0)\">\(e($0.1))</a>" }.joined(separator: " · ") + "</p>")
        out.append("<ul>")
        for identity in identities {
            out.append("<li><a href=\"#\(e(ids[identity]!))\"><code>\(e(Self.code(identity)))</code></a></li>")
        }
        out.append("</ul>")
        out.append("</nav>")
        out.append("<main>")
        out.append("<noscript><p class=\"muted\">The plots need JavaScript; every number is also in the tables.</p></noscript>")
        out += body
        out.append("</main>")
        out.append("<script type=\"application/json\" id=\"report-data\">\(try payload.json())</script>")
        out.append("<script>")
        out.append(ReportScript.source)
        out.append("</script>")
        out.append("</body>")
        out.append("</html>")
        return out.joined(separator: "\n") + "\n"
    }

    /// Facts of the run as a grid of small cards.
    private func facts() -> String {
        let e = ReportMarkup.escape
        func distinct(_ values: [String]) -> String { values.uniqued().joined(separator: "; ") }
        let files = model.files
        let baseline = model.groups[model.baselineGroup]
        var items: [(String, String)] = []
        items.append(("Baseline", "\(baseline.label) (\(baseline.sha))"))
        items.append(("Refs", model.groups.map { "\($0.label) [\($0.componentModel)] \($0.sha.prefix(12))" }.joined(separator: "; ")))
        items.append(("Replicates (k) per ref", replicateSummary))
        let starts = files.map(\.run.startedAt).min() ?? "", finishes = files.map(\.run.finishedAt).max() ?? ""
        items.append(("Runs", "\(files.count) result files, \(starts) to \(finishes)"))
        let batches = Set(files.compactMap(\.run.batchId)).sorted()
        items.append(("Batch (run id)", batches.isEmpty ? "none recorded" : batches.joined(separator: ", ")))
        let seeds = Set(files.compactMap { $0.run.replicate?.seed }).sorted()
        items.append(("Seed", seeds.isEmpty ? "none recorded" : seeds.map(String.init).joined(separator: ", ")))
        items.append(("Host", distinct(files.map { "\($0.host.osName) \($0.host.osVersion), \($0.host.architecture), \($0.host.cpuModel), \($0.host.coreCount) cores" })))
        items.append(("Toolchain", distinct(files.map { "\($0.toolchain.swiftVersion.replacingOccurrences(of: "\n", with: " / ")) (\($0.toolchain.buildMode))" })))
        items.append(("Series", "\(model.series.count) (ref, component model, backend)"))
        let filters = Set(files.map(\.suite.filter)).sorted()
        items.append(("Selection filter", filters.joined(separator: ", ")))
        return "<dl class=\"facts\">\n" + items.map { "<div class=\"fact\"><dt>\(e($0.0))</dt><dd>\(e($0.1))</dd></div>" }.joined(separator: "\n") + "\n</dl>"
    }

    // MARK: Emitting

    /// Moves the pending prose into the body as HTML.
    private mutating func flush() {
        guard !lines.isEmpty else { return }
        body.append(ReportMarkup.html(lines, anchors: anchors))
        lines = []
    }

    private mutating func emit(_ html: [String]) {
        flush()
        body += html
    }

    private mutating func emit(_ table: HTMLTable) {
        emit(table.render())
    }

    private var replicateSummary: String {
        let counts = model.groups.map { "\($0.label): \($0.fileIndices.count) of \($0.expectedReplicates)" }
        return counts.joined(separator: "; ")
    }

    /// The same for the Markdown-subset prose: labels sit in code spans, so entities, `*` and brackets display verbatim.
    private var replicateSummaryText: String {
        let counts = model.groups.map { "`\(Self.codeText($0.label))`: \($0.fileIndices.count) of \($0.expectedReplicates)" }
        return counts.joined(separator: "; ")
    }

    // MARK: Header

    private mutating func header() {
        lines.append("## Reading notes")
        lines.append("")
        let baseline = model.groups[model.baselineGroup]
        lines.append("- Baseline: `\(Self.codeText(baseline.label))` (\(Self.text(baseline.sha)))")
        lines.append("- Inputs: \(model.files.count) result files, \(model.groups.count) refs, \(model.series.count) series (ref, component model, backend)")
        lines.append("- Replicates per ref: \(replicateSummaryText)")
        let filters = Set(model.files.map(\.suite.filter)).sorted()
        lines.append("- Selection filter: " + filters.map { "`\(Self.codeText($0))`" }.joined(separator: ", "))
        lines.append("- Every replicate is an independent process; the replicate is the unit of analysis. `median` is the median over replicates of each replicate's median per iteration. `CI low` and `CI high` bound the 95% distribution-free confidence interval of that median (exact coverage in the methods section). `replicates` is the number of replicates behind the value, `iterations` the median number of measurements per replicate (time-based sampling, so it differs between series by design).")
        lines.append("- Non-baseline series add, for wall clock only, `speed (×)` = baseline ÷ series (above 1 is faster) with its distribution-free 95% CI, `change (%)` = (1 ÷ speed − 1) × 100, `q` (Benjamini–Hochberg adjusted p of an exact Mann–Whitney test across every wall-clock comparison of this report) and a `verdict`: `faster`/`slower` need q < \(Self.percent(ReportStatistics.significanceLevel)) and a CI entirely outside the ±\(Self.percent(ReportStatistics.defaultDelta)) zone, `equivalent` needs the CI entirely inside it. Other metrics are descriptive only.")
        lines.append("- Every unit is in its column header and applies to the whole column of that table. Values keep at most the \(ReportFormat.significantDigits) significant digits the package measured. Anything missing or not comparable is `unavailable`, and a metric the package did not record (throughput of an iteration of about 2 s or longer) is `n/a` (hover for the reason), never zero. `n/a (k replicates)` means the statistic needs more replicates.")
        lines.append("- Plots are drawn in the page from the embedded data: the wall-clock median per iteration with CI error bars and a light within-run IQR band (spread of the measurements inside a run, not uncertainty). Each plot starts on log-log axes and has a Log/Linear toggle (and there is one for all plots); entity count 0 cannot sit on a log axis and appears in the plots only on linear axes and in the tables.")
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
            if let reason = model.series[series].notRecorded[key] { return (nil, HTMLCell.notRecordedPrefix + reason) }
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

    private mutating func summary(_ identities: [String], _ ids: [String: String]) {
        guard let wall = model.wallClockMetric else { return }
        lines.append("## Summary")
        lines.append("")
        lines.append("Wall clock, `speed (×)` against the paired baseline series (above 1 is faster) with its distribution-free 95% CI and the verdict (δ = \(Self.percent(ReportStatistics.defaultDelta)), q across all comparisons). The last block of each series is the largest entity count for which the comparison exists (its count in the `entities` column).")
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
        emit(HTMLTable(rowHeader: "Workload", rowLabels: identities, rowHrefs: identities.map { "#\(ids[$0]!)" }, blocks: blocks))
        lines.append("")
    }

    private func summaryBlock(_ series: Int, subgroup: String, items: [ReportComparison?], entities: [Int?]?) -> HTMLColumnBlock {
        let columns = comparisonColumns(items, includeChange: false, includeQ: false)
        let tints = items.map(Self.verdictClass)
        var headers = columns.headers
        var cells = columns.cells
        if let entities {
            headers.insert("entities", at: 0)
            cells.insert(entities.map { $0.map { HTMLCell(ReportFormat.grouped($0)) } ?? .unavailable("no entity count with a comparison") }, at: 0)
        }
        return HTMLColumnBlock(group: groupLabel(series), subgroup: subgroup, headers: headers, columns: cells, series: series, tints: tints)
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

    /// Symbol of a verdict, so that the row tint is never the only signal. Nothing for a verdict that was not reached.
    static func verdictSymbol(_ verdict: ReportStatistics.Verdict) -> String? {
        switch verdict {
        case .faster: "\u{25B2}"
        case .slower: "\u{25BC}"
        case .equivalent: "="
        case .inconclusive: "?"
        case .notAvailable: nil
        }
    }

    /// Class suffix (`v-<class>`) tinting the cells of a compared series in a row: green for faster, red for slower, neutral otherwise.
    static func verdictClass(_ item: ReportComparison?) -> String? {
        guard let item, item.reason == nil, item.speed != nil, let verdict = item.verdict else { return "unavailable" }
        switch verdict {
        case .faster: return "faster"
        case .slower: return "slower"
        case .equivalent: return "equivalent"
        case .inconclusive: return "inconclusive"
        case .notAvailable: return "unavailable"
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
            var cell = HTMLCell(item.verdict.map(Self.verdictText) ?? "unavailable", symbol: item.verdict.flatMap(Self.verdictSymbol))
            cell.isVerdict = true
            return cell
        })
        return (headers, cells)
    }

    // MARK: Workload sections

    private mutating func workloads(_ identities: [String], _ ids: [String: String]) {
        lines.append("## Workloads")
        lines.append("")
        flush()
        anchors = false
        defer { anchors = true }
        let hasComparisons = model.series.indices.contains { !model.isBaseline($0) }
        for identity in identities {
            let id = ids[identity]!
            emit(["<section class=\"workload\" id=\"\(ReportMarkup.escape(id))\">"])
            lines.append("### `\(Self.codeText(identity))`")
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
            if model.wallClockMetric != nil {
                var kinds = ["total", "perEntity"]
                if hasComparisons { kinds.append("relative") }
                emit(["<div class=\"plots\">"] + kinds.map { "<div class=\"plot\" data-w=\"\(ReportMarkup.escape(id))\" data-kind=\"\($0)\"></div>" } + ["</div>"])
            }
            wallClockTables(identity)
            details(identity)
            emit(["</section>"])
        }
    }

    private mutating func wallClockTables(_ identity: String) {
        guard let wall = model.wallClockMetric else { return }
        let scales = Set(model.keys.filter { $0.identity == identity && $0.metric == wall }.map(\.scale)).sorted()
        statisticsTables(identity, wall, scales, headingLevel: 4, detail: true)
    }

    /// Every metric with mean and percentile columns, folded away by default; the wall-clock statistics are already shown above.
    private mutating func details(_ identity: String) {
        emit(["<details>", "<summary>All metrics, means and percentiles</summary>"])
        lines.append("`median`, `CI low`, `CI high`, `replicates` and `iterations` are defined in the [glossary](#\(ReportGlossary.anchor)). `mean` is the median over replicates of each replicate's mean per iteration; it is descriptive (upstream parity), not an inference input. Percentile columns are the median over replicates of each replicate's percentile.")
        lines.append("")
        let metrics = model.keys.filter { $0.identity == identity }.map(\.metric).uniqued()
        for metric in metrics {
            let scales = Set(model.keys.filter { $0.identity == identity && $0.metric == metric }.map(\.scale)).sorted()
            let polarity = referenceCell(ReportKey(identity: identity, scale: scales[0], metric: metric))?.prefersLarger == true ? "larger is better" : "smaller is better"
            lines.append("#### \(Self.text(metric)) (\(polarity))")
            lines.append("")
            if metric != model.wallClockMetric { statisticsTables(identity, metric, scales, headingLevel: 5, detail: true) }
            let small = scales.filter { $0 <= Self.smallLimit }
            let large = scales.filter { $0 > Self.smallLimit }
            for (label, part) in [("up to \(ReportFormat.grouped(Self.smallLimit))", small), ("above \(ReportFormat.grouped(Self.smallLimit))", large)] where !part.isEmpty {
                lines.append("##### Percentiles, entity counts \(label)")
                lines.append("")
                emit(percentileTable(identity, metric, part))
            }
        }
        emit(["</details>"])
    }

    private mutating func statisticsTables(_ identity: String, _ metric: String, _ scales: [Int], headingLevel: Int, detail: Bool) {
        let hashes = String(repeating: "#", count: headingLevel)
        let small = scales.filter { $0 <= Self.smallLimit }
        let large = scales.filter { $0 > Self.smallLimit }
        for (label, part) in [("Entity counts up to \(ReportFormat.grouped(Self.smallLimit))", small), ("Entity counts above \(ReportFormat.grouped(Self.smallLimit))", large)] where !part.isEmpty {
            lines.append("\(hashes) \(Self.text(metric)): \(label)")
            lines.append("")
            emit(statisticsTable(identity, metric, part, detail: detail))
        }
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
            var tints: [String?]?
            if isWall, !model.isBaseline(index) {
                let items: [ReportComparison?] = scales.map { model.comparisons[ReportComparisonKey(series: index, key: ReportKey(identity: identity, scale: $0, metric: metric))] }
                let comparison = comparisonColumns(items, includeChange: true, includeQ: true)
                headers += comparison.headers
                columns += comparison.cells
                tints = items.map(Self.verdictClass)
            }
            blocks.append(HTMLColumnBlock(group: groupLabel(index), subgroup: model.series[index].backend, headers: headers, columns: columns, series: index, tints: tints))
        }
        return HTMLTable(rowHeader: "Entities", rowLabels: scales.map(ReportFormat.grouped), workload: ids[identity], rowScales: scales, blocks: blocks)
    }

    private func percentileTable(_ identity: String, _ metric: String, _ scales: [Int]) -> HTMLTable {
        let dimension = dimension(identity, metric, scales)
        let percentiles = Statistics.defaultPercentilesToCalculate.map { Int($0) }
        var blocks: [HTMLColumnBlock] = []
        for index in model.series.indices {
            var block = HTMLColumnBlock(group: groupLabel(index), subgroup: model.series[index].backend, headers: [], columns: [], series: index)
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
        return HTMLTable(rowHeader: "Entities", rowLabels: scales.map(ReportFormat.grouped), workload: ids[identity], rowScales: scales, blocks: blocks)
    }

    // MARK: Plot data

    private func plotWorkload(_ identity: String, _ id: String) -> ReportPlotPayload.Workload {
        var workload = ReportPlotPayload.Workload(id: id, identity: identity, series: [], rel: [])
        guard let wall = model.wallClockMetric else { return workload }
        let keys = model.keys.filter { $0.identity == identity && $0.metric == wall }
        for (index, entry) in model.series.enumerated() {
            let group = model.groups[entry.groupIndex]
            var points: [ReportPlotPayload.Point] = []
            var relative: [ReportPlotPayload.RelativePoint] = []
            for key in keys {
                let comparison = model.comparisons[ReportComparisonKey(series: index, key: key)]
                if let cell = resolve(index, key).cell, let point = plotPoint(cell, scale: key.scale, comparison: comparison) { points.append(point) }
                if !model.isBaseline(index), let item = comparison, let speed = item.speed, speed.isFinite {
                    let significant = item.verdict == .faster || item.verdict == .slower
                    relative.append(ReportPlotPayload.RelativePoint(
                        n: key.scale, speed: speed, ciLow: item.ciLow.flatMap(Self.finite), ciHigh: item.ciHigh.flatMap(Self.finite), sig: significant,
                        text: Self.speedText(item), verdict: item.verdict.map(Self.verdictText), sym: item.verdict.flatMap(Self.verdictSymbol)
                    ))
                }
            }
            workload.series.append(ReportPlotPayload.Series(
                idx: index, color: index, label: entry.label, ref: group.label, backend: entry.backend, baseline: model.isBaseline(index), points: points
            ))
            if !model.isBaseline(index) {
                workload.rel.append(ReportPlotPayload.Relative(idx: index, color: index, label: entry.label, ref: group.label, backend: entry.backend, points: relative))
            }
        }
        return workload
    }

    private static func finite(_ value: Double) -> Double? {
        value.isFinite ? value : nil
    }

    /// "2.05× (CI 1.9–2.2×)": speed and CI ends with the same decimals.
    private static func speedText(_ item: ReportComparison) -> String {
        guard let speed = item.speed else { return "unavailable" }
        let values = [speed] + [item.ciLow, item.ciHigh].compactMap { $0 }
        let decimals = ReportFormat.columnDecimals(values, divisor: 1)
        let text = ReportFormat.text(speed, columnDecimals: decimals) + "\u{00D7}"
        guard let low = item.ciLow, let high = item.ciHigh else { return text }
        return text + " (CI \(ReportFormat.text(low, columnDecimals: decimals))\u{2013}\(ReportFormat.text(high, columnDecimals: decimals))\u{00D7})"
    }

    private func plotPoint(_ cell: ReportCell, scale: Int, comparison: ReportComparison?) -> ReportPlotPayload.Point? {
        guard cell.median.isFinite, cell.iqrLow.isFinite, cell.iqrHigh.isFinite else { return nil }
        func shown(_ values: [Double], _ unit: ReportUnit) -> (Double) -> String {
            let decimals = ReportFormat.columnDecimals(values, divisor: unit.divisor)
            return { ReportFormat.text($0, divisor: unit.divisor, columnDecimals: decimals) }
        }
        func suffix(_ unit: ReportUnit) -> String { unit.label.isEmpty ? "" : " " + unit.label }
        let unit = cell.dimension.unit(fitting: [cell.median])
        let interval = cell.interval.flatMap { $0.low.isFinite && $0.high.isFinite ? $0 : nil }
        let format = shown([cell.median] + (interval.map { [$0.low, $0.high] } ?? []), unit)
        var per: String?
        if scale > 0 {
            let value = cell.median / Double(scale)
            let perUnit = cell.dimension.unit(fitting: [value])
            per = shown([value], perUnit)(value) + suffix(perUnit)
        }
        let verdict = comparison?.verdict
        let usable = comparison.map { $0.reason == nil && $0.speed != nil } ?? false
        return ReportPlotPayload.Point(
            n: scale, median: cell.median, ciLow: interval?.low, ciHigh: interval?.high, cov: interval?.coverage, iqrLow: cell.iqrLow, iqrHigh: cell.iqrHigh,
            k: cell.replicates, tMedian: format(cell.median) + suffix(unit),
            tCI: interval.map { "\(format($0.low)) \u{2013} \(format($0.high))" + suffix(unit) }, tPer: per,
            tSpeed: usable ? comparison.map(Self.speedText) : nil, verdict: usable ? verdict.map(Self.verdictText) : nil,
            sym: usable ? verdict.flatMap(Self.verdictSymbol) : nil
        )
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
            lines.append("- **Protocol:** each ref is built once and run k = \(counts.map(String.init).joined(separator: ", ")) times as independent processes (\(replicateSummaryText)). Replicates run in interleaved rounds: each round runs every ref once, in an order shuffled by the recorded seed (seed \(seeds.map(String.init).joined(separator: ", ")); batch \(batches.isEmpty ? "none recorded" : batches.map { "`\(Self.codeText($0))`" }.joined(separator: ", "))). The suite settings are identical for all refs.")
        } else {
            lines.append("- **Protocol:** the inputs carry no replicate provenance, so each counts as replicate 1 of 1 (one process per ref). Only medians and within-run spread are reported; intervals, tests and verdicts need replicates.")
        }
        lines.append("- **Per replicate:** median, p25, p75 and mean of the iterations, read from the stored histogram. **Per series and cell:** the centre is the median of the replicate medians; the error bar is the distribution-free order-statistic confidence interval of that median, [x(l), x(k−l+1)] with the largest l such that P(Binomial(k, ½) ≤ l−1) ≤ 0.025 (omitted and marked when k < 6); the light band is the median over replicates of each replicate's p25 and p75.")
        let coverage = coverageSummary()
        lines.append("- **Coverage:** \(coverage.median) \(coverage.speed)")
        lines.append("- **Effect:** `speed (×)` = baseline ÷ series, estimated by Hodges–Lehmann on the log replicate medians (exp of the median of all pairwise log differences) with the Mann–Whitney-based distribution-free confidence interval of those differences (exact when no replicate medians tie, approximate with ties). `change (%)` = (1 ÷ speed − 1) × 100.")
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
                return "`\(Self.codeText(model.series[item.series].label))` / `\(Self.codeText(item.key.identity))` @ \(ReportFormat.grouped(item.key.scale)) (\(tau), q=\(ReportFormat.qValue(item.q ?? 1)))"
            }
            text += ": " + shown.joined(separator: "; ") + (flagged.count > 20 ? "; and \(flagged.count - 20) more." : ".")
        }
        return text
    }

    // MARK: Provenance, pairing, parity

    /// A small key/value style table; the cells are already HTML.
    private static func simpleTable(_ headers: [String], _ rows: [[String]]) -> [String] {
        var out = ["<div class=\"table-wrap\">", "<table class=\"kv\">", "<thead>", "<tr>" + headers.map { "<th>\(ReportMarkup.escape($0))</th>" }.joined() + "</tr>", "</thead>", "<tbody>"]
        for row in rows {
            out.append("<tr>" + row.map { "<td>\($0)</td>" }.joined() + "</tr>")
        }
        out += ["</tbody>", "</table>", "</div>"]
        return out
    }

    private static func codeHTML(_ value: String) -> String {
        "<code>\(ReportMarkup.escape(code(value)))</code>"
    }

    private mutating func provenance() {
        lines.append("## Provenance")
        lines.append("")
        flush()
        anchors = false
        defer { anchors = true }
        for group in model.groups {
            let files = group.fileIndices.map { model.files[$0] }
            let first = files[0]
            lines.append("### \(Self.text(group.label))")
            lines.append("")
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
            emit(Self.simpleTable(["Field", "Value"], rows.map { [ReportMarkup.escape($0.0), ReportMarkup.escape($0.1)] }))
        }
    }

    private mutating func pairing() {
        lines.append("## Series and pairing")
        lines.append("")
        var rows: [[String]] = []
        for index in model.series.indices {
            let series = model.series[index]
            let group = model.groups[series.groupIndex]
            let target: String = if model.isBaseline(index) {
                "baseline"
            } else if let paired = model.pairedSeries(for: index) {
                ReportMarkup.escape(model.series[paired].label)
            } else {
                "unavailable (the baseline has several backends and none is \(Self.codeHTML(series.backend)))"
            }
            rows.append([ReportMarkup.escape(series.label), "\(group.fileIndices.count) of \(group.expectedReplicates)", target])
        }
        emit(Self.simpleTable(["Series", "Replicates", "Compared with"], rows))
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
        var parityRows: [[String]] = []
        for identity in parity.keys.sorted() {
            for text in parity[identity]!.keys.sorted() {
                parityRows.append([Self.codeHTML(identity), ReportMarkup.escape(text), ReportMarkup.escape(parity[identity]![text]!.joined(separator: ", "))])
            }
        }
        emit(Self.simpleTable(["Workload", "Parity", "Refs"], parityRows))
        lines.append("## Unsupported workloads")
        lines.append("")
        lines.append("Unsupported workloads are not measured and not approximated.")
        lines.append("")
        var unsupportedRows: [[String]] = []
        for identity in unsupported.keys.sorted() {
            for reason in unsupported[identity]!.keys.sorted() {
                unsupportedRows.append([Self.codeHTML(identity), ReportMarkup.escape(reason), ReportMarkup.escape(unsupported[identity]![reason]!.joined(separator: ", "))])
            }
        }
        emit(Self.simpleTable(["Workload", "Reason", "Refs"], unsupportedRows))
    }

    // MARK: Text

    /// Prose text for the Markdown subset: `&`, `<`, `>` as entities (`ReportMarkup` escapes exactly once), `\`, `*`, `[` and `]`
    /// backslash-escaped so data never turns into emphasis or links, one line.
    static func text(_ value: String) -> String {
        var escaped = value.replacingOccurrences(of: "\\", with: "\\\\")
        for mark in ["*", "[", "]"] { escaped = escaped.replacingOccurrences(of: mark, with: "\\" + mark) }
        return entities(escaped).replacingOccurrences(of: "\n", with: " ")
    }

    private static func entities(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
    }

    /// The text of a code span of the Markdown subset: no backticks, entities written so that it displays verbatim.
    static func codeText(_ value: String) -> String {
        text(code(value))
    }

    /// Inside a code span: no backticks.
    static func code(_ value: String) -> String {
        value.replacingOccurrences(of: "`", with: "'").replacingOccurrences(of: "\n", with: " ")
    }
}
