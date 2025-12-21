// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "aws-signer-v4",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .watchOS(.v6), .tvOS(.v13), .macCatalyst(.v13), .visionOS(.v1),
    ],
    products: [
        .library(name: "AWSSigner", targets: ["AWSSigner"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio", from: "2.86.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0"..<"5.0.0"),
    ],
    targets: [
        .target(
            name: "AWSSigner",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "Crypto", package: "swift-crypto"),
            ]
        ),
        .testTarget(name: "AWSSignerTests", dependencies: ["AWSSigner"]),
    ]
)
