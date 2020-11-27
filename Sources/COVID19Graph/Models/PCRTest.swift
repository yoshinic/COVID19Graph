import Foundation
import SotoDynamoDB

// pcr_tested_daily.csv
struct PCRTest: BasicDataModel {
    
    static let tableName: String = "pcr_tests"
    
    var date: String = ""
    var number: String = ""
    
    var createdAt: Date?
    var updatedAt: Date?
    
    struct DynamoDBField {
        static let date = "date"
        static let number = "number"
        
        static let createdAt = "created_at"
        static let updatedAt = "updated_at"
    }
}

extension PCRTest {
    init(dic: [String: DynamoDB.AttributeValue]) throws {
        if
            let dateAtValue = dic[DynamoDBField.date],
            case let .s(date) = dateAtValue,
            !date.isEmpty
        {
            self.date = date
        }
        
        if
            let numberAtValue = dic[DynamoDBField.number],
            case let .s(number) = numberAtValue,
            !number.isEmpty
        {
            self.number = number
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

extension PCRTest {
    var dynamoDbDictionary: [String: DynamoDB.AttributeValue] {
        var dic: [String: DynamoDB.AttributeValue] = [:]
        
        if !date.isEmpty {
            dic[DynamoDBField.date] = .s(date)
        }
        if !number.isEmpty {
            dic[DynamoDBField.number] = .s(number)
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

extension PCRTest {
    static var attributeDefinitions: [DynamoDB.AttributeDefinition] {
        [
            .init(attributeName: DynamoDBField.date, attributeType: .s),
        ]
    }
    
    static var keySchema: [DynamoDB.KeySchemaElement] {
        [
            .init(attributeName: DynamoDBField.date, keyType: .hash),
        ]
    }
}
