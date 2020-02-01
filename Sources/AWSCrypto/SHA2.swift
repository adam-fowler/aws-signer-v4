// SHA2.swift
// based on the Vapor/open-crypto project which tries to replicate the CryptoKit framework interface
// written by AdamFowler 2020/01/30
#if canImport(CommonCrypto)

public struct SHA256Digest : ByteDigest {
    public static var byteCount: Int { return Int(CC_SHA256_DIGEST_LENGTH) }
    public var bytes: [UInt8]
}

import CommonCrypto

public struct SHA256: CCHashFunction {
    public typealias Digest = SHA256Digest
    public static var algorithm: CCHmacAlgorithm { return CCHmacAlgorithm(kCCHmacAlgSHA256) }
    var context: CC_SHA256_CTX

    public static func hash(bytes: UnsafeRawBufferPointer) -> Self.Digest {
        var digest: [UInt8] = .init(repeating: 0, count: Digest.byteCount)
        CC_SHA256(bytes.baseAddress, CC_LONG(bytes.count), &digest)
        return .init(bytes: digest)
    }

    public init() {
        context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)
    }
    
    public mutating func update(bytes: UnsafeRawBufferPointer) {
        CC_SHA256_Update(&context, bytes.baseAddress, CC_LONG(bytes.count))
    }
    
    public mutating func finalize() -> Self.Digest {
        var digest: [UInt8] = .init(repeating: 0, count: Digest.byteCount)
        CC_SHA256_Final(&digest, &context)
        return .init(bytes: digest)
    }
}

#else

import CAWSCrypto

public struct SHA256Digest : ByteDigest {
    public static var byteCount: Int { return Int(SHA256_DIGEST_LENGTH) }
    public var bytes: [UInt8]
}

public struct SHA256: _OpenSSLHashFunction {
    public typealias Digest = SHA256Digest
    public static var algorithm: OpaquePointer { return EVP_sha256() }
    var context: OpaquePointer
}

#endif
