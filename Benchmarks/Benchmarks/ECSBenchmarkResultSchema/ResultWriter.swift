import Benchmark
import ECSCompatSuite
import Foundation

/// Provenance passed by the caller (Scripts/benchmark-snapshot.sh); everything else is derived in-process.
public struct WriteRequest {
    public var baselinePath: String
    public var runID: String
    public var startedAt: String
    public var finishedAt: String
    public var requestedRef: String
    public var refSHA: String
    public var suiteSHA: String
    public var filter: String
    public var packageResolvedPath: String
    public var swiftVersion: String

    public init(
        baselinePath: String, runID: String, startedAt: String, finishedAt: String, requestedRef: String, refSHA: String,
        suiteSHA: String, filter: String, packageResolvedPath: String, swiftVersion: String
    ) {
        self.baselinePath = baselinePath
        self.runID = runID
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.requestedRef = requestedRef
        self.refSHA = refSHA
        self.suiteSHA = suiteSHA
        self.filter = filter
        self.packageResolvedPath = packageResolvedPath
        self.swiftVersion = swiftVersion
    }
}

public enum ResultWriter {
    /// Builds and returns the encoded result file. Never mutates the decoded statistics.
    public static func makeFile(_ request: WriteRequest, host: ResultHost) throws -> BenchmarkResultFile {
        try require("run id", request.runID)
        try require("requested ref", request.requestedRef)
        try require("suite filter", request.filter)
        try require("swift version text", request.swiftVersion)
        try requireSHA("ref SHA", request.refSHA)
        try requireSHA("suite SHA", request.suiteSHA)
        try ResultValidator.requireDate("run start", request.startedAt)
        try ResultValidator.requireDate("run finish", request.finishedAt)

        let packages = try readPins(request.packageResolvedPath)
        try ResultValidator.checkPins(packages)

        let baselineData = try readFile(request.baselinePath, "native baseline")
        let envelope: NativeBaselineEnvelope
        do {
            envelope = try JSONDecoder().decode(NativeBaselineEnvelope.self, from: baselineData)
        } catch {
            throw ResultError("native baseline \(request.baselinePath) does not decode with the pinned Benchmark types: \(error)")
        }

        var benchmarks: [ResultBenchmark] = []
        for (identifier, results) in envelope.results.sorted(by: { $0.key < $1.key }) {
            guard identifier.target == CompatManifest.benchmarkTarget else {
                throw ResultError("baseline benchmark '\(identifier.name)' belongs to target '\(identifier.target)', expected \(CompatManifest.benchmarkTarget)")
            }
            guard let parsed = CompatManifest.parseBenchmarkName(identifier.name) else {
                throw ResultError("benchmark name '\(identifier.name)' does not parse to a registered workload identity, backend and scale")
            }
            let metrics = results.map(\.metric.description)
            let expected = CompatManifest.metrics.map(\.description)
            guard Set(metrics) == Set(expected), metrics.count == expected.count else {
                throw ResultError("benchmark '\(identifier.name)' has metrics \(metrics.sorted()), expected \(expected.sorted())")
            }
            benchmarks.append(ResultBenchmark(name: identifier.name, identity: parsed.identity, backend: parsed.backend, scale: parsed.scale))
        }

        let file = BenchmarkResultFile(
            schema: ResultSchema.name,
            schemaVersion: ResultSchema.version,
            run: ResultRun(id: request.runID, startedAt: request.startedAt, finishedAt: request.finishedAt),
            ref: ResultRef(requested: request.requestedRef, sha: request.refSHA, componentModel: CompatManifest.componentModel, backends: CompatManifest.backends),
            suite: ResultSuite(
                sha: request.suiteSHA,
                target: CompatManifest.benchmarkTarget,
                filter: request.filter,
                configurationHash: configurationHash(suiteSHA: request.suiteSHA, filter: request.filter, configuration: CompatManifest.configurationDescription)
            ),
            packages: packages,
            toolchain: ResultToolchain(swiftVersion: request.swiftVersion, buildMode: ResultSchema.buildMode),
            host: host,
            workloads: CompatManifest.workloads,
            unsupported: CompatManifest.unsupported,
            benchmarks: benchmarks,
            baseline: envelope
        )
        try ResultValidator.validate(file)
        return file
    }

    public static func write(_ request: WriteRequest, to outputPath: String, host: ResultHost? = nil) throws {
        let file = try makeFile(request, host: host ?? HostFacts.current())
        let data = try BenchmarkResultFile.encoder().encode(file)
        try data.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
    }

    static func readPins(_ path: String) throws -> [PackagePin] {
        struct Resolved: Decodable {
            struct Pin: Decodable {
                struct State: Decodable { var version: String?; var revision: String }
                var identity: String
                var state: State
            }
            var pins: [Pin]
        }
        let data = try readFile(path, "Package.resolved")
        do {
            return try JSONDecoder().decode(Resolved.self, from: data).pins
                .map { PackagePin(identity: $0.identity, version: $0.state.version, revision: $0.state.revision) }
        } catch {
            throw ResultError("cannot parse \(path) as Package.resolved: \(error)")
        }
    }

    static func readFile(_ path: String, _ what: String) throws -> Data {
        guard let data = FileManager.default.contents(atPath: path) else { throw ResultError("cannot read \(what) at \(path)") }
        return data
    }

    static func require(_ what: String, _ value: String) throws {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { throw ResultError("missing required provenance: \(what)") }
    }

    static func requireSHA(_ what: String, _ value: String) throws {
        try require(what, value)
        guard value.count == 40, value.allSatisfy({ $0.isHexDigit && !$0.isUppercase }) else {
            throw ResultError("\(what) must be a full 40-character lowercase hex SHA, got '\(value)'")
        }
    }
}
