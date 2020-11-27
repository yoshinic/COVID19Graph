import Foundation
import NIO
import SotoDynamoDB
import AsyncKit

struct PrefectureController: DynamoDBController {
    typealias Model = Prefecture
    
    let db: DynamoDB
    let prefectureNameController: PrefectureNameController
    
    init(db: DynamoDB) {
        self.db = db
        self.prefectureNameController = .init(db: db)
    }
    
    func get(
        _ date: String,
        _ prefectureNameID: String
    ) -> EventLoopFuture<Model> {
        get(
            .init(
                key: [
                    Model.DynamoDBField.date: .s(date),
                    Model.DynamoDBField.prefectureNameID: .s(prefectureNameID)
                ],
                tableName: Model.tableName
            )
        )
    }
    
    func create(
        date: String,
        prefectureNameID: String,
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
                date: date,
                prefectureNameID: prefectureNameID,
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
        date: String,
        prefectureNameID: String,
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
                Model.DynamoDBField.date: .s(date),
                Model.DynamoDBField.prefectureNameID: .s(prefectureNameID)
            ],
            returnValues: .allNew,
            tableName: Model.tableName,
            updateExpression: """
                SET \
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
        
        return db.updateItem(input).flatMap { _ in self.get(date, prefectureNameID) }
    }
    
    func delete(
        _ date: String,
        _ prefectureNameID: String
    ) -> EventLoopFuture<Void> {
        db
            .deleteItem(
                .init(
                    key: [
                        Model.DynamoDBField.date: .s(date),
                        Model.DynamoDBField.prefectureNameID: .s(prefectureNameID)
                    ],
                    tableName: Model.tableName
                )
            )
            .map { _ in }
    }
}

// 新規 or 更新を判断してから保存
extension PrefectureController {
    func add(
        date: String,
        prefectureNameID: String,
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
                        Model.DynamoDBField.date: .s(date),
                        Model.DynamoDBField.prefectureNameID: .s(prefectureNameID)
                    ],
                    tableName: Model.tableName
                )
            )
            .flatMap { output in
                if let _ = output.item {
                    return update(
                        date: date,
                        prefectureNameID: prefectureNameID,
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
                        date: date,
                        prefectureNameID: prefectureNameID,
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

extension PrefectureController {
    func add(_ a: [String]) -> EventLoopFuture<Prefecture> {
        prefectureNameController
            .add(name: a[3], eName: a[4])
            .flatMap { prefectureName in
                add(
                    date: "\(a[0])-\(a[1])-\(a[2])",
                    prefectureNameID: prefectureName.id,
                    positive: a[5],
                    peopleTested: a[6],
                    hospitalized: a[7],
                    serious: a[8],
                    discharged: a[9],
                    deaths: a[10],
                    effectiveReproductionNumber: a[11]
                )
            }
    }
}
