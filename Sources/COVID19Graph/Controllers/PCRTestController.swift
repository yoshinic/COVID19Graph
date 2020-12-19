import Foundation
import SotoDynamoDB

struct PCRTestController: DownloadController {
    typealias Model = PCRTest
    
    let db: DynamoDB
    
    init(db: DynamoDB) {
        self.db = db
    }
    
    func get(date: String) -> EventLoopFuture<Model> {
        get(
            .init(
                key: [Model.DynamoDBField.date: .s(date)],
                tableName: Model.tableName
            )
        )
    }
    
    func create(date: String, number: String) -> EventLoopFuture<Model> {
        create(.init(date: date, number: number))
    }
    
    func update(date: String, number: String) -> EventLoopFuture<Model> {
        let input = DynamoDB.UpdateItemInput(
            expressionAttributeNames: [
                "#number": Model.DynamoDBField.number,
                "#updatedAt": Model.DynamoDBField.updatedAt
            ],
            expressionAttributeValues: [
                ":number": .s("\(number)"),
                ":updatedAt": .s(Date().iso8601)
            ],
            key: [Model.DynamoDBField.date: .s(date)],
            returnValues: .allNew,
            tableName: Model.tableName,
            updateExpression: "SET #number = :number, #updatedAt = :updatedAt"
        )
        
        return db.updateItem(input).flatMap { _ in self.get(date: date) }
    }
    
    func delete(_ date: String) -> EventLoopFuture<Void> {
        db
            .deleteItem(
                .init(
                    key: [Model.DynamoDBField.date: .s(date)],
                    tableName: Model.tableName
                )
            )
            .map { _ in }
    }
}

// 新規 or 更新を判断してから保存
extension PCRTestController {
    func add(date: String, number: String) -> EventLoopFuture<Model> {
        db
            .getItem(
                .init(
                    key: [Model.DynamoDBField.date: .s(date)],
                    tableName: Model.tableName
                )
            )
            .flatMap { output in
                if let _ = output.item {
                    return update(date: date, number: number)
                } else {
                    return create(date: date, number: number)
                }
            }
    }
}

extension PCRTestController {
    func add(_ a: [String]) -> EventLoopFuture<PCRTest> {
        add(date: a[0].replacingOccurrences(of: "/", with: "-"), number: a[1])
    }
}

extension PCRTestController {
    func batch(_ a: [[String]]) -> EventLoopFuture<[DynamoDB.BatchWriteItemOutput]> {
        batch(
            a.map {
                Model(
                    date: $0[0].replacingOccurrences(of: "/", with: "-"),
                    number: $0[1]
                )
            }
        )
    }
}
