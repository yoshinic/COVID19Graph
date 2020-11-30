import AWSLambdaRuntime
import AsyncHTTPClient
import SotoDynamoDB

protocol DynamoDBLambdaHandler: EventLoopLambdaHandler {
    
}

extension DynamoDBLambdaHandler {
    static func createDynamoDBClient(
        endpoint: String? = nil,
        on eventLoop: EventLoop
    ) -> SotoDynamoDB.DynamoDB {
        let accessKeyId = Lambda.env("ACCESS_KEY_ID") ?? "dummyAccessKeyId"
        let secretAccessKey = Lambda.env("SECRET_ACCESS_KEY") ?? "dummySecretAccessKey"
        let region = Lambda.env("REGION") ?? Region.uswest2.rawValue
        let endpoint = Lambda.env("ENDPOINT") ?? endpoint
        
        let httpClient: AsyncHTTPClient.HTTPClient = .init(
            eventLoopGroupProvider: .shared(eventLoop),
            configuration: .init(
                timeout: .init(
                    connect: .seconds(30),
                    read: .seconds(30)
                )
            )
        )
        
        return .init(
            client: .init(
                credentialProvider: .static(
                    accessKeyId: accessKeyId,
                    secretAccessKey: secretAccessKey,
                    sessionToken: nil
                ),
                httpClientProvider: .shared(httpClient)
            ),
            region: .init(rawValue: region),
            endpoint: endpoint,
            timeout: .seconds(30)
        )
    }
}
