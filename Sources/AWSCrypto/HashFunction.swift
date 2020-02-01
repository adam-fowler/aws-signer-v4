// HashFunction.swift
// HashFunction protocol and OpenSSL, CommonCrypto specialisations
// based on the Vapor/open-crypto project which tries to replicate the CryptoKit framework interface
// written by AdamFowler 2020/01/30
import protocol Foundation.DataProtocol

/// Protocol for Hashing function
public protocol HashFunction {
    /// associated digest object
    associatedtype Digest: AWSCrypto.Digest

    /// hash raw buffer
    static func hash(bufferPointer: UnsafeRawBufferPointer) -> Self.Digest

    /// initialization
    init()
    
    /// update hash function with data
    mutating func update(bufferPointer: UnsafeRawBufferPointer)
    /// finalize hash function and return digest
    mutating func finalize() -> Self.Digest
}

extension HashFunction {
    
    /// default version of hash which call init, update and finalize
    public static func hash(bufferPointer: UnsafeRawBufferPointer) -> Self.Digest {
        var function = Self()
        function.update(bufferPointer: bufferPointer)
        return function.finalize()
    }
    
    /// version of hash that takes data in any form that complies with DataProtocol
    public static func hash<D: DataProtocol>(data: D) -> Self.Digest {
        if let digest = data.withContiguousStorageIfAvailable({ bytes in
            return self.hash(bufferPointer: .init(bytes))
        }) {
            return digest
        } else {
            var buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: data.count)
            data.copyBytes(to: buffer)
            defer { buffer.deallocate() }
            return self.hash(bufferPointer: .init(buffer))
        }
    }
    
    /// version of update that takes data in any form that complies with DataProtocol
    public mutating func update<D: DataProtocol>(data: D) {
        if let digest = data.withContiguousStorageIfAvailable({ bytes in
            return self.update(bufferPointer: .init(bytes))
        }) {
            return digest
        } else {
            var buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: data.count)
            data.copyBytes(to: buffer)
            defer { buffer.deallocate() }
            self.update(bufferPointer: .init(buffer))
        }
    }
}

#if canImport(CommonCrypto)

import CommonCrypto

/// public protocol for Common Crypto hash functions
public protocol CCHashFunction: HashFunction {
    static var algorithm: CCHmacAlgorithm { get }
}

#else

import CAWSCrypto

/// public protocol for OpenSSL hash function
public protocol OpenSSLHashFunction: HashFunction {
    static var algorithm: OpaquePointer { get }
}

/// internal protocol for OpenSSL hash functions that hides implementation details
protocol _OpenSSLHashFunction: OpenSSLHashFunction where Digest: ByteDigest {
    var context: OpaquePointer { get set }
    init(context: OpaquePointer)
}

extension _OpenSSLHashFunction {
    /// initialization
    public init() {
        self.init(context: AWSCRYPTO_EVP_MD_CTX_new())
        initialize()
    }
    
    /// initialize hash function
    mutating func initialize() {
        EVP_DigestInit_ex(context, Self.algorithm, nil)
    }
    
    /// update hash function with data
    public mutating func update(bufferPointer: UnsafeRawBufferPointer) {
        EVP_DigestUpdate(context, bufferPointer.baseAddress, bufferPointer.count)
    }
    
    /// finalize hash function and return digest
    public mutating func finalize() -> Self.Digest {
        var digest: [UInt8] = .init(repeating: 0, count: Digest.byteCount)
        var count: UInt32 = 0
        EVP_DigestFinal_ex(context, &digest, &count)
        AWSCRYPTO_EVP_MD_CTX_free(context)
        return .init(bytes: .init(digest))
    }
}

#endif
