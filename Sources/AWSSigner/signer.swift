//
//  signer.swift
//  AWSSigner
//
//  Created by Adam Fowler on 2019/08/29.
//  Amazon Web Services V4 Signer
//  AWS documentation about signing requests is here https://docs.aws.amazon.com/general/latest/gr/signing_aws_api_requests.html
//
import Foundation
import NIO
import AsyncHTTPClient

/// Amazon Web Services V4 Signer
public class AWSSigner {
    static let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    let credentials: CredentialProvider
    let service: String
    let region: String
    
    /// Initialise the Signer class with AWS credentials
    public init(credentials: CredentialProvider, service: String, region: String) {
        self.credentials = credentials
        self.service = service
        self.region = region
    }
    
    /// sign a HTTP Request and place in "Authorization" header
    public func signInHeader(request: HTTPClient.Request) -> HTTPClient.Request {
        
        var request = request
        // add date, host, sha256 and if available security token headers
        request.headers.add(name: "X-Amz-Date", value: AWSSigner.timestamp(Date()))
        request.headers.add(name: "host", value: request.url.host ?? "")
        request.headers.add(name: "x-amz-content-sha256", value: AWSSigner.hashedPayload(request.body))
        if let sessionToken = credentials.sessionToken {
            request.headers.add(name: "x-amz-security-token", value: sessionToken)
        }

        // construct signing data. Do this after adding the headers as it uses data from the headers
        let signingData = SigningData(request: request, signer: self)
        
        // construct authorization string
        let authorization = "AWS4-HMAC-SHA256 " +
            "Credential=\(credentials.accessKeyId)/\(signingData.date)/\(region)/\(service)/aws4_request, " +
            "SignedHeaders=\(signingData.signedHeaders), " +
        "Signature=\(signature(signingData: signingData))"
        
        // add Authorization header
        request.headers.add(name: "Authorization", value: authorization)
        return request
    }
    
    /// structure used to store data used throughout the signing process
    struct SigningData {
        let request : HTTPClient.Request
        let hashedPayload : String
        let datetime : String
        let headersToSign: [String: String]
        let signedHeaders : String
        var unsignedURL : URL
        
        var date : String { return String(datetime.prefix(8))}
        
        init(request: HTTPClient.Request, signer: AWSSigner) {
            self.request = request
            self.datetime = request.headers["x-amz-date"].first ?? AWSSigner.timestamp(Date())
            self.hashedPayload = request.headers["x-amz-content-sha256"].first ?? AWSSigner.hashedPayload(request.body)
            self.unsignedURL = request.url
            
            let headersNotToSign: Set<String> = [
                "Authorization"
            ]
            var headersToSign : [String: String] = [:]
            for header in request.headers {
                if headersNotToSign.contains(header.name) {
                    continue
                }
                headersToSign[header.name] = header.value
            }
            self.headersToSign = headersToSign
            self.signedHeaders = headersToSign.map { return "\($0.key.lowercased())" }
                .sorted()
                .joined(separator: ";")
        }
    }
    
