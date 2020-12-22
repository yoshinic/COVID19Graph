import Foundation

struct Utils {
    static let iso8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

extension Date {
    var iso8601: String {
        Utils.iso8601Formatter.string(from: self)
    }
}

extension Calendar {
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
