// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "NotchNotes",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "NotchNotes", targets: ["NotchNotes"])
    ],
    targets: [
        .executableTarget(name: "NotchNotes"),
        .testTarget(name: "NotchNotesTests", dependencies: ["NotchNotes"])
    ]
)
