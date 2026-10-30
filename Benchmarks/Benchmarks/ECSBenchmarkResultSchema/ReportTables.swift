// HTML tables of the report. GitHub and VS Code render `colspan`/`rowspan`, which Markdown pipe tables cannot express: the
// header has three levels (ref, backend, value columns). Cells are plain text or `unavailable` with the reason in a `title`.
import Foundation

struct HTMLCell {
    var text: String
    /// Tooltip with the reason a value is unavailable.
    var title: String?

    init(_ text: String, title: String? = nil) {
        self.text = text
        self.title = title
    }

    static func unavailable(_ reason: String) -> HTMLCell {
        HTMLCell("unavailable", title: reason)
    }
}

/// The columns of one series (or of one summary scale): shown under a ref header and a backend header.
struct HTMLColumnBlock {
    var group: String
    var subgroup: String
    var headers: [String]
    /// `columns[c][r]`
    var columns: [[HTMLCell]]
}

struct HTMLTable {
    init(rowHeader: String, rowLabels: [String], rowHrefs: [String]? = nil, blocks: [HTMLColumnBlock]) {
        self.rowHeader = rowHeader
        self.rowLabels = rowLabels
        self.rowHrefs = rowHrefs
        self.blocks = blocks
    }

    var rowHeader: String
    var rowLabels: [String]
    /// Optional link target per row label.
    var rowHrefs: [String]?
    var blocks: [HTMLColumnBlock]

    func render() -> [String] {
        var lines = ["<table>", "<thead>"]
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
            var cells = ["<td align=\"\(rowHrefs == nil ? "right" : "left")\">\(linked)</td>"]
            for block in blocks {
                for column in block.columns {
                    let cell = column[row]
                    let title = cell.title.map { " title=\"\(Self.html($0))\"" } ?? ""
                    cells.append("<td align=\"right\"\(title)>\(Self.html(cell.text))</td>")
                }
            }
            lines.append("<tr>" + cells.joined() + "</tr>")
        }
        lines.append("</tbody>")
        lines.append("</table>")
        return lines
    }

    static func html(_ text: String) -> String {
        var out = ""
        for character in text {
            switch character {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            case "\n": out += " "
            default: out.append(character)
            }
        }
        return out
    }
}
