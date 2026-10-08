// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FGNetwork",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "FGNetwork", targets: ["FGNetwork"])
    ],
    targets: [
        .target(name: "FGNetwork"),
        .testTarget(
            name: "FGNetworkTests",
            dependencies: ["FGNetwork"]
        )
    ],
    swiftLanguageModes: [.v6]
)
