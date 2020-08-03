//
//  request.swift
//  AWSSigner
//
//  Created by Adam Fowler on 2019/08/30.
//

import AsyncHTTPClient
import AWSSigner
import Foundation
import NIO
import NIOHTTP1

public extension AWSSigner.BodyData {
    /// Convert to HTTPClient Body struct
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

public extension HTTPClient {
    /// return signed HTTPClient request with signature in the headers
    @available(*, deprecated, message: "Support for AsyncHTTPClient will be removed in v3.0")
    static func awsHeaderSignedRequest(url: URL, method: HTTPMethod = .GET, headers: HTTPHeaders = HTTPHeaders(), body: AWSSigner.BodyData? = nil, date: Date = Date(), signer: AWSSigner) throws -> HTTPClient.Request {
        let signedHeaders = signer.signHeaders(url: url, method: method, headers: headers, body: body, date: date)
        return try HTTPClient.Request(url: url, method: method, headers: signedHeaders, body: body?.body)
    }
    
    /// return signed HTTPClient request with signature in the URL
    @available(*, deprecated, message: "Support for AsyncHTTPClient will be removed in v3.0")
    static func awsURLSignedRequest(url: URL, method: HTTPMethod = .GET, body: AWSSigner.BodyData? = nil, date: Date = Date(), expires: Int = 86400, signer: AWSSigner) throws -> HTTPClient.Request {
        let signedURL = signer.signURL(url: url, method: method, body: body, date: date, expires: expires)
        return try HTTPClient.Request(url: signedURL, method: method, body: body?.body)
    }
}

