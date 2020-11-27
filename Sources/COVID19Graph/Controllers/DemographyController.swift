import Foundation
import NIO
import SotoDynamoDB
import AsyncKit

struct DemographyController: DynamoDBController {
    typealias Model = Demography
    
    let db: DynamoDB
    
    init(db: DynamoDB) {
        self.db = db
    }
    
    func get(
        _ date: String,
        _ ageGroup: String
    ) -> EventLoopFuture<Model> {
        get(
            .init(
                key: [
                    Model.DynamoDBField.date: .s(date),
                    Model.DynamoDBField.ageGroup: .s(ageGroup)
                ],
                tableName: Model.tableName
            )
        )
    }
    
    func create(
        date: String,
        ageGroup: String,
        positive: String,
        hospitalized: String,
        serious: String,
        death: String
    ) -> EventLoopFuture<Model> {
        create(
            .init(
                date: date,
                ageGroup: ageGroup,
                positive: positive,
                hospitalized: hospitalized,
                serious: serious,
                death: death
            )
        )
    }
    
    func update(
        date: String,
        ageGroup: String,
        positive: String,
        hospitalized: String,
        serious: String,
        death: String
    ) -> EventLoopFuture<Model> {
        let input = DynamoDB.UpdateItemInput(
            expressionAttributeNames: [
                "#positive": Model.DynamoDBField.positive,
                "#hospitalized": Model.DynamoDBField.hospitalized,
                "#serious": Model.DynamoDBField.serious,
                "#death": Model.DynamoDBField.death,
                "#updatedAt": Model.DynamoDBField.updatedAt
            ],
            expressionAttributeValues: [
                ":positive": .s(positive),
                ":hospitalized": .s(hospitalized),
                ":serious": .s(serious),
                ":death": .s(death),
                ":updatedAt": .s(Date().iso8601)
            ],
            key: [
                Model.DynamoDBField.date: .s(date),
                Model.DynamoDBField.ageGroup: .s(ageGroup)
            ],
            returnValues: .allNew,
            tableName: Model.tableName,
            updateExpression: """
                SET \
                #positive = :positive, \
                #hospitalized = :hospitalized, \
                #serious = :serious, \
                #death = :death, \
                #updatedAt = :updatedAt
            """
        )
        
        return db.updateItem(input).flatMap { _ in self.get(date, ageGroup) }
    }
    
    func delete(
        _ date: String,
        _ ageGroup: String
    ) -> EventLoopFuture<Void> {
        db
            .deleteItem(
                .init(
                    key: [
                        Model.DynamoDBField.date: .s(date),
                        Model.DynamoDBField.ageGroup: .s(ageGroup)
                    ],
                    tableName: Model.tableName
                )
            )
            .map { _ in }
    }
}

// 新規 or 更新を判断してから保存
extension DemographyController {
    func add(
        date: String,
        ageGroup: String,
        positive: String,
        hospitalized: String,
        serious: String,
        death: String
    ) -> EventLoopFuture<Model> {
        db
            .getItem(
                .init(
                    key: [
                        Model.DynamoDBField.date: .s(date),
                        Model.DynamoDBField.ageGroup: .s(ageGroup)
                    ],
                    tableName: Model.tableName
                )
            )
            .flatMap { output in
                if let _ = output.item {
                    return update(
                        date: date,
                        ageGroup: ageGroup,
                        positive: positive,
                        hospitalized: hospitalized,
                        serious: serious,
                        death: death
                    )
                } else {
                    return create(
                        date: date,
                        ageGroup: ageGroup,
                        positive: positive,
                        hospitalized: hospitalized,
                        serious: serious,
                        death: death
                    )
                }
            }
    }
}

extension DemographyController {
    func add(_ a: [String]) -> EventLoopFuture<Demography> {
        add(
            date: "\(a[0])-\(a[1])-\(a[2])",
            ageGroup: a[3],
            positive: a[4],
            hospitalized: a[5],
            serious: a[6],
            death: a[7]
        )
    }
}
