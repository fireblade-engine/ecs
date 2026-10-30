import Benchmark
import ECSCompatSuite
import Foundation
import Testing
@testable import ECSBenchmarkResultSchema

@Suite
struct ResultWrapperTests {
    private func makeFile() throws -> (BenchmarkResultFile, WriteRequest) {
        let directory = try Support.scratchDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = try Support.writeEnvelope(Support.syntheticEnvelope(variant: 0), in: directory)
        let request = Support.request(baseline: path)
        let file = try ResultWriter.makeFile(request, host: Support.host)
        return (try ResultValidator.decode(BenchmarkResultFile.encoder().encode(file)), request)
    }

    @Test
    func wrapperAndProvenanceRoundTripFieldByField() throws {
        let (file, request) = try makeFile()
        #expect(file.schema == "fireblade-ecs-benchmark-result")
        #expect(file.schemaVersion == 1)
        #expect(file.run == ResultRun(id: "run-1", startedAt: request.startedAt, finishedAt: request.finishedAt))
        #expect(file.ref == ResultRef(requested: "1.4.3", sha: Support.sha, componentModel: CompatManifest.componentModel, backends: CompatManifest.backends))
        #expect(file.suite.sha == Support.suiteSHA)
        #expect(file.suite.target == "ECSCompatBenchmark")
        #expect(file.suite.filter == request.filter)
        #expect(file.suite.configurationHash == configurationHash(suiteSHA: Support.suiteSHA, filter: request.filter, configuration: CompatManifest.configurationDescription))
        #expect(file.toolchain == ResultToolchain(swiftVersion: request.swiftVersion, buildMode: "release"))
        #expect(file.host == Support.host)
        #expect(file.workloads == CompatManifest.workloads)
        #expect(file.unsupported == CompatManifest.unsupported)
        #expect(file.benchmarks == [ResultBenchmark(name: Support.registeredName, identity: "entity.create.empty", backend: Support.backend, scale: 16)])
        #expect(file.baseline.baselineName == "synthetic")
        #expect(file.baseline.machine == NativeBenchmarkMachine(hostname: "h", processors: 10, processorType: "arm64", memory: 64, kernelVersion: "Darwin"))
    }

    @Test
    func replicateProvenanceRoundTripsAndIsOptional() throws {
        let (plain, request) = try makeFile()
        #expect(plain.run.replicate == nil)
        #expect(!String(decoding: try BenchmarkResultFile.encoder().encode(plain), as: UTF8.self).contains("replicate"))

        var replicated = request
        replicated.replicate = ResultReplicate(index: 3, count: 10, round: 3, position: 2, seed: 18_446_744_073_709_551_615)
        let directory = try Support.scratchDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        replicated.baselinePath = try Support.writeEnvelope(Support.syntheticEnvelope(variant: 0), in: directory)
        let file = try ResultWriter.makeFile(replicated, host: Support.host)
        let decoded = try ResultValidator.decode(BenchmarkResultFile.encoder().encode(file))
        #expect(decoded.run.replicate == replicated.replicate)
        #expect(decoded.run.startedAt == replicated.startedAt && decoded.run.finishedAt == replicated.finishedAt)
    }

    @Test
    func packagesListEveryResolvedPin() throws {
        let (file, _) = try makeFile()
        let resolved = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: Support.realPackageResolved))) as? [String: Any]
        let pins = try #require(resolved?["pins"] as? [[String: Any]])
        #expect(file.packages.count == pins.count)
        for pin in pins {
            let identity = try #require(pin["identity"] as? String)
            let state = try #require(pin["state"] as? [String: Any])
            let match = try #require(file.packages.first { $0.identity == identity })
            #expect(match.revision == state["revision"] as? String)
            #expect(match.version == state["version"] as? String)
        }
        for required in ResultSchema.requiredPins { #expect(file.packages.contains(required)) }
    }

    @Test
    func manifestDescribesTheCompiledAdapter() {
        #expect(["class", "value"].contains(CompatManifest.componentModel))
        #expect(!CompatManifest.backends.isEmpty)
        #expect(CompatManifest.workloads.count == Set(CompatManifest.workloads.map(\.identity)).count)
        #expect(CompatManifest.workloads.contains { $0.persistsState })
        #expect(CompatManifest.workloads.allSatisfy { $0.parityKind == "equivalent" ? $0.parityReason == nil : !($0.parityReason ?? "").isEmpty })
        #expect(!CompatManifest.unsupported.isEmpty)
        #expect(CompatManifest.unsupported.allSatisfy { !$0.reason.isEmpty })
    }

    @Test
    func hostFactsAreGatheredInProcess() throws {
        let host = try HostFacts.current()
        #expect(!host.osName.isEmpty && !host.osVersion.isEmpty && !host.architecture.isEmpty && !host.cpuModel.isEmpty)
        #expect(host.coreCount == ProcessInfo.processInfo.processorCount)
        #expect(host.physicalMemoryBytes == ProcessInfo.processInfo.physicalMemory)
    }

    @Test
    func benchmarkNamesParseOnlyWhenRegistered() throws {
        let parsed = try #require(CompatManifest.parseBenchmarkName(Support.registeredName))
        #expect(parsed.identity == "entity.create.empty" && parsed.backend == Support.backend && parsed.scale == 16)
        #expect(CompatManifest.parseBenchmarkName("entity.create.no-entities [\(Support.backend)] / 0") != nil)
        #expect(CompatManifest.parseBenchmarkName("entity.create.no-entities [\(Support.backend)] / 16") == nil)
        for bad in ["", "entity.create.empty", "entity.create.empty [\(Support.backend)] / x", "entity.create.empty [nope] / 16",
                    "entity.create.empty [\(Support.backend)] / 17", "unknown.workload [\(Support.backend)] / 16"] {
            #expect(CompatManifest.parseBenchmarkName(bad) == nil, "\(bad)")
        }
    }

    @Test
    func sha256MatchesKnownVectors() {
        #expect(SHA256.hexDigest("") == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        #expect(SHA256.hexDigest("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        #expect(SHA256.hexDigest(String(repeating: "a", count: 1000)) == "41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3")
    }

    @Test
    func configurationHashCoversSuiteFilterAndConfiguration() {
        let base = configurationHash(suiteSHA: "a", filter: "f", configuration: "c")
        #expect(base.count == 64)
        #expect(base != configurationHash(suiteSHA: "b", filter: "f", configuration: "c"))
        #expect(base != configurationHash(suiteSHA: "a", filter: "g", configuration: "c"))
        #expect(base != configurationHash(suiteSHA: "a", filter: "f", configuration: "d"))
    }

    /// Pins the configuration the results are hashed over. If this fails, the suite configuration (enabled metrics, iteration
    /// constants) changed: results recorded before and after are no longer comparable. Update the pinned values deliberately.
    @Test
    func configurationDescriptionAndHashAreGolden() {
        #expect(
            CompatManifest.configurationDescription
                == "metrics=Time (wall clock),Time (total CPU),Throughput (# / s),Memory (resident peak),Malloc (total);warmupIterations=0;maxIterations=1000000000;maxDuration=0.5 seconds;maxScale=2097152"
        )
        #expect(
            configurationHash(suiteSHA: Support.suiteSHA, filter: "^entity.create.empty .* / 16$", configuration: CompatManifest.configurationDescription)
                == "0f5931e3b73836ef71b43bb63fccf52d13fde5da3bb24215c0f36b7a1f3cb93b"
        )
    }
}
