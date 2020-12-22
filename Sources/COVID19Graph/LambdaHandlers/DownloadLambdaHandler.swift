import Foundation
import AWSLambdaRuntime
import AWSLambdaEvents
import SotoCore

struct Input: Codable {
    let prefecture: String
}

struct Output: Codable {
    let result: String
}

struct DownloadLambdaHandler: DynamoDBLambdaHandler {
    typealias In = Input
    typealias Out = Output
    
    let prefectureController: PrefectureController
    let downloadResultController: DownloadResultController
    
    init(context: Lambda.InitializationContext) {
        let db = Self.createDynamoDBClient(on: context.eventLoop)
        
        self.prefectureController = .init(db: db)
        self.downloadResultController = .init(db: db)
    }
    
    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        _handle(prefectureController, event.prefecture, on: context.eventLoop)
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
