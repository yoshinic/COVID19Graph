import Foundation
import SotoDynamoDB

struct DownloadResult: DynamoDBModelWithTable {
    
    static let tableName: String = "results"
    
    var message: String = ""
    
    var createdAt: Date?
    var updatedAt: Date?
    
    struct DynamoDBField {
        static let message = "message"
        
        static let createdAt = "created_at"
        static let updatedAt = "updated_at"
    }
}

extension DownloadResult {
    init(dic: [String: DynamoDB.AttributeValue]) throws {
        if
            let messageAtValue = dic[DynamoDBField.message],
            case let .s(message) = messageAtValue,
            !message.isEmpty
        {
            self.message = message
        }
        
        if
            let createdAtValue = dic[DynamoDBField.createdAt],
            case let .s(createdAtValueString) = createdAtValue,
            let createdAt = Utils.iso8601Formatter.date(from: createdAtValueString)
        {
            self.createdAt = createdAt
        }
        
        if
            let updatedAtValue = dic[DynamoDBField.updatedAt],
            case let .s(updatedAtValueString) = updatedAtValue,
            let updatedAt = Utils.iso8601Formatter.date(from: updatedAtValueString)
        {
            self.updatedAt = updatedAt
        }
    }
}

extension DownloadResult {
    var dynamoDbDictionary: [String: DynamoDB.AttributeValue] {
        var dic: [String: DynamoDB.AttributeValue] = [:]
        
        if !message.isEmpty {
            dic[DynamoDBField.message] = .s(message)
        }
        
        if let createdAt = createdAt {
            dic[DynamoDBField.createdAt] = .s(Utils.iso8601Formatter.string(from: createdAt))
        }
        
        if let updatedAt = updatedAt {
            dic[DynamoDBField.updatedAt] = .s(Utils.iso8601Formatter.string(from: updatedAt))
        }
        
        return dic
    }
}

extension DownloadResult {
    static var attributeDefinitions: [DynamoDB.AttributeDefinition] {
        [
            .init(attributeName: DynamoDBField.message, attributeType: .s),
        ]
    }
    
    static var keySchema: [DynamoDB.KeySchemaElement] {
        [
            .init(attributeName: DynamoDBField.message, keyType: .hash),
        ]
    }
}
