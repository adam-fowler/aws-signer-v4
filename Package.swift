// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AWSSigner",
    products: [
        .library(name: "AWSSigner", targets: ["AWSSigner"]),
        .library(name: "HTTPClientAWSSigner", targets: ["HTTPClientAWSSigner"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/swift-server/async-http-client", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(name: "AWSSigner", dependencies: ["NIOHTTP1"]),
        .target(name: "HTTPClientAWSSigner", dependencies: ["AWSSigner", "AsyncHTTPClient"]),
        .testTarget(name: "AWSSignerTests", dependencies: ["AWSSigner", "HTTPClientAWSSigner"]),
    ]
)

// switch for whether to use CAWSSigner to shim between OpenSSL versions
#if os(Linux)
let useOpenSSLShim = true
#else
let useOpenSSLShim = false
#endif

// AWSSDKSwiftCore target
let awsSdkSwiftCoreTarget = package.targets.first(where: {$0.name == "AWSSigner"})

// Decide on where we get our SSL support from. Linux usses NIOSSL to provide SSL. Linux also needs CAWSSDKOpenSSL to shim across different OpenSSL versions for the HMAC functions.
if useOpenSSLShim {
    package.targets.append(.target(name: "CAWSSigner"))
    awsSdkSwiftCoreTarget?.dependencies.append("CAWSSigner")
    package.dependencies.append(.package(url: "https://github.com/apple/swift-nio-ssl-support.git", from: "1.0.0"))
}
