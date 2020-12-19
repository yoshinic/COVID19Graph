import Foundation
import SotoDynamoDB

struct DownloadResultController: DynamoDBController {
    typealias Model = DownloadResult
    
    let db: DynamoDB
    
    init(db: DynamoDB) {
        self.db = db
    }
    
    func get(message: String) -> EventLoopFuture<Model> {
        get(
            .init(
                key: [Model.DynamoDBField.message: .s(message)],
                tableName: Model.tableName
            )
        )
    }
    
    func create(message: String) -> EventLoopFuture<Model> {
        create(.init(message: message))
    }
    
    func update(message: String) -> EventLoopFuture<Model> {
        let input = DynamoDB.UpdateItemInput(
            expressionAttributeNames: [
                "#updatedAt": Model.DynamoDBField.updatedAt
            ],
            expressionAttributeValues: [
                ":updatedAt": .s(Date().iso8601)
            ],
            key: [Model.DynamoDBField.message: .s(message)],
            returnValues: .allNew,
            tableName: Model.tableName,
            updateExpression: "SET #updatedAt = :updatedAt"
        )
        
        return db.updateItem(input).flatMap { _ in self.get(message: message) }
    }
    
    func delete(_ message: String) -> EventLoopFuture<Void> {
        db
            .deleteItem(
                .init(
                    key: [Model.DynamoDBField.message: .s(message)],
                    tableName: Model.tableName
                )
            )
            .map { _ in }
    }
}

// 新規 or 更新を判断してから保存
extension DownloadResultController {
    func add(message: String) -> EventLoopFuture<Model> {
        db
            .getItem(
                .init(
                    key: [Model.DynamoDBField.message: .s(message)],
                    tableName: Model.tableName
                )
            )
            .flatMap { output in
                if let _ = output.item {
                    return update(message: message)
                } else {
                    return create(message: message)
                }
            }
    }
}
