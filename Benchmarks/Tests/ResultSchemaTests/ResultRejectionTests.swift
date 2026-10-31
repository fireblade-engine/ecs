import Benchmark
import ECSCompatSuite
import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

@Suite
struct ResultRejectionTests {
    /// Runs `body` with a scratch directory holding a valid baseline for one benchmark.
    private func withBaseline(_ envelope: NativeBaselineEnvelope = Support.syntheticEnvelope(variant: 0), _ body: (URL, String) throws -> Void) throws {
        let directory = try Support.scratchDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(directory, Support.writeEnvelope(envelope, in: directory))
    }

    private func expectRejected(_ message: String, _ work: () throws -> Void) {
        do {
            try work()
            Issue.record("expected a rejection containing '\(message)'")
        } catch let error as ResultError {
            #expect(error.description.contains(message), "got: \(error.description)")
        } catch {
            Issue.record("unexpected error type \(error)")
        }
    }

    private func validFileData() throws -> Data {
        var data = Data()
        try withBaseline { _, path in
            data = try BenchmarkResultFile.encoder().encode(ResultWriter.makeFile(Support.request(baseline: path), host: Support.host))
        }
        return data
    }

    private func mutated(_ change: (inout [String: Any]) -> Void) throws -> Data {
        var object = try #require(JSONSerialization.jsonObject(with: validFileData()) as? [String: Any])
        change(&object)
        return try JSONSerialization.data(withJSONObject: object)
    }

    // MARK: - Schema and version

    @Test
    func rejectsWrongSchemaName() throws {
        let data = try mutated { $0["schema"] = "something-else" }
        expectRejected("unsupported schema 'something-else'") { _ = try ResultValidator.decode(data) }
    }

    @Test(arguments: [0, 2, 99])
    func rejectsWrongSchemaVersion(version: Int) throws {
        let data = try mutated { $0["schemaVersion"] = version }
        expectRejected("unsupported schema version \(version)") { _ = try ResultValidator.decode(data) }
    }

    @Test
    func rejectsMissingSchemaAndNonJSON() throws {
        let data = try mutated { $0.removeValue(forKey: "schema") }
        expectRejected("unsupported schema 'none'") { _ = try ResultValidator.decode(data) }
        expectRejected("not a JSON object") { _ = try ResultValidator.decode(Data("nope".utf8)) }
    }

    @Test
    func rejectsMalformedWrapperValues() throws {
        let data = try mutated { object in
            var host = object["host"] as? [String: Any] ?? [:]
            host["coreCount"] = "ten"
            object["host"] = host
        }
        expectRejected("does not match the schema") { _ = try ResultValidator.decode(data) }
    }

    // MARK: - Replicate provenance

    private func replicateData(_ fields: [String: Any]) throws -> Data {
        try mutated { object in
            var run = object["run"] as? [String: Any] ?? [:]
            run["replicate"] = fields
            object["run"] = run
        }
    }

    private func replicate(index: Int = 2, count: Int = 5, round: Int = 2, position: Int = 1, seed: Int = 7) -> [String: Any] {
        ["index": index, "count": count, "round": round, "position": position, "seed": seed]
    }

    @Test
    func acceptsConsistentReplicateFields() throws {
        let file = try ResultValidator.decode(replicateData(replicate()))
        #expect(file.run.replicate == ResultReplicate(index: 2, count: 5, round: 2, position: 1, seed: 7))
        _ = try ResultValidator.decode(replicateData(replicate(index: 1, count: 1, round: 1)))
    }

    @Test
    func rejectsInconsistentReplicateFields() throws {
        expectRejected("replicate index 6 is outside 1...5") { _ = try ResultValidator.decode(replicateData(replicate(index: 6))) }
        expectRejected("replicate index 0 is outside 1...5") { _ = try ResultValidator.decode(replicateData(replicate(index: 0))) }
        expectRejected("replicate count must be at least 1") { _ = try ResultValidator.decode(replicateData(replicate(count: 0))) }
        expectRejected("replicate round 6 is outside 1...5") { _ = try ResultValidator.decode(replicateData(replicate(round: 6))) }
        expectRejected("replicate position must be at least 1") { _ = try ResultValidator.decode(replicateData(replicate(position: 0))) }
        expectRejected("does not match the schema") { _ = try ResultValidator.decode(replicateData(replicate(seed: -1))) }
        expectRejected("does not match the schema") { _ = try ResultValidator.decode(replicateData(["index": 1, "count": 1])) }
    }

