// swift-tools-version: 6.1
import CompilerPluginSupport
import PackageDescription

/// Platforms that run macro expansion tests. The expansion tests import the macro implementation,
/// which is only available where the compiler itself runs, not on iOS, tvOS, watchOS or WebAssembly.
let macroHostPlatforms: [Platform] = [.macOS, .linux, .windows]

/// Platforms that link the macro support library into the macro test target. Besides the macro host platforms,
/// Xcode builds a testable copy of the macro target into Apple platform test bundles, which needs the support
/// library at link time. WebAssembly builds don't.
let macroSupportLinkPlatforms: [Platform] = macroHostPlatforms + [.iOS, .tvOS, .watchOS, .visionOS, .macCatalyst]

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
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0" ..< "604.0.0")
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
                        .target(name: "FirebladeECSMacrosSupport", condition: .when(platforms: macroSupportLinkPlatforms)),
                        .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax",
                                 condition: .when(platforms: macroHostPlatforms)),
                        .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax",
                                 condition: .when(platforms: macroHostPlatforms))
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
