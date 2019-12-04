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

/// Protocol for providing credential details for accessing AWS services
public protocol CredentialProvider {
    func getCredential() -> EventLoopFuture<Credential>
}

public protocol StaticCredentialProvider: CredentialProvider {
    var credential    : StaticCredential { get }
    var eventLoopGroup: EventLoopGroup   { get }
}

extension StaticCredentialProvider {
  
    public func getCredential() -> EventLoopFuture<Credential> {
        // don't hop if not necessary
        if eventLoopGroup is MultiThreadedEventLoopGroup {
          return MultiThreadedEventLoopGroup.currentEventLoop!.makeSucceededFuture(credential)
        }
        
        return eventLoopGroup.next().makeSucceededFuture(credential)
    }
  
}

public struct StaticCredentialProv: StaticCredentialProvider {
  
    public let credential    : StaticCredential
    public let eventLoopGroup: EventLoopGroup
    
    init(credential: StaticCredential, eventLoopGroup: EventLoopGroup) {
        self.credential     = credential
        self.eventLoopGroup = eventLoopGroup
    }
}

/// environment variable version of credential provider that uses system environment variables to get credential details
public struct EnvironmentCredential: StaticCredentialProvider {

    public let credential    : StaticCredential
    public let eventLoopGroup: EventLoopGroup
    
    public init?(eventLoopGroup: EventLoopGroup) {
        guard let accessKeyId = ProcessInfo.processInfo.environment["AWS_ACCESS_KEY_ID"] else {
            return nil
        }
        guard let secretAccessKey = ProcessInfo.processInfo.environment["AWS_SECRET_ACCESS_KEY"] else {
            return nil
        }
      
        self.credential = StaticCredential(
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey,
            sessionToken: ProcessInfo.processInfo.environment["AWS_SESSION_TOKEN"])
        self.eventLoopGroup = eventLoopGroup
    }
}

// MARK: MetaDataProvider

public struct ExpiringCredential: Credential {
  
    public let accessKeyId: String
    public let secretAccessKey: String
    public let sessionToken: String?
    public let expiration: Date?
    
    public init(accessKeyId: String, secretAccessKey: String, sessionToken: String? = nil, expiration: Date? = nil) {
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
        self.sessionToken = sessionToken ?? ProcessInfo.processInfo.environment["AWS_SESSION_TOKEN"]
        self.expiration = expiration
    }
    
    func nearExpiration() -> Bool {
        guard let expiration = self.expiration else {
            return false
        }
      
        // are we within 5 minutes of expiration?
        return Date().addingTimeInterval(5.0 * 60.0) > expiration
    }
}

/// protocol for decodable objects containing credential information
public protocol CredentialContainer: Decodable {
    var credential: ExpiringCredential { get }
}

public protocol MetaDataClient {
    associatedtype MetaData: CredentialContainer
    
    func getMetaData() -> EventLoopFuture<MetaData>
}

public protocol AWSHTTPClient {
    var eventLoopGroup: EventLoopGroup { get }
}

class MetaDataCredentialProvider<Client: MetaDataClient> {
    typealias MetaData  = Client.MetaData
    
    let eventLoopGroup  : EventLoopGroup
    let metaDataClient  : Client
    
    let lock            = NIOConcurrencyHelpers.Lock()
    var credential      : ExpiringCredential? = nil
    var credentialFuture: EventLoopFuture<Credential>? = nil

    init(eventLoopGroup: EventLoopGroup, client: Client) {
        self.eventLoopGroup = eventLoopGroup
        self.metaDataClient = client

        _ = self.refreshCredentials()
    }
    
    func getCredential() -> EventLoopFuture<Credential> {
        self.lock.lock()
        let cred = credential
        self.lock.unlock()
        
        if let cred = cred, cred.nearExpiration() == false {
            // we have credentials and those are still valid
            
            if self.eventLoopGroup is MultiThreadedEventLoopGroup {
              // if we are in a MultiThreadedEventLoopGroup we try to minimize hops.
              return MultiThreadedEventLoopGroup.currentEventLoop!.makeSucceededFuture(cred)
            }
            return self.eventLoopGroup.next().makeSucceededFuture(cred)
        }
        
        // we need to refresh the credentials
        return self.refreshCredentials()
    }
    