    // MARK: - Package pins

    @Test(arguments: ["benchmark", "hdrhistogram-swift"])
    func writerRejectsWrongPackageVersion(identity: String) throws {
        try withBaseline { directory, path in
            let resolved = try tamperedResolved(in: directory, identity: identity, version: "9.9.9", revision: nil)
            expectRejected("\(identity) is pinned at 9.9.9") {
                _ = try ResultWriter.makeFile(Support.request(baseline: path, resolved: resolved), host: Support.host)
            }
        }
    }

    @Test(arguments: ["benchmark", "hdrhistogram-swift"])
    func writerRejectsWrongPackageRevision(identity: String) throws {
        try withBaseline { directory, path in
            let resolved = try tamperedResolved(in: directory, identity: identity, version: nil, revision: "0000")
            expectRejected("\(identity) is pinned at") {
                _ = try ResultWriter.makeFile(Support.request(baseline: path, resolved: resolved), host: Support.host)
            }
        }
    }

    @Test
    func writerRejectsMissingPin() throws {
        try withBaseline { directory, path in
            let resolved = try tamperedResolved(in: directory, identity: "hdrhistogram-swift", version: nil, revision: nil, remove: true)
            expectRejected("does not pin hdrhistogram-swift") {
                _ = try ResultWriter.makeFile(Support.request(baseline: path, resolved: resolved), host: Support.host)
            }
        }
    }

    @Test
    func validatorRejectsWrongPackageVersion() throws {
        let data = try mutated { object in
            var packages = object["packages"] as? [[String: Any]] ?? []
            for index in packages.indices where packages[index]["identity"] as? String == "benchmark" { packages[index]["version"] = "1.0.0" }
            object["packages"] = packages
        }
        expectRejected("benchmark is pinned at 1.0.0") { _ = try ResultValidator.decode(data) }
    }

