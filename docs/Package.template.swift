// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "MPVKit",
    platforms: [.macOS(.v11), .iOS(.v14), .tvOS(.v14)],
    products: [
        .library(
            name: "MPVKit",
            targets: ["_MPVKit"]
        ),
    ],
    targets: [
        .target(
            name: "_MPVKit",
            dependencies: [
                // Libmpv, the 7 FFmpeg libraries, Libuchardet and everything
                // _FFmpeg used to list are all inside one dynamic
                // MPVKit.xcframework now -- see the root Package.swift for the
                // full account. Depending on them separately as well made every
                // consumer link a second, static copy of each on top of the dylib
                // that already contained them, which is how libdovi's Rust
                // symbols ended up binding across images and crashing arm64e
                // Apple TV hardware at launch.
                //
                // Libbluray is gone for a different reason: mpv is built
                // -Dlibbluray=disabled, so nothing referenced it.
                //
                // NOTE: MPVKit_dynamic must be emitted into the AUTO_GENERATE
                // region below as a binaryTarget pointing at the merged
                // MPVKit.xcframework.zip. Sources/BuildScripts does not produce
                // that framework yet -- the merge step lives in Cue's
                // Scripts/mpvkit-link-dynamic.sh, which consumes this build's
                // dist/ tree. Until it is wired into the release pipeline and
                // Library.targets emits MPVKit_dynamic (and stops emitting the
                // merged-away libraries), a generated release/Package.swift will
                // fail to resolve rather than silently reintroducing the
                // duplication.
                "MPVKit_dynamic", "_FFmpeg",
                .target(name: "Libluajit", condition: .when(platforms: [.macOS])),
            ],
            path: "Sources/_MPVKit",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreImage"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("Metal"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("CoreAudio"),
            ]
        ),
        .target(
            name: "_FFmpeg",
            // Empty: every library that used to be listed here is inside
            // MPVKit_dynamic. The target survives for its linkerSettings below.
            dependencies: [],
            path: "Sources/_FFmpeg",
            linkerSettings: [
                .linkedFramework("AudioToolbox"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("CoreFoundation"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("Metal"),
                .linkedFramework("Security"),
                .linkedFramework("VideoToolbox"),
                .linkedLibrary("bz2"),
                .linkedLibrary("iconv"),
                .linkedLibrary("expat"),
                .linkedLibrary("resolv"),
                .linkedLibrary("xml2"),
                .linkedLibrary("z"),
                .linkedLibrary("c++"),
            ]
        ),

        //AUTO_GENERATE_TARGETS_BEGIN//
        //AUTO_GENERATE_TARGETS_END//
    ]
)
