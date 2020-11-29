import Foundation
import NIO
import SotoDynamoDB
import AsyncKit

struct PrefectureController: DynamoDBController {
    typealias Model = Prefecture
    
    let db: DynamoDB
    
    init(db: DynamoDB) {
        self.db = db
    }
    
    func get(
        _ date: String,
        _ prefectureNameJ: String
    ) -> EventLoopFuture<Model> {
        get(
            .init(
                key: [
                    Model.DynamoDBField.date: .s(date),
                    Model.DynamoDBField.prefectureNameJ: .s(prefectureNameJ)
                ],
                tableName: Model.tableName
            )
        )
    }
    
    func create(
        date: String,
        prefectureNameJ: String,
        prefectureNameE: String,
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
                prefectureNameJ: prefectureNameJ,
                prefectureNameE: prefectureNameE,
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
        prefectureNameJ: String,
        prefectureNameE: String,
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
                "#prefectureNameE": Model.DynamoDBField.prefectureNameE,
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
                ":prefectureNameE": .s(prefectureNameE),
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
                Model.DynamoDBField.prefectureNameJ: .s(prefectureNameJ)
            ],
            returnValues: .allNew,
            tableName: Model.tableName,
            updateExpression: """
                SET \
                #prefectureNameE = :prefectureNameE, \
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
        
        return db.updateItem(input).flatMap { _ in self.get(date, prefectureNameJ) }
    }
    
    func delete(
        _ date: String,
        _ prefectureNameJ: String
    ) -> EventLoopFuture<Void> {
        db
            .deleteItem(
                .init(
                    key: [
                        Model.DynamoDBField.date: .s(date),
                        Model.DynamoDBField.prefectureNameJ: .s(prefectureNameJ)
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
        prefectureNameJ: String,
        prefectureNameE: String,
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
                        Model.DynamoDBField.prefectureNameJ: .s(prefectureNameJ)
                    ],
                    tableName: Model.tableName
                )
            )
            .flatMap { output in
                if let _ = output.item {
                    return update(
                        date: date,
                        prefectureNameJ: prefectureNameJ,
                        prefectureNameE: prefectureNameE,
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
                        prefectureNameJ: prefectureNameJ,
                        prefectureNameE: prefectureNameE,
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
        add(
            date: "\(a[0])-\(a[1])-\(a[2])",
            prefectureNameJ: a[3],
            prefectureNameE: a[4],
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

extension PrefectureController {
    func batch(_ a: [[String]]) -> EventLoopFuture<[DynamoDB.BatchWriteItemOutput]> {
        batch(
            a.map {
                Model(
                    date: "\($0[0])-\($0[1])-\($0[2])",
                    prefectureNameJ: $0[3],
                    prefectureNameE: $0[4],
                    positive: $0[5],
                    peopleTested: $0[6],
                    hospitalized: $0[7],
                    serious: $0[8],
                    discharged: $0[9],
                    deaths: $0[10],
                    effectiveReproductionNumber: $0[11]
                )
            },
            batchMaximumValue: batchMaximumAllowedValue,
            waittime: 1
        )
    }
}