    private func tamperedResolved(in directory: URL, identity: String, version: String?, revision: String?, remove: Bool = false) throws -> String {
        var object = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: Support.realPackageResolved))) as? [String: Any])
        var pins = try #require(object["pins"] as? [[String: Any]])
        if remove {
            pins.removeAll { $0["identity"] as? String == identity }
        } else {
            for index in pins.indices where pins[index]["identity"] as? String == identity {
                var state = pins[index]["state"] as? [String: Any] ?? [:]
                if let version { state["version"] = version }
                if let revision { state["revision"] = revision }
                pins[index]["state"] = state
            }
        }
        object["pins"] = pins
        let url = directory.appendingPathComponent("Package.resolved")
        try JSONSerialization.data(withJSONObject: object).write(to: url)
        return url.path
    }

    // MARK: - Missing provenance

    private static let provenanceFields = [
        "run id", "requested ref", "suite filter", "swift version text", "ref SHA", "suite SHA", "run start", "run finish"
    ]

    @Test(arguments: provenanceFields)
    func writerRejectsMissingProvenance(field: String) throws {
        try withBaseline { _, path in
            var request = Support.request(baseline: path)
            switch field {
            case "run id": request.runID = "  "
            case "requested ref": request.requestedRef = ""
            case "suite filter": request.filter = ""
            case "swift version text": request.swiftVersion = " "
            case "ref SHA": request.refSHA = ""
            case "suite SHA": request.suiteSHA = ""
            case "run start": request.startedAt = ""
            default: request.finishedAt = ""
            }
            expectRejected("missing required provenance: \(field)") { _ = try ResultWriter.makeFile(request, host: Support.host) }
        }
    }

    @Test
    func writerRejectsMalformedProvenance() throws {
        try withBaseline { _, path in
            var request = Support.request(baseline: path)
            request.refSHA = "main"
            expectRejected("full 40-character") { _ = try ResultWriter.makeFile(request, host: Support.host) }
            request = Support.request(baseline: path)
            request.startedAt = "yesterday"
            expectRejected("ISO 8601 UTC") { _ = try ResultWriter.makeFile(request, host: Support.host) }
            request = Support.request(baseline: path)
            request.finishedAt = "2026-10-29T09:00:00Z"
            expectRejected("finished before it started") { _ = try ResultWriter.makeFile(request, host: Support.host) }
            request = Support.request(baseline: "/nonexistent/baseline.json")
            expectRejected("cannot read native baseline") { _ = try ResultWriter.makeFile(request, host: Support.host) }
        }
    }

    @Test(arguments: ["run", "ref", "suite", "toolchain", "host"])
    func validatorRejectsMissingWrapperSection(section: String) throws {
        let data = try mutated { $0.removeValue(forKey: section) }
        expectRejected("does not match the schema") { _ = try ResultValidator.decode(data) }
    }

    @Test
    func validatorRejectsEmptyProvenanceValues() throws {
        let emptySHA = try mutated { object in
            var suite = object["suite"] as? [String: Any] ?? [:]
            suite["sha"] = ""
            object["suite"] = suite
        }
        expectRejected("missing required provenance: suite SHA") { _ = try ResultValidator.decode(emptySHA) }
        let emptyCPU = try mutated { object in
            var host = object["host"] as? [String: Any] ?? [:]
            host["cpuModel"] = ""
            object["host"] = host
        }
        expectRejected("missing required provenance: host CPU model") { _ = try ResultValidator.decode(emptyCPU) }
        let debug = try mutated { object in
            var toolchain = object["toolchain"] as? [String: Any] ?? [:]
            toolchain["buildMode"] = "debug"
            object["toolchain"] = toolchain
        }
        expectRejected("build mode must be release") { _ = try ResultValidator.decode(debug) }
    }

    // MARK: - Benchmark names and metrics

    @Test(arguments: ["unknown.workload [\(Support.backend)] / 16", "entity.create.empty", "entity.create.empty [\(Support.backend)] / many",
                      "entity.create.empty [other] / 16", "entity.create.empty [\(Support.backend)] / 15"])
    func writerRejectsUnparseableOrUnknownBenchmarkNames(name: String) throws {
        try withBaseline(Support.syntheticEnvelope(variant: 0, name: name)) { _, path in
            expectRejected("does not parse to a registered workload identity") {
                _ = try ResultWriter.makeFile(Support.request(baseline: path), host: Support.host)
            }
        }
    }

    @Test
    func writerRejectsWrongTarget() throws {
        var envelope = Support.syntheticEnvelope(variant: 0)
        let results = try #require(envelope.results.first?.value)
        envelope.results = [NativeBenchmarkIdentifier(target: "ECSBenchmark", name: Support.registeredName): results]
        try withBaseline(envelope) { _, path in
            expectRejected("belongs to target 'ECSBenchmark'") { _ = try ResultWriter.makeFile(Support.request(baseline: path), host: Support.host) }
        }
    }

    @Test
    func writerRejectsMissingOrExtraMetrics() throws {
        var missing = Support.syntheticEnvelope(variant: 0)
        let key = try #require(missing.results.keys.first)
        missing.results[key]?.removeLast()
        try withBaseline(missing) { _, path in
            expectRejected("has metrics") { _ = try ResultWriter.makeFile(Support.request(baseline: path), host: Support.host) }
        }
        var extra = Support.syntheticEnvelope(variant: 0)
        extra.results[key]?.append(Support.syntheticResult(metric: .instructions, variant: 0))
        try withBaseline(extra) { _, path in
            expectRejected("has metrics") { _ = try ResultWriter.makeFile(Support.request(baseline: path), host: Support.host) }
        }
    }

    @Test
    func writerRecordsMissingThroughputWithItsReason() throws {
        var envelope = Support.syntheticEnvelope(variant: 0)
        let key = try #require(envelope.results.keys.first)
        envelope.results[key]?.removeAll { $0.metric == .throughput }
        try withBaseline(envelope) { _, path in
            let file = try ResultWriter.makeFile(Support.request(baseline: path), host: Support.host)
            let unrecorded = try #require(file.benchmarks[0].unrecordedMetrics)
            #expect(unrecorded == [UnrecordedMetric(metric: BenchmarkMetric.throughput.description, reason: ResultSchema.optionalMetricReason)])
            #expect(unrecorded[0].reason.contains("Benchmark 1.38.1"))
            // Survives the encode and validate round trip.
            let decoded = try ResultValidator.decode(BenchmarkResultFile.encoder().encode(file))
            #expect(decoded.benchmarks[0].unrecordedMetrics == unrecorded)
        }
    }

    @Test
    func writerStillRejectsOtherMissingMetrics() throws {
        for metric in CompatManifest.metrics where metric != .throughput {
            var envelope = Support.syntheticEnvelope(variant: 0)
            let key = try #require(envelope.results.keys.first)
            envelope.results[key]?.removeAll { $0.metric == metric }
            try withBaseline(envelope) { _, path in
                expectRejected("only") { _ = try ResultWriter.makeFile(Support.request(baseline: path), host: Support.host) }
            }
        }
    }

    @Test
    func validatorAcceptsOnlyThroughputAsUnrecorded() throws {
        var file = try ResultValidator.decode(validFileData())
        let key = try #require(file.baseline.results.keys.first)
        file.baseline.results[key]?.removeAll { $0.metric == .throughput }
        let record = UnrecordedMetric(metric: ResultSchema.optionalMetric, reason: ResultSchema.optionalMetricReason)
        file.benchmarks[0].unrecordedMetrics = [record]
        try ResultValidator.validate(file)
        // Empty reason.
        file.benchmarks[0].unrecordedMetrics = [UnrecordedMetric(metric: ResultSchema.optionalMetric, reason: " ")]
        expectRejected("without a reason") { try ResultValidator.validate(file) }
        // Listed twice.
        file.benchmarks[0].unrecordedMetrics = [record, record]
        expectRejected("twice") { try ResultValidator.validate(file) }
        // Another metric listed as unrecorded.
        file.benchmarks[0].unrecordedMetrics = [record, UnrecordedMetric(metric: BenchmarkMetric.wallClock.description, reason: "x")]
        expectRejected("only") { try ResultValidator.validate(file) }
        // A recorded metric cannot also be listed as unrecorded.
        var present = try ResultValidator.decode(validFileData())
        present.benchmarks[0].unrecordedMetrics = [record]
        expectRejected("also has it") { try ResultValidator.validate(present) }
    }

    @Test
    func validatorRejectsBenchmarkListThatDisagreesWithBaseline() throws {
        let renamed = try mutated { object in
            var benchmarks = object["benchmarks"] as? [[String: Any]] ?? []
            benchmarks[0]["name"] = "entity.create.minimal [\(Support.backend)] / 16"
            object["benchmarks"] = benchmarks
        }
        expectRejected("does not match its parsed identity") { _ = try ResultValidator.decode(renamed) }
        let unknown = try mutated { object in
            var benchmarks = object["benchmarks"] as? [[String: Any]] ?? []
            benchmarks[0]["identity"] = "bogus.identity"
            benchmarks[0]["name"] = "bogus.identity [\(Support.backend)] / 16"
            object["benchmarks"] = benchmarks
        }
        expectRejected("unknown workload identity 'bogus.identity'") { _ = try ResultValidator.decode(unknown) }
        let empty = try mutated { $0["benchmarks"] = [Any]() }
        expectRejected("no benchmarks") { _ = try ResultValidator.decode(empty) }
    }

    @Test
    func validatorRejectsUnavailableBackend() throws {
        let data = try mutated { object in
            var ref = object["ref"] as? [String: Any] ?? [:]
            ref["backends"] = ["elsewhere"]
            object["ref"] = ref
        }
        expectRejected("not available for this ref") { _ = try ResultValidator.decode(data) }
    }

    // MARK: - Command line

    @Test
    func commandLineWritesAndValidates() throws {
        try withBaseline { directory, path in
            let out = directory.appendingPathComponent("result.json").path
            let request = Support.request(baseline: path)
            let arguments = [
                "write", "--baseline", path, "--out", out, "--run-id", request.runID, "--started", request.startedAt,
                "--finished", request.finishedAt, "--ref", request.requestedRef, "--ref-sha", request.refSHA,
                "--suite-sha", request.suiteSHA, "--filter", request.filter, "--package-resolved", request.packageResolvedPath,
                "--swift-version", request.swiftVersion
            ]
            #expect(ResultsCLI.run(arguments) == 0)
            #expect(ResultsCLI.run(["validate", out]) == 0)
            #expect(ResultsCLI.run(["validate", path]) != 0, "a native baseline is not a result file")
            #expect(ResultsCLI.run(["validate", "/nonexistent.json"]) != 0)
            #expect(ResultsCLI.run(Array(arguments.dropLast(2))) != 0, "missing --swift-version")
            #expect(ResultsCLI.run(arguments + ["--bogus", "x"]) != 0)
            #expect(ResultsCLI.run(arguments + ["--ref", "again"]) != 0)
            #expect(ResultsCLI.run([]) != 0)
            #expect(ResultsCLI.run(["frobnicate"]) != 0)
        }
    }
}
