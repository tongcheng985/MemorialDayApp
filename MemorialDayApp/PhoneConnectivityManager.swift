import Foundation
import WatchConnectivity

class PhoneConnectivityManager: NSObject, ObservableObject {
    static let shared = PhoneConnectivityManager()
    
    @Published var isWatchConnected = false
    @Published var isWatchReachable = false
    
    private var session: WCSession?
    private var memorialDayStore: MemorialDayStore?
    private var categoryManager: CategoryManager?
    private var pendingSyncWorkItem: DispatchWorkItem?
    private let payloadQueue = DispatchQueue(label: "com.memorialday.watch.payload", qos: .utility)
    private var lastScheduledChangeToken: UInt64?
    private var lastSentChangeToken: UInt64?
    
    private struct SyncMemorialDay {
        let id: String
        let title: String
        let date: TimeInterval
        let repeatType: String
        let repeatInterval: Int
        let isPinned: Bool
        let categoryId: String
        let isNotificationEnabled: Bool
    }
    
    private struct SyncCategory {
        let id: String
        let name: String
        let colorName: String
    }
    
    private struct SyncSnapshot {
        let memorialDays: [SyncMemorialDay]
        let categories: [SyncCategory]
        let showPastEvents: Bool
    }
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // 设置数据源
    func setDataSources(store: MemorialDayStore, categoryManager: CategoryManager) {
        self.memorialDayStore = store
        self.categoryManager = categoryManager
    }
    
    // 发送数据到Watch
    func sendDataToWatch() {
        guard let session = session else {
            return
        }
        guard session.activationState == .activated else { return }
        guard session.isPaired, session.isWatchAppInstalled else { return }
        guard let dataToSend = buildSyncPayload(includeAction: true) else {
            return
        }
        
        // 尝试通过应用上下文发送（更可靠）
        do {
            try session.updateApplicationContext(dataToSend)
        } catch {
            print("Phone: 应用上下文发送失败: \(error.localizedDescription)")
        }
        
        // 如果Watch可达，也尝试实时消息
        if session.isReachable {
            session.sendMessage(dataToSend, replyHandler: nil) { error in
                print("Phone: 实时消息发送失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func sendDataToWatch(payload dataToSend: [String: Any], changeToken: UInt64?) {
        guard let session = session else { return }
        guard session.activationState == .activated else { return }
        guard session.isPaired, session.isWatchAppInstalled else { return }
        
        do {
            try session.updateApplicationContext(dataToSend)
        } catch {
            print("Phone: 应用上下文发送失败: \(error.localizedDescription)")
        }
        
        if session.isReachable {
            session.sendMessage(dataToSend, replyHandler: nil) { error in
                print("Phone: 实时消息发送失败: \(error.localizedDescription)")
            }
        }
        
        if let changeToken {
            lastSentChangeToken = changeToken
        }
    }
    
    // 响应Watch的同步请求
    private func handleSyncRequest() -> [String: Any] {
        guard let payload = buildSyncPayload(includeAction: false) else {
            return [:]
        }
        return payload
    }
    
    // 数据变化时自动同步到Watch
    func dataDidChange(changeToken: UInt64? = nil) {
        if let changeToken, lastScheduledChangeToken == changeToken {
            return
        }
        if let changeToken, lastSentChangeToken == changeToken {
            return
        }
        if let changeToken {
            lastScheduledChangeToken = changeToken
        }
        guard let snapshot = captureSnapshot() else { return }
        
        // 取消上一次待发送任务，合并高频更新，降低内存峰值和瞬时分配
        pendingSyncWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.payloadQueue.async { [weak self] in
                guard let self else { return }
                let payload = self.buildPayload(from: snapshot, includeAction: true)
                DispatchQueue.main.async { [weak self] in
                    self?.sendDataToWatch(payload: payload, changeToken: changeToken)
                }
            }
        }
        pendingSyncWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: work)
    }

    private func buildSyncPayload(includeAction: Bool) -> [String: Any]? {
        guard let snapshot = captureSnapshotThreadSafe() else { return nil }
        return buildPayload(from: snapshot, includeAction: includeAction)
    }
    
    private func captureSnapshot() -> SyncSnapshot? {
        guard let store = memorialDayStore,
              let categoryManager = categoryManager else {
            return nil
        }
        
        let memorialDays = store.memorialDays.map { memorialDay in
            SyncMemorialDay(
                id: memorialDay.id.uuidString,
                title: memorialDay.title,
                date: memorialDay.date.timeIntervalSince1970,
                repeatType: memorialDay.repeatType.rawValue,
                repeatInterval: memorialDay.repeatInterval,
                isPinned: memorialDay.isPinned,
                categoryId: memorialDay.categoryId?.uuidString ?? "",
                isNotificationEnabled: memorialDay.isNotificationEnabled
            )
        }
        let categories = categoryManager.categories.map { category in
            SyncCategory(
                id: category.id.uuidString,
                name: category.name,
                colorName: category.color
            )
        }
        
        return SyncSnapshot(
            memorialDays: memorialDays,
            categories: categories,
            showPastEvents: store.showPastEvents
        )
    }
    
    private func captureSnapshotThreadSafe() -> SyncSnapshot? {
        if Thread.isMainThread {
            return captureSnapshot()
        }
        
        var snapshot: SyncSnapshot?
        DispatchQueue.main.sync { [weak self] in
            snapshot = self?.captureSnapshot()
        }
        return snapshot
    }
    
    private func buildPayload(from snapshot: SyncSnapshot, includeAction: Bool) -> [String: Any] {
        autoreleasepool {
            var payload: [String: Any] = [
                "memorialDays": snapshot.memorialDays.map { memorialDay in
                    [
                        "id": memorialDay.id,
                        "title": memorialDay.title,
                        "date": memorialDay.date,
                        "repeatType": memorialDay.repeatType,
                        "repeatInterval": memorialDay.repeatInterval,
                        "isPinned": memorialDay.isPinned,
                        "categoryId": memorialDay.categoryId,
                        "isNotificationEnabled": memorialDay.isNotificationEnabled
                    ]
                },
                "categories": snapshot.categories.map { category in
                    [
                        "id": category.id,
                        "name": category.name,
                        "colorName": category.colorName
                    ]
                },
                "showPastEvents": snapshot.showPastEvents
            ]
            
            if includeAction {
                payload["action"] = "syncData"
            }
            
            return payload
        }
    }
}

// MARK: - WCSessionDelegate
extension PhoneConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = activationState == .activated
        }
        
        if let error = error {
            print("Phone: WCSession激活失败: \(error.localizedDescription)")
        } else {
            print("Phone: WCSession激活成功")
            // 激活成功后立即发送初始数据
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("Phone: 发送初始数据到Watch")
                self.dataDidChange()
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Phone: WCSession变为非活跃")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Phone: WCSession已停用")
        // 重新激活会话
        session.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
        print("Phone: Watch连接状态变化 - 可达: \(session.isReachable)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("Phone: 收到Watch消息: \(message)")
        
        if message["action"] as? String == "requestSync" {
            // Watch请求同步数据
            DispatchQueue.main.async {
                self.sendDataToWatch()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        print("Phone: 收到Watch带回复消息: \(message)")
        
        if message["action"] as? String == "requestSync" {
            // 响应同步请求
            let responseData = handleSyncRequest()
            replyHandler(responseData)
            print("Phone: 已回复同步数据")
        }
    }
}
