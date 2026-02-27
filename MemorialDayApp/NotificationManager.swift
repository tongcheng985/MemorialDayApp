import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notificationPermissionGranted = false
    
    private init() {
        checkNotificationPermission()
    }
    
    // 检查通知权限状态
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // 请求通知权限
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = granted
                completion(granted)
            }
            
            if let error = error {
                print("通知权限请求失败: \(error.localizedDescription)")
            }
        }
    }
    
    // 为纪念日安排通知（前一天提醒）
    func scheduleNotificationForMemorialDay(_ memorialDay: MemorialDay) {
        guard notificationPermissionGranted else {
            print("通知权限未授权，无法安排通知")
            return
        }
        
        // 先移除旧通知
        removeNotificationForMemorialDay(memorialDay)
        
        // 计算提醒日期（纪念日前一天）
        let calendar = Calendar.current
        let targetDate: Date
        
        if memorialDay.repeatType != .none {
            // 重复纪念日：使用下一个纪念日
            targetDate = memorialDay.calculateNextDate() ?? memorialDay.date
        } else {
            targetDate = memorialDay.date
        }
        
        // 前一天提醒
        guard let reminderDate = calendar.date(byAdding: .day, value: -1, to: targetDate) else {
            print("无法计算提醒日期")
            return
        }
        
        // 如果提醒日期已经过了，不安排通知
        if reminderDate < Date() {
            print("提醒日期已过，不安排通知")
            return
        }
        
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = LanguageManager.shared.localizedString("Memorial Day Reminder")
        content.body = String(format: LanguageManager.shared.localizedString("Tomorrow is %@"), memorialDay.title)
        content.sound = .default
        content.badge = 1
        
        // 设置通知时间（上午9点）
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        // 创建触发器
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // 创建请求
        let identifier = "memorial_\(memorialDay.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // 添加通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知安排失败: \(error.localizedDescription)")
            } else {
                print("成功安排通知 - 纪念日: \(memorialDay.title), 提醒日期: \(reminderDate)")
            }
        }
    }
    
    // 移除纪念日的通知
    func removeNotificationForMemorialDay(_ memorialDay: MemorialDay) {
        let identifier = "memorial_\(memorialDay.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("移除通知: \(identifier)")
    }
    
    // 更新纪念日的通知状态
    func updateNotificationForMemorialDay(_ memorialDay: MemorialDay) {
        if memorialDay.isNotificationEnabled {
            scheduleNotificationForMemorialDay(memorialDay)
        } else {
            removeNotificationForMemorialDay(memorialDay)
        }
    }
    
    // 批量更新所有纪念日的通知
    func updateAllNotifications(for memorialDays: [MemorialDay]) {
        for memorialDay in memorialDays {
            updateNotificationForMemorialDay(memorialDay)
        }
    }
    
    // 清除所有纪念日通知
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("已清除所有通知")
    }
    
    // 获取待处理的通知数量
    func getPendingNotificationCount(completion: @escaping (Int) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests.count)
            }
        }
    }
    
    // 打印所有待处理的通知（调试用）
    func debugPrintPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("待处理通知数量: \(requests.count)")
            for request in requests {
                print("通知ID: \(request.identifier)")
                print("标题: \(request.content.title)")
                print("内容: \(request.content.body)")
                if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("触发时间: \(calendarTrigger.dateComponents)")
                }
                print("---")
            }
        }
    }
}

// 扩展通知名称，用于应用内通信
extension Notification.Name {
    static let notificationPermissionChanged = Notification.Name("notificationPermissionChanged")
}
