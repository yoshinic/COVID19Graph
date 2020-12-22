import Foundation
import AWSLambdaRuntime
import SotoCore

struct MakeTableInput: Codable {
    
}

struct TableLambdaHandler: DynamoDBLambdaHandler {
    typealias In = MakeTableInput
    typealias Out = Output
    
    let prefectureController: PrefectureController
    
    let downloadResultController: DownloadResultController
    
    init(context: Lambda.InitializationContext) {
        let db = Self.createDynamoDBClient(on: context.eventLoop)
        
        self.prefectureController = .init(db: db)
        self.downloadResultController = .init(db: db)
    }
    
    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        prefectureController
            .createTable(on: context.eventLoop)
            .flatMap { _ in downloadResultController.createTable(true, true, on: context.eventLoop) }
            .transform(to: .init(result: "OK!"))
    }
}
