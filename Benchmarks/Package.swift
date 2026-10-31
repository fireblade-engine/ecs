// swift-tools-version: 6.3
// Runtime benchmarks for FirebladeECS, kept in a separate package so that the
// benchmark dependency never becomes part of FirebladeECS's dependency graph.
//
// Run from this directory:
//   swift package benchmark

import Foundation
import PackageDescription

// ECS_BENCHMARK_SUITE=shared builds only the compatibility suite, which compiles against every FirebladeECS
// revision. Scripts/benchmark-snapshot.sh sets it for snapshots of older revisions, whose component model the
// reference benchmarks in ECSBenchmark do not support.
let sharedSuiteOnly = ProcessInfo.processInfo.environment["ECS_BENCHMARK_SUITE"] == "shared"

// ECS_BENCHMARK_CLASS_COMPONENTS=1 (set by the snapshot script together with -DECS_CLASS_COMPONENTS) drops the macro
// product, which revisions with class components do not have. Value revisions declare their components with @Component.
let classComponents = ProcessInfo.processInfo.environment["ECS_BENCHMARK_CLASS_COMPONENTS"] == "1"

let package = Package(
    name: "ECSBenchmarks",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    dependencies: [
        .package(name: "ecs", path: ".."),
        .package(url: "https://github.com/ordo-one/benchmark", .upToNextMajor(from: "1.38.1"))
    ],
    targets: [
        // Workload definitions, per-revision adapter and the enabled metric set. Shared by the plugin executable,
        // the result tool and the tests.
        .target(
            name: "ECSCompatSuite",
            dependencies: [
                .product(name: "FirebladeECS", package: "ecs"),
                .product(name: "Benchmark", package: "benchmark")
            ] + (classComponents ? [] : [.product(name: "FirebladeECSMacros", package: "ecs")]),
            path: "Benchmarks/ECSCompatSuite"
        ),
        .executableTarget(
            name: "ECSCompatBenchmark",
            dependencies: [
                "ECSCompatSuite",
                .product(name: "Benchmark", package: "benchmark")
            ],
            path: "Benchmarks/ECSCompatBenchmark",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "benchmark")
            ]
        ),
        // Wrapper schema, native-baseline mirror, writer and validator of the per-ref result file.
        .target(
            name: "ECSBenchmarkResultSchema",
            dependencies: [
                "ECSCompatSuite",
                .product(name: "Benchmark", package: "benchmark")
            ],
            path: "Benchmarks/ECSBenchmarkResultSchema"
        ),
        .executableTarget(
            name: "ECSBenchmarkResults",
            dependencies: ["ECSBenchmarkResultSchema"],
            path: "Benchmarks/ECSBenchmarkResults"
        ),
        .testTarget(
            name: "ResultSchemaTests",
            dependencies: [
                "ECSBenchmarkResultSchema",
                "ECSCompatSuite",
                .product(name: "Benchmark", package: "benchmark")
            ],
            path: "Tests/ResultSchemaTests",
            resources: [.copy("Fixtures")]
        ),
        .testTarget(
            name: "CompatSuiteTests",
            dependencies: ["ECSCompatSuite"],
            path: "Tests/CompatSuiteTests"
        )
    ] + (sharedSuiteOnly ? [] : [
        .executableTarget(
            name: "ECSBenchmark",
            dependencies: [
                .product(name: "FirebladeECS", package: "ecs"),
                .product(name: "Benchmark", package: "benchmark")
            ],
            path: "Benchmarks/ECSBenchmark",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "benchmark")
            ]
        ),
        .testTarget(
            name: "ReferenceUpdateTests",
            dependencies: ["ECSBenchmark"],
            path: "Tests/ReferenceUpdateTests"
        )
    ])
)
