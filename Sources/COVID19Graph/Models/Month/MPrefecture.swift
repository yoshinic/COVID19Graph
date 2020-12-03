import Foundation
import SotoDynamoDB

struct MPrefecture: DynamoDBModelWithTable {
    
    static let tableName: String = "m_prefectures"
    
    var month: String = ""
    var dayOfTheWeek: String = ""
    var prefectureName: String = ""
    var positive: String = ""
    var peopleTested: String = ""
    var hospitalized: String = ""
    var serious: String = ""
    var discharged: String = ""
    var deaths: String = ""
    var effectiveReproductionNumber: String = ""
    
    var createdAt: Date?
    var updatedAt: Date?
    
    struct DynamoDBField {
        static let month = "month"
        static let dayOfTheWeek = "day_of_the_week"
        static let prefectureName = "prefecture_name"
        static let positive = "positive"
        static let peopleTested = "people_tested"
        static let hospitalized = "hospitalized"
        static let serious = "serious"
        static let discharged = "discharged"
        static let deaths = "deaths"
        static let effectiveReproductionNumber = "ern"
        
        static let createdAt = "created_at"
        static let updatedAt = "updated_at"
    }
}

extension MPrefecture {
    init(dic: [String: DynamoDB.AttributeValue]) throws {
        if
            let monthAtValue = dic[DynamoDBField.month],
            case let .s(month) = monthAtValue,
            !month.isEmpty
        {
            self.month = month
        }
        
        if
            let dayOfTheWeekAtValue = dic[DynamoDBField.dayOfTheWeek],
            case let .s(dayOfTheWeek) = dayOfTheWeekAtValue,
            !dayOfTheWeek.isEmpty
        {
            self.dayOfTheWeek = dayOfTheWeek
        }
        
        if
            let prefectureNameAtValue = dic[DynamoDBField.prefectureName],
            case let .s(prefectureName) = prefectureNameAtValue,
            !prefectureName.isEmpty
        {
            self.prefectureName = prefectureName
        }
        
        if
            let positiveAtValue = dic[DynamoDBField.positive],
            case let .s(positive) = positiveAtValue,
            !positive.isEmpty
        {
            
            self.positive = positive
        }
        
        if
            let peopleTestedAtValue = dic[DynamoDBField.peopleTested],
            case let .s(peopleTested) = peopleTestedAtValue,
            !peopleTested.isEmpty
        {
            self.peopleTested = peopleTested
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
            let dischargedAtValue = dic[DynamoDBField.discharged],
            case let .s(discharged) = dischargedAtValue,
            !discharged.isEmpty
        {
            self.discharged = discharged
        }
        
        if
            let deathsAtValue = dic[DynamoDBField.deaths],
            case let .s(deaths) = deathsAtValue,
            !deaths.isEmpty
        {
            self.deaths = deaths
        }
        
        if
            let effectiveReproductionNumberAtValue = dic[DynamoDBField.effectiveReproductionNumber],
            case let .s(effectiveReproductionNumber) = effectiveReproductionNumberAtValue,
            !effectiveReproductionNumber.isEmpty
        {
            self.effectiveReproductionNumber = effectiveReproductionNumber
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

extension MPrefecture {
    var dynamoDbDictionary: [String: DynamoDB.AttributeValue] {
        var dic: [String: DynamoDB.AttributeValue] = [:]
        
        if !month.isEmpty {
            dic[DynamoDBField.month] = .s(month)
        }
        if !dayOfTheWeek.isEmpty {
            dic[DynamoDBField.dayOfTheWeek] = .s(dayOfTheWeek)
        }
        if !prefectureName.isEmpty {
            dic[DynamoDBField.prefectureName] = .s(prefectureName)
        }
        if !positive.isEmpty {
            dic[DynamoDBField.positive] = .s(positive)
        }
        if !peopleTested.isEmpty {
            dic[DynamoDBField.peopleTested] = .s(peopleTested)
        }
        if !hospitalized.isEmpty {
            dic[DynamoDBField.hospitalized] = .s(hospitalized)
        }
        if !serious.isEmpty {
            dic[DynamoDBField.serious] = .s(serious)
        }
        if !discharged.isEmpty {
            dic[DynamoDBField.discharged] = .s(discharged)
        }
        if !deaths.isEmpty {
            dic[DynamoDBField.deaths] = .s(deaths)
        }
        if !effectiveReproductionNumber.isEmpty {
            dic[DynamoDBField.effectiveReproductionNumber] = .s(effectiveReproductionNumber)
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

extension MPrefecture {
    static var attributeDefinitions: [DynamoDB.AttributeDefinition] {
        [
            .init(attributeName: DynamoDBField.month, attributeType: .s),
            .init(attributeName: DynamoDBField.dayOfTheWeek, attributeType: .s),
        ]
    }
    
    static var keySchema: [DynamoDB.KeySchemaElement] {
        [
            .init(attributeName: DynamoDBField.month, keyType: .hash),
            .init(attributeName: DynamoDBField.dayOfTheWeek, keyType: .range),
        ]
    }
}
