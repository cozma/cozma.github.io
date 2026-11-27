// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MorningBoardKit",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "MorningBoardKit", targets: ["MorningBoardKit"])
    ],
    targets: [
        .target(
            name: "MorningBoardKit",
            path: "Sources/MorningBoardKit"
        ),
        .testTarget(
            name: "MorningBoardKitTests",
            dependencies: ["MorningBoardKit"],
            path: "Tests/MorningBoardKitTests"
        )
    ]
)
