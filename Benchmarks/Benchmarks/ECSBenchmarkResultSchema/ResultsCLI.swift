import Foundation

/// Command line of `ECSBenchmarkResults`. Arguments are parsed by hand: the package takes no ArgumentParser dependency.
public enum ResultsCLI {
    static let usage = """
    Usage:
      ECSBenchmarkResults write --baseline <path> --out <path> --run-id <id> --started <iso8601> --finished <iso8601>
                                --ref <requested> --ref-sha <sha> --suite-sha <sha> --filter <regex>
                                --package-resolved <path> --swift-version <text> [--batch-id <id>]
      ECSBenchmarkResults validate <result.json>
      ECSBenchmarkResults host-check
      ECSBenchmarkResults report <result.json>... --output-dir <dir> [--baseline <requested-ref>] [--title <text>] [--overwrite]
    """

    public static func run(_ arguments: [String]) -> Int32 {
        guard let command = arguments.first else { return fail("missing command\n\(usage)") }
        do {
            switch command {
            case "write":
                try write(Array(arguments.dropFirst()))
            case "validate":
                guard arguments.count == 2 else { return fail("validate takes exactly one path\n\(usage)") }
                let file = try ResultValidator.validateFile(at: arguments[1])
                print("valid: \(file.benchmarks.count) benchmarks, ref \(file.ref.requested) \(file.ref.sha)")
            case "host-check":
                guard arguments.count == 1 else { return fail("host-check takes no arguments\n\(usage)") }
                let host = try HostFacts.current()
                print("host ok: \(host.osName) \(host.osVersion), \(host.architecture), \(host.cpuModel), \(host.coreCount) cores")
            case "report":
                try report(Array(arguments.dropFirst()))
            default:
                return fail("unknown command '\(command)'\n\(usage)")
            }
            return 0
        } catch {
            return fail("\(error)")
        }
    }

    private static func write(_ arguments: [String]) throws {
        let options = try parseOptions(arguments, allowed: [
            "baseline", "out", "run-id", "started", "finished", "ref", "ref-sha", "suite-sha", "filter", "package-resolved", "swift-version", "batch-id"
        ])
        func value(_ key: String) throws -> String {
            guard let value = options[key] else { throw ResultError("missing required option --\(key)") }
            return value
        }
        let request = try WriteRequest(
            baselinePath: value("baseline"), runID: value("run-id"), startedAt: value("started"), finishedAt: value("finished"),
            requestedRef: value("ref"), refSHA: value("ref-sha"), suiteSHA: value("suite-sha"), filter: value("filter"),
            packageResolvedPath: value("package-resolved"), swiftVersion: value("swift-version"), batchID: options["batch-id"]
        )
        let output = try value("out")
        try ResultWriter.write(request, to: output)
        // Prove the written file is accepted before reporting success.
        _ = try ResultValidator.validateFile(at: output)
        print("wrote \(output)")
    }

    /// Reads and validates every input, renders the report and writes it. This is the only file IO of the report path.
    private static func report(_ arguments: [String]) throws {
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
        let options = try parseOptions(optionArguments, allowed: ["baseline", "title", "output-dir"])
        guard let output = options["output-dir"] else { throw ResultError("missing required option --output-dir") }
        guard paths.count >= 2 else { throw ResultError("report needs at least two result files, got \(paths.count)\n\(usage)") }
        try checkOutputDirectory(output, inputs: paths, overwrite: overwrite)

        var files: [BenchmarkResultFile] = []
        for path in paths {
            do {
                try files.append(ResultValidator.validateFile(at: path))
            } catch {
                throw ResultError("\(path): \(error)")
            }
        }
        var reportOptions = ReportOptions(baseline: options["baseline"])
        if let title = options["title"] {
            reportOptions.title = title
        }
        let rendered = try BenchmarkReport.render(files, options: reportOptions)
        for warning in rendered.warnings {
            FileHandle.standardError.write(Data("ECSBenchmarkResults: warning: \(warning)\n".utf8))
        }
        // The generated paths must not be inputs (checked again here because the file set is only known after rendering).
        for file in rendered.files {
            let target = output + "/" + file.path
            for input in paths where canonical(input) == canonical(target) || sameFile(input, target) {
                throw ResultError("report file \(target) is the input \(input); refusing to overwrite a result file")
            }
        }
        try write(rendered.files, to: output)
        print("wrote \(rendered.files.count) files to \(output)")
    }

    /// Replaces the generated files: stale `*.md` in `workloads/` and `*.svg` in `img/` from an earlier report are removed first, so
    /// the directory never mixes two reports. Nothing else in the directory is touched.
    private static func write(_ files: [RenderedFile], to directory: String) throws {
        let fileManager = FileManager.default
        do {
            for (subdirectory, suffix) in [("workloads", ".md"), ("img", ".svg")] {
                let path = directory + "/" + subdirectory
                if let existing = try? fileManager.contentsOfDirectory(atPath: path) {
                    for name in existing where name.hasSuffix(suffix) {
                        try fileManager.removeItem(atPath: path + "/" + name)
                    }
                }
            }
            for file in files {
                let url = URL(fileURLWithPath: directory + "/" + file.path)
                try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try Data(file.contents.utf8).write(to: url, options: .atomic)
            }
        } catch {
            throw ResultError("cannot write \(directory): \(error)")
        }
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

    static func parseOptions(_ arguments: [String], allowed: Set<String>) throws -> [String: String] {
        var options: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            guard argument.hasPrefix("--"), allowed.contains(String(argument.dropFirst(2))) else {
                throw ResultError("unknown option '\(argument)'\n\(usage)")
            }
            guard index + 1 < arguments.count else { throw ResultError("option \(argument) needs a value") }
            let key = String(argument.dropFirst(2))
            guard options[key] == nil else { throw ResultError("option \(argument) given twice") }
            options[key] = arguments[index + 1]
            index += 2
        }
        return options
    }

    private static func fail(_ message: String) -> Int32 {
        FileHandle.standardError.write(Data("ECSBenchmarkResults: \(message)\n".utf8))
        return 1
    }
}
