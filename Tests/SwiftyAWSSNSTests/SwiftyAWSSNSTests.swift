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
        if let resource = NSDictionary(contentsOfFile: "/tmp/Info.plist") {
            accessKeyId = resource["accessKeyId"] as? String
            secretKey = resource["secretKey"] as? String
            region = resource["region"] as? String
            platformApplicationArn = resource["platformApplicationArn"] as? String
            token = resource["token"] as? String
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
        /*
            {
            "APNS_SANDBOX":"{\"aps\":{\"alert\":\"Hello!\"}}"
            }
         
            {'aps':{'alert':'Hello!'}}
        */
        let json = "{\"aps\":{\"alert\":\"Hello!\"}}"
        let urlEncoadedJson = json.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!

        sns.publish(message: json, target: .endpointArn(endpoint)) { response in
            switch response {
            case .success:
                break
            case .error:
                XCTFail()
            }
            
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    static var allTests = [
        ("testCreatePlatformEndpoint", testCreatePlatformEndpoint),
    ]
}
