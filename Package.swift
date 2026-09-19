// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MuPiBoxControl",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "MuPiBoxCore", targets: ["MuPiBoxCore"])
    ],
    targets: [
        .target(name: "MuPiBoxCore"),
        .testTarget(name: "MuPiBoxCoreTests", dependencies: ["MuPiBoxCore"])
    ]
)
