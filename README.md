# AWS Signer

Generate a signed URL or Request headers for submitting to Amazon Web Services. Supply the library with your URL, HTTP method, headers and body and get back a signed URL or signed headers to use in your HTTP Request. 

## Usage Guide
Create an AWSSigner object. Initialise it with security credentials for accessing Amazon Web Services, the signing name of the service you are using and the AWS region you are working in. You can create a credentials object directly and enter your credientials or get them from the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` using the `EnvironmentCredential` struct. There are other ways of accessing AWS security credentials but that isn't the purpose of this library. The signing name in general is the same as the service name eg `s3`, `sns`, `iam` but this is not always the case.

The following example code creates a signed URL to access a file in S3.

```
let credentials = Credential(accessKeyId: "MYACCESSKEY", secretAccessKey: "MYSECRETACCESSKEY")
let signer = AWSSigner(credentials: credentials, name: "s3", region: "us-east-1")
let signedURL = AWSSigner.signURL(
                    url: URL(string:"mybucket.s3.us-east-1.amazonaws.com/myfile")!, 
                    method: .GET)
```

Alternatively you can store the authentication details in the request headers. The following returns the headers required to sign a request plus the original headers. The signature is stored in the 'Authorization' header. This request will return a response containing a list of SNS Topics from AWS region us-east-1.

```
let credentials = Credential(accessKeyId: "MYACCESSKEY", secretAccessKey: "MYSECRETACCESSKEY")
let signer = AWSSigner(credentials: credentials, name: "sns", region: "us-east-1")
let body = "Action=ListTopics&Version=2010-03-31"
let signedHeaders = HTTPClient.signHeaders(
                  url: URL(string:"sns.us-east-1.amazonaws.com/")!, 
                  method: .GET, 
                  headers: ["Content-Type": "application/x-www-form-urlencoded; charset=utf-8"], 
                  body: .string(body))
```

## AsyncHTTPClient
The library includes extensions to the HTTPClient of [AsyncHttpClient](https://github.com/swift-server/async-http-client) from the [Swift Server Working Group](https://swift.org/server/). 

Both `HTTPClient.awsURLSignedRequest()` and `HTTPClient.awsHeaderSignedRequest()` will create a signed Request that can be sent to AWS via the HTTPClient from AsyncHttpClient. The following creates a signed S3 Request to upload a file to an S3 bucket and processes it. 
```
let credentials = Credential(accessKeyId: "MYACCESSKEY", secretAccessKey: "MYSECRETACCESSKEY")
let signer = AWSSigner(credentials: credentials, name: "s3", region: "us-east-1")
let body = "FileContents"
let request = try HTTPClient.awsURLSignedRequest(
                    url: URL(string:"mybucket.s3.us-east-1.amazonaws.com/mynewfile")!, 
                    method: .PUT, 
                    body: .string(body),
                    signer: signer)
let client = HTTPClient(eventLoopGroupProvider: .createNew)
client.execute(request: request).whenComplete { result in
    switch result {
    case .failure(let error):
        // process error
    case .success(let response):
        if response.status == .ok {
            // handle response
        } else {
            // handle remote error
        }
    }
}
```
