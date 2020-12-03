import Foundation
import NIO
import SotoDynamoDB

protocol DynamoDBController {
    associatedtype Model: DynamoDBModelWithTable
    var db: DynamoDB { get }
    init(db: DynamoDB)
    func createTable(_ ifNotExists: Bool, on eventLoop: EventLoop) -> EventLoopFuture<DynamoDB.CreateTableOutput?>
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
    
    var batchMaximumAllowedValue: Int { 25 }
    
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
    
    func batch(
        _ models: [Model],
        batchMaximumValue: Int = 25,
        waittime: UInt32 = 0
    ) -> EventLoopFuture<[DynamoDB.BatchWriteItemOutput]> {
        var batchMaximumValue = batchMaximumValue
        if batchMaximumValue > batchMaximumAllowedValue { batchMaximumValue = batchMaximumAllowedValue }
        
        var lowerIndex: Int = 0
        var upperIndex: Int
        var a: [[Model]] = []
        while lowerIndex < models.count {
            if lowerIndex + batchMaximumValue < models.count {
                upperIndex = lowerIndex + batchMaximumValue
            } else {
                upperIndex = models.count
            }
            a.append(models[lowerIndex..<upperIndex].map { $0 })
            lowerIndex += batchMaximumValue
        }
        
        guard waittime > 0 else {
            return a.map { _batch($0) }.flatten(on: db.eventLoopGroup.next())
        }
        
        return a.reduce(into: db.eventLoopGroup.future([])) { f, e in
            f = f.flatMap { _a in
                var _a = _a
                return _batch(e).map {
                    sleep(waittime)
                    _a.append($0)
                    return _a
                }
            }
        }
    }
}

extension DynamoDBController {
    func all() -> EventLoopFuture<[Model]> {
        db
            .scan(.init(tableName: Model.tableName))
            .map { $0.items ?? [] }
            .flatMapEachThrowing { try .init(dic: $0) }
    }
}
