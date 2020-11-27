import Foundation
import AWSLambdaRuntime
import AsyncHTTPClient
import NIO
import SotoDynamoDB

struct Input: Codable {
    let death: String
    let demography: String
    let ern: String
    let hospitalization: String
    let pcrCase: String
    let pcrPositive: String
    let pcrTest: String
    let prefecture: String
    let recovery: String
    let severity: String
}

struct Output: Codable {
    let result: String
}

struct LambdaHandler: EventLoopLambdaHandler {
    typealias In = Input
    typealias Out = Output
    
    let deathController: DeathController
    let demographyController: DemographyController
    let ernController: EffectiveReproductionNumberController
    let hospitalizationController: HospitalizationController
    let pcrCaseController: PCRCaseController
    let pcrPositiveController: PCRPositiveController
    let pcrTestController: PCRTestController
    let prefectureNameController: PrefectureNameController
    let prefectureController: PrefectureController
    let recoveryController: RecoveryController
    let severityController: SeverityController
    
    init(context: Lambda.InitializationContext) {
        let db = Self.createDynamoDBClient(on: context.eventLoop)
        
        self.deathController = .init(db: db)
        self.demographyController = .init(db: db)
        self.ernController = .init(db: db)
        self.hospitalizationController = .init(db: db)
        self.pcrCaseController = .init(db: db)
        self.pcrPositiveController = .init(db: db)
        self.pcrTestController = .init(db: db)
        self.prefectureNameController = .init(db: db)
        self.prefectureController = .init(db: db)
        self.recoveryController = .init(db: db)
        self.severityController = .init(db: db)
    }
    
    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        prefectureNameController
            .createTable(on: context.eventLoop)
            .transform(to: ())
            .flatMap { _handle(deathController, event.death, on: context.eventLoop) }
            .flatMap { _handle(demographyController, event.demography, on: context.eventLoop) }
            .flatMap { _handle(ernController, event.ern, on: context.eventLoop) }
            .flatMap { _handle(hospitalizationController, event.hospitalization, on: context.eventLoop) }
            .flatMap { _handle(pcrCaseController, event.pcrCase, on: context.eventLoop) }
            .flatMap { _handle(pcrPositiveController, event.pcrPositive, on: context.eventLoop) }
            .flatMap { _handle(pcrTestController, event.pcrTest, on: context.eventLoop) }
            .flatMap { _handle(prefectureController, event.prefecture, on: context.eventLoop) }
            .flatMap { _handle(recoveryController, event.recovery, on: context.eventLoop) }
            .flatMap { _handle(severityController, event.severity, on: context.eventLoop) }
            .transform(to: .init(result: "OK!"))
    }
    
    private func _handle<T: DynamoDBController>(
        _ controller: T,
        _ url: String,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<Void> {
        controller
            .createTable(on: eventLoop)
            .map { _ in URL(string: url) }
            .unwrap(orError: APIError.request)
            .map { AWSHTTPRequest(url: $0, method: .GET, headers: [:]) }
            .flatMap {
                controller
                    .db
                    .client
                    .httpClient
                    .execute(
                        request: $0,
                        timeout: .seconds(30),
                        on: eventLoop,
                        logger: .init(label: "httpClientLog")
                    )
                    .map { $0.body }
                    .unwrap(orError: APIError.description("CSVデータを取得できません。"))
                    .map { String(buffer: $0) }
            }
            .map { $0.components(separatedBy: .newlines).filter { !$0.isEmpty }.dropFirst().map { $0 } }
            .mapEach { $0.components(separatedBy: ",") }
            .flatMapEach(on: eventLoop) { controller.add($0) }
            .transform(to: ())
    }
}

extension LambdaHandler {
    static func createDynamoDBClient(on eventLoop: EventLoop) -> SotoDynamoDB.DynamoDB {
        let accessKeyId = Lambda.env("ACCESS_KEY_ID") ?? "dummyAccessKeyId"
        let secretAccessKey = Lambda.env("SECRET_ACCESS_KEY") ?? "dummySecretAccessKey"
        let region = Lambda.env("REGION") ?? Region.uswest2.rawValue
        let endpoint = Lambda.env("ENDPOINT") ?? "http://localhost:8000"
        
        let httpClient: AsyncHTTPClient.HTTPClient = .init(
            eventLoopGroupProvider: .shared(eventLoop),
            configuration: .init(
                timeout: .init(
                    connect: .seconds(30),
                    read: .seconds(120)
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
            timeout: .seconds(120)
        )
    }
}
