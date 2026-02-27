import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var memorialDays: [WatchMemorialDay] = []
    @Published var isConnected = false
    @Published var showPastEvents = false
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    
    private let memorialDaysKey = "WatchMemorialDays"
    private let showPastEventsKey = "WatchShowPastEvents"
    private let lastSyncDateKey = "WatchLastSyncDate"
    
    private override init() {
        super.init()
        // 先加载持久化的数据
        loadPersistedData()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // 加载持久化的数据
    private func loadPersistedData() {
        if let data = UserDefaults.standard.data(forKey: memorialDaysKey) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let loadedDays = try decoder.decode([WatchMemorialDay].self, from: data)
                self.memorialDays = loadedDays
                print("Watch: 成功加载 \(loadedDays.count) 个持久化的纪念日")
            } catch {
                print("Watch: 加载持久化数据失败: \(error)")
            }
        }
        
        self.showPastEvents = UserDefaults.standard.bool(forKey: showPastEventsKey)
        
        if let syncDate = UserDefaults.standard.object(forKey: lastSyncDateKey) as? Date {
            self.lastSyncDate = syncDate
        }
    }
    
    // 保存数据到持久化存储
    private func persistData() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(memorialDays)
            UserDefaults.standard.set(data, forKey: memorialDaysKey)
            
            UserDefaults.standard.set(showPastEvents, forKey: showPastEventsKey)
            
            let now = Date()
            UserDefaults.standard.set(now, forKey: lastSyncDateKey)
            self.lastSyncDate = now
            
            print("Watch: 数据持久化成功，保存了 \(memorialDays.count) 个纪念日")
        } catch {
            print("Watch: 数据持久化失败: \(error)")
        }
    }
    
    func requestMemorialDays() {
        print("Watch: 开始请求纪念日数据")
        
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        if WCSession.default.isReachable {
            print("Watch: iPhone app is reachable, sending message")
            let message = ["action": "requestSync"]
            WCSession.default.sendMessage(message, replyHandler: { response in
                print("Watch: 收到iPhone回复: \(response)")
                self.processReceivedData(response)
                DispatchQueue.main.async {
                    self.isSyncing = false
                }
            }, errorHandler: { error in
                print("Watch: 消息发送失败: \(error)")
                // 同步失败不影响显示之前的数据，只是停止同步状态
                DispatchQueue.main.async {
                    self.isSyncing = false
                }
                // 如果消息发送失败，尝试读取上下文数据
                self.tryReadApplicationContext()
            })
        } else {
            print("Watch: iPhone app is not reachable, trying application context")
            // iPhone不可达时，尝试从 Application Context 获取数据
            self.tryReadApplicationContext()
            DispatchQueue.main.async {
                self.isSyncing = false
            }
        }
    }
    
    private func tryReadApplicationContext() {
        let context = WCSession.default.receivedApplicationContext
        print("Watch: 尝试读取 Application Context: \(context)")
        if !context.isEmpty {
            processReceivedData(context)
        } else {
            print("Watch: Application Context 为空")
        }
    }
    
    private func processReceivedData(_ data: [String: Any]) {
        DispatchQueue.main.async {
            print("Watch: processReceivedData 开始处理数据")
            print("Watch: 数据键: \(data.keys)")
            
            if let memorialDaysData = data["memorialDays"] as? [[String: Any]] {
                print("Watch: 找到纪念日数据，条数: \(memorialDaysData.count)")
                
                // 手动解析数据而不是依赖 JSONDecoder
                var watchMemorialDays: [WatchMemorialDay] = []
                
                for item in memorialDaysData {
                    if let idString = item["id"] as? String,
                       let id = UUID(uuidString: idString),
                       let title = item["title"] as? String,
                       let dateTimestamp = item["date"] as? TimeInterval,
                       let repeatTypeRaw = item["repeatType"] as? String,
                       let repeatInterval = item["repeatInterval"] as? Int,
                       let isPinned = item["isPinned"] as? Bool {
                        
                        let date = Date(timeIntervalSince1970: dateTimestamp)
                        let repeatType = WatchMemorialDay.RepeatType(rawValue: repeatTypeRaw) ?? .none
                        
                        let categoryId: UUID?
                        if let categoryIdString = item["categoryId"] as? String, !categoryIdString.isEmpty {
                            categoryId = UUID(uuidString: categoryIdString)
                        } else {
                            categoryId = nil
                        }
                        
                        let watchMemorialDay = WatchMemorialDay(
                            id: id,
                            title: title,
                            date: date,
                            repeatType: repeatType,
                            repeatInterval: repeatInterval,
                            isPinned: isPinned,
                            categoryId: categoryId
                        )
                        
                        watchMemorialDays.append(watchMemorialDay)
                        print("Watch: 解析纪念日成功: \(title)")
                    } else {
                        print("Watch: 解析纪念日失败，数据不完整: \(item)")
                    }
                }
                
                self.memorialDays = watchMemorialDays
                print("Watch: 最终成功解析 \(watchMemorialDays.count) 个纪念日")
                
                // 持久化数据
                self.persistData()
                
            } else {
                print("Watch: 未找到纪念日数据或数据格式错误")
                print("Watch: memorialDays 类型: \(type(of: data["memorialDays"]))")
            }
            
            // 处理showPastEvents设置
            if let showPast = data["showPastEvents"] as? Bool {
                self.showPastEvents = showPast
                print("Watch: 设置显示过期事件: \(showPast)")
            } else {
                print("Watch: 未找到showPastEvents设置，默认不显示过期事件")
                self.showPastEvents = false
            }
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = (activationState == .activated)
            if self.isConnected {
                print("Watch: WatchConnectivity activated successfully")
                // 延迟请求数据，确保 iPhone 端也已准备好
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.requestMemorialDays()
                }
            } else {
                print("Watch: WatchConnectivity activation failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let dataString = message["memorialDays"] as? String,
           let data = dataString.data(using: .utf8) {
            DispatchQueue.main.async {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let memorialDays = try decoder.decode([WatchMemorialDay].self, from: data)
                    self.memorialDays = memorialDays
                    print("Watch: Updated memorial days from phone: \(memorialDays.count)")
                } catch {
                    print("Watch: Error decoding memorial days: \(error)")
                }
            }
            
            replyHandler(["status": "received"])
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Watch: 收到 Application Context 更新: \(applicationContext.keys)")
        processReceivedData(applicationContext)
    }
}