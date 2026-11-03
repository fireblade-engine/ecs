import ECSBenchmarkResultSchema
import Foundation

/// Command line of `ECSBenchmarkReportCLI`: renders the HTML report from saved result files. Arguments are parsed by hand: the
/// package takes no ArgumentParser dependency.
public enum ReportCLI {
    static let usage = """
    Usage:
      ECSBenchmarkReportCLI <result.json>... --output-dir <dir> [--baseline <requested-ref>] [--title <text>] [--overwrite]
    """

    public static func run(_ arguments: [String]) -> Int32 {
        do {
            try render(arguments)
            return 0
        } catch {
            FileHandle.standardError.write(Data("ECSBenchmarkReportCLI: \(error)\n".utf8))
            return 1
        }
    }

    /// Reads and validates every input, renders the report and writes it. This is the only file IO of the report path.
    static func render(_ arguments: [String]) throws {
        var paths: [String] = []
        var optionArguments: [String] = []
        var overwrite = false
        var index = 0
        while index < arguments.count {
            if arguments[index] == "--overwrite" {
                overwrite = true
                index += 1
            } else if arguments[index].hasPrefix("--") {
                optionArguments += arguments[index ..< min(index + 2, arguments.count)]
                index += 2
            } else {
                paths.append(arguments[index])
                index += 1
            }
        }
        let options = try ResultsCLI.parseOptions(optionArguments, allowed: ["baseline", "title", "output-dir"], usage: usage)
        guard let output = options["output-dir"] else { throw ResultError("missing required option --output-dir") }
        guard paths.count >= 2 else { throw ResultError("the report needs at least two result files, got \(paths.count)\n\(usage)") }
        try checkOutputDirectory(output, inputs: paths, overwrite: overwrite)

        var inputs: [ReportInput] = []
        for path in paths {
            do {
                try inputs.append(ReportInput.load(at: path))
            } catch {
                throw ResultError("\(path): \(error)")
            }
        }
        var reportOptions = ReportOptions(baseline: options["baseline"])
        if let title = options["title"] {
            reportOptions.title = title
        }
        let rendered = try BenchmarkReport.render(inputs, options: reportOptions)
        for warning in rendered.warnings {
            FileHandle.standardError.write(Data("ECSBenchmarkReportCLI: warning: \(warning)\n".utf8))
        }
        // The generated path must not be an input (checked again here because the file set is only known after rendering).
        let target = output + "/" + BenchmarkReport.fileName
        for input in paths where canonical(input) == canonical(target) || sameFile(input, target) {
            throw ResultError("report file \(target) is the input \(input); refusing to overwrite a result file")
        }
        do {
            try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
            try Data(rendered.html.utf8).write(to: URL(fileURLWithPath: target), options: .atomic)
        } catch {
            throw ResultError("cannot write \(output): \(error)")
        }
        print("wrote \(target)")
    }

    /// Refuses an output directory that is a file, that is (or links to) an input's directory entry, or that already holds
    /// anything unless `overwrite` is set. Paths are standardized and symlinks resolved; hard links are caught by file identity.
    static func checkOutputDirectory(_ output: String, inputs: [String], overwrite: Bool) throws {
        let fileManager = FileManager.default
        let target = canonical(output)
        for input in inputs where canonical(input) == target || sameFile(input, output) {
            throw ResultError("--output-dir \(output) is the input \(input); refusing to overwrite a result file")
        }
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: output, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else { throw ResultError("--output-dir \(output) is a file, not a directory") }
            let entries = (try? fileManager.contentsOfDirectory(atPath: output)) ?? []
            guard entries.isEmpty || overwrite else { throw ResultError("--output-dir \(output) is not empty; pass --overwrite to replace the generated report files") }
        }
    }

    private static func canonical(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath().path
    }

    private static func sameFile(_ lhs: String, _ rhs: String) -> Bool {
        let fileManager = FileManager.default
        guard let a = try? fileManager.attributesOfItem(atPath: lhs), let b = try? fileManager.attributesOfItem(atPath: rhs),
              let aNumber = a[.systemFileNumber] as? UInt64, let bNumber = b[.systemFileNumber] as? UInt64,
              let aSystem = a[.systemNumber] as? Int, let bSystem = b[.systemNumber] as? Int else { return false }
        return aNumber == bNumber && aSystem == bSystem
    }
}
