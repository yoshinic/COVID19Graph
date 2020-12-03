import Foundation
import NIO
import SotoDynamoDB
import AsyncKit

struct PCRCaseController: DownloadController {
    typealias Model = PCRCase
    
    let db: DynamoDB
    
    init(db: DynamoDB) {
        self.db = db
    }
    
    func get(date: String) -> EventLoopFuture<Model> {
        get(
            .init(
                key: [Model.DynamoDBField.date: .s(date)],
                tableName: Model.tableName
            )
        )
    }
    
    func create(
        date: String,
        national: String,
        quarantine: String,
        local: String,
        `private`: String,
        university: String,
        medical: String
    ) -> EventLoopFuture<Model> {
        create(
            .init(
                date: date,
                national: national,
                quarantine: quarantine,
                local: local,
                private: `private`,
                university: university,
                medical: medical
            )
        )
    }
    
    func update(
        date: String,
        national: String,
        quarantine: String,
        local: String,
        `private`: String,
        university: String,
        medical: String
    ) -> EventLoopFuture<Model> {
        let input = DynamoDB.UpdateItemInput(
            expressionAttributeNames: [
                "#national": Model.DynamoDBField.national,
                "#quarantine": Model.DynamoDBField.quarantine,
                "#local": Model.DynamoDBField.local,
                "#private": Model.DynamoDBField.`private`,
                "#university": Model.DynamoDBField.university,
                "#medical": Model.DynamoDBField.medical,
                "#updatedAt": Model.DynamoDBField.updatedAt
            ],
            expressionAttributeValues: [
                ":national": .s(national),
                ":quarantine": .s(quarantine),
                ":local": .s(local),
                ":private": .s(`private`),
                ":university": .s(university),
                ":medical": .s(medical),
                ":updatedAt": .s(Date().iso8601)
            ],
            key: [Model.DynamoDBField.date: .s(date)],
            returnValues: .allNew,
            tableName: Model.tableName,
            updateExpression: """
                SET \
                #national = :national, \
                #quarantine = :quarantine, \
                #local = :local, \
                #private = :private, \
                #university = :university, \
                #medical = :medical, \
                #updatedAt = :updatedAt
            """
        )
        
        return db.updateItem(input).flatMap { _ in self.get(date: date) }
    }
    
    func delete(_ date: String) -> EventLoopFuture<Void> {
        db
            .deleteItem(
                .init(
                    key: [Model.DynamoDBField.date: .s(date)],
                    tableName: Model.tableName
                )
            )
            .map { _ in }
    }
}

// 新規 or 更新を判断してから保存
extension PCRCaseController {
    func add(
        date: String,
        national: String,
        quarantine: String,
        local: String,
        `private`: String,
        university: String,
        medical: String
    ) -> EventLoopFuture<Model> {
        db
            .getItem(
                .init(
                    key: [Model.DynamoDBField.date: .s(date)],
                    tableName: Model.tableName
                )
            )
            .flatMap { output in
                if let _ = output.item {
                    return update(
                        date: date,
                        national: national,
                        quarantine: quarantine,
                        local: local,
                        private: `private`,
                        university: university,
                        medical: medical
                    )
                } else {
                    return create(
                        date: date,
                        national: national,
                        quarantine: quarantine,
                        local: local,
                        private: `private`,
                        university: university,
                        medical: medical
                    )
                }
            }
    }
}

extension PCRCaseController {
    func add(_ a: [String]) -> EventLoopFuture<PCRCase> {
        add(
            date: a[0].replacingOccurrences(of: "/", with: "-"),
            national: a[1],
            quarantine: a[2],
            local: a[3],
            private: a[4],
            university: a[5],
            medical: a[6]
        )
    }
}

extension PCRCaseController {
    func batch(_ a: [[String]]) -> EventLoopFuture<[DynamoDB.BatchWriteItemOutput]> {
        batch(
            a.map {
                Model(
                    date: $0[0].replacingOccurrences(of: "/", with: "-"),
                    national: $0[1],
                    quarantine: $0[2],
                    local: $0[3],
                    private: $0[4],
                    university: $0[5],
                    medical: $0[6]
                )
            }
        )
    }
}
