import Benchmark
import ECSCompatSuite
import Foundation

public enum ResultValidator {
    /// Decodes `data`, checks schema, version and internal consistency, and returns the decoded file (whose baseline holds the
    /// native `BenchmarkResult`/`Statistics` values).
    public static func decode(_ data: Data) throws -> BenchmarkResultFile {
        struct Header: Decodable {
            var schema: String?
            var schemaVersion: Int?
        }
        let header: Header
        do {
            header = try JSONDecoder().decode(Header.self, from: data)
        } catch {
            throw ResultError("not a JSON object: \(error)")
        }
        guard header.schema == ResultSchema.name else {
            throw ResultError("unsupported schema '\(header.schema ?? "none")', expected '\(ResultSchema.name)'")
        }
        guard header.schemaVersion == ResultSchema.version else {
            throw ResultError("unsupported schema version \(header.schemaVersion.map(String.init) ?? "none"), expected \(ResultSchema.version)")
        }
        let file: BenchmarkResultFile
        do {
            file = try JSONDecoder().decode(BenchmarkResultFile.self, from: data)
        } catch {
            throw ResultError("result file does not match the schema: \(error)")
        }
        try validate(file)
        return file
    }

    public static func validateFile(at path: String) throws -> BenchmarkResultFile {
        try decode(ResultWriter.readFile(path, "result file"))
    }

    /// Like `validateFile(at:)`, for the report only: the histogram counts are read by a linear scan instead of `JSONDecoder`
    /// (see `StrippedResultFile`). The decoded file's native histograms are not usable; the report reads `storedHistograms`.
    static func loadForReport(at path: String) throws -> BenchmarkResultFile {
        let stripped = try StrippedResultFile(ResultWriter.readFile(path, "result file"))
        var file = try decode(stripped.data)
        file.storedHistograms = stripped.histograms
        return file
    }

    /// Consistency checks of a decoded file. Does not compare against the validating binary's own suite, so results of any
    /// revision's adapter validate; the writer additionally pins names and metrics to its own suite.
    public static func validate(_ file: BenchmarkResultFile) throws {
        guard file.schema == ResultSchema.name else { throw ResultError("unsupported schema '\(file.schema)'") }
        guard file.schemaVersion == ResultSchema.version else { throw ResultError("unsupported schema version \(file.schemaVersion)") }

        try ResultWriter.require("run id", file.run.id)
        if let batch = file.run.batchId {
            try ResultWriter.require("batch id", batch)
        }
        if let replicate = file.run.replicate {
            guard replicate.count >= 1 else { throw ResultError("replicate count must be at least 1, got \(replicate.count)") }
            guard (1 ... replicate.count).contains(replicate.index) else {
                throw ResultError("replicate index \(replicate.index) is outside 1...\(replicate.count)")
            }
            guard (1 ... replicate.count).contains(replicate.round) else {
                throw ResultError("replicate round \(replicate.round) is outside 1...\(replicate.count)")
            }
            guard replicate.position >= 1 else { throw ResultError("replicate position must be at least 1, got \(replicate.position)") }
        }
        let started = try requireDate("run start", file.run.startedAt)
        let finished = try requireDate("run finish", file.run.finishedAt)
        guard finished >= started else { throw ResultError("run finished before it started") }
        try ResultWriter.require("requested ref", file.ref.requested)
        try ResultWriter.requireSHA("ref SHA", file.ref.sha)
        try ResultWriter.requireSHA("suite SHA", file.suite.sha)
        try ResultWriter.require("suite filter", file.suite.filter)
        try ResultWriter.require("suite target", file.suite.target)
        guard file.suite.configurationHash.count == 64, file.suite.configurationHash.allSatisfy({ $0.isHexDigit && !$0.isUppercase }) else {
            throw ResultError("configuration hash must be 64 lowercase hex characters")
        }
        guard ["class", "value"].contains(file.ref.componentModel) else { throw ResultError("unknown component model '\(file.ref.componentModel)'") }
        guard !file.ref.backends.isEmpty else { throw ResultError("ref lists no backends") }
        try ResultWriter.require("swift version text", file.toolchain.swiftVersion)
        guard file.toolchain.buildMode == ResultSchema.buildMode else { throw ResultError("build mode must be \(ResultSchema.buildMode), got '\(file.toolchain.buildMode)'") }
        try ResultWriter.require("host OS name", file.host.osName)
        try ResultWriter.require("host OS version", file.host.osVersion)
        try ResultWriter.require("host architecture", file.host.architecture)
        try ResultWriter.require("host CPU model", file.host.cpuModel)
        guard file.host.coreCount > 0, file.host.physicalMemoryBytes > 0 else { throw ResultError("host core count and memory must be positive") }
        try checkPins(file.packages)

        let workloadIdentities = file.workloads.map(\.identity)
        guard Set(workloadIdentities).count == workloadIdentities.count else { throw ResultError("duplicate workload identities") }
        for workload in file.workloads {
            guard ["equivalent", "adapted"].contains(workload.parityKind) else { throw ResultError("workload '\(workload.identity)' has unknown parity kind '\(workload.parityKind)'") }
            if workload.parityKind == "adapted", (workload.parityReason ?? "").isEmpty {
                throw ResultError("adapted workload '\(workload.identity)' has no reason")
            }
        }
        for entry in file.unsupported where entry.reason.isEmpty {
            throw ResultError("unsupported workload '\(entry.identity)' has no reason")
        }

        // Every benchmark entry must match a baseline entry and an own workload; nothing may be left over on either side.
        guard !file.benchmarks.isEmpty else { throw ResultError("result file contains no benchmarks") }
        let names = file.benchmarks.map(\.name)
        guard Set(names).count == names.count else { throw ResultError("duplicate benchmark names") }
        for benchmark in file.benchmarks {
            guard workloadIdentities.contains(benchmark.identity) else { throw ResultError("benchmark '\(benchmark.name)' has unknown workload identity '\(benchmark.identity)'") }
            guard file.ref.backends.contains(benchmark.backend) else { throw ResultError("benchmark '\(benchmark.name)' uses backend '\(benchmark.backend)' not available for this ref") }
            guard benchmark.name == "\(benchmark.identity) [\(benchmark.backend)] / \(benchmark.scale)" else {
                throw ResultError("benchmark name '\(benchmark.name)' does not match its parsed identity, backend and scale")
            }
        }
        let baselineNames = Set(file.baseline.results.keys.map(\.name))
        guard baselineNames == Set(names) else {
            throw ResultError("baseline benchmarks \(baselineNames.symmetricDifference(names).sorted()) differ from the benchmark list")
        }
        for (identifier, results) in file.baseline.results {
            guard identifier.target == file.suite.target else { throw ResultError("baseline target '\(identifier.target)' differs from suite target '\(file.suite.target)'") }
            guard !results.isEmpty else { throw ResultError("benchmark '\(identifier.name)' has no metrics") }
            let metrics = results.map(\.metric.description)
            guard Set(metrics).count == metrics.count else { throw ResultError("benchmark '\(identifier.name)' repeats a metric") }
            try checkUnrecorded(identifier.name, metrics, file.benchmarks.first { $0.name == identifier.name }?.unrecordedMetrics ?? [])
            // A metric without measurements (for example a counter that never fired) is valid data: the report prints it as
            // `unavailable`. Only structurally malformed statistics are rejected, and those fail to decode.
        }
    }

