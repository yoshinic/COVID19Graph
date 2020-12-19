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
                    month: "\(month)",
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

fileprivate extension Calendar {
    static let `default`: Calendar = {
        var calendar: Calendar = .init(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        calendar.locale = .current
        return calendar
    }()
    
    func isLast(_ day: Int, ofThe ym: (year: Int, month: Int)) -> Bool {
        guard
            let current = self.date(from: .init(year: ym.year, month: ym.month, day: day)),
            let tomorrow = self.date(byAdding: .day, value: 1, to: current),
            let tomorrowMonth = self.dateComponents([.month], from: tomorrow).month,
            ym.month == tomorrowMonth - 1
        else { return false }
        return true
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
