import KituraNet
import SwiftAWSSignatureV4
import Foundation

public class SwiftyAWSSNS {
    private let service = "sns"
    private let version = "2010-03-31"
    private var accessKeyId:String!
    private var secretKey:String!
    private var region: String!
    private var baseURL:String!
    private var platformApplicationArn: String!
    private var account:AWSAccount!
    
    public enum Result<T> {
        case success(T)
        case error(AWSError)
    }
    
    public enum AWSError : Swift.Error {
        case httpStatusError(Int?)
        case jsonDeserializationError(Swift.Error)
        case jsonParsingError
    }
    
    init(accessKeyId: String, secretKey: String, region: String, platformApplicationArn: String) {
        self.accessKeyId = accessKeyId
        self.secretKey = secretKey
        self.region = region
        baseURL = "sns.\(region).amazonaws.com"
        self.platformApplicationArn = platformApplicationArn
        account = AWSAccount(serviceName: service, region: region, accessKeyID: accessKeyId, secretAccessKey: secretKey)
    }
    
    func sendRequest(request: URLRequest, queryParameters: String, completion:@escaping (Result<[String: Any]>)->()) {
    
        var request = request
        
        // Without this header, I get an error: <Message>When Content-Type:application/x-www-form-urlencoded, URL cannot include query-string parameters
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.setValue(baseURL, forHTTPHeaderField: "Host")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        request.sign(for: account, signPayload: true)
        
        let headers = request.allHTTPHeaderFields!
        // print("headers: \(headers)")
        
        let options:[ClientRequest.Options] = [
            .method(request.httpMethod!),
            .headers(headers),
            .schema("https"),
            .hostname(baseURL),
            .path("/?" + queryParameters)
        ]

        let req = HTTP.request(options) { response in
            // print("response?.httpStatusCode: \(String(describing: response?.httpStatusCode))")
            var jsonResult:Any!
            
            if response?.httpStatusCode == .OK {
                do {
                    var bodyData = Data()
                    try response?.readAllData(into: &bodyData)
                    jsonResult = try JSONSerialization.jsonObject(with: bodyData, options: [])
                }
                catch (let error) {
                    completion(.error(AWSError.jsonDeserializationError(error)))
                    return
                }
                
                guard let jsonDict = jsonResult as? [String: Any] else {
                    completion(.error(AWSError.jsonParsingError))
                    return
                }
                
                // print("endpointArn: \(endpointArn)")
                completion(.success(jsonDict))
            }
            else {
                completion(.error(AWSError.httpStatusError(response?.httpStatusCode.rawValue)))
            }
        }
        
        // print("req.url: \(req.url)")
        // print("req.headers: \(req.headers)")

        req.end() // send the request
    }
    
    // On success, completion returns the endpointArn created
    // https://docs.aws.amazon.com/sns/latest/api/API_CreatePlatformEndpoint.html
    public func createPlatformEndpoint(apnsToken: String,
        completion:@escaping (Result<String>)->()) {
        
        let action = "CreatePlatformEndpoint"
        
        let queryParameters = "Action=\(action)&PlatformApplicationArn=\(platformApplicationArn!)&Token=\(apnsToken)&Version=\(version)"

        let urlPath = "https://" + baseURL + "/?" + queryParameters
        let url = URL(string: urlPath)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        sendRequest(request: request, queryParameters: queryParameters) { result in
            switch result {
            case .success(let dict):
                guard let createPlatformEndpointResponse = dict["CreatePlatformEndpointResponse"] as? [String: Any],
                    let createPlatformEndpointResult = createPlatformEndpointResponse["CreatePlatformEndpointResult"] as? [String: Any],
                    let endpointArn = createPlatformEndpointResult["EndpointArn"] as? String  else {
                    completion(.error(AWSError.jsonParsingError))
                    return
                }
                
                completion(.success(endpointArn))
            case .error(let error):
                completion(.error(error))
            }
        }
    }
    
    // On success, responds with Topic ARN.
    // https://docs.aws.amazon.com/sns/latest/api/API_CreateTopic.html
    public func createTopic(topicName: String, completion:@escaping (Result<String>)->()) {
        let action = "CreateTopic"
        let queryParameters = "Action=\(action)&Name=\(topicName)&Version=\(version)"

        let urlPath = "https://" + baseURL + "/?" + queryParameters
        let url = URL(string: urlPath)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        sendRequest(request: request, queryParameters: queryParameters) { result in
            switch result {
            case .success(let dict):
                guard let createTopicResponse = dict["CreateTopicResponse"] as? [String: Any],
                    let createTopicResult = createTopicResponse["CreateTopicResult"] as? [String: Any],
                    let topicArn = createTopicResult["TopicArn"] as? String  else {
                    completion(.error(AWSError.jsonParsingError))
                    return
                }
                completion(.success(topicArn))
            case .error(let error):
                completion(.error(error))
            }
        }
    }
    
    // On success, returns a subscription ARN.
    // https://docs.aws.amazon.com/sns/latest/api/API_Subscribe.html
    public func subscribe(endpointArn: String, topicArn: String, completion:@escaping (Result<String>)->()) {
        let action = "Subscribe"
        let protocolName = "Application"
        let queryParameters = "Action=\(action)&Endpoint=\(endpointArn)&Protocol=\(protocolName)&TopicArn=\(topicArn)&Version=\(version)"

        let urlPath = "https://" + baseURL + "/?" + queryParameters
        let url = URL(string: urlPath)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        sendRequest(request: request, queryParameters: queryParameters) { result in
            switch result {
            case .success(let dict):
                guard let subscribeResponse = dict["SubscribeResponse"] as? [String: Any],
                    let subscribeResult = subscribeResponse["SubscribeResult"] as? [String: Any],
                    let subscriptionArn = subscribeResult["SubscriptionArn"] as? String  else {
                    completion(.error(AWSError.jsonParsingError))
                    return
                }
                completion(.success(subscriptionArn))
            case .error(let error):
                completion(.error(error))
            }
        }
    }
    
    public func listSubscriptionsByTopic() {
    }
    
    public func deleteTopic() {
    }

    public func unsubscribe() {
    }
    
    public func deleteEndpoint() {
    }
    
    public func publish() {
    }
}