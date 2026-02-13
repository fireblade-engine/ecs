// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FirebladeECS",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "FirebladeECS",
                 targets: ["FirebladeECS"])
    ],
    traits: [
        .trait(name: "benchmarks", description: "Enable performance tests")
    ],
    targets: [
        .target(name: "FirebladeECS",
                exclude: ["Stencils/Family.stencil"],
                swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]),
        .testTarget(name: "FirebladeECSTests",
                    dependencies: ["FirebladeECS"],
                    exclude: ["Stencils/FamilyTests.stencil"],
                    swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]),
        .testTarget(name: "FirebladeECSPerformanceTests",
                    dependencies: ["FirebladeECS"],
                    swiftSettings: [
                        .enableUpcomingFeature("StrictConcurrency"),
                        .define("FRB_ENABLE_BENCHMARKS", .when(traits: ["benchmarks"]))
                    ])
    ]
)

#if os(macOS)
package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.6")
)
#endif
