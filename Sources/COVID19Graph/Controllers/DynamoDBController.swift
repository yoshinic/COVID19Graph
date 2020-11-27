import Foundation
import NIO
import SotoDynamoDB

protocol _DynamoDBController {
    associatedtype Model: DynamoDBModelWithTable
    var db: DynamoDB { get }
    init(db: DynamoDB)
    func createTable(_ ifNotExists: Bool, on eventLoop: EventLoop) -> EventLoopFuture<DynamoDB.CreateTableOutput?>
}

protocol DynamoDBController: _DynamoDBController {
    func add(_ a: [String]) -> EventLoopFuture<Model>
}

// Create Table
extension _DynamoDBController {
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

extension _DynamoDBController {
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
