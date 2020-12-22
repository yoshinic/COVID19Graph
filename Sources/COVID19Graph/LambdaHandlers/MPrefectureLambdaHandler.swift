import Foundation
import AWSLambdaRuntime
import AWSLambdaEvents
import SotoCore

struct MPrefectureLambdaHandler: DynamoDBLambdaHandler {
    typealias In = AWSLambdaEvents.DynamoDB.Event
    typealias Out = Output
    
    let prefectureController: PrefectureController
    let mprefectureController: MPrefectureController
    
    init(context: Lambda.InitializationContext) {
        let db = Self.createDynamoDBClient(on: context.eventLoop)
        self.prefectureController = .init(db: db)
        self.mprefectureController = .init(db: db)
    }
    
    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        mprefectureController
            .createTable(on: context.eventLoop)
            .flatMap { _ in prefectureController.all() }
            .mapEachCompact {
                guard let date = $0.date.toDate else { return nil }
                let c = Calendar.default.dateComponents([.year, .month, .day], from: date)
                guard
                    let year = c.year,
                    let month = c.month,
                    let day = c.day,
                    
                    // このファイルは累計データなので、月日が月末のデータのみ取得する
                    Calendar.default.isLast(day, ofThe: (year, month))
                
                else { return nil }
                return MPrefecture(
                    ym: "\(year)\(month.fill(2))",
                    prefectureName: $0.prefectureNameJ,
                    positive: $0.positive,
                    peopleTested: $0.peopleTested,
                    hospitalized: $0.hospitalized,
                    serious: $0.serious,
                    discharged: $0.discharged,
                    deaths: $0.deaths,
                    effectiveReproductionNumber: $0.effectiveReproductionNumber
                )
            }
            .flatMap { mprefectureController.batch($0) }
            .map { .init(result: "\($0)") }
    }
}

fileprivate extension String {
    var toDate: Date? {
        let a = self.components(separatedBy: "-")
        guard a.count == 3, let y = Int(a[0]), let m = Int(a[1]), let d = Int(a[2]) else {
            return nil
        }
        return Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: y, month: m, day: d, hour: 0, minute: 0, second: 0))!
    }
}

fileprivate extension Int {
    func fill(_ digit: Int, character c: Character = "0") -> String {
        return "\((0..<digit).reduce(into: ""){r, _ in r += String(c)})\(self)".suffix(digit).description
    }
}
