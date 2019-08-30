//
//  signer.swift
//  AWSSigner
//
//  Created by Adam Fowler on 2019/08/29.
//  Amazon Web Services V4 Signer
//  AWS documentation about signing requests is here https://docs.aws.amazon.com/general/latest/gr/signing_aws_api_requests.html
//

import AsyncHTTPClient
import Foundation
import NIO
import NIOHTTP1

/// Amazon Web Services V4 Signer
public class AWSSigner {
    /// security credentials for accessing AWS services
    let credentials: CredentialProvider
    /// service signing name. In general this is the same as the service name
    let name: String
    /// AWS region you are working in
    let region: String
    
    /// Initialise the Signer class with AWS credentials
    public init(credentials: CredentialProvider, name: String, region: String) {
        self.credentials = credentials
        self.name = name
        self.region = region
    }
    
    /// Enum for holding your body data
    public enum BodyData {
        case string(String)
        case data(Data)
        case byteBuffer(ByteBuffer)
        
        var body : HTTPClient.Body {
            switch self {
            case .string(let string):
                return .string(string)
            case .data(let data):
                return .data(data)
            case .byteBuffer(let byteBuffer):
                return .byteBuffer(byteBuffer)
            }
        }
    }
    
    /// Generate signed headers, for a HTTP request
    public func signHeaders(url: URL, method: HTTPMethod = .GET, headers: HTTPHeaders = HTTPHeaders(), body: BodyData? = nil, date: Date = Date()) -> HTTPHeaders {
        var headers = headers
        // add date, host, sha256 and if available security token headers
        headers.add(name: "X-Amz-Date", value: AWSSigner.timestamp(date))
        headers.add(name: "host", value: url.host ?? "")
        headers.add(name: "x-amz-content-sha256", value: AWSSigner.hashedPayload(body))
        if let sessionToken = credentials.sessionToken {
            headers.add(name: "x-amz-security-token", value: sessionToken)
        }
        
        // construct signing data. Do this after adding the headers as it uses data from the headers
        let signingData = AWSSigner.SigningData(url: url, method: method, headers: headers, body: body, date: date, signer: self)
        
        // construct authorization string
        let authorization = "AWS4-HMAC-SHA256 " +
            "Credential=\(credentials.accessKeyId)/\(signingData.date)/\(region)/\(name)/aws4_request, " +
            "SignedHeaders=\(signingData.signedHeaders), " +
        "Signature=\(signature(signingData: signingData))"
        
        // add Authorization header
        headers.add(name: "Authorization", value: authorization)
        
        return headers
    }
    
    /// Generate a signed URL, for a HTTP request
    public func signURL(url: URL, method: HTTPMethod = .GET, body: BodyData? = nil, date: Date = Date(), expires: Int = 86400) -> URL {
        let headers = HTTPHeaders([("host", url.host ?? "")])
        // Create signing data
        var signingData = AWSSigner.SigningData(url: url, method: method, headers: headers, body: body, date: date, signer: self)
        
        // Construct query string. Start with original query strings and append all the signing info.
        var query = url.query ?? ""
        if query.count > 0 {
            query += "&"
        }
        query += "X-Amz-Algorithm=AWS4-HMAC-SHA256"
        query += "&X-Amz-Credential=\(credentials.accessKeyId)/\(signingData.date)/\(region)/\(name)/aws4_request"
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
        
        // update unsignedURL in the signingData so when the canonical request is constructed it includes all the signing query items
        signingData.unsignedURL = URL(string: url.absoluteString.split(separator: "?")[0]+"?"+query)! // NEED TO DEAL WITH SITUATION WHERE THIS FAILS
        query += "&X-Amz-Signature=\(signature(signingData: signingData))"
        
        // Add signature to query items and build a new Request
        let signedURL = URL(string: url.absoluteString.split(separator: "?")[0]+"?"+query)!
        return signedURL
    }
    
    /// structure used to store data used throughout the signing process
    struct SigningData {
        let url : URL
        let method : HTTPMethod
        let hashedPayload : String
        let datetime : String
        let headersToSign: [String: String]
        let signedHeaders : String
        var unsignedURL : URL
        
        var date : String { return String(datetime.prefix(8))}
        
        init(url: URL, method: HTTPMethod = .GET, headers: HTTPHeaders = HTTPHeaders(), body: BodyData? = nil, date: Date = Date(), signer: AWSSigner) {
            self.url = url
            self.method = method
            self.datetime = headers["x-amz-date"].first ?? AWSSigner.timestamp(date)
            self.unsignedURL = self.url

            if let hash = headers["x-amz-content-sha256"].first {
                self.hashedPayload = hash
            } else if signer.name == "s3" {
                self.hashedPayload = "UNSIGNED-PAYLOAD"
            } else {
                self.hashedPayload = AWSSigner.hashedPayload(body)
            }
            
            let headersNotToSign: Set<String> = [
                "Authorization"
            ]
            var headersToSign : [String: String] = [:]
            for header in headers {
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
    
    // Calculating signature as in https://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
    func signature(signingData: SigningData) -> String {
        let kDate = hmac(string:signingData.date, key:Array("AWS4\(credentials.secretAccessKey)".utf8))
        let kRegion = hmac(string: region, key: kDate)
        let kService = hmac(string: name, key: kRegion)
        let kSigning = hmac(string: "aws4_request", key: kService)
        let kSignature = hmac(string: stringToSign(signingData: signingData), key: kSigning)
        return AWSSigner.hexEncoded(kSignature)
    }
    
    /// Create the string to sign as in https://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
    func stringToSign(signingData: SigningData) -> String {
        let stringToSign = "AWS4-HMAC-SHA256\n" +
            "\(signingData.datetime)\n" +
            "\(signingData.date)/\(region)/\(name)/aws4_request\n" +
            AWSSigner.hexEncoded(sha256(canonicalRequest(signingData: signingData)))
        return stringToSign
    }
    
    /// Create the canonical request as in https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
    func canonicalRequest(signingData: SigningData) -> String {
        let canonicalHeaders = signingData.headersToSign.map { return "\($0.key.lowercased()):\($0.value)" }
            .sorted()
            .joined(separator: "\n") // REMEMBER TO TRIM THE VALUE
        let canonicalRequest = "\(signingData.method.rawValue)\n" +
            "\(signingData.unsignedURL.path)\n" +
            "\(signingData.unsignedURL.query ?? "")\n" +
            "\(canonicalHeaders)\n\n" +
            "\(signingData.signedHeaders)\n" +
            signingData.hashedPayload
        return canonicalRequest
    }
    
    /// Create a SHA256 hash of the Requests body
    static func hashedPayload(_ payload: BodyData?) -> String {
        guard let payload = payload else { return AWSSigner.hexEncoded(sha256([UInt8]())) }
        let hash : [UInt8]?
        switch payload {
        case .string(let string):
            hash = sha256(string)
        case .data(let data):
            hash = data.withUnsafeBytes { bytes in
                return sha256(bytes.bindMemory(to: UInt8.self))
            }
        case .byteBuffer(let byteBuffer):
            let byteBufferView = byteBuffer.readableBytesView
            hash = byteBufferView.withContiguousStorageIfAvailable { bytes in
                return sha256(bytes)
            }
        }
        if let hash = hash {
            return AWSSigner.hexEncoded(hash)
        } else {
            return AWSSigner.hexEncoded(sha256([UInt8]()))
        }
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
