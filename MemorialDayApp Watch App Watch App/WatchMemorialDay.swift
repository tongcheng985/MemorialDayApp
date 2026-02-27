import Foundation

struct WatchMemorialDay: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let date: Date
    let repeatType: RepeatType
    let repeatInterval: Int
    let isPinned: Bool
    let categoryId: UUID?
    
    init(id: UUID, title: String, date: Date, repeatType: RepeatType, repeatInterval: Int, isPinned: Bool, categoryId: UUID?) {
        self.id = id
        self.title = title
        self.date = date
        self.repeatType = repeatType
        self.repeatInterval = repeatInterval
        self.isPinned = isPinned
        self.categoryId = categoryId
    }
    
    enum RepeatType: String, CaseIterable, Codable {
        case none = "不重复"
        case daily = "每天"
        case weekly = "每周"
        case monthly = "每月"
        case yearly = "每年"
        
        var localizedName: String {
            switch self {
            case .none:
                return WatchLanguageManager.shared.localizedString(for: "Never repeat")
            case .daily:
                return WatchLanguageManager.shared.localizedString(for: "Every Day")
            case .weekly:
                return WatchLanguageManager.shared.localizedString(for: "Every Week")
            case .monthly:
                return WatchLanguageManager.shared.localizedString(for: "Every Month")
            case .yearly:
                return WatchLanguageManager.shared.localizedString(for: "Every Year")
            }
        }
    }
    
    var daysFromNow: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        var targetDate = date
        
        if repeatType != .none && targetDate < now {
            let components = calendar.dateComponents([.year, .month, .day], from: targetDate)
            
            switch repeatType {
            case .yearly:
                let currentYear = calendar.component(.year, from: now)
                var nextYear = currentYear
                
                var nextDate = calendar.date(from: DateComponents(year: nextYear, month: components.month, day: components.day))!
                
                if nextDate <= now {
                    nextYear += 1
                    nextDate = calendar.date(from: DateComponents(year: nextYear, month: components.month, day: components.day))!
                }
                
                targetDate = nextDate
                
            case .monthly:
                let currentComponents = calendar.dateComponents([.year, .month], from: now)
                var nextMonth = currentComponents.month!
                var nextYear = currentComponents.year!
                
                var nextDate = calendar.date(from: DateComponents(year: nextYear, month: nextMonth, day: components.day))
                
                while nextDate == nil || nextDate! <= now {
                    nextMonth += 1
                    if nextMonth > 12 {
                        nextMonth = 1
                        nextYear += 1
                    }
                    nextDate = calendar.date(from: DateComponents(year: nextYear, month: nextMonth, day: components.day))
                }
                
                targetDate = nextDate!
                
            case .weekly:
                let weekday = calendar.component(.weekday, from: targetDate)
                let nextWeekDate = calendar.nextDate(after: now, matching: DateComponents(weekday: weekday), matchingPolicy: .nextTime)
                targetDate = nextWeekDate ?? targetDate
                
            case .daily:
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
                let tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                targetDate = calendar.date(from: DateComponents(year: tomorrowComponents.year, month: tomorrowComponents.month, day: tomorrowComponents.day, hour: components.hour, minute: components.minute))!
                
            case .none:
                break
            }
        }
        
        // 使用 startOfDay 计算，与手机端保持一致
        let startOfTarget = calendar.startOfDay(for: targetDate)
        let days = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget).day ?? 0
        
        return days
    }
}

class WatchLanguageManager {
    static let shared = WatchLanguageManager()
    private init() {}
    
    func localizedString(for key: String) -> String {
        switch key {
        case "Never repeat":
            return NSLocalizedString("Never repeat", comment: "")
        case "Every Day":
            return NSLocalizedString("Every Day", comment: "")
        case "Every Week":
            return NSLocalizedString("Every Week", comment: "")
        case "Every Month":
            return NSLocalizedString("Every Month", comment: "")
        case "Every Year":
            return NSLocalizedString("Every Year", comment: "")
        case "Day":
            return NSLocalizedString("Day", comment: "")
        case "Days":
            return NSLocalizedString("Days", comment: "")
        case "Today":
            return NSLocalizedString("Today", comment: "")
        default:
            return key
        }
    }
}