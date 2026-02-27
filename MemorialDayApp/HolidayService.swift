import Foundation

struct PublicHoliday: Decodable {
    let date: String // e.g., "2025-01-01"
    let localName: String
    let name: String
}

final class HolidayService: ObservableObject {
    static let shared = HolidayService()
    
    private let session: URLSession
    private let countryCode: String
    @Published var isLoading = false
    @Published var lastSyncYear: Int?
    
    private init(session: URLSession = .shared, countryCode: String = "CN") {
        self.session = session
        self.countryCode = countryCode
        self.lastSyncYear = UserDefaults.standard.object(forKey: "lastSyncYear") as? Int
    }
    
    // 检查是否需要同步（年份变化或首次启动）
    func shouldSync() -> Bool {
        let currentYear = Calendar.current.component(.year, from: Date())
        return lastSyncYear != currentYear
    }
    
    // 自动同步当前年份的法定节假日
    @MainActor
    func autoSyncIfNeeded() async {
        guard shouldSync() else { return }
        
        let currentYear = Calendar.current.component(.year, from: Date())
        await syncHolidays(for: currentYear)
    }
    
    // 同步指定年份的法定节假日
    @MainActor
    func syncHolidays(for year: Int) async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("开始同步 \(year) 年法定节假日...")
            let holidays = try await fetchHolidays(year: year)
            
            // 更新法定节假日到本地存储
            await updateLocalHolidays(holidays, year: year)
            
            // 记录同步的年份
            lastSyncYear = year
            UserDefaults.standard.set(year, forKey: "lastSyncYear")
            
            print("成功同步了 \(holidays.count) 个法定节假日")
            
        } catch {
            print("同步法定节假日失败: \(error.localizedDescription)")
            // 如果网络同步失败，使用本地备用数据
            await useLocalFallbackHolidays(for: year)
        }
    }
    
    // 网络获取法定节假日
    private func fetchHolidays(year: Int) async throws -> [(name: String, date: Date)] {
        // 先尝试官方 API
        if let holidays = try? await fetchFromOfficialAPI(year: year) {
            return holidays
        }
        
        // 如果官方 API 失败，使用备用 API
        return try await fetchFromBackupAPI(year: year)
    }
    
    // 官方 API
    private func fetchFromOfficialAPI(year: Int) async throws -> [(name: String, date: Date)] {
        guard let url = URL(string: "https://date.nager.at/api/v3/PublicHolidays/\(year)/\(countryCode)") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        let items = try decoder.decode([PublicHoliday].self, from: data)
        let df = DateFormatter()
        df.locale = Locale(identifier: "zh_CN")
        df.dateFormat = "yyyy-MM-dd"
        return items.compactMap { item in
            guard let d = df.date(from: item.date) else { return nil }
            let displayName = item.localName.isEmpty ? item.name : item.localName
            return (name: displayName, date: d)
        }
    }
    
    // 备用 API（可以添加其他法定节假日 API）
    private func fetchFromBackupAPI(year: Int) async throws -> [(name: String, date: Date)] {
        // 这里可以添加其他 API 作为备用
        throw URLError(.cannotFindHost)
    }
    
    // 更新本地法定节假日存储
    @MainActor
    private func updateLocalHolidays(_ holidays: [(name: String, date: Date)], year: Int) async {
        // 通知 ContentView 更新法定节假日
        NotificationCenter.default.post(
            name: .holidaysUpdated, 
            object: nil, 
            userInfo: ["holidays": holidays, "year": year]
        )
    }
    
    // 使用本地备用数据
    @MainActor
    private func useLocalFallbackHolidays(for year: Int) async {
        print("使用本地备用法定节假日数据")
        let holidays = getLocalFallbackHolidays(for: year)
        await updateLocalHolidays(holidays, year: year)
        
        // 即使使用备用数据，也记录年份避免重复尝试
        lastSyncYear = year
        UserDefaults.standard.set(year, forKey: "lastSyncYear")
    }
    
    // 本地备用法定节假日数据
    private func getLocalFallbackHolidays(for year: Int) -> [(name: String, date: Date)] {
        let c = Calendar.current
        switch year {
        case 2024:
            return [
                ("元旦", c.date(from: DateComponents(year: 2024, month: 1, day: 1))!),
                ("春节", c.date(from: DateComponents(year: 2024, month: 2, day: 10))!),
                ("清明节", c.date(from: DateComponents(year: 2024, month: 4, day: 4))!),
                ("劳动节", c.date(from: DateComponents(year: 2024, month: 5, day: 1))!),
                ("端午节", c.date(from: DateComponents(year: 2024, month: 6, day: 10))!),
                ("中秋节", c.date(from: DateComponents(year: 2024, month: 9, day: 17))!),
                ("国庆节", c.date(from: DateComponents(year: 2024, month: 10, day: 1))!)
            ]
        case 2025:
            return [
                ("元旦", c.date(from: DateComponents(year: 2025, month: 1, day: 1))!),
                ("春节", c.date(from: DateComponents(year: 2025, month: 1, day: 29))!),
                ("清明节", c.date(from: DateComponents(year: 2025, month: 4, day: 4))!),
                ("劳动节", c.date(from: DateComponents(year: 2025, month: 5, day: 1))!),
                ("端午节", c.date(from: DateComponents(year: 2025, month: 5, day: 31))!),
                ("国庆节", c.date(from: DateComponents(year: 2025, month: 10, day: 1))!),
                ("中秋节", c.date(from: DateComponents(year: 2025, month: 10, day: 6))!)
            ]
        case 2026:
            return [
                ("元旦", c.date(from: DateComponents(year: 2026, month: 1, day: 1))!),
                ("春节", c.date(from: DateComponents(year: 2026, month: 2, day: 17))!),
                ("清明节", c.date(from: DateComponents(year: 2026, month: 4, day: 5))!),
                ("劳动节", c.date(from: DateComponents(year: 2026, month: 5, day: 1))!),
                ("端午节", c.date(from: DateComponents(year: 2026, month: 6, day: 19))!),
                ("中秋节", c.date(from: DateComponents(year: 2026, month: 9, day: 25))!),
                ("国庆节", c.date(from: DateComponents(year: 2026, month: 10, day: 1))!)
            ]
        default:
            // 默认使用通用的法定节假日
            return [
                ("元旦", c.date(from: DateComponents(year: year, month: 1, day: 1))!),
                ("春节", c.date(from: DateComponents(year: year, month: 2, day: 10))!),
                ("清明节", c.date(from: DateComponents(year: year, month: 4, day: 4))!),
                ("劳动节", c.date(from: DateComponents(year: year, month: 5, day: 1))!),
                ("端午节", c.date(from: DateComponents(year: year, month: 6, day: 10))!),
                ("中秋节", c.date(from: DateComponents(year: year, month: 9, day: 17))!),
                ("国庆节", c.date(from: DateComponents(year: year, month: 10, day: 1))!)
            ]
        }
    }
}

extension Notification.Name {
    static let holidaysUpdated = Notification.Name("holidaysUpdated")
}

