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

struct DownloadLambdaHandler: DynamoDBLambdaHandler {
    typealias In = Input
    typealias Out = Output
    
    let deathController: DeathController
    let demographyController: DemographyController
    let ernController: EffectiveReproductionNumberController
    let hospitalizationController: HospitalizationController
    let pcrCaseController: PCRCaseController
    let pcrPositiveController: PCRPositiveController
    let pcrTestController: PCRTestController
    let prefectureController: PrefectureController
    let recoveryController: RecoveryController
    let severityController: SeverityController
    
    let downloadResultController: DownloadResultController
    
    init(context: Lambda.InitializationContext) {
        let db = Self.createDynamoDBClient(on: context.eventLoop)
        
        self.deathController = .init(db: db)
        self.demographyController = .init(db: db)
        self.ernController = .init(db: db)
        self.hospitalizationController = .init(db: db)
        self.pcrCaseController = .init(db: db)
        self.pcrPositiveController = .init(db: db)
        self.pcrTestController = .init(db: db)
        self.prefectureController = .init(db: db)
        self.recoveryController = .init(db: db)
        self.severityController = .init(db: db)
        
        self.downloadResultController = .init(db: db)
    }
    
    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        _handle(deathController, event.death, on: context.eventLoop)
            .flatMap { _handle(demographyController, event.demography, on: context.eventLoop) }
            .flatMap { _handle(ernController, event.ern, on: context.eventLoop) }
            .flatMap { _handle(hospitalizationController, event.hospitalization, on: context.eventLoop) }
            .flatMap { _handle(pcrCaseController, event.pcrCase, on: context.eventLoop) }
            .flatMap { _handle(pcrPositiveController, event.pcrPositive, on: context.eventLoop) }
            .flatMap { _handle(pcrTestController, event.pcrTest, on: context.eventLoop) }
            .flatMap { _handle(prefectureController, event.prefecture, on: context.eventLoop) }
            .flatMap { _handle(recoveryController, event.recovery, on: context.eventLoop) }
            .flatMap { _handle(severityController, event.severity, on: context.eventLoop) }
            .flatMap { downloadResultController.createTable(on: context.eventLoop) }
            .flatMap { _ in downloadResultController.add(message: "OK!") }
            .transform(to: .init(result: "OK!"))
    }
    
    private func _handle<T: DownloadController>(
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
            .flatMap { controller.batch($0) }
            .transform(to: ())
    }
}
