import Foundation
import NIO
import SotoDynamoDB
import AsyncKit

struct MPrefectureController: DynamoDBController {
    typealias Model = MPrefecture
    
    let db: DynamoDB
    
    init(db: DynamoDB) {
        self.db = db
    }
    
    func get(
        _ month: String,
        _ dayOfTheWeek: String
    ) -> EventLoopFuture<Model> {
        get(
            .init(
                key: [
                    Model.DynamoDBField.month: .s(month),
                    Model.DynamoDBField.dayOfTheWeek: .s(dayOfTheWeek)
                ],
                tableName: Model.tableName
            )
        )
    }
    
    func create(
        month: String,
        dayOfTheWeek: String,
        prefectureName: String,
        positive: String,
        peopleTested: String,
        hospitalized: String,
        serious: String,
        discharged: String,
        deaths: String,
        effectiveReproductionNumber: String
    ) -> EventLoopFuture<Model> {
        create(
            .init(
                month: month,
                dayOfTheWeek: dayOfTheWeek,
                prefectureName: prefectureName,
                positive: positive,
                peopleTested: peopleTested,
                hospitalized: hospitalized,
                serious: serious,
                discharged: discharged,
                deaths: deaths,
                effectiveReproductionNumber: effectiveReproductionNumber
            )
        )
    }
    
    func update(
        month: String,
        dayOfTheWeek: String,
        prefectureName: String,
        positive: String,
        peopleTested: String,
        hospitalized: String,
        serious: String,
        discharged: String,
        deaths: String,
        effectiveReproductionNumber: String
    ) -> EventLoopFuture<Model> {
        let input = DynamoDB.UpdateItemInput(
            expressionAttributeNames: [
                "#prefectureName": Model.DynamoDBField.prefectureName,
                "#positive": Model.DynamoDBField.positive,
                "#peopleTested": Model.DynamoDBField.peopleTested,
                "#hospitalized": Model.DynamoDBField.hospitalized,
                "#serious": Model.DynamoDBField.serious,
                "#discharged": Model.DynamoDBField.discharged,
                "#deaths": Model.DynamoDBField.deaths,
                "#effectiveReproductionNumber": Model.DynamoDBField.effectiveReproductionNumber,
                "#updatedAt": Model.DynamoDBField.updatedAt
            ],
            expressionAttributeValues: [
                ":prefectureName": .s(prefectureName),
                ":positive": .s(positive),
                ":peopleTested": .s(peopleTested),
                ":hospitalized": .s(hospitalized),
                ":serious": .s(serious),
                ":discharged": .s(discharged),
                ":deaths": .s(deaths),
                ":effectiveReproductionNumber": .s(effectiveReproductionNumber),
                ":updatedAt": .s(Date().iso8601)
            ],
            key: [
                Model.DynamoDBField.month: .s(month),
                Model.DynamoDBField.dayOfTheWeek: .s(dayOfTheWeek)
            ],
            returnValues: .allNew,
            tableName: Model.tableName,
            updateExpression: """
                SET \
                #prefectureName = :prefectureName, \
                #positive = :positive, \
                #peopleTested = :peopleTested, \
                #hospitalized = :hospitalized, \
                #serious = :serious, \
                #discharged = :discharged, \
                #deaths = :deaths, \
                #effectiveReproductionNumber = :effectiveReproductionNumber, \
                #updatedAt = :updatedAt
            """
        )
        
        return db.updateItem(input).flatMap { _ in self.get(month, dayOfTheWeek) }
    }
    
    func delete(
        _ month: String,
        _ dayOfTheWeek: String
    ) -> EventLoopFuture<Void> {
        db
            .deleteItem(
                .init(
                    key: [
                        Model.DynamoDBField.month: .s(month),
                        Model.DynamoDBField.dayOfTheWeek: .s(dayOfTheWeek)
                    ],
                    tableName: Model.tableName
                )
            )
            .map { _ in }
    }
}

// 新規 or 更新を判断してから保存
extension MPrefectureController {
    func add(
        month: String,
        dayOfTheWeek: String,
        prefectureName: String,
        positive: String,
        peopleTested: String,
        hospitalized: String,
        serious: String,
        discharged: String,
        deaths: String,
        effectiveReproductionNumber: String
    ) -> EventLoopFuture<Model> {
        db
            .getItem(
                .init(
                    key: [
                        Model.DynamoDBField.month: .s(month),
                        Model.DynamoDBField.dayOfTheWeek: .s(dayOfTheWeek)
                    ],
                    tableName: Model.tableName
                )
            )
            .flatMap { output in
                if let _ = output.item {
                    return update(
                        month: month,
                        dayOfTheWeek: dayOfTheWeek,
                        prefectureName: prefectureName,
                        positive: positive,
                        peopleTested: peopleTested,
                        hospitalized: hospitalized,
                        serious: serious,
                        discharged: discharged,
                        deaths: deaths,
                        effectiveReproductionNumber: effectiveReproductionNumber
                    )
                } else {
                    return create(
                        month: month,
                        dayOfTheWeek: dayOfTheWeek,
                        prefectureName: prefectureName,
                        positive: positive,
                        peopleTested: peopleTested,
                        hospitalized: hospitalized,
                        serious: serious,
                        discharged: discharged,
                        deaths: deaths,
                        effectiveReproductionNumber: effectiveReproductionNumber
                    )
                }
            }
    }
}
