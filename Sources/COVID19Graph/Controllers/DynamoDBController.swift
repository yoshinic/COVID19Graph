import Foundation
import NIO
import SotoDynamoDB

protocol DynamoDBController {
    associatedtype Model: DynamoDBModelWithTable
    var db: DynamoDB { get }
    init(db: DynamoDB)
    func createTable(_ ifNotExists: Bool, on eventLoop: EventLoop) -> EventLoopFuture<DynamoDB.CreateTableOutput?>
    func add(_ a: [String]) -> EventLoopFuture<Model>
    func batch(_ a: [[String]]) -> EventLoopFuture<[DynamoDB.BatchWriteItemOutput]>
}

// Create Table
extension DynamoDBController {
    func createTable(
        _ ifNotExists: Bool,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DynamoDB.CreateTableOutput?> {
        guard ifNotExists else { return _createTable().map { $0 } }
        return db
            .listTables(.init())
            .flatMap {
                guard let a = $0.tableNames, a.contains(Model.tableName)
                else { return _createTable().map { $0 } }
                return eventLoop.next().makeSucceededFuture(nil)
            }
    }
    
    func createTable(on eventLoop: EventLoop) -> EventLoopFuture<DynamoDB.CreateTableOutput?> {
        createTable(true, on: eventLoop)
    }
    
    private func _createTable() -> EventLoopFuture<DynamoDB.CreateTableOutput> {
        db.createTable(
            .init(
                attributeDefinitions: Model.attributeDefinitions,
                billingMode: .provisioned,
                keySchema: Model.keySchema,
                provisionedThroughput: .init(
                    readCapacityUnits: 5,
                    writeCapacityUnits: 5
                ),
                streamSpecification: .init(
                    streamEnabled: true,
                    streamViewType: .newImage
                ),
                tableName: Model.tableName
            )
        )
    }
}

extension DynamoDBController {
    func get(_ input: DynamoDB.GetItemInput) -> EventLoopFuture<Model> {
        db
            .getItem(input)
            .map { $0.item }
            .guard({ $0 != nil }, else: APIError.notFound)
            .flatMapThrowing { try .init(dic: $0!) }
    }
    
    func create(_ model: Model) -> EventLoopFuture<Model> {
        var model = model
        
        let currentDate = Date()
        model.updatedAt = currentDate
        model.createdAt = currentDate
        
        return db
            .putItem(
                DynamoDB.PutItemInput.init(
                    item: model.dynamoDbDictionary,
                    tableName: Model.tableName
                )
            )
            .map { _ in model }
    }
}

extension DynamoDBController {
    private func _batch(_ models: [Model]) -> EventLoopFuture<DynamoDB.BatchWriteItemOutput> {
        var models = models
        let currentDate = Date()
        for i in (0..<models.count) {
            models[i].createdAt = currentDate
            models[i].updatedAt = currentDate
        }
        return db.batchWriteItem(
            DynamoDB.BatchWriteItemInput(
                requestItems: [
                    Model.tableName: models.map {
                        DynamoDB.WriteRequest(
                            deleteRequest: nil,
                            putRequest: DynamoDB.PutRequest(item: $0.dynamoDbDictionary)
                        )
                    }
                ]
            )
        )
    }
    
    func batch(_ models: [Model]) -> EventLoopFuture<[DynamoDB.BatchWriteItemOutput]> {
        let batchMaximumAllowedValue: Int = 25
        
        var lowerIndex: Int = 0
        var upperIndex: Int
        var a: [[Model]] = []
        while lowerIndex < models.count {
            if lowerIndex + batchMaximumAllowedValue < models.count {
                upperIndex = lowerIndex + batchMaximumAllowedValue
            } else {
                upperIndex = models.count
            }
            a.append(models[lowerIndex..<upperIndex].map { $0 })
            lowerIndex += batchMaximumAllowedValue
        }
        
        return a.map { _batch($0) }.flatten(on: db.eventLoopGroup.next())
    }
}
