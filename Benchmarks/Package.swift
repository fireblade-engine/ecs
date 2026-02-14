// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "ECSBenchmarks",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: "../"),
        .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.29.11"))
    ],
    targets: [
        .executableTarget(
            name: "ECSBenchmark",
            dependencies: [
                .product(name: "FirebladeECS", package: "ecs"),
                .product(name: "Benchmark", package: "package-benchmark")
            ],
            path: "Benchmarks/ECSBenchmark",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
            ]
        )
    ]
)
