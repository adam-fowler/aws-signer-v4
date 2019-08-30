import XCTest

import aws_signTests

var tests = [XCTestCaseEntry]()
tests += aws_signTests.allTests()
XCTMain(tests)
