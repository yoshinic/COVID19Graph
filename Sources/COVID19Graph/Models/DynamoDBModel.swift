import Foundation
import SotoDynamoDB

protocol DynamoDBModel: Codable {
    var dynamoDbDictionary: [String: DynamoDB.AttributeValue] { get }
    init(dic: [String: DynamoDB.AttributeValue]) throws
}

protocol DynamoDBModelWithTable: DynamoDBModel {
    static var attributeDefinitions: [DynamoDB.AttributeDefinition] { get }
    static var keySchema: [DynamoDB.KeySchemaElement] { get }
    static var tableName: String { get }
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
}

protocol BasicDataModel: DynamoDBModelWithTable {
    var date: String { get set }
    var number: String { get set }
    
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
}
