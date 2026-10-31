// HTML tables of the report: the header has three levels (ref, backend, value columns) and cells are plain text or `unavailable`
// with the reason in a `title`. Verdict cells carry a symbol and every cell of a compared series block carries the verdict as a
// class, so a row's tint is never the only signal. Tables are inside their own scroll container.
import Foundation

struct HTMLCell {
    var text: String
    /// Tooltip with the reason a value is unavailable.
    var title: String?
    /// Verdict symbol shown before the text of a verdict cell.
    var symbol: String?
    /// Marks the cell as the verdict column (bold, coloured text for faster and slower).
    var isVerdict = false

    init(_ text: String, title: String? = nil, symbol: String? = nil) {
        self.text = text
        self.title = title
        self.symbol = symbol
    }

    /// Prefix of the reason of a metric the package did not record (stated by the result file); such a cell reads `n/a`.
    static let notRecordedPrefix = "not recorded: "

    static func unavailable(_ reason: String) -> HTMLCell {
        HTMLCell(reason.hasPrefix(notRecordedPrefix) ? "n/a" : "unavailable", title: reason)
    }
}

/// The columns of one series (or of one summary scale): shown under a ref header and a backend header.
struct HTMLColumnBlock {
    var group: String
    var subgroup: String
    var headers: [String]
    /// `columns[c][r]`
    var columns: [[HTMLCell]]
    /// Index of the series the block belongs to (links table cells to plot points).
    var series: Int?
    /// Per row: the verdict class (`faster`, `slower`, `equivalent`, `inconclusive`, `unavailable`) tinting every cell of the block.
    var tints: [String?]?
}

struct HTMLTable {
    init(rowHeader: String, rowLabels: [String], rowHrefs: [String]? = nil, workload: String? = nil, rowScales: [Int]? = nil, blocks: [HTMLColumnBlock]) {
        self.rowHeader = rowHeader
        self.rowLabels = rowLabels
        self.rowHrefs = rowHrefs
        self.workload = workload
        self.rowScales = rowScales
        self.blocks = blocks
    }

    var rowHeader: String
    var rowLabels: [String]
    /// Optional in-page link target per row label.
    var rowHrefs: [String]?
    /// Section id and entity count per row: the plot highlights the row of the hovered point.
    var workload: String?
    var rowScales: [Int]?
    var blocks: [HTMLColumnBlock]

    func render() -> [String] {
        var lines = ["<div class=\"table-wrap\">", workload.map { "<table data-w=\"\(Self.html($0))\">" } ?? "<table>", "<thead>"]
        // Level 1: ref groups; consecutive blocks with the same group merge.
        var level1 = [#"<th rowspan="3">\#(Self.html(rowHeader))</th>"#]
        var level2: [String] = []
        var groupStart = 0
        while groupStart < blocks.count {
            var end = groupStart
            while end + 1 < blocks.count, blocks[end + 1].group == blocks[groupStart].group { end += 1 }
            let span = blocks[groupStart ... end].reduce(0) { $0 + $1.headers.count }
            level1.append(#"<th colspan="\#(span)">\#(Self.html(blocks[groupStart].group))</th>"#)
            groupStart = end + 1
        }
        for block in blocks {
            level2.append(#"<th colspan="\#(block.headers.count)">\#(Self.html(block.subgroup))</th>"#)
        }
        lines.append("<tr>" + level1.joined() + "</tr>")
        lines.append("<tr>" + level2.joined() + "</tr>")
        lines.append("<tr>" + blocks.flatMap(\.headers).map { "<th>\(Self.html($0))</th>" }.joined() + "</tr>")
        lines.append("</thead>")
        lines.append("<tbody>")
        for row in rowLabels.indices {
            let label = Self.html(rowLabels[row])
            let linked = rowHrefs.map { "<a href=\"\(Self.html($0[row]))\">\(label)</a>" } ?? label
            var cells = [rowHrefs == nil ? "<td>\(linked)</td>" : "<td class=\"lbl\">\(linked)</td>"]
            for block in blocks {
                let tint = block.tints?[row]
                for column in block.columns {
                    cells.append(Self.cell(column[row], tint: tint, series: block.series))
                }
            }
            let attributes = (workload != nil && rowScales != nil) ? " data-w=\"\(Self.html(workload!))\" data-n=\"\(rowScales![row])\"" : ""
            lines.append("<tr\(attributes)>" + cells.joined() + "</tr>")
        }
        lines.append("</tbody>")
        lines.append("</table>")
        lines.append("</div>")
        return lines
    }

    private static func cell(_ cell: HTMLCell, tint: String?, series: Int?) -> String {
        var classes: [String] = []
        if cell.isVerdict { classes.append("verdict") }
        if let tint { classes.append("v-" + tint) }
        let title = cell.title.map { " title=\"\(html($0))\"" } ?? ""
        let data = series.map { " data-s=\"\($0)\"" } ?? ""
        let symbol = cell.symbol.map { "<span class=\"sym\" aria-hidden=\"true\">\(html($0))</span> " } ?? ""
        let attribute = classes.isEmpty ? "" : " class=\"\(classes.joined(separator: " "))\""
        return "<td\(attribute)\(data)\(title)>\(symbol)\(html(cell.text))</td>"
    }

    static func html(_ text: String) -> String {
        ReportMarkup.escape(text)
    }
}

extension Sequence where Element: Hashable {
    /// The elements without repeats, in order of first appearance.
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
