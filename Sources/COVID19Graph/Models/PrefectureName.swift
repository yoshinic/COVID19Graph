import Foundation
import SotoDynamoDB

// demography.csv
struct PrefectureName: DynamoDBModelWithTable {
    
    static let tableName: String = "prefecture_names"
    
    var id: String = ""
    var name: String = ""
    var eName: String = ""
    
    var createdAt: Date?
    var updatedAt: Date?
    
    struct DynamoDBField {
        static let id = "id"
        static let name = "name"
        static let eName = "e_name"
        
        static let createdAt = "created_at"
        static let updatedAt = "updated_at"
    }
}

extension PrefectureName {
    init(dic: [String: DynamoDB.AttributeValue]) throws {
        if
            let idAtValue = dic[DynamoDBField.id],
            case let .s(id) = idAtValue
        {
            self.id = id
        }
        
        if
            let nameAtValue = dic[DynamoDBField.name],
            case let .s(name) = nameAtValue
        {
            self.name = name
        }
        
        if
            let eNameAtValue = dic[DynamoDBField.eName],
            case let .s(eName) = eNameAtValue
        {
            self.eName = eName
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

extension PrefectureName {
    var dynamoDbDictionary: [String: DynamoDB.AttributeValue] {
        var dic: [String: DynamoDB.AttributeValue] = [:]
        
        if !id.isEmpty {
            dic[DynamoDBField.id] = .s(id)
        }
        if !name.isEmpty {
            dic[DynamoDBField.name] = .s(name)
        }
        if !eName.isEmpty {
            dic[DynamoDBField.eName] = .s(eName)
        }
        
        return dic
    }
}

extension PrefectureName {
    static var attributeDefinitions: [DynamoDB.AttributeDefinition] {
        [
            .init(attributeName: DynamoDBField.id, attributeType: .s),
        ]
    }
    
    static var keySchema: [DynamoDB.KeySchemaElement] {
        [
            .init(attributeName: DynamoDBField.id, keyType: .hash),
        ]
    }
}

let prefectureNames: [String] = [
    "北海道", "青森", "岩手", "宮城", "秋田", "山形", "福島", "茨城", "栃木", "群馬", "埼玉", "千葉", "東京",
    "神奈川", "新潟", "富山", "石川", "福井", "山梨", "長野", "岐阜", "静岡", "愛知", "三重", "滋賀", "京都",
    "大阪", "兵庫", "奈良", "和歌山", "鳥取", "島根", "岡山", "広島", "山口", "徳島", "香川", "愛媛", "高知",
    "福岡", "佐賀", "長崎", "熊本", "大分", "宮崎", "鹿児島", "沖縄"
]
