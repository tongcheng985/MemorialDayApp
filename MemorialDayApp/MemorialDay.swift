import Foundation

enum RepeatType: String, Codable, Equatable {
    case none = "不重复"
    case daily = "每天"
    case weekly = "每周"
    case monthly = "每月"
    case yearly = "每年"
    case custom = "自定义"
}

struct MemorialDay: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var date: Date
    var repeatType: RepeatType = .none
    var repeatInterval: Int = 1 // 重复间隔，例如每2天、每3周等
    var isPinned: Bool = false
    var categoryId: UUID? = nil // 分类ID
    var isNotificationEnabled: Bool = false // 通知开关状态
    
    // 定义CodingKeys明确要序列化的字段
    enum CodingKeys: String, CodingKey {
        case id, title, dateValue = "date", repeatType, repeatInterval, isPinned, categoryId, isNotificationEnabled
    }
    
    // 共享的日期格式器，避免频繁创建
    private static let mediumDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
    
    private static let mediumDateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
    
    // 注意：缓存管理已移至MemorialDayStore统一处理
    
    var isYearly: Bool { // 保留兼容性
        return repeatType == .yearly
    }
    
    // 手动公开init，避免私有属性导致的init歧义
    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        repeatType: RepeatType = .none,
        repeatInterval: Int = 1,
        isPinned: Bool = false,
        categoryId: UUID? = nil,
        isNotificationEnabled: Bool = false
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.repeatType = repeatType
        self.repeatInterval = repeatInterval
        self.isPinned = isPinned
        self.categoryId = categoryId
        self.isNotificationEnabled = isNotificationEnabled
    }
    
    // 自定义编码器实现
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .dateValue)
        try container.encode(repeatType, forKey: .repeatType)
        try container.encode(max(repeatInterval, 1), forKey: .repeatInterval)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encodeIfPresent(categoryId, forKey: .categoryId)
        try container.encode(isNotificationEnabled, forKey: .isNotificationEnabled)
    }
    
    // 自定义解码器实现
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        title = (try? container.decode(String.self, forKey: .title)) ?? "未命名纪念日"
        
        if let decodedDate = try? container.decode(Date.self, forKey: .dateValue) {
            date = decodedDate
        } else {
            date = Date()
        }
        
        repeatType = (try? container.decode(RepeatType.self, forKey: .repeatType)) ?? .none
        repeatInterval = max((try? container.decode(Int.self, forKey: .repeatInterval)) ?? 1, 1)
        isPinned = (try? container.decode(Bool.self, forKey: .isPinned)) ?? false
        categoryId = try? container.decode(UUID.self, forKey: .categoryId)
        isNotificationEnabled = (try? container.decode(Bool.self, forKey: .isNotificationEnabled)) ?? false
    }
    
    // 计算还有多少天（外部缓存管理）
    func daysRemaining() -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        // 对于重复纪念日，计算下一个纪念日
        let targetDate: Date
        if repeatType != .none {
            targetDate = calculateNextDate() ?? date
        } else {
            targetDate = date
        }
        
        let startOfTarget = calendar.startOfDay(for: targetDate)
        let days = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget).day ?? 0
        
        return days
    }
    
    // 获取下一个纪念日日期的描述
    func nextDateDescription() -> String {
        let calendar = Calendar.current
        
        if repeatType == .none {
            return Self.mediumDateFormatter.string(from: date)
        }
        
        guard let nextDate = calculateNextDate() else {
            return "计算错误"
        }
        
        let today = Date()
        let daysUntilNext = calendar.dateComponents([.day], from: today, to: nextDate).day ?? 0
        
        if daysUntilNext == 0 {
            return "今天"
        } else if daysUntilNext == 1 {
            return "明天"
        } else if daysUntilNext == -1 {
            return "昨天"
        } else if daysUntilNext > 0 {
            return "还有 \(daysUntilNext) 天"
        } else {
            return "已过期 \(abs(daysUntilNext)) 天"
        }
    }
    
    // 获取重复类型的描述文本
    static func repeatTypeDescription(type: RepeatType, interval: Int) -> String {
        switch type {
        case .none:
            return LanguageManager.shared.localizedString("No Repeat")
        case .daily:
            return interval == 1 ? LanguageManager.shared.localizedString("Daily") : "\(interval) \(LanguageManager.shared.localizedString("days"))"
        case .weekly:
            return interval == 1 ? LanguageManager.shared.localizedString("Weekly") : "\(interval) \(LanguageManager.shared.localizedString("weeks"))"
        case .monthly:
            return interval == 1 ? LanguageManager.shared.localizedString("Monthly") : "\(interval) \(LanguageManager.shared.localizedString("months"))"
        case .yearly:
            return interval == 1 ? LanguageManager.shared.localizedString("Yearly") : "\(interval) \(LanguageManager.shared.localizedString("years"))"
        case .custom:
            return "\(interval) \(LanguageManager.shared.localizedString("days"))"
        }
    }
    
    func calculateNextDate() -> Date? {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now) // 使用今天的开始时间
        
        // 获取纪念日的月、日
        let originalDay = calendar.component(.day, from: date)
        let originalMonth = calendar.component(.month, from: date)
        let originalYear = calendar.component(.year, from: date)
        
        // 调试信息：如果是过去日期，记录调试信息
        if date < now {
            print("调试：计算过去日期的下次重复 - 原始:\(date), 今天:\(today), 重复:\(repeatType.rawValue), 间隔:\(repeatInterval)")
        }
        
        // 根据重复类型计算下一个纪念日
        switch repeatType {
        case .none:
            // 不重复，直接使用原始日期
            return date
        
        case .daily:
            // 每X天重复
            // 先计算从原始日期到今天的天数
            let daysSinceOriginal = max(0, calendar.dateComponents([.day], from: date, to: today).day ?? 0)
            
                    // 计算已经过去了多少个完整的周期
                    let completedCycles = daysSinceOriginal / repeatInterval
            
            // 计算下一个周期的日期
            let nextCycle = completedCycles + 1
            let daysToAdd = nextCycle * repeatInterval
                    
            // 从原始日期加上天数得到下一个纪念日
            return calendar.date(byAdding: .day, value: daysToAdd, to: date)
        
        case .weekly:
            // 每周重复
            let weeksSinceOriginal = max(0, calendar.dateComponents([.weekOfYear], from: date, to: today).weekOfYear ?? 0)
            let completedCycles = weeksSinceOriginal / repeatInterval
            let nextCycle = completedCycles + 1
            let weeksToAdd = nextCycle * repeatInterval
            return calendar.date(byAdding: .weekOfYear, value: weeksToAdd, to: date)
        
        case .monthly:
            // 每X月重复
            // 获取当前年月日
            let currentYear = calendar.component(.year, from: today)
            let currentMonth = calendar.component(.month, from: today)
            let currentDay = calendar.component(.day, from: today)
            
            // 计算从原始日期开始的月份差
            let monthDiff = (currentYear - originalYear) * 12 + (currentMonth - originalMonth)
            
            // 计算已经过去了多少个完整的周期
            let completedCycles = monthDiff / repeatInterval
            
            // 检查是否已经过了这个月的纪念日
            if originalDay >= currentDay && monthDiff % repeatInterval == 0 {
                // 这个月的纪念日还没到，直接使用今年当月的日期
                var components = DateComponents()
                components.year = currentYear
                components.month = currentMonth
                components.day = originalDay
                return calendar.date(from: components)
            } else {
                // 计算下一个周期
                let nextCycle = completedCycles + 1
                
                // 计算下一个周期的月份总数
                let totalMonthsToAdd = nextCycle * repeatInterval
                
                // 计算年份和月份
                let monthsFromOriginal = originalMonth + totalMonthsToAdd - 1
                let nextYear = originalYear + (monthsFromOriginal / 12)
                let nextMonth = (monthsFromOriginal % 12) + 1
                
                var components = DateComponents()
                components.year = nextYear
                components.month = nextMonth
                components.day = originalDay
                return calendar.date(from: components)
            }
            
        case .yearly:
            // 每X年重复
            let currentYear = calendar.component(.year, from: today)
            let currentMonth = calendar.component(.month, from: today)
            let currentDay = calendar.component(.day, from: today)
            let originalMonth = calendar.component(.month, from: date)
            let originalDay = calendar.component(.day, from: date)
            let originalYear = calendar.component(.year, from: date)

            // 1. 当前日期早于原始纪念日，直接返回原始纪念日
            if (currentYear < originalYear) ||
               (currentYear == originalYear && (currentMonth < originalMonth || (currentMonth == originalMonth && currentDay < originalDay))) {
                return date
            }

            // 2. 当前日期晚于等于原始纪念日，推算下一个周期
            var nextYear = originalYear
            while true {
                if nextYear > currentYear ||
                   (nextYear == currentYear && (originalMonth > currentMonth || (originalMonth == currentMonth && originalDay > currentDay))) {
                    break
                }
                nextYear += repeatInterval
            }
            var components = DateComponents()
            components.year = nextYear
            components.month = originalMonth
            components.day = originalDay
            return calendar.date(from: components)
        case .custom:
            // 自定义按天数重复
            let daysSinceOriginal = max(0, calendar.dateComponents([.day], from: date, to: today).day ?? 0)
            let completedCycles = daysSinceOriginal / repeatInterval
            let nextCycle = completedCycles + 1
            let daysToAdd = nextCycle * repeatInterval
            return calendar.date(byAdding: .day, value: daysToAdd, to: date)
        }
        
        return nil
    }
    
    // 缓存清除已移至MemorialDayStore统一管理
    mutating func clearCache() {
        // 保留此方法以兼容现有代码，但实际缓存在Store中管理
    }
    
    // 添加调试方法，打印日期计算的详细信息
    func debugDateCalculation() -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 获取基本信息
        let originalDay = calendar.component(.day, from: date)
        let originalMonth = calendar.component(.month, from: date)
        let originalYear = calendar.component(.year, from: date)
        let currentYear = calendar.component(.year, from: today)
        let currentMonth = calendar.component(.month, from: today)
        let currentDay = calendar.component(.day, from: today)
        
        var result = "原始日期: \(formatDate(date))\n"
        result += "今天: \(formatDate(today))\n"
        result += "原始日期: 年=\(originalYear), 月=\(originalMonth), 日=\(originalDay)\n"
        result += "当前日期: 年=\(currentYear), 月=\(currentMonth), 日=\(currentDay)\n"
        result += "重复类型: \(repeatType.rawValue), 间隔: \(repeatInterval)\n\n"
        
        // 计算下一个日期
        if let nextDate = calculateNextDate() {
            result += "计算的下一个日期: \(formatDate(nextDate))\n"
            
            // 计算天数差异
            let days = calendar.dateComponents([.day], from: today, to: nextDate).day ?? 0
            result += "距离下一个日期的天数: \(days)\n\n"
            
            // 对于年度重复，添加更多详细信息
            if repeatType == .yearly {
                let yearsSinceOriginal = currentYear - originalYear
                let completedCycles = yearsSinceOriginal / repeatInterval
                
                result += "年份差: \(yearsSinceOriginal)\n"
                result += "完成的周期数: \(completedCycles)\n"
                result += "是否为周期年份: \(yearsSinceOriginal % repeatInterval == 0 ? "是" : "否")\n\n"
                
                // 计算下一个周期年份
                let nextCycleYear: Int
                
                if yearsSinceOriginal % repeatInterval == 0 {
                    // 当前年份是周期年份
                    if originalMonth > currentMonth || (originalMonth == currentMonth && originalDay >= currentDay) {
                        nextCycleYear = currentYear
                        result += "当前年份是周期年份，且纪念日还未到，使用今年\n"
                    } else {
                        nextCycleYear = originalYear + (completedCycles + 1) * repeatInterval
                        result += "当前年份是周期年份，但纪念日已过，使用下一个周期年份\n"
                    }
                } else {
                    nextCycleYear = originalYear + (completedCycles + 1) * repeatInterval
                    result += "当前年份不是周期年份，使用下一个周期年份\n"
                }
                
                result += "下一个周期年份: \(nextCycleYear)\n"
                
                // 计算具体日期
                var components = DateComponents()
                components.year = nextCycleYear
                components.month = originalMonth
                components.day = originalDay
                
                if let calculatedDate = calendar.date(from: components) {
                    result += "计算的具体日期: \(formatDate(calculatedDate))\n"
                    
                    // 再次计算天数差异，确认结果
                    let confirmedDays = calendar.dateComponents([.day], from: today, to: calculatedDate).day ?? 0
                    result += "确认的天数差异: \(confirmedDays)\n"
                }
            }
        } else {
            result += "无法计算下一个日期\n"
        }
        
        return result
    }
    
    // 辅助方法，格式化日期
    private func formatDate(_ date: Date) -> String {
        return Self.mediumDateTimeFormatter.string(from: date)
    }
} 
