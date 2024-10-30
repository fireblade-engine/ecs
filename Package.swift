// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "FirebladeECS",
    products: [
        .library(name: "FirebladeECS",
                 targets: ["FirebladeECS"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(name: "FirebladeECS",
                exclude: ["Stencils/Family.stencil"]),
        .testTarget(name: "FirebladeECSTests",
                    dependencies: ["FirebladeECS"],
                    exclude: ["Stencils/FamilyTests.stencil"]),
        .testTarget(name: "FirebladeECSPerformanceTests",
                    dependencies: ["FirebladeECS"])
    ],
    swiftLanguageVersions: [.v5]
)
