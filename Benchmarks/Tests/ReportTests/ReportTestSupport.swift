import Foundation
@testable import ECSBenchmarkReport
@testable import ECSBenchmarkResultSchema

/// Constants and helpers the report tests share with the schema tests' `Support`.
enum ReportSupport {
    static let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    static let suiteSHA = String(repeating: "cd", count: 20)

    static let host = ResultHost(osName: "macOS", osVersion: "26.0.0", architecture: "arm64", cpuModel: "Test CPU", coreCount: 10, physicalMemoryBytes: 68_719_476_736)

    static func scratchDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("report-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
