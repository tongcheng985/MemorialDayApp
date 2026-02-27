import Foundation
import SwiftUI
import UIKit

class MemorialDayStore: ObservableObject {
    @Published var memorialDays: [MemorialDay] = []
    @Published var showPastEvents: Bool = true
    @Published var isDataError: Bool = false // 添加数据错误状态标志
    @Published private(set) var changeToken: UInt64 = 0
    
    // 最近删除的缓存，用于撤销
    private var lastDeleted: (item: MemorialDay, deletedAt: Date)? = nil
    // 撤销有效期（秒）
    private let undoValiditySeconds: TimeInterval = 10
    
    let saveKey = "MemorialDays"
    let showPastKey = "ShowPastEvents"
    
    // 排序功能已移除，仅保留数据版本用于每日缓存失效
    var dataVersion: Int = 0
    func bumpDataVersion() {
        dataVersion &+= 1
        changeToken &+= 1
        // 数据变更时清理每日缓存和排序缓存
        daysRemainingCache.removeAll()
        sortedCache = nil
    }
    
    func bumpChangeToken() {
        changeToken &+= 1
    }

    // 每日缓存：按天缓存 daysRemaining 结果，减少重复计算
    private var cacheStartOfDay: Date = Calendar.current.startOfDay(for: Date())
    private var daysRemainingCache: [UUID: Int] = [:]
    private func clearDailyCachesIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        if today != cacheStartOfDay {
            cacheStartOfDay = today
            daysRemainingCache.removeAll()
            // 当天变化时，相关缓存需要失效
        }
    }
    
    func daysRemaining(for day: MemorialDay) -> Int {
        clearDailyCachesIfNeeded()
        // 优先返回缓存，提升查询速度
        if let cached = daysRemainingCache[day.id] {
            return cached
        }
        // 异步预热缓存，减少主线程阻塞
        let value = day.daysRemaining()
        daysRemainingCache[day.id] = value
        return value
    }
    
    // 后台保存队列与防抖
    // 使用更高优先级的队列，提升响应速度
    let ioQueue = DispatchQueue(label: "com.memorialday.store.io", qos: .userInitiated)
    var saveWorkItem: DispatchWorkItem?
    private var memoryWarningObserver: NSObjectProtocol?
    
    init() {
        print("初始化MemorialDayStore")
        
        // 在系统内存告警时主动释放瞬时缓存，避免使用过程中持续抬升
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.trimTransientMemory(aggressive: true)
        }
        
        // 延迟加载，提升启动速度
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 首先尝试加载现有数据
            do {
                let loadResult = self.loadMemorialDaysSnapshot()
                let showPast = self.loadShowPastEventsSnapshot()

                DispatchQueue.main.async {
                    self.memorialDays = loadResult.days
                    self.isDataError = loadResult.isDataError
                    self.showPastEvents = showPast
                    self.bumpDataVersion()
                    self.objectWillChange.send()

                    // 如果没有数据，保存空数组（后台队列）
                    if self.memorialDays.isEmpty {
                        self.debounceSave(delay: 0)
                    }
                }
            } catch {
                print("初始化MemorialDayStore时出错: \(error.localizedDescription)")
                MemorialDayApp.reportError(error)
                
                // 标记数据错误
                DispatchQueue.main.async {
                    self.isDataError = true
                    HapticManager.shared.error()
                }
                
                // 确保至少有一些默认数据
                DispatchQueue.main.async {
                    if self.memorialDays.isEmpty {
                        self.createDefaultData()
                    }
                }
            }
        }
    }
    
    deinit {
        if let memoryWarningObserver {
            NotificationCenter.default.removeObserver(memoryWarningObserver)
        }
    }
    
    // 创建默认数据
    func createDefaultData() {
        print("创建空的纪念日数据数组")
        
        // 不再创建默认纪念日，直接使用空数组
        memorialDays = []
        bumpDataVersion()
        
        // 保存空数据
        do {
            try saveMemorialDaysWithErrorHandling()
            print("空数据数组已创建并保存")
        } catch {
            print("保存空数据失败: \(error.localizedDescription)")
            MemorialDayApp.reportError(error)
            
            // 触发错误震动反馈
                DispatchQueue.main.async {
                HapticManager.shared.error()
            }
        }
    }
    
    // MARK: - 数据操作
    
    func addMemorialDay(_ memorialDay: MemorialDay) {
        memorialDays.append(memorialDay)
        bumpDataVersion()
        debounceSave()
    }
    
    func updateMemorialDay(_ memorialDay: MemorialDay) {
        if let index = memorialDays.firstIndex(where: { $0.id == memorialDay.id }) {
            // 确保在主线程中更新，触发SwiftUI响应
            DispatchQueue.main.async {
                self.memorialDays[index] = memorialDay
                self.bumpDataVersion()
                
                // 强制清除这个特定项目的缓存，确保下次计算使用新数据
                self.daysRemainingCache.removeValue(forKey: memorialDay.id)
                
                self.debounceSave()
            }
        }
    }
    
    func deleteMemorialDay(with id: UUID) {
        // 使用主队列确保线程安全
        DispatchQueue.main.async {
            // 在修改数据前创建备份
            let dataBefore = self.memorialDays
            
            // 找到要删除的项并缓存用于撤销
            if let idx = self.memorialDays.firstIndex(where: { $0.id == id }) {
                self.lastDeleted = (self.memorialDays[idx], Date())
            }
            
            // 删除指定ID的纪念日
            self.memorialDays.removeAll { $0.id == id }
            self.bumpDataVersion()
            
            // 检查删除操作是否成功
            if dataBefore.count == self.memorialDays.count {
                print("未找到要删除的纪念日ID: \(id)")
                return 
            }
            
            // 成功删除后，检测是否删除了特殊倒计时并自动关闭设置
            let gaokaoID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
            let holidayID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")
            if id == gaokaoID { UserDefaults.standard.set(false, forKey: "showGaokaoCountdown") }
            if id == holidayID { UserDefaults.standard.set(false, forKey: "showHolidayCountdown") }
            
            self.debounceSave()
        }
    }
    
    func moveMemorialDay(from source: IndexSet, to destination: Int) {
        memorialDays.move(fromOffsets: source, toOffset: destination)
        bumpDataVersion()
        debounceSave()
    }
    
    // 提供一个公共方法来重新加载数据
    func reloadMemorialDays() {
        loadMemorialDays()
        bumpDataVersion()
    }
    
    // 刷新数据：清除缓存并强制视图更新
    func refreshData() {
        // 清除每日缓存，确保重新计算天数
        daysRemainingCache.removeAll()
        cacheStartOfDay = Calendar.current.startOfDay(for: Date())
        sortedCache = nil
        
        // 触发视图更新
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // 释放列表排序/倒计时等瞬时缓存，控制内存增长
    func trimTransientMemory(aggressive: Bool = false) {
        daysRemainingCache.removeAll(keepingCapacity: false)
        sortedCache = nil
        sortCacheVersion = -1
        cacheStartOfDay = Calendar.current.startOfDay(for: Date())
        
        if aggressive {
            lastDeleted = nil
        }
    }
    
    // 缓存排序结果，避免重复计算
    var sortedCache: [MemorialDay]?
    var sortCacheVersion: Int = -1
    
    // 撤销最近一次删除
    func undoLastDelete() {
        guard let snapshot = lastDeleted else { return }
        // 判断是否在有效时间内
        if Date().timeIntervalSince(snapshot.deletedAt) <= undoValiditySeconds {
            self.memorialDays.append(snapshot.item)
            self.bumpDataVersion()
            self.debounceSave()
        }
        // 清空缓存
        lastDeleted = nil
    }
    
    // 用于给外部判断是否可以显示撤销
    func canUndoLastDelete() -> Bool {
        guard let snapshot = lastDeleted else { return false }
        return Date().timeIntervalSince(snapshot.deletedAt) <= undoValiditySeconds
    }
    
} 
