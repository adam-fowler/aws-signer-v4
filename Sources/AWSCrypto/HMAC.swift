// HMAC.swift
// based on the Vapor/open-crypto project which tries to replicate the CryptoKit framework interface
// written by AdamFowler 2020/01/30
import protocol Foundation.DataProtocol

/// Hash Authentication Code returned by HMAC
public struct HashAuthenticationCode: ByteArray {
    public var bytes: [UInt8]
}

#if canImport(CommonCrypto)

import CommonCrypto

/// Object generating HMAC for data block given a symmetric key
public struct HMAC<H: CCHashFunction> {
    
    let key: [UInt8]
    var context: CCHmacContext
    
    /// return authentication code for data block given a symmetric key
    public static func authenticationCode<D : DataProtocol>(for data: D, using key: [UInt8]) -> HashAuthenticationCode {
        var hmac = HMAC(key: key)
        hmac.update(data: data)
        return hmac.finalize()
    }
    
    /// update HMAC calculation with a block of data
    public mutating func update<D: DataProtocol>(data: D) {
        if let digest = data.withContiguousStorageIfAvailable({ bytes in
            return self.update(bytes: .init(bytes))
        }) {
            return digest
        } else {
            var buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: data.count)
            data.copyBytes(to: buffer)
            defer { buffer.deallocate() }
            self.update(bytes: .init(buffer))
        }
    }
}

extension HMAC {
    /// initialize HMAC with symmetric key
    public init(key: [UInt8]) {
        self.key = key
        self.context = CCHmacContext()
        self.initialize()
    }
    
    /// initialize HMAC calculation
    mutating func initialize() {
        CCHmacInit(&context, H.algorithm, key, key.count)
    }
    
    /// update HMAC calculation with a buffer
    public mutating func update(bytes: UnsafeRawBufferPointer) {
        CCHmacUpdate(&context, bytes.baseAddress, bytes.count)
    }
    
    /// finalize HMAC calculation and return authentication code
    public mutating func finalize() -> HashAuthenticationCode {
        var authenticationCode: [UInt8] = .init(repeating: 0, count: H.Digest.byteCount)
        CCHmacFinal(&context, &authenticationCode)
        return .init(bytes: authenticationCode)
    }
}

#else

import CAWSCrypto

public struct HMAC<H: OpenSSLHashFunction> {
    
    let key: [UInt8]
    var context: OpaquePointer
    
    /// return authentication code for data block given a symmetric key
    public static func authenticationCode<D : DataProtocol>(for data: D, using key: [UInt8]) -> HashAuthenticationCode {
        var hmac = HMAC(key: key)
        hmac.update(data: data)
        return hmac.finalize()
    }
    
    /// update HMAC calculation with a block of data
    public mutating func update<D: DataProtocol>(data: D) {
        if let digest = data.withContiguousStorageIfAvailable({ bytes in
            return self.update(bytes: bytes)
        }) {
            return digest
        } else {
            var buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: data.count)
            data.copyBytes(to: buffer)
            defer { buffer.deallocate() }
            self.update(bytes: .init(buffer))
        }
    }
}

extension HMAC {
    /// initialize HMAC with symmetric key
    public init(key: [UInt8]) {
        self.key = key
        self.context = AWSCRYPTO_HMAC_CTX_new()
        self.initialize()
    }
    
    /// initialize HMAC calculation
    mutating func initialize() {
        HMAC_Init_ex(context, key, Int32(key.count), H.algorithm, nil)
    }
    
    /// update HMAC calculation with a buffer
    mutating func update(bytes: UnsafeBufferPointer<UInt8>) {
        HMAC_Update(context, bytes.baseAddress, bytes.count)
    }
    
    /// finalize HMAC calculation and return authentication code
    public mutating func finalize() -> HashAuthenticationCode {
        var authenticationCode: [UInt8] = .init(repeating: 0, count: H.Digest.byteCount)
        var length: UInt32 = 0
        HMAC_Final(context, &authenticationCode, &length)
        AWSCRYPTO_HMAC_CTX_free(context)
        return .init(bytes: authenticationCode)
    }
}

#endif