    private func refreshCredentials() -> EventLoopFuture<Credential> {
        self.lock.lock()
        defer { self.lock.unlock() }
        
        if let future = credentialFuture {
            // a refresh is already running
            return future
        }
        
        credentialFuture = self.metaDataClient.getMetaData()
            .map { (metadata) -> (Credential) in
                let credential = metadata.credential
                
                self.lock.lock()
                defer { self.lock.unlock() }
                
                self.credentialFuture = nil
                self.credential = credential
                
                return credential
            }

        return credentialFuture!
    }
  
}

public struct ECSMetaDataClient: MetaDataClient {
    public typealias MetaData = ECSMetaData
    
    public struct ECSMetaData: CredentialContainer {
        let accessKeyId: String
        let secretAccessKey: String
        let token: String
        let expiration: Date
        let roleArn: String

        public var credential: ExpiringCredential {
            return ExpiringCredential(
                accessKeyId: accessKeyId,
                secretAccessKey: secretAccessKey,
                sessionToken: token,
                expiration: expiration
            )
        }

        enum CodingKeys: String, CodingKey {
            case accessKeyId = "AccessKeyId"
            case secretAccessKey = "SecretAccessKey"
            case token = "Token"
            case expiration = "Expiration"
            case roleArn = "RoleArn"
        }
    }
    
    static let Host = "169.254.170.2"
    
    public let httpClient    : AWSHTTPClient
    public let endpointURL   : String

    
    init?(httpClient: AWSHTTPClient, host: String = ECSMetaDataClient.Host) {
        guard let relativeURL  = ProcessInfo.processInfo.environment["AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"] else {
            return nil
        }
        
        self.httpClient     = httpClient
        self.endpointURL    = "http://\(host)\(relativeURL)"
    }
    
    public func getMetaData() -> EventLoopFuture<ECSMetaData> {
      return self.httpClient.eventLoopGroup.next().makeSucceededFuture(
          ECSMetaData(accessKeyId: "abc123",
                      secretAccessKey: "abc123",
                      token: "abc123",
                      expiration: Date(timeIntervalSinceNow: 3600),
                      roleArn: "arn:asd:ghj"))
    }
  
}

//MARK: InstanceMetaDataServiceProvider

/// Provide AWS credentials for instances
struct InstanceMetaDataClient: MetaDataClient {
    public typealias MetaData = InstanceMetaData

    struct InstanceMetaData: CredentialContainer {
        let accessKeyId: String
        let secretAccessKey: String
        let token: String
        let expiration: Date
        let code: String
        let lastUpdated: Date
        let type: String

        var credential: ExpiringCredential {
            return ExpiringCredential(
                accessKeyId: accessKeyId,
                secretAccessKey: secretAccessKey,
                sessionToken: token,
                expiration: expiration
            )
        }

        enum CodingKeys: String, CodingKey {
            case accessKeyId = "AccessKeyId"
            case secretAccessKey = "SecretAccessKey"
            case token = "Token"
            case expiration = "Expiration"
            case code = "Code"
            case lastUpdated = "LastUpdated"
            case type = "Type"
        }
    }
  
    static let Host = "169.254.169.254"
    static let MetadataUri = "/latest/meta-data/iam/security-credentials/"

    public let httpClient    : AWSHTTPClient
    public let endpointURL   : String
  
    init(httpClient: AWSHTTPClient, host: String = InstanceMetaDataClient.Host, uri: String = InstanceMetaDataClient.MetadataUri) {
        self.httpClient = httpClient
        self.endpointURL = "http://\(host)\(uri)"
    }

//    func uri(httpClient: AWSHTTPClient) -> EventLoopFuture<String> {
//        // instance service expects absoluteString as uri...
//        return request(url: self.endpointURL, timeout: 2, httpClient: httpClient)
//            .flatMapThrowing{ response in
//                switch response.status {
//                case .ok:
//                    if let body = response.body, let roleName = body.getString(at: body.readerIndex, length: body.readableBytes, encoding: .utf8) {
//                        return "\(InstanceMetaDataServiceProvider.baseURLString)/\(roleName)"
//                    }
//                    return InstanceMetaDataServiceProvider.baseURLString
//                default:
//                    throw MetaDataServiceError.couldNotGetInstanceRoleName
//                }
//        }
//    }

    public func getMetaData() -> EventLoopFuture<InstanceMetaData> {
      // TODO: Call instance meta data service first to get url
      return self.httpClient.eventLoopGroup.next().makeSucceededFuture(
        InstanceMetaData(accessKeyId: "abc123",
                         secretAccessKey: "abc123",
                         token: "abc123",
                         expiration: Date(timeIntervalSinceNow: 3600),
                         code: "abc123",
                         lastUpdated: Date(),
                         type: "abc123"))
    }
}
