import Foundation

extension MemorialDayStore {
    func loadMemorialDays() {
        let snapshot = loadMemorialDaysSnapshot()
        memorialDays = snapshot.days
        isDataError = snapshot.isDataError
        bumpDataVersion()
    }
    
    func loadMemorialDaysSnapshot() -> (days: [MemorialDay], isDataError: Bool) {
        print("尝试加载纪念日数据")
        
        if let data = UserDefaults.standard.data(forKey: saveKey), !data.isEmpty {
            do {
                let decoded = try Self.makeJSONDecoder().decode([MemorialDay].self, from: data)
                print("成功从UserDefaults加载了 \(decoded.count) 条纪念日数据")
                return (decoded, false)
            } catch {
                print("解码纪念日数据失败: \(error.localizedDescription)")
                MemorialDayApp.reportError(error)
                DispatchQueue.main.async {
                    HapticManager.shared.error()
                }
                return ([], true)
            }
        } else {
            print("未找到保存的纪念日数据")
            return ([], false)
        }
    }
    
    func loadShowPastEventsSnapshot() -> Bool {
        if UserDefaults.standard.object(forKey: showPastKey) != nil {
            return UserDefaults.standard.bool(forKey: showPastKey)
        }
        
        UserDefaults.standard.set(true, forKey: showPastKey)
        return true
    }
    
    func saveMemorialDays() {
        do {
            try saveMemorialDaysWithErrorHandling()
        } catch {
            print("保存数据失败: \(error.localizedDescription)")
        }
    }
    
    func debounceSave(delay: TimeInterval = 0.1) {
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.saveMemorialDays()
        }
        saveWorkItem = work
        ioQueue.asyncAfter(deadline: .now() + delay, execute: work)
    }
    
    func saveMemorialDaysWithErrorHandling() throws {
        guard !self.memorialDays.isEmpty else {
            let sharedDefaults = UserDefaults(suiteName: "group.com.tongcheng.anniversaryapp")
            sharedDefaults?.removeObject(forKey: self.saveKey)
            UserDefaults.standard.removeObject(forKey: self.saveKey)
            return
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let encoded = try encoder.encode(self.memorialDays)
            let decoder = Self.makeJSONDecoder()
            _ = try decoder.decode([MemorialDay].self, from: encoded)
            
            let sharedDefaults = UserDefaults(suiteName: "group.com.tongcheng.anniversaryapp")
            UserDefaults.standard.set(encoded, forKey: self.saveKey)
            sharedDefaults?.set(encoded, forKey: self.saveKey)
        } catch {
            print("安全保存纪念日数据失败: \(error.localizedDescription)")
            MemorialDayApp.reportError(error)
            throw error
        }
    }
    
    func resetAllData() {
        print("正在重置所有应用数据...")
        
        let keysToRemove = [saveKey, showPastKey]
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        let sharedDefaults = UserDefaults(suiteName: "group.com.tongcheng.anniversaryapp")
        for key in keysToRemove {
            sharedDefaults?.removeObject(forKey: key)
        }
        
        memorialDays = []
        bumpDataVersion()
        do {
            try saveMemorialDaysWithErrorHandling()
        } catch {
            print("保存空数据失败: \(error.localizedDescription)")
            MemorialDayApp.reportError(error)
        }
        isDataError = false
        
        DispatchQueue.main.async {
            HapticManager.shared.customPattern()
        }
        
        print("应用数据重置完成")
    }
}

extension MemorialDayStore {
    fileprivate static func makeJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
