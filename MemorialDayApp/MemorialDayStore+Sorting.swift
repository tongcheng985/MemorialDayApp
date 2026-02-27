import Foundation

extension MemorialDayStore {
    func setShowPastEvents(_ show: Bool) {
        showPastEvents = show
        bumpChangeToken()
        UserDefaults.standard.set(show, forKey: showPastKey)
        sortedCache = nil
        objectWillChange.send()
    }
    
    func sortedMemorialDays() -> [MemorialDay] {
        if let cached = sortedCache, sortCacheVersion == dataVersion {
            return cached
        }
        
        var daysById: [UUID: Int] = [:]
        daysById.reserveCapacity(memorialDays.count)
        for day in memorialDays {
            daysById[day.id] = self.daysRemaining(for: day)
        }
        let days: (MemorialDay) -> Int = { day in
            daysById[day.id] ?? 0
        }
        
        let daysToShow = showPastEvents ? memorialDays : memorialDays.filter { days($0) >= 0 }
        let unexpired = daysToShow.filter { days($0) >= 0 }
        let expired = daysToShow.filter { days($0) < 0 }
        
        func sortWithPinnedFirst(_ arr: [MemorialDay]) -> [MemorialDay] {
            let pinned = arr.filter { $0.isPinned }
            let unpinned = arr.filter { !$0.isPinned }
            let sortedPinned = pinned.sorted { days($0) < days($1) }
            let sortedUnpinned = unpinned.sorted { days($0) < days($1) }
            return sortedPinned + sortedUnpinned
        }
        
        let result = sortWithPinnedFirst(unexpired) + sortWithPinnedFirst(expired)
        sortedCache = result
        sortCacheVersion = dataVersion
        return result
    }
}
