// MD5.swift
// based on the Vapor/open-crypto project which tries to replicate the CryptoKit framework interface
// written by AdamFowler 2020/01/30
#if canImport(CommonCrypto)

import CommonCrypto

public struct MD5Digest : ByteDigest {
    public static var byteCount: Int { return Int(CC_MD5_DIGEST_LENGTH) }
    public var bytes: [UInt8]
}

public struct MD5: CCHashFunction {
    public typealias Digest = MD5Digest
    public static var algorithm: CCHmacAlgorithm { return CCHmacAlgorithm(kCCHmacAlgMD5) }
    var context: CC_MD5_CTX

    public static func hash(bytes: UnsafeRawBufferPointer) -> Self.Digest {
        var digest: [UInt8] = .init(repeating: 0, count: Digest.byteCount)
        CC_MD5(bytes.baseAddress, CC_LONG(bytes.count), &digest)
        return .init(bytes: digest)
    }

    public init() {
        context = CC_MD5_CTX()
        CC_MD5_Init(&context)
    }
    
    public mutating func update(bytes: UnsafeRawBufferPointer) {
        CC_MD5_Update(&context, bytes.baseAddress, CC_LONG(bytes.count))
    }
    
    public mutating func finalize() -> Self.Digest {
        var digest: [UInt8] = .init(repeating: 0, count: Digest.byteCount)
        CC_MD5_Final(&digest, &context)
        return .init(bytes: digest)
    }
}

#else

import CAWSCrypto

public struct MD5Digest : ByteDigest {
    public static var byteCount: Int { return Int(MD5_DIGEST_LENGTH) }
    public var bytes: [UInt8]
}

public struct MD5: _OpenSSLHashFunction {
    public typealias Digest = MD5Digest
    public static var algorithm: OpaquePointer { return EVP_md5() }
    var context: OpaquePointer
}

#endif
