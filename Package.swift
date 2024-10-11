// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "FirebladeECS",
    products: [
        .library(name: "FirebladeECS",
                 targets: ["FirebladeECS"])
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