    /// return a request with a signed URL
    public func signURL(request: HTTPClient.Request, expires: Int = 86400) throws -> HTTPClient.Request {

        var request = request
        // add date, host headers. If the service is s3 then add a sha256 of "UNSIGNED-PAYLOAD"
        request.headers.add(name: "X-Amz-Date", value: AWSSigner.timestamp(Date()))
        request.headers.add(name: "host", value: request.url.host ?? "")
        if service == "s3" {
            request.headers.add(name: "x-amz-content-sha256", value:"UNSIGNED-PAYLOAD")
        }
        
        // Create signing data
        var signingData = SigningData(request: request, signer: self)
        
        // Construct query string. Start with original query strings and append all the signing info.
        var query = request.url.query ?? ""
        if query.count > 0 {
            query += "&"
        }
        query += "X-Amz-Algorithm=AWS4-HMAC-SHA256"
        query += "&X-Amz-Credential=\(credentials.accessKeyId)/\(signingData.date)/\(region)/\(service)/aws4_request"
        query += "&X-Amz-Date=\(signingData.datetime)"
        query += "&X-Amz-Expires=\(expires)"
        query += "&X-Amz-SignedHeaders=\(signingData.signedHeaders)"
        if let sessionToken = credentials.sessionToken {
            query += "&X-Amz-Security-Token=\(sessionToken)"
        }
        // Split the string and sort to ensure the order of query strings is the same as AWS
        query = query.split(separator: "&")
            .sorted()
            .joined(separator: "&")
            .addingPercentEncoding(withAllowedCharacters: AWSSigner.queryAllowedCharacters)!
        
        // update unsignURL in the signingData so when the canonical request is constructed it includes all the signing query items
        signingData.unsignedURL = URL(string: request.url.absoluteString.split(separator: "?")[0]+"?"+query)! // NEED TO DEAL WITH SITUATION WHERE THIS FAILS
        query += "&X-Amz-Signature=\(signature(signingData: signingData))"

        // Add signature to query items and build a new Request
        let signedURL = URL(string: request.url.absoluteString.split(separator: "?")[0]+"?"+query)!
        return try HTTPClient.Request(url: signedURL, method: request.method, headers: request.headers, body: request.body)
    }
    
    // Calculating signature as in https://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
    func signature(signingData: SigningData) -> String {
        let kDate = hmac(string:signingData.date, key:Array("AWS4\(credentials.secretAccessKey)".utf8))
        let kRegion = hmac(string: region, key: kDate)
        let kService = hmac(string: service, key: kRegion)
        let kSigning = hmac(string: "aws4_request", key: kService)
        let kSignature = hmac(string: stringToSign(signingData: signingData), key: kSigning)
        return AWSSigner.hexEncoded(kSignature)
    }
    
    /// Create the string to sign as in https://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
    func stringToSign(signingData: SigningData) -> String {
        let stringToSign = "AWS4-HMAC-SHA256\n" +
            "\(signingData.datetime)\n" +
            "\(signingData.date)/\(region)/\(service)/aws4_request\n" +
            AWSSigner.hexEncoded(sha256(canonicalRequest(signingData: signingData)))
        return stringToSign
    }
    
    /// Create the canonical request as in https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
    func canonicalRequest(signingData: SigningData) -> String {
        let canonicalHeaders = signingData.headersToSign.map { return "\($0.key.lowercased()):\($0.value)" }
            .sorted()
            .joined(separator: "\n") // REMEMBER TO TRIM THE VALUE
        let canonicalRequest = "\(signingData.request.method.rawValue)\n" +
            "\(signingData.unsignedURL.path)\n" +
            "\(signingData.unsignedURL.query ?? "")\n" +
            "\(canonicalHeaders)\n\n" +
            "\(signingData.signedHeaders)\n" +
            signingData.hashedPayload
        return canonicalRequest
    }
    
    /// Create a SHA256 hash of the Requests body
    static func hashedPayload(_ payload: HTTPClient.Body?) -> String {
        guard let payload = payload else { return AWSSigner.hexEncoded(sha256([UInt8]())) }
        var hash : [UInt8] = []
        _ = payload.stream(HTTPClient.Body.StreamWriter { (data) -> EventLoopFuture<Void> in
            guard case .byteBuffer(let buffer) = data else {return AWSSigner.eventLoopGroup.next().makeSucceededFuture(Void())}
            hash = sha256(Array(buffer.readableBytesView))
            return AWSSigner.eventLoopGroup.next().makeSucceededFuture(Void())
        })
        return AWSSigner.hexEncoded(hash)
    }
    
    /// return a hexEncoded string buffer from an array of bytes
    static func hexEncoded(_ buffer: [UInt8]) -> String {
        return buffer.map{String(format: "%02x", $0)}.joined(separator: "")
    }
    
    /// return a timestamp formatted for signing requests
    static func timestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    static let queryAllowedCharacters = CharacterSet(charactersIn:"/;+").inverted
}
