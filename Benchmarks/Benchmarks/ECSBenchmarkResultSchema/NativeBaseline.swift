// App-owned mirror of the Benchmark plugin's baseline envelope (`BenchmarkBaseline` in the plugin's BenchmarkTool, which
// is internal to the plugin). Field names and the encoding of the results dictionary match the plugin's JSON exactly, so
// a file written here can be read back by `swift package benchmark baseline read`. The payload types are the package's
// own public `BenchmarkResult` and `Statistics`.
import Benchmark

public struct NativeBenchmarkMachine: Codable, Equatable, Sendable {
    public var hostname: String
    public var processors: Int
    public var processorType: String
    /// Gigabytes, as recorded by the plugin.
    public var memory: Int
    public var kernelVersion: String

    public init(hostname: String, processors: Int, processorType: String, memory: Int, kernelVersion: String) {
        self.hostname = hostname
        self.processors = processors
        self.processorType = processorType
        self.memory = memory
        self.kernelVersion = kernelVersion
    }
}

public struct NativeBenchmarkIdentifier: Codable, Hashable, Comparable, Sendable {
    public var target: String
    public var name: String

    public init(target: String, name: String) {
        self.target = target
        self.name = name
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.target, lhs.name) < (rhs.target, rhs.name)
    }
}

public struct NativeBaselineEnvelope: Codable {
    public var baselineName: String
    public var machine: NativeBenchmarkMachine
    public var results: [NativeBenchmarkIdentifier: [BenchmarkResult]]

    public init(baselineName: String, machine: NativeBenchmarkMachine, results: [NativeBenchmarkIdentifier: [BenchmarkResult]]) {
        self.baselineName = baselineName
        self.machine = machine
        self.results = results
    }

    private enum CodingKeys: String, CodingKey {
        case baselineName, machine, results
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baselineName = try container.decode(String.self, forKey: .baselineName)
        machine = try container.decode(NativeBenchmarkMachine.self, forKey: .machine)
        results = try container.decode([NativeBenchmarkIdentifier: [BenchmarkResult]].self, forKey: .results)
    }

    /// Encodes the dictionary the way `Dictionary` encodes non-string keys (a flat key, value, key, value array) but in
    /// sorted key order, so the output is deterministic.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(baselineName, forKey: .baselineName)
        try container.encode(machine, forKey: .machine)
        var flat = container.nestedUnkeyedContainer(forKey: .results)
        for key in results.keys.sorted() {
            try flat.encode(key)
            try flat.encode(results[key])
        }
    }
}