    /// The only metric a file may claim as unrecorded is throughput, with a reason, and not while it is also present. Completeness
    /// of the other metrics is not checked here (the validator accepts files of any adapter revision, and a metric without
    /// measurements is valid data); the writer pins the full metric set and so refuses anything else missing.
    private static func checkUnrecorded(_ name: String, _ metrics: [String], _ unrecorded: [UnrecordedMetric]) throws {
        let optional = ResultSchema.optionalMetric
        let listed = unrecorded.map(\.metric)
        guard Set(listed).count == listed.count else { throw ResultError("benchmark '\(name)' lists an unrecorded metric twice") }
        for entry in unrecorded {
            guard entry.metric == optional else { throw ResultError("benchmark '\(name)' lists '\(entry.metric)' as unrecorded, but only \(optional) may be missing") }
            guard !entry.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ResultError("benchmark '\(name)' lists unrecorded metric '\(entry.metric)' without a reason") }
            guard !metrics.contains(entry.metric) else { throw ResultError("benchmark '\(name)' lists '\(entry.metric)' as unrecorded but also has it") }
        }
    }

    static func checkPins(_ packages: [PackagePin]) throws {
        for required in ResultSchema.requiredPins {
            guard let pin = packages.first(where: { $0.identity == required.identity }) else {
                throw ResultError("Package.resolved does not pin \(required.identity)")
            }
            guard pin.version == required.version, pin.revision == required.revision else {
                throw ResultError("\(required.identity) is pinned at \(pin.version ?? "none") (\(pin.revision)), expected \(required.version ?? "") (\(required.revision))")
            }
        }
    }

    @discardableResult
    static func requireDate(_ what: String, _ value: String) throws -> Date {
        try ResultWriter.require(what, value)
        guard let date = ISO8601DateFormatter().date(from: value), value.hasSuffix("Z") else {
            throw ResultError("\(what) must be an ISO 8601 UTC timestamp (YYYY-MM-DDThh:mm:ssZ), got '\(value)'")
        }
        return date
    }
}
