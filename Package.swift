// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AWSSigner",
    products: [
        .library(name: "AWSSigner", targets: ["AWSSigner"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/async-http-client", .upToNextMajor(from: "1.0.0-alpha.1"))
    ],
    targets: [
        .target(name: "AWSSigner", dependencies: ["AsyncHTTPClient"]),
        .testTarget(name: "AWSSignerTests", dependencies: ["AWSSigner"]),
    ]
)
