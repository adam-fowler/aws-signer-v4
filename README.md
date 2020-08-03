# AWS Signer
[<img src="http://img.shields.io/badge/swift-5.1-brightgreen.svg" alt="Swift 5.1" />](https://swift.org)
[<img src="https://github.com/adam-fowler/aws-signer-v4/workflows/CI/badge.svg" />](https://github.com/adam-fowler/aws-signer/actions)

Generate a signed URL or Request headers for submitting to Amazon Web Services. Supply the library with your URL, HTTP method, headers and body and get back a signed URL or signed headers to use in your HTTP Request. 

## Usage Guide
Create an AWSSigner object. Initialise it with security credentials for accessing Amazon Web Services, the signing name of the service you are using and the AWS region you are working in. You can create a credentials object directly and enter your credentials or get them from the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` using the `EnvironmentCredential` struct. There are other ways of accessing AWS security credentials but that isn't the purpose of this library. The signing name in general is the same as the service name eg `s3`, `sns`, `iam` but this is not always the case.

The following example code creates a signed URL to access a file in S3.

```
let credentials = StaticCredential(accessKeyId: "MYACCESSKEY", secretAccessKey: "MYSECRETACCESSKEY")
let signer = AWSSigner(credentials: credentials, name: "s3", region: "us-east-1")
let signedURL = signer.signURL(
                    url: URL(string:"mybucket.s3.us-east-1.amazonaws.com/myfile")!,
                    method: .GET)
```

Alternatively you can store the authentication details in the request headers. The following returns the headers required to sign a request plus the original headers. The signature is stored in the 'Authorization' header. This request will return a response containing a list of SNS Topics from AWS region us-east-1.

```
let credentials = StaticCredential(accessKeyId: "MYACCESSKEY", secretAccessKey: "MYSECRETACCESSKEY")
let signer = AWSSigner(credentials: credentials, name: "sns", region: "us-east-1")
let body = "Action=ListTopics&Version=2010-03-31"
let signedHeaders = signer.signHeaders(
                  url: URL(string:"sns.us-east-1.amazonaws.com/")!,
                  method: .GET,
                  headers: ["Content-Type": "application/x-www-form-urlencoded; charset=utf-8"],
                  body: .string(body))
```

