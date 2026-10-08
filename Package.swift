// swift-tools-version: 6.1
import CompilerPluginSupport
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
                 targets: ["FirebladeECS"]),
        .library(name: "FirebladeECSMacros",
                 targets: ["FirebladeECSMacros"])
    ],
    traits: [
        .trait(name: "benchmarks", description: "Enable performance tests")
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0" ..< "700.0.0")
    ],
    targets: [
        .target(name: "FirebladeECS",
                swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]),
        .target(name: "FirebladeECSMacrosSupport",
                dependencies: [
                    .product(name: "SwiftSyntax", package: "swift-syntax"),
                    .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                    .product(name: "SwiftDiagnostics", package: "swift-syntax")
                ]),
        .macro(name: "FirebladeECSMacrosImpl",
               dependencies: [
                   "FirebladeECSMacrosSupport",
                   .product(name: "SwiftSyntax", package: "swift-syntax"),
                   .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                   .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
               ]),
        .target(name: "FirebladeECSMacros",
                dependencies: ["FirebladeECS", "FirebladeECSMacrosImpl"],
                swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]),
        .testTarget(name: "FirebladeECSMacrosTests",
                    dependencies: [
                        "FirebladeECSMacros",
                        "FirebladeECSMacrosSupport",
                        .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
                        .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax")
                    ],
                    swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]),
        .testTarget(name: "FirebladeECSTests",
                    dependencies: ["FirebladeECS"],
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
