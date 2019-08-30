import XCTest
import AsyncHTTPClient
@testable import AWSSigner

final class aws_signTests: XCTestCase {
    let credentials : CredentialProvider = (SharedCredential() ?? EnvironmentCredential()) ?? Credential(accessKeyId: "", secretAccessKey: "")
    
    func testSignS3Headers() {
        do {
            let client = HTTPClient(eventLoopGroupProvider: .createNew)
            let request = try HTTPClient.Request(url: "https://s3.us-east-1.amazonaws.com/test-bucket", method: .PUT, headers: [:])
            let signedRequest = try AWSSigner(credentials: credentials, service:"s3", region:"us-east-1").signURL(request: request)
            let response = try client.execute(request: signedRequest).wait()
            print("Status code \(response.status.code)")
            XCTAssertTrue(200..<300 ~= response.status.code || response.status.code == 409)
            if let body = response.body {
                let bodyString = body.getString(at: 0, length: body.readableBytes)
                print(bodyString ?? "")
            }
            
            try client.syncShutdown()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testSignSNSHeaders() {
        do {
            let client = HTTPClient(eventLoopGroupProvider: .createNew)
            let request = try HTTPClient.Request(url: "https://sns.eu-west-1.amazonaws.com/", method: .POST, headers: ["Content-Type": "application/x-www-form-urlencoded; charset=utf-8"], body: .string("Action=ListTopics&Version=2010-03-31"))
            let signedRequest = AWSSigner(credentials: credentials, service:"sns", region:"eu-west-1").signInHeader(request: request)
            let response = try client.execute(request: signedRequest).wait()
            print("Status code \(response.status.code)")
            XCTAssertTrue(200..<300 ~= response.status.code)
            if let body = response.body {
                let bodyString = body.getString(at: 0, length: body.readableBytes)
                print(bodyString ?? "")
            }
            
            try client.syncShutdown()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testSignS3URL() {
        do {
            let client = HTTPClient(eventLoopGroupProvider: .createNew)
            let request = try HTTPClient.Request(url: "https://s3.eu-west-1.amazonaws.com/", method: .GET, headers: [:])
            let signedRequest = try AWSSigner(credentials: credentials, service:"s3", region:"eu-west-1").signURL(request: request)
            let response = try client.execute(request: signedRequest).wait()
            print("Status code \(response.status.code)")
            XCTAssertTrue(200..<300 ~= response.status.code)
            if let body = response.body {
                let bodyString = body.getString(at: 0, length: body.readableBytes)
                print(bodyString ?? "")
            } else {
                XCTFail("Empty body")
            }
            
            try client.syncShutdown()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    static var allTests = [
        ("testSignS3URL", testSignS3URL),
        ("testSignSNSHeaders", testSignSNSHeaders),
        ("testSignS3Headers", testSignS3Headers),
    ]
}
