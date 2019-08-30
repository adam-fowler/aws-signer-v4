//
//  credentials.swift
//  aws-sign
//
//  Created by Adam Fowler on 2019/08/29.
//
import Foundation
import INIParser

public protocol CredentialProvider {
    var accessKeyId: String {get}
    var secretAccessKey: String {get}
    var sessionToken: String? {get}
}

public struct Credential : CredentialProvider {
    public let accessKeyId: String
    public let secretAccessKey: String
    public let sessionToken: String?
    
    public init(accessKeyId: String, secretAccessKey: String, sessionToken: String? = nil) {
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
        self.sessionToken = sessionToken
    }
}

public struct EnvironmentCredential: CredentialProvider {
    public let accessKeyId: String
    public let secretAccessKey: String
    public let sessionToken: String?
    
    public init?() {
        guard let accessKeyId = ProcessInfo.processInfo.environment["AWS_ACCESS_KEY_ID"] else {
            return nil
        }
        guard let secretAccessKey = ProcessInfo.processInfo.environment["AWS_SECRET_ACCESS_KEY"] else {
            return nil
        }
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
        self.sessionToken = ProcessInfo.processInfo.environment["AWS_SESSION_TOKEN"]
    }
}

/// Protocol for parsing AWS credential configs
protocol SharedCredentialsConfigParser {
    /// Parse a specified file
    ///
    /// - Parameter filename: The path to the file
    /// - Returns: A dictionary of dictionaries where the key is each profile
    /// and the value is the fields and values within that profile
    /// - Throws: If the file cannot be parsed
    func parse(filename: String) throws -> [String: [String:String]]
}

/// An implementation of SharedCredentialsConfigParser that uses INIParser
class IniConfigParser: SharedCredentialsConfigParser {
    func parse(filename: String) throws -> [String : [String : String]] {
        return try INIParser(filename).sections
    }
}

public struct SharedCredential: CredentialProvider {
    
    public let accessKeyId: String
    public let secretAccessKey: String
    public let sessionToken: String?
    public let expiration: Date? = nil
    
    public init?(filename: String = "~/.aws/credentials",
                profile: String = "default") {
        self.init(
            filename: filename,
            profile: profile,
            parser: IniConfigParser()
        )
    }
    
    init?(filename: String, profile: String, parser: SharedCredentialsConfigParser) {
        // Expand tilde before parsing the file
        let filename = NSString(string: filename).expandingTildeInPath
        guard let contents = try? parser.parse(filename: filename) else { return nil }
        guard let config = contents[profile] else { return nil }
        guard let accessKeyId = config["aws_access_key_id"] else { return nil }
        guard let secretAccessKey = config["aws_secret_access_key"] else { return nil }

        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
        self.sessionToken = config["aws_session_token"]
    }
}

