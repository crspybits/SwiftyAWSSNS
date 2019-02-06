import XCTest
@testable import SwiftyAWSSNS

// Because of the dependency on the Info.plist file, these tests must be run from the command line: ./Tools/runTests.sh

final class SwiftyAWSSNSTests: XCTestCase {
    var accessKeyId:String!
    var secretKey:String!
    var region:String!
    var platformApplicationArn:String!
    var token:String!

    override func setUp() {
        super.setUp()

        if let resourceData = try? Data(contentsOf: URL(fileURLWithPath: "/tmp/Info.plist")),
            let resource = try? PropertyListSerialization.propertyList(from: resourceData, format: nil) as? [String:Any], let info = resource {
            accessKeyId = info["accessKeyId"] as? String
            secretKey = info["secretKey"] as? String
            region = info["region"] as? String
            platformApplicationArn = info["platformApplicationArn"] as? String
            token = info["token"] as? String
        }
    }

    func createPlatformEndpoint() -> String? {
        var endpoint: String?
        
        let sns = SwiftyAWSSNS(accessKeyId: accessKeyId, secretKey: secretKey, region: region, platformApplicationArn: platformApplicationArn)
        let expect = expectation(description: "Done")
        sns.createPlatformEndpoint(apnsToken: token) { result in
            switch result {
            case .success(let arn):
                endpoint = arn
            case .error:
                XCTFail()
            }
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
        return endpoint
    }
    
    func testCreatePlatformEndpoint() {
        guard let endpointARN = createPlatformEndpoint() else {
            XCTFail()
            return
        }
        
        print("endpointARN: \(endpointARN)")
    }
    
    func createTopic() -> String? {
        var topicArn: String?
        
        let sns = SwiftyAWSSNS(accessKeyId: accessKeyId, secretKey: secretKey, region: region, platformApplicationArn: platformApplicationArn)
        let topicName = "crspybits"
        
        let expect = expectation(description: "Done")

        sns.createTopic(topicName: topicName) { result in
            switch result {
            case .success(let arn):
                topicArn = arn
            case .error:
                XCTFail()
            }
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
        
        return topicArn
    }
    
    func testCreateTopic() {
        guard let _ = createTopic() else {
            XCTFail()
            return
        }
    }
    
    func testSubscribe() {
        let sns = SwiftyAWSSNS(accessKeyId: accessKeyId, secretKey: secretKey, region: region, platformApplicationArn: platformApplicationArn)
        
        guard let topicArn = createTopic() else {
            XCTFail()
            return
        }
        
        guard let endpoint = createPlatformEndpoint() else {
            XCTFail()
            return
        }

        let expect = expectation(description: "Done")

        sns.subscribe(endpointArn: endpoint, topicArn: topicArn) { result in
            switch result {
            case .success(let arn):
                print("subscribeArn: \(arn)")
            case .error:
                XCTFail()
            }
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testPublishToEndpoint() {
        guard let endpoint = createPlatformEndpoint() else {
            XCTFail()
            return
        }
        
        let sns = SwiftyAWSSNS(accessKeyId: accessKeyId, secretKey: secretKey, region: region, platformApplicationArn: platformApplicationArn)

        let expect = expectation(description: "Done")
        
        // Format of messages: https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html
        // https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html
        
        func strForJSON(json: Any) -> String? {
            if let result = try? JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions(rawValue: 0)) {
                return String(data: result, encoding: .utf8)
            }
            return nil
        }
        
        let messageContentsDict = ["aps":
            ["alert": "Hello!",
            "sound": "default"]
        ]
        
        guard let messageContentsString = strForJSON(json: messageContentsDict) else {
            XCTFail()
            return
        }
        
        // Looks like the top level key must be "APNS" for production; see https://forums.aws.amazon.com/thread.jspa?threadID=145907
        let messageDict = ["APNS_SANDBOX": messageContentsString,
            "APNS": messageContentsString
        ]

        guard let messageString = strForJSON(json: messageDict) else {
            XCTFail()
            return
        }

        sns.publish(message: messageString, target: .endpointArn(endpoint)) { response in
            switch response {
            case .success:
                break
            case .error(let error):
                print("error: \(error)")
                XCTFail()
            }
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    static var allTests = [
        ("testCreatePlatformEndpoint", testCreatePlatformEndpoint),
        ("testCreateTopic", testCreateTopic),
        ("testSubscribe", testSubscribe),
        ("testPublishToEndpoint", testPublishToEndpoint)
    ]
}
