import Foundation
import NIO
import SotoDynamoDB
import AsyncKit

struct PrefectureNameController: _DynamoDBController {
    typealias Model = PrefectureName
    
    let db: DynamoDB
    
    init(db: DynamoDB) {
        self.db = db
    }
    
    func get(id: String) -> EventLoopFuture<Model> {
        get(
            .init(
                key: [Model.DynamoDBField.id: .s(id)],
                tableName: Model.tableName
            )
        )
    }
    
    private func create(
        id: String,
        name: String,
        eName: String
    ) -> EventLoopFuture<Model> {
        create(.init(id: id, name: name, eName: eName))
    }
    
    private func update(
        id: String,
        name: String,
        eName: String
    ) -> EventLoopFuture<Model> {
        let input = DynamoDB.UpdateItemInput(
            expressionAttributeNames: [
                "#name": Model.DynamoDBField.name,
                "#eName": Model.DynamoDBField.eName,
                "#updatedAt": Model.DynamoDBField.updatedAt
            ],
            expressionAttributeValues: [
                ":name": .s(name),
                ":eName": .s(eName),
                ":updatedAt": .s(Date().iso8601)
            ],
            key: [Model.DynamoDBField.id: .s(id)],
            returnValues: .allNew,
            tableName: Model.tableName,
            updateExpression: "SET #name = :name, #eName = :eName, #updatedAt = :updatedAt"
        )
        
        return db.updateItem(input).flatMap { _ in self.get(id: id) }
    }
    
    func delete(_ name: String) -> EventLoopFuture<Void> {
        db
            .deleteItem(
                .init(
                    key: [Model.DynamoDBField.name: .s(name)],
                    tableName: Model.tableName
                )
            )
            .map { _ in }
    }
}

// 新規 or 更新を判断してから保存
extension PrefectureNameController {
    func add(
        name: String,
        eName: String
    ) -> EventLoopFuture<Model> {
        let i = String(prefectureNames.firstIndex { name.range(of: $0) != nil } ?? -1)
        return db
            .getItem(
                .init(
                    key: [Model.DynamoDBField.id: .s(i)],
                    tableName: Model.tableName
                )
            )
            .flatMap { output in
                if let _ = output.item {
                    return update(id: i, name: name, eName: eName)
                } else {
                    return create(id: i, name: name, eName: eName)
                }
            }
    }
}
