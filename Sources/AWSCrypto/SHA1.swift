// SHA1.swift
// based on the Vapor/open-crypto project which tries to replicate the CryptoKit framework interface
// written by AdamFowler 2020/01/30
#if canImport(CommonCrypto)

import CommonCrypto

public extension Insecure {
    
    struct SHA1Digest : ByteDigest {
        public static var byteCount: Int { return Int(CC_SHA1_DIGEST_LENGTH) }
        public var bytes: [UInt8]
    }

    struct SHA1: CCHashFunction {
        public typealias Digest = SHA1Digest
        public static var algorithm: CCHmacAlgorithm { return CCHmacAlgorithm(kCCHmacAlgSHA1) }
        var context: CC_SHA1_CTX

        public static func hash(bufferPointer: UnsafeRawBufferPointer) -> Self.Digest {
            var digest: [UInt8] = .init(repeating: 0, count: Digest.byteCount)
            CC_SHA1(bufferPointer.baseAddress, CC_LONG(bufferPointer.count), &digest)
            return .init(bytes: digest)
        }

        public init() {
            context = CC_SHA1_CTX()
            CC_SHA1_Init(&context)
        }
        
        public mutating func update(bufferPointer: UnsafeRawBufferPointer) {
            CC_SHA1_Update(&context, bufferPointer.baseAddress, CC_LONG(bufferPointer.count))
        }
        
        public mutating func finalize() -> Self.Digest {
            var digest: [UInt8] = .init(repeating: 0, count: Digest.byteCount)
            CC_SHA1_Final(&digest, &context)
            return .init(bytes: digest)
        }
    }
}

#else

import CAWSCrypto

public extension Insecure {
    struct SHA1Digest : ByteDigest {
        public static var byteCount: Int { return Int(SHA_DIGEST_LENGTH) }
        public var bytes: [UInt8]
    }

    struct SHA1: _OpenSSLHashFunction {
        public typealias Digest = SHA1Digest
        public static var algorithm: OpaquePointer { return EVP_sha1() }
        var context: OpaquePointer
    }
}

#endif

