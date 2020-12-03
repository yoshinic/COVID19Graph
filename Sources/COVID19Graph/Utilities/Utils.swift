import Foundation

public struct Utils {
    public static let iso8601Formatter: DateFormatter = {
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

extension String {
    func fill(_ digit: Int, character c: Character = "0") -> String {
        return Int(self).fill(digit, character: c)
    }
    
    var filledDateString: String {
        self.components(separatedBy: "-").enumerated().map {
            $0.offset == 1 || $0.offset == 2 ? $0.element.fill(2) : $0.element
        }
        .joined(separator: "-")
    }
}

extension Int {
    func fill(_ digit: Int, character c: Character = "0") -> String {
        return "\((0..<digit).reduce(into: ""){r, _ in r += String(c)})\(self)".suffix(digit).description
    }
}

extension Optional where Wrapped == Int {
    func fill(_ digit: Int, character c: Character = "0", fillEvenSoNil b: Bool = true) -> String {
        guard digit > 0 else { return "" }
        let i: Wrapped
        if self == nil && b {
            i = 0
        } else if self == nil && b == false {
            return ""
        } else {
            i = self!
        }
        return i.fill(digit, character: c)
    }
}

extension Calendar {
    static let `default`: Calendar = {
        var calendar: Calendar = .init(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        calendar.locale = .current
        return calendar
    }()
}

extension DateFormatter {
    static let `default`: DateFormatter = {
        let formatter: DateFormatter = DateFormatter()
        formatter.calendar = .default
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter
    }()
}

extension Date {
    var toString: String {
        return DateFormatter.default.string(from: self)
    }
}

extension String {
    var toDate: Date? {
        let a = self.components(separatedBy: "-")
        guard a.count == 3, let y = Int(a[0]), let m = Int(a[1]), let d = Int(a[2]) else {
            return nil
        }
        return Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: y, month: m, day: d, hour: 0, minute: 0, second: 0))!
    }
}
