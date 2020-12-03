import Foundation
import AWSLambdaRuntime
import AWSLambdaEvents
import AsyncHTTPClient
import NIO
import SotoDynamoDB

struct MPrefectureLambdaHandler: DynamoDBLambdaHandler {
    typealias In = AWSLambdaEvents.DynamoDB.Event
    typealias Out = Output
    
    let prefectureController: PrefectureController
    let mprefectureController: MPrefectureController
    
    init(context: Lambda.InitializationContext) {
        let db = Self.createDynamoDBClient(on: context.eventLoop)
        self.prefectureController = .init(db: db)
        self.mprefectureController = .init(db: db)
    }
    
    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        context
            .eventLoop
            .makeSucceededFuture(event)
            .map { $0.records }
            .guard({ $0.count == 1 }, else: APIError.request)
            .mapEachCompact { $0.change.newImage }
            .mapEachCompact { $0[DownloadResult.DynamoDBField.message] }
            .guard({ $0.count == 1 }, else: APIError.request)
            .flatMap { _ in prefectureController.all() }
            .mapEachCompact {
                guard let date = $0.date.toDate else { return nil }
                let c = Calendar.default.dateComponents([.month, .weekday], from: date)
                guard let month = c.month, let weekday = c.weekday else { return nil }
                return MPrefecture(
                    month: "\(month)",
                    dayOfTheWeek: "\(weekday)",
                    prefectureName: $0.prefectureNameJ,
                    positive: $0.positive,
                    peopleTested: $0.peopleTested,
                    hospitalized: $0.hospitalized,
                    serious: $0.serious,
                    discharged: $0.discharged,
                    deaths: $0.deaths,
                    effectiveReproductionNumber: $0.effectiveReproductionNumber
                )
            }
            .flatMap { mprefectureController.batch($0) }
            .map { .init(result: "\($0)") }
    }
}
