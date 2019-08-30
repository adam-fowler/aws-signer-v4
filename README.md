# AWS Signer

Generate AWS Signed Requests for the [AsyncHttpClient](https://github.com/swift-server/async-http-client) from the [Swift Server Working Group](https://swift.org/server/). 

The library extends `HTTPClient` with two functions. One for providing a `HTTPClient.Request` containing a signed URL and the other one with the authorization in the headers. 

## Usage Guide
Firstly you need to create a signer object, which is initialised with security credentials for accessing Amazon Web Services, the signing name of the service you are using and the AWS region you are working in. You can create a credentials object directly and enter your credientials or get them from the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`. There are other ways of accessing AWS security credentials but that isn't the purpose of this library. The signing name in general is the same as the service name eg `s3`, `sns`, `iam` but this is not always the case. 

The following example code creates a signed URL to access a file in S3.
```
let credentials = Credential(accessKeyId: "MYACCESSKEY", secretAccessKey: "MYSECRETACCESSKEY")
let signer = AWSSigner(credentials: credentials, name: "s3", region: "us-east-1")
let client = HTTPClient(eventLoopGroupProvider: .createNew)
let request = HTTPClient.awsURLSignedRequest(
                    url: URL(string:"mybucket.s3.us-east-1.amazonaws.com/myfile")!, 
                    method: .GET)
let response = try client.execute(request: request).wait()
```

Alternatively you can store the authentication details in the request headers. The following creates a request with an 'Authorization' header. Its response contains a list of SNS Topics from AWS region us-east-1.
```
let credentials = Credential(accessKeyId: "MYACCESSKEY", secretAccessKey: "MYSECRETACCESSKEY")
let signer = AWSSigner(credentials: credentials, name: "sns", region: "us-east-1")
let body = "Action=ListTopics&Version=2010-03-31"
let client = HTTPClient(eventLoopGroupProvider: .createNew)
let request = HTTPClient.awsHeaderSignedRequest(
                  url: URL(string:"sns.us-east-1.amazonaws.com/")!, 
                  method: .GET, 
                  headers: ["Content-Type": "application/x-www-form-urlencoded; charset=utf-8"], 
                  body: .string(body))
let response = try client.execute(request: request).wait()
```

If you don't want to use AsyncHttpClient you can access the signing code via `AWSSigner.signURL()` and `AWSSigner.signHeaders()`directly and use their results in your own HTTP client code.
