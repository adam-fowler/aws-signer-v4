import XCTest
@testable import AWSCrypto

final class AWSCryptoTests: XCTestCase {
    
    // create a buffer of random values. Will always create the same given you supply the same z and w values
    // Random number generator from https://www.codeproject.com/Articles/25172/Simple-Random-Number-Generation
    func createRandomBuffer(_ w: UInt, _ z: UInt, size: Int) -> [UInt8] {
        var z = z
        var w = w
        func getUInt8() -> UInt8
        {
            z = 36969 * (z & 65535) + (z >> 16);
            w = 18000 * (w & 65535) + (w >> 16);
            return UInt8(((z << 16) + w) & 0xff);
        }
        var data = Array<UInt8>(repeating: 0, count: size)
        for i in 0..<size {
            data[i] = getUInt8()
        }
        return data
    }
    
    func testMD5() {
        let data = createRandomBuffer(34, 2345, size: 234896)
        let digest = MD5.hash(data: data)
        print(digest)
        XCTAssertEqual(digest.description, "3abdd8d79be09bc250d60ada1f000912")
    }

    func testSHA256() {
        let data = createRandomBuffer(872, 12489, size: 562741)
        let digest = SHA256.hash(data: data)
        print(digest)
        XCTAssertEqual(digest.description, "3cff070559024d8652d1257e5f455787e95ebd8e95378d62df1a466f78860f74")
    }
    
    func testHMAC() {
        let data = createRandomBuffer(1, 91, size: 347237)
        let key = createRandomBuffer(102, 3, size: 32)
        let authenticationKey = HMAC<SHA256>.authenticationCode(for: data, using: SymmetricKey(data: key))
        print(authenticationKey)
        XCTAssertEqual(authenticationKey.description, "ddec250211f1b546254bab3fb027af1acc4842898e8af6eeadcdbf8e2c6c1ff5")
    }

    static var allTests = [
        ("testMD5", testMD5),
        ("testSHA256", testSHA256),
        ("testHMAC", testHMAC),
    ]
}
