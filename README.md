# AWS Signer

Generate AWS Signed Requests for the [AsyncHttpClient](https://github.com/swift-server/async-http-client) from the [Swift Server Working Group](https://swift.org/server/). 

The library extends `HTTPClient` with two functions. One for providing a `HTTPClient.Request` containing a signed URL and the other one a `HTTPClient.Request` with the authorization in the headers. Following code creates a signed URL accessing a file in S3.
```
let credentials = Credential(accessKeyId: "MYACCESSKEY", secretAccessKey: "MYSECRETACCESSKEY")
let signer = AWSSigner(credentials: credentials, name: "s3", region: "us-east-1")
let client = HTTPClient(eventLoopGroupProvider: .createNew)
let request = HTTPClient.awsURLSignedRequest(
                    url: URL(string:"MYBUCKET.s3.us-east-1.amazonaws.com/MYFILE")!, 
                    method: .GET)
let response = try client.execute(request: request).wait()
```
The following creates a request with an 'Authorization' header. It's output is a list of SNS Topics from AWS region us-east-1.
```
let credentials = Credential(accessKeyId: "MYACCESSKEY", secretAccessKey: "MYSECRETACCESSKEY")
let signer = AWSSigner(credentials: credentials, name: "sns", region: "us-east-1")
let client = HTTPClient(eventLoopGroupProvider: .createNew)
let request = HTTPClient.awsHeaderSignedRequest(
                  url: URL(string:"sns.us-east-1.amazonaws.com/")!, 
                  method: .GET, 
                  headers: ["Content-Type": "application/x-www-form-urlencoded; charset=utf-8"], 
                  body: .string("Action=ListTopics&Version=2010-03-31"))
let response = try client.execute(request: request).wait()
```
If you don't want to use AsyncHttpClient you can access the signing code via `AWSSigner.signURL()` and `AWSSigner.signHeaders()`.
