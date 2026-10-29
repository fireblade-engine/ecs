import Foundation

/// Command line of `ECSBenchmarkResults`. Arguments are parsed by hand: the package takes no ArgumentParser dependency.
public enum ResultsCLI {
    static let usage = """
    Usage:
      ECSBenchmarkResults write --baseline <path> --out <path> --run-id <id> --started <iso8601> --finished <iso8601>
                                --ref <requested> --ref-sha <sha> --suite-sha <sha> --filter <regex>
                                --package-resolved <path> --swift-version <text>
      ECSBenchmarkResults validate <result.json>
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
            "baseline", "out", "run-id", "started", "finished", "ref", "ref-sha", "suite-sha", "filter", "package-resolved", "swift-version"
        ])
        func value(_ key: String) throws -> String {
            guard let value = options[key] else { throw ResultError("missing required option --\(key)") }
            return value
        }
        let request = try WriteRequest(
            baselinePath: value("baseline"), runID: value("run-id"), startedAt: value("started"), finishedAt: value("finished"),
            requestedRef: value("ref"), refSHA: value("ref-sha"), suiteSHA: value("suite-sha"), filter: value("filter"),
            packageResolvedPath: value("package-resolved"), swiftVersion: value("swift-version")
        )
        let output = try value("out")
        try ResultWriter.write(request, to: output)
        // Prove the written file is accepted before reporting success.
        _ = try ResultValidator.validateFile(at: output)
        print("wrote \(output)")
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
