// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CopyPad",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "CopyPad",
            targets: ["CopyPad"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/aramnhammer/KeyboardShortcuts", from: "2.4.1")
    ],
    targets: [
        .executableTarget(
            name: "CopyPad",
            dependencies: [
                "KeyboardShortcuts"
            ],
            path: "Sources",
            resources: [
                .copy("Assets.xcassets"),
                .copy("Preview Content/Preview Assets.xcassets"),
                .copy("CopyPad.entitlements")
            ]
        ),
        // lol
        // .testTarget(
        //     name: "CopyPadTests",
        //     dependencies: ["CopyPad"]
        // ),
    ]
)