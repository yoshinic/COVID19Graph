import Foundation
import AWSLambdaRuntime
import AsyncHTTPClient
import NIO
import SotoDynamoDB

struct MakeTableInput: Codable {
    
}

struct TableLambdaHandler: DynamoDBLambdaHandler {
    typealias In = MakeTableInput
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
        deathController.createTable(on: context.eventLoop)
            .flatMap { _ in demographyController.createTable(on: context.eventLoop) }
            .flatMap { _ in ernController.createTable(on: context.eventLoop) }
            .flatMap { _ in hospitalizationController.createTable(on: context.eventLoop) }
            .flatMap { _ in pcrCaseController.createTable(on: context.eventLoop) }
            .flatMap { _ in pcrPositiveController.createTable(on: context.eventLoop) }
            .flatMap { _ in pcrTestController.createTable(on: context.eventLoop) }
            .flatMap { _ in prefectureController.createTable(on: context.eventLoop) }
            .flatMap { _ in recoveryController.createTable(on: context.eventLoop) }
            .flatMap { _ in severityController.createTable(on: context.eventLoop) }
            .flatMap { _ in downloadResultController.createTable(true, true, on: context.eventLoop) }
            .transform(to: .init(result: "OK!"))
    }
}
