//
//  hash.swift
//  AsyncHTTPClient
//
//  Created by Adam Fowler on 29/08/2019.
//

import Foundation

//
//  Hash.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/13.
//
//

import Foundation

#if canImport(CAWSSignOpenSSL)

import CAWSSignOpenSSL

public func sha256(_ string: String) -> [UInt8] {
    var bytes = Array(string.utf8)
    return sha256(&bytes)
}

public func sha256(_ bytes: inout [UInt8]) -> [UInt8] {
    var hash = [UInt8](repeating: 0, count: Int(SHA256_DIGEST_LENGTH))
    SHA256(&bytes, bytes.count, &hash)
    return hash
}

public func sha256(_ data: Data) -> [UInt8] {
    return data.withUnsafeBytes { ptr in
        var hash = [UInt8](repeating: 0, count: Int(SHA256_DIGEST_LENGTH))
        if let bytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) {
            SHA256(bytes, data.count, &hash)
        }
        return hash
    }
}

#elseif canImport(CommonCrypto)

import CommonCrypto

public func sha256(_ string: String) -> [UInt8] {
    let bytes = Array(string.utf8)
    return sha256(bytes)
}

public func sha256(_ bytes: [UInt8]) -> [UInt8] {
    var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    CC_SHA256(bytes, CC_LONG(bytes.count), &hash)
    return hash
}

public func sha256(_ buffer: UnsafeBufferPointer<UInt8>) -> [UInt8] {
    var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
    return hash
}

public func hmac(string: String, key: [UInt8]) -> [UInt8] {
    var context = CCHmacContext()
    CCHmacInit(&context, CCHmacAlgorithm(kCCHmacAlgSHA256), key, key.count)
    
    let bytes = Array(string.utf8)
    CCHmacUpdate(&context, bytes, bytes.count)
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    CCHmacFinal(&context, &digest)
    
    return digest
}

#endif
