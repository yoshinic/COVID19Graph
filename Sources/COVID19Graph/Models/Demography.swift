import Foundation
import SotoDynamoDB

// demography.csv
struct Demography: DynamoDBModelWithTable {
    
    static let tableName: String = "demographys"
    
    var date: String = ""
    var ageGroup: String = ""
    var positive: String = ""
    var hospitalized: String = ""
    var serious: String = ""
    var death: String = ""
    
    var createdAt: Date?
    var updatedAt: Date?
    
    struct DynamoDBField {
        static let date = "date"
        static let ageGroup = "age_group"
        static let positive = "positive"
        static let hospitalized = "hospitalized"
        static let serious = "serious"
        static let death = "death"
        
        static let createdAt = "created_at"
        static let updatedAt = "updated_at"
    }
}

extension Demography {
    init(dic: [String: DynamoDB.AttributeValue]) throws {
        if
            let dateAtValue = dic[DynamoDBField.date],
            case let .s(date) = dateAtValue,
            !date.isEmpty
        {
            self.date = date
        }
        
        if
            let ageGroupAtValue = dic[DynamoDBField.ageGroup],
            case let .s(ageGroup) = ageGroupAtValue,
            !ageGroup.isEmpty
        {
            self.ageGroup = ageGroup
        }
        
        if
            let positiveAtValue = dic[DynamoDBField.positive],
            case let .s(positive) = positiveAtValue,
            !positive.isEmpty
        {
            
            self.positive = positive
        }
        
        if
            let hospitalizedAtValue = dic[DynamoDBField.hospitalized],
            case let .s(hospitalized) = hospitalizedAtValue,
            !hospitalized.isEmpty
        {
            self.hospitalized = hospitalized
        }
        
        if
            let seriousAtValue = dic[DynamoDBField.serious],
            case let .s(serious) = seriousAtValue,
            !serious.isEmpty
        {
            self.serious = serious
        }
        
        if
            let deathAtValue = dic[DynamoDBField.death],
            case let .s(death) = deathAtValue,
            !death.isEmpty
        {
            self.death = death
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

extension Demography {
    var dynamoDbDictionary: [String: DynamoDB.AttributeValue] {
        var dic: [String: DynamoDB.AttributeValue] = [:]
        
        if !date.isEmpty {
            dic[DynamoDBField.date] = .s(date)
        }
        if !ageGroup.isEmpty {
            dic[DynamoDBField.ageGroup] = .s(ageGroup)
        }
        if !positive.isEmpty {
            dic[DynamoDBField.positive] = .s(positive)
        }
        if !hospitalized.isEmpty {
            dic[DynamoDBField.hospitalized] = .s(hospitalized)
        }
        if !serious.isEmpty {
            dic[DynamoDBField.serious] = .s(serious)
        }
        if !death.isEmpty {
            dic[DynamoDBField.death] = .s(death)
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

extension Demography {
    static var attributeDefinitions: [DynamoDB.AttributeDefinition] {
        [
            .init(attributeName: DynamoDBField.date, attributeType: .s),
            .init(attributeName: DynamoDBField.ageGroup, attributeType: .s),
        ]
    }
    
    static var keySchema: [DynamoDB.KeySchemaElement] {
        [
            .init(attributeName: DynamoDBField.date, keyType: .hash),
            .init(attributeName: DynamoDBField.ageGroup, keyType: .range),
        ]
    }
}
