// swift-tools-version: 6.1
import CompilerPluginSupport
import Foundation
import PackageDescription

/// Platforms that run macro expansion tests. The expansion tests import the macro implementation,
/// which is only available where the compiler itself runs, not on iOS, tvOS, watchOS or WebAssembly.
let macroHostPlatforms: [Platform] = [.macOS, .linux, .windows]

/// Platforms that link the macro support library into the macro test targets when `linksMacroSupport` is set.
/// Besides the macro host platforms, Xcode builds a testable copy of the macro target into Apple platform test
/// bundles, which needs the support library at link time. WebAssembly builds don't.
let macroSupportLinkPlatforms: [Platform] = macroHostPlatforms + [.iOS, .tvOS, .watchOS, .visionOS, .macCatalyst]

/// Whether the macro tests link the macro support library instead of depending on the macro target.
///
/// SwiftPM uses the swift-syntax prebuilt only for macro targets and test targets that depend on a macro target.
/// A test target that links swift-syntax or FirebladeECSMacrosSupport without a macro target dependency makes it
/// build swift-syntax from source for the whole package graph, even when a platform condition excludes the
/// dependency. So by default the expansion tests depend on the macro target and nothing links the support library.
///
/// Builds where that layout fails link the support library instead (and build swift-syntax from source):
/// - Windows hosts: SwiftPM 6.1 links the plugin's `main` into test bundles that depend on a macro target.
/// - Xcode builds for iOS, tvOS, watchOS and visionOS (Xcode 16 and 26) and WebAssembly cross builds: the CI
///   workflows set `FIREBLADE_ECS_LINK_MACRO_SUPPORT=1`, because the manifest cannot see the destination.
#if os(Windows)
let linksMacroSupport = true
#else
let linksMacroSupport = ProcessInfo.processInfo.environment["FIREBLADE_ECS_LINK_MACRO_SUPPORT"] == "1"
#endif

/// Dependencies of the integration tests, which use the macro like a client package does.
let macroIntegrationTestDependencies: [Target.Dependency] = linksMacroSupport
    ? ["FirebladeECSMacros", .target(name: "FirebladeECSMacrosSupport", condition: .when(platforms: macroSupportLinkPlatforms))]
    : ["FirebladeECSMacros"]

/// Dependencies of the expansion tests, which run the macro implementation through swift-syntax's macro
/// expansion test support. The test sources compile only on `macroHostPlatforms`.
let macroExpansionTestDependencies: [Target.Dependency] = [
    linksMacroSupport
        ? .target(name: "FirebladeECSMacrosSupport", condition: .when(platforms: macroSupportLinkPlatforms))
        : .target(name: "FirebladeECSMacrosImpl", condition: .when(platforms: [.macOS, .linux])),
    .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax", condition: .when(platforms: macroHostPlatforms)),
    .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax", condition: .when(platforms: macroHostPlatforms))
]

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
                    dependencies: macroIntegrationTestDependencies,
                    swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]),
        .testTarget(name: "FirebladeECSMacrosExpansionTests",
                    dependencies: macroExpansionTestDependencies,
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
