import Foundation
import SotoDynamoDB

// pcr_case_daily.csv
struct PCRCase: DynamoDBModelWithTable {
    
    static let tableName: String = "pcr_cases"
    
    var date: String = ""
    var national: String = ""       // 国立感染症研究所
    var quarantine: String = ""     // 検疫所
    var local: String = ""          // 地方衛生研究所・保健所
    var `private`: String = ""      // 民間検査会社
    var university: String = ""     // 大学等
    var medical: String = ""        // 医療機関
    
    var createdAt: Date?
    var updatedAt: Date?
    
    struct DynamoDBField {
        static let date = "date"
        static let national = "national"
        static let quarantine = "quarantine"
        static let local = "local"
        static let `private` = "private"
        static let university = "university"
        static let medical = "medical"
        
        static let createdAt = "created_at"
        static let updatedAt = "updated_at"
    }
}

extension PCRCase {
    init(dic: [String: DynamoDB.AttributeValue]) throws {
        if
            let dateAtValue = dic[DynamoDBField.date],
            case let .s(date) = dateAtValue,
            !date.isEmpty
        {
            self.date = date
        }
        
        if
            let nationalAtValue = dic[DynamoDBField.national],
            case let .s(national) = nationalAtValue,
            !national.isEmpty
        {
            self.national = national
        }
        
        if
            let quarantineAtValue = dic[DynamoDBField.quarantine],
            case let .s(quarantine) = quarantineAtValue,
            !quarantine.isEmpty
        {
            
            self.quarantine = quarantine
        }
        
        if
            let localAtValue = dic[DynamoDBField.local],
            case let .s(local) = localAtValue,
            !local.isEmpty
        {
            self.local = local
        }
        
        if
            let privateAtValue = dic[DynamoDBField.`private`],
            case let .s(`private`) = privateAtValue,
            !`private`.isEmpty
        {
            self.`private` = `private`
        }
        
        if
            let universityAtValue = dic[DynamoDBField.university],
            case let .s(university) = universityAtValue,
            !university.isEmpty
        {
            self.university = university
        }
        
        if
            let medicalAtValue = dic[DynamoDBField.medical],
            case let .s(medical) = medicalAtValue,
            !medical.isEmpty
        {
            self.medical = medical
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

extension PCRCase {
    var dynamoDbDictionary: [String: DynamoDB.AttributeValue] {
        var dic: [String: DynamoDB.AttributeValue] = [:]
        
        if !date.isEmpty {
            dic[DynamoDBField.date] = .s(date)
        }
        if !national.isEmpty {
            dic[DynamoDBField.national] = .s(national)
        }
        if !quarantine.isEmpty {
            dic[DynamoDBField.quarantine] = .s(quarantine)
        }
        if !local.isEmpty {
            dic[DynamoDBField.local] = .s(local)
        }
        if !`private`.isEmpty {
            dic[DynamoDBField.`private`] = .s(`private`)
        }
        if !university.isEmpty {
            dic[DynamoDBField.university] = .s(university)
        }
        if !medical.isEmpty {
            dic[DynamoDBField.medical] = .s(medical)
        }
        
        return dic
    }
}

extension PCRCase {
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
