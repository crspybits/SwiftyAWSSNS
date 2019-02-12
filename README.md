# SwiftyAWSSNS

    let sns = SwiftyAWSSNS(accessKeyId: accessKeyId, secretKey: secretKey, region: region, platformApplicationArn: platformApplicationArn)
        
    // Format of messages: https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html
    // https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html
    
    // Prepare your messageString

    sns.publish(message: messageString, target: .endpointArn(endpoint)) { response in
        switch response {
        case .success:
            break
        case .error(let error):
            print("error: \(error)")
        }
    }

    // See the test cases for other examples of usage: createPlatformEndpoint, createTopic, and subscribe.
