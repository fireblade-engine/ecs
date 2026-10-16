// swift-tools-version: 6.1
import CompilerPluginSupport
import PackageDescription

/// Platforms that run macro expansion tests. The expansion tests import the macro implementation,
/// which is only available where the compiler itself runs, not on iOS, tvOS, watchOS or WebAssembly.
let macroHostPlatforms: [Platform] = [.macOS, .linux, .windows]

/// Macro host platforms where the expansion tests reach the macro implementation through the macro target.
/// SwiftPM uses the swift-syntax prebuilt only for macro targets and test targets that depend on a macro target.
/// A test target that links swift-syntax or FirebladeECSMacrosSupport without a macro target dependency makes it
/// build swift-syntax from source for the whole package graph, even when a platform condition excludes the
/// dependency. Windows is left out because SwiftPM 6.1 links the plugin's main symbol into test bundles that
/// depend on a macro target. Xcode builds a test target with a macro dependency for the host only, so the iOS
/// workflow skips the expansion tests; they compile to nothing on iOS, tvOS, watchOS and WebAssembly anyway.
let macroTargetTestPlatforms: [Platform] = [.macOS, .linux]

/// Macro host platforms where the expansion tests link the macro support library directly instead.
let macroSupportLinkPlatforms: [Platform] = [.windows]

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
        // Integration tests use the macro like a client package does. They run on every platform and must not
        // depend on swift-syntax, so that the swift-syntax prebuilt stays usable (see macroTargetTestPlatforms).
        .testTarget(name: "FirebladeECSMacrosTests",
                    dependencies: ["FirebladeECSMacros"],
                    swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]),
        // Expansion tests run the macro implementation through swift-syntax's macro expansion test support.
        .testTarget(name: "FirebladeECSMacrosExpansionTests",
                    dependencies: [
                        .target(name: "FirebladeECSMacrosImpl", condition: .when(platforms: macroTargetTestPlatforms)),
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
