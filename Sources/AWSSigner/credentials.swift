//
//  credentials.swift
//  aws-sign
//
//  Created by Adam Fowler on 29/08/2019.
//

import Foundation
import NIO
import NIOConcurrencyHelpers

public protocol Credential {
    var accessKeyId: String     { get }
    var secretAccessKey: String { get }
    var sessionToken: String?   { get }
}


/// basic version of CredentialProvider where you supply the credentials
public struct StaticCredential: Credential {
    public let accessKeyId: String
    public let secretAccessKey: String
    public let sessionToken: String?
    
    public init(accessKeyId: String, secretAccessKey: String, sessionToken: String? = nil) {
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
        self.sessionToken = sessionToken
    }
}
