import Foundation

/// Command line of `ECSBenchmarkResults`. Arguments are parsed by hand: the package takes no ArgumentParser dependency.
public enum ResultsCLI {
    static let usage = """
    Usage:
      ECSBenchmarkResults write --baseline <path> --out <path> --run-id <id> --started <iso8601> --finished <iso8601>
                                --ref <requested> --ref-sha <sha> --suite-sha <sha> --filter <regex>
                                --package-resolved <path> --swift-version <text> [--batch-id <id>]
                                [--replicate <i> --replicates <k> --position <p> --seed <s>]
      ECSBenchmarkResults validate <result.json>
      ECSBenchmarkResults host-check
      ECSBenchmarkResults filter-check --filter <regex>   (benchmark names on stdin, one per line)
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
            case "filter-check":
                try filterCheck(Array(arguments.dropFirst()))
            default:
                return fail("unknown command '\(command)'\n\(usage)")
            }
            return 0
        } catch {
            return fail("\(error)")
        }
    }

    /// Fails unless the filter whole-matches at least one benchmark name of the plugin listing read from stdin.
    private static func filterCheck(_ arguments: [String]) throws {
        let options = try parseOptions(arguments, allowed: ["filter"], usage: usage)
        guard let filter = options["filter"] else { throw ResultError("missing required option --filter") }
        var listing = ""
        while let line = readLine() { listing += line + "\n" }
        let result = try checkFilter(listing: listing, filter: filter)
        print("filter matches \(result.matched.count) of \(result.names.count) benchmarks")
    }

    /// Benchmark names of `swift package benchmark list` output: the lines between a `Target '<name>' available benchmarks:` header and the next
    /// empty line (the plugin's `listBenchmarks` format). Every other line is ignored.
    static func benchmarkNames(inListing listing: String) -> [String] {
        var names: [String] = []
        var inTarget = false
        for line in listing.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            if line.hasPrefix("Target '"), line.hasSuffix("' available benchmarks:") {
                inTarget = true
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                inTarget = false
            } else if inTarget {
                names.append(line)
            }
        }
        return names
    }

    /// The semantics of the benchmark plugin's `--filter`: a name matches when the whole name matches the regular expression.
    static func checkFilter(listing: String, filter: String) throws -> (names: [String], matched: [String]) {
        let regex: Regex<AnyRegexOutput>
        do { regex = try Regex(filter) } catch { throw ResultError("the benchmark filter '\(filter)' is not a valid regular expression: \(error)") }
        let names = benchmarkNames(inListing: listing)
        guard !names.isEmpty else { throw ResultError("the benchmark list is empty; nothing to filter") }
        let matched = names.filter { $0.wholeMatch(of: regex) != nil }
        guard !matched.isEmpty else { throw ResultError("the benchmark filter '\(filter)' matches none of the \(names.count) listed benchmarks") }
        return (names, matched)
    }

    private static func write(_ arguments: [String]) throws {
        let options = try parseOptions(arguments, allowed: [
            "baseline", "out", "run-id", "started", "finished", "ref", "ref-sha", "suite-sha", "filter", "package-resolved", "swift-version", "batch-id",
            "replicate", "replicates", "position", "seed"
        ], usage: usage)
        func value(_ key: String) throws -> String {
            guard let value = options[key] else { throw ResultError("missing required option --\(key)") }
            return value
        }
        let replicateKeys = ["replicate", "replicates", "position", "seed"]
        var replicate: ResultReplicate?
        if replicateKeys.contains(where: { options[$0] != nil }) {
            func number<T: FixedWidthInteger>(_ key: String, as _: T.Type) throws -> T {
                guard let text = options[key] else { throw ResultError("replicate options must be given together; missing --\(key)") }
                guard let parsed = T(text) else { throw ResultError("--\(key) must be a non-negative integer, got '\(text)'") }
                return parsed
            }
            replicate = try ResultReplicate(
                index: number("replicate", as: Int.self), count: number("replicates", as: Int.self),
                position: number("position", as: Int.self), seed: number("seed", as: UInt64.self)
            )
        }
        let request = try WriteRequest(
            baselinePath: value("baseline"), runID: value("run-id"), startedAt: value("started"), finishedAt: value("finished"),
            requestedRef: value("ref"), refSHA: value("ref-sha"), suiteSHA: value("suite-sha"), filter: value("filter"),
            packageResolvedPath: value("package-resolved"), swiftVersion: value("swift-version"), batchID: options["batch-id"], replicate: replicate
        )
        let output = try value("out")
        try ResultWriter.write(request, to: output)
        print("wrote \(output)")
    }

    /// `--key value` pairs; `usage` is appended to the error of an unknown option.
    public static func parseOptions(_ arguments: [String], allowed: Set<String>, usage: String) throws -> [String: String] {
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
