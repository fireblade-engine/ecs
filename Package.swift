// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "FirebladeECS",
    products: [
        .library(
            name: "FirebladeECS",
            targets: ["FirebladeECS"])
    ],
    targets: [
        .target(
            name: "FirebladeECS",
            dependencies: []),
        .testTarget(
            name: "FirebladeECSTests",
            dependencies: ["FirebladeECS"]),
        .testTarget(
            name: "FirebladeECSPerformanceTests",
            dependencies: ["FirebladeECS"])
    ]
)
