// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FirebladeECS",
    products: [
        .library(name: "FirebladeECS",
                 targets: ["FirebladeECS"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.3")
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
                    swiftSettings: [.enableUpcomingFeature("StrictConcurrency")])
    ],
    swiftLanguageModes: [.v6]
)
