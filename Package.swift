// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "Whiteboard",
    products: [
        .library(
            name: "Whiteboard",
            targets: ["Whiteboard"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mipalgu/gusimplewhiteboard.git", branch: "cwhiteboard"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Whiteboard",
            dependencies: [.product(name: "cwhiteboard", package: "gusimplewhiteboard")]),
        .testTarget(
            name: "WhiteboardTests",
            dependencies: ["Whiteboard"]),
    ]
)
