// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftLCARS",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "SwiftLCARS", targets: ["SwiftLCARS"]),
        .executable(name: "LCARSCatalog", targets: ["LCARSCatalog"])
    ],
    targets: [
        .target(name: "SwiftLCARS", resources: [.process("Resources")]),
        .executableTarget(name: "LCARSCatalog", dependencies: ["SwiftLCARS"], resources: [.process("Resources")]),
        .testTarget(name: "SwiftLCARSTests", dependencies: ["SwiftLCARS"])
    ]
)
