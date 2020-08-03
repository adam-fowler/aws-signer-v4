// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "aws-signer-v4",
    products: [
        .library(name: "AWSSigner", targets: ["AWSSigner"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio", .upToNextMajor(from: "2.13.1"))
    ],
    targets: [
        .target(name: "AWSSigner", dependencies: ["AWSCrypto", "NIO", "NIOHTTP1"]),
        .target(name: "AWSCrypto", dependencies: []),
        
        .testTarget(name: "AWSSignerTests", dependencies: ["AWSSigner"])
    ]
)

// switch for whether to use swift crypto. Swift crypto requires macOS10.15 or iOS13.I'd rather not pass this requirement on
#if os(Linux)
let useSwiftCrypto = true
#else
let useSwiftCrypto = false
#endif

// Use Swift cypto on Linux.
if useSwiftCrypto {
    package.dependencies.append(.package(url: "https://github.com/apple/swift-crypto.git", from: "1.0.0"))
    package.targets.first{$0.name == "AWSCrypto"}?.dependencies.append("Crypto")
}
