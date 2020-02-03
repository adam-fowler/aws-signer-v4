// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AWSSigner",
    platforms: [.macOS(.v10_15), .iOS(.v13), .watchOS(.v6), .tvOS(.v13)],
    products: [
        .library(name: "AWSSigner", targets: ["AWSSigner"]),
        .library(name: "HTTPClientAWSSigner", targets: ["HTTPClientAWSSigner"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-nio", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/swift-server/async-http-client", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(name: "AWSSigner", dependencies: ["Crypto", "NIO", "NIOHTTP1"]),
        .target(name: "HTTPClientAWSSigner", dependencies: ["AWSSigner", "AsyncHTTPClient"]),
        .testTarget(name: "AWSSignerTests", dependencies: ["AWSSigner", "HTTPClientAWSSigner"])
    ]
)
