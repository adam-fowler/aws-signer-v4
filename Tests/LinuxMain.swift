import XCTest

@testable import AWSSignerTests
@testable import AWSCryptoTests

XCTMain([
    testCase(AWSSignerTests.allTests),
    testCase(AWSCryptoTests.allTests)
])
