// Public, read-only description of the suite as compiled for one FirebladeECS revision. The result tool embeds it so that
// every result file states which workloads, backends and metrics that revision's adapter really provides.
import Benchmark

public enum CompatManifest {
    public struct Workload: Codable, Equatable, Sendable {
        public let identity: String
        public let upstreamName: String
        /// `equivalent` or `adapted`.
        public let parityKind: String
        /// Why the workload is only adapted; nil when equivalent.
        public let parityReason: String?
        public let persistsState: Bool
    }

    public struct Unsupported: Codable, Equatable, Sendable {
        public let identity: String
        public let upstreamName: String
        public let reason: String
    }

    /// A benchmark name decomposed into its registered parts.
    public struct ParsedName: Equatable, Sendable {
        public let identity: String
        public let backend: String
        public let scale: Int
    }

    /// Target name of the executable the Benchmark plugin runs.
    public static let benchmarkTarget = "ECSCompatBenchmark"

    public static var componentModel: String {
        CompatSuite.componentModel
    }

    public static var backends: [String] {
        CompatSuite.backends
    }

    public static var metrics: [BenchmarkMetric] {
        CompatSuite.metrics
    }

    public static var workloads: [Workload] {
        CompatWorkload.allCases.map { workload in
            let kind: String
            let reason: String?
            switch workload.parity {
            case .equivalent:
                kind = "equivalent"
                reason = nil
            case let .adapted(why):
                kind = "adapted"
                reason = why
            }
            return Workload(identity: workload.identity, upstreamName: workload.upstreamName, parityKind: kind, parityReason: reason, persistsState: workload.persistsState)
        }
    }

    public static var unsupported: [Unsupported] {
        CompatUnsupported.all.map { Unsupported(identity: $0.identity, upstreamName: $0.upstreamName, reason: $0.reason) }
    }

    /// Everything that changes what a run measures, other than the suite commit and the filter: enabled metrics and the
    /// sampling parameters. Hashed into the result's configuration hash.
    public static var configurationDescription: String {
        let metricList = metrics.map(\.description).joined(separator: ",")
        return "metrics=\(metricList);warmupIterations=\(CompatSuite.warmupIterations);maxIterations=\(CompatSuite.maxIterations);"
            + "maxDuration=\(CompatSuite.maxDuration);maxScale=\(CompatWorkload.maximumScale)"
    }

    /// Parses `<identity> [<backend>] / <scale>` and accepts it only if that exact benchmark is registered.
    public static func parseBenchmarkName(_ name: String) -> ParsedName? {
        guard let space = name.firstIndex(of: " ") else { return nil }
        let identity = String(name[..<space])
        guard let workload = CompatWorkload(rawValue: identity) else { return nil }
        for backend in CompatSuite.backends {
            for scale in workload.registeredScales where workload.benchmarkName(backend: backend, scale: scale) == name {
                return ParsedName(identity: identity, backend: backend, scale: scale)
            }
        }
        return nil
    }
}
