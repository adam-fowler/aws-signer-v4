// Digest.swift
// based on the Vapor/open-crypto project which tries to replicate the CryptoKit framework interface
// written by AdamFowler 2020/01/30
import protocol Foundation.ContiguousBytes

/// Protocol for Digest object returned from HashFunction
public protocol Digest: Sequence, ContiguousBytes, CustomStringConvertible, Hashable where Element == UInt8 {
    static var byteCount: Int {get}
}

/// Protocol for Digest object consisting of a byte array
protocol ByteDigest: Digest, ByteArray { }

