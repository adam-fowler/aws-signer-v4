//
//  request.swift
//  AWSSigner
//
//  Created by Adam Fowler on 2019/08/30.
//

import AsyncHTTPClient
import Foundation
import NIO
import NIOHTTP1

public extension HTTPClient.Request {
    /// return signed HTTPClient request with signature in the headers
    static func awsHeaderSignedRequest(url: URL, method: HTTPMethod = .GET, headers: HTTPHeaders = HTTPHeaders(), body: AWSSigner.BodyData? = nil, date: Date = Date(), signer: AWSSigner) throws -> HTTPClient.Request {
        let signedHeaders = signer.signHeaders(url: url, method: method, headers: headers, body: body, date: date)
        return try HTTPClient.Request(url: url, method: method, headers: signedHeaders, body: body?.body)
    }
    
    /// return signed HTTPClient request with signature in the URL
    static func awsURLSignedRequest(url: URL, method: HTTPMethod = .GET, body: AWSSigner.BodyData? = nil, date: Date = Date(), expires: Int = 86400, signer: AWSSigner) throws -> HTTPClient.Request {
        let signedURL = signer.signURL(url: url, method: method, body: body, date: date, expires: expires)
        return try HTTPClient.Request(url: signedURL, method: method, body: body?.body)
    }
}

