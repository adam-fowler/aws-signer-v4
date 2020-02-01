// ByteArray.swift
// based on the Vapor/open-crypto project which tries to replicate the CryptoKit framework interface
// written by AdamFowler 2020/01/30
import protocol Foundation.ContiguousBytes

/// Protocol for object encapsulating an array of bytes
protocol ByteArray: Sequence, ContiguousBytes, CustomStringConvertible, Hashable where Element == UInt8 {
    init(bytes: [UInt8])
    var bytes: [UInt8] { get set }
}

extension ByteArray {
    public func makeIterator() -> Array<UInt8>.Iterator {
        return self.bytes.makeIterator()
    }

    public init?(bufferPointer: UnsafeRawBufferPointer) {
        self.init(bytes: [UInt8](bufferPointer))
    }

    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        return try bytes.withUnsafeBytes(body)
    }

    public var description: String {
        // hex digest
        return bytes.map{String(format: "%02x", $0)}.joined()
    }
}

