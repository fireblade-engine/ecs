// swift-tools-version: 6.3
// Runtime benchmarks for FirebladeECS, kept in a separate package so that the
// benchmark dependency never becomes part of FirebladeECS's dependency graph.
//
// Run from this directory:
//   swift package benchmark

import PackageDescription

let package = Package(
    name: "ECSBenchmarks",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    dependencies: [
        // The package identity of a path dependency is its directory name, i.e. the repository name.
        .package(path: ".."),
        .package(url: "https://github.com/ordo-one/benchmark", .upToNextMajor(from: "1.38.1"))
    ],
    targets: [
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
        )
    ]
)
