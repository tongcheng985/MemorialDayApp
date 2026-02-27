import SwiftUI
import os.log
import UIKit
import Foundation
import Combine

// 添加快速操作通知
extension Notification.Name {
    static let showAddMemorialDay = Notification.Name("showAddMemorialDay")
}

// 语言管理相关定义
enum AppLanguage: String, CaseIterable {
    case system = "system"
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    
    var displayName: String {
        return LanguageManager.shared.localizedString(self.localizedKey)
    }
    
    var localizedKey: String {
        switch self {
        case .system:
            return "Follow System"
        case .english:
            return "English"
        case .simplifiedChinese:
            return "Simplified Chinese"
        case .traditionalChinese:
            return "Traditional Chinese"
        }
    }
    
    var localeIdentifier: String {
        switch self {
        case .system:
            return Locale.current.identifier
        case .english:
            return "en"
        case .simplifiedChinese:
            return "zh_CN"
        case .traditionalChinese:
            return "zh_TW"
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            updateLocale()
        }
    }
    
    // 本地化字符串字典
    private var localizedStrings: [AppLanguage: [String: String]] = [:]
    
    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? AppLanguage.simplifiedChinese.rawValue
        self.currentLanguage = AppLanguage(rawValue: savedLanguage) ?? .simplifiedChinese
        setupLocalizedStrings()
        updateLocale()
    }
    
    private func setupLocalizedStrings() {
        localizedStrings = [
            .simplifiedChinese: [
                "Memorial Days": "纪念日",
                "Add Memorial Day": "添加纪念日",
                "Edit Memorial Day": "编辑纪念日",
                "Title": "标题",
                "Enter title...": "请输入标题…",
                "Save": "保存",
                "Delete": "删除",
                "Past Events": "过去事件",
                "Legal Holidays": "法定节假日",
                "Language": "语言",
                "Follow System": "跟随系统",
                "Simplified Chinese": "简体中文",
                "Traditional Chinese": "繁體中文",
                "English": "English",
                "No Repeat": "不重复",
                "Daily": "每天",
                "Weekly": "每周",
                "Monthly": "每月",
                "Yearly": "每年",
                "Custom": "自定义",
                "Interval": "间隔",
                "Pin this memorial day": "置顶该纪念日",
                "Gaokao Countdown": "高考倒计时",
                "Zhongkao Countdown": "中考倒计时",
                "New Year Countdown": "元旦倒计时",
                "Spring Festival Countdown": "春节倒计时",
                "Qingming Festival Countdown": "清明节倒计时",
                "Labor Day Countdown": "劳动节倒计时",
                "Dragon Boat Festival Countdown": "端午节倒计时",
                "National Day Countdown": "国庆节倒计时",
                "Mid-Autumn Festival Countdown": "中秋节倒计时",
                "Unnamed": "未命名",
                "days": "天",
                "Passed": "已过",
                "Done": "完成",
                "Cancel": "取消",
                "Confirm": "确定",
                "Warning": "提示",
                "Deleted": "已删除",
                "Undo": "撤销",
                "weeks": "周",
                "months": "个月",
                "years": "年",
                "Categories": "分类",
                "Add Category": "添加分类",
                "Category Name": "分类名称",
                "Work": "工作",
                "Personal": "个人",
                "Family": "家庭",
                "Category": "分类",
                "All": "全部",
                "All Categories": "所有",
                "None": "无分类",
                "Delete Category": "删除分类",
                "Are you sure you want to delete this category?": "确定要删除这个分类吗？",
                "Category name cannot be empty": "分类名称不能为空",
                "Category name already exists": "分类名称已存在",
                "Color": "颜色",
                "Theme Color": "主题色",
                "Pin": "置顶",
                "Unpin": "取消置顶",
                "Copy Title": "复制标题",
                "Theme Orange": "橙色",
                "Theme Blue": "蓝色",
                "Theme Purple": "紫色",
                "Theme Green": "绿色",
                "Theme Red": "红色",
                "Theme Pink": "粉色",
                "Remind me one day before": "提前一天提醒",
                "Memorial Day Reminder": "纪念日提醒",
                "Tomorrow is %@": "明天是%@",
                "Notification Permission Required": "需要通知权限",
                "Please allow notifications in Settings to enable reminders.": "请在设置中允许通知以启用提醒功能。",
                "Go to Settings": "去设置"
            ],
            .traditionalChinese: [
                "Memorial Days": "紀念日",
                "Add Memorial Day": "添加紀念日",
                "Edit Memorial Day": "編輯紀念日",
                "Title": "標題",
                "Enter title...": "請輸入標題…",
                "Save": "保存",
                "Delete": "刪除",
                "Past Events": "過去事件",
                "Legal Holidays": "法定節假日",
                "Language": "語言",
                "Follow System": "跟隨系統",
                "Simplified Chinese": "简体中文",
                "Traditional Chinese": "繁體中文",
                "English": "English",
                "No Repeat": "不重複",
                "Daily": "每天",
                "Weekly": "每週",
                "Monthly": "每月",
                "Yearly": "每年",
                "Custom": "自定義",
                "Interval": "間隔",
                "Pin this memorial day": "置頂該紀念日",
                "Gaokao Countdown": "高考倒計時",
                "Zhongkao Countdown": "中考倒計時",
                "New Year Countdown": "元旦倒計時",
                "Spring Festival Countdown": "春節倒計時",
                "Qingming Festival Countdown": "清明節倒計時",
                "Labor Day Countdown": "勞動節倒計時",
                "Dragon Boat Festival Countdown": "端午節倒計時",
                "National Day Countdown": "國慶節倒計時",
                "Mid-Autumn Festival Countdown": "中秋節倒計時",
                "Unnamed": "未命名",
                "days": "天",
                "Passed": "已過",
                "Done": "完成",
                "Cancel": "取消",
                "Confirm": "確定",
                "Warning": "提示",
                "Deleted": "已刪除",
                "Undo": "撤銷",
                "weeks": "週",
                "months": "個月",
                "years": "年",
                "Categories": "分類",
                "Add Category": "添加分類",
                "Category Name": "分類名稱",
                "Work": "工作",
                "Personal": "個人",
                "Family": "家庭",
                "Category": "分類",
                "All": "全部",
                "All Categories": "所有",
                "None": "無分類",
                "Delete Category": "刪除分類",
                "Are you sure you want to delete this category?": "確定要刪除這個分類嗎？",
                "Category name cannot be empty": "分類名稱不能為空",
                "Category name already exists": "分類名稱已存在",
                "Color": "顏色",
                "Theme Color": "主題色",
                "Pin": "置頂",
                "Unpin": "取消置頂",
                "Copy Title": "複製標題",
                "Theme Orange": "橙色",
                "Theme Blue": "藍色",
                "Theme Purple": "紫色",
                "Theme Green": "綠色",
                "Theme Red": "紅色",
                "Theme Pink": "粉色",
                "Remind me one day before": "提前一天提醒",
                "Memorial Day Reminder": "紀念日提醒",
                "Tomorrow is %@": "明天是%@",
                "Notification Permission Required": "需要通知權限",
                "Please allow notifications in Settings to enable reminders.": "請在設置中允許通知以啟用提醒功能。",
                "Go to Settings": "去設置"
            ],
            .english: [
                "Memorial Days": "Memorial Days",
                "Add Memorial Day": "Add Memorial Day",
                "Edit Memorial Day": "Edit Memorial Day",
                "Title": "Title",
                "Enter title...": "Enter title...",
                "Save": "Save",
                "Delete": "Delete",
                "Past Events": "Past Events",
                "Legal Holidays": "Legal Holidays",
                "Language": "Language",
                "Follow System": "Follow System",
                "Simplified Chinese": "简体中文",
                "Traditional Chinese": "繁體中文",
                "English": "English",
                "No Repeat": "No Repeat",
                "Daily": "Daily",
                "Weekly": "Weekly",
                "Monthly": "Monthly",
                "Yearly": "Yearly",
                "Custom": "Custom",
                "Interval": "Interval",
                "Pin this memorial day": "Pin this memorial day",
                "Gaokao Countdown": "Gaokao Countdown",
                "Zhongkao Countdown": "Zhongkao Countdown",
                "New Year Countdown": "New Year Countdown",
                "Spring Festival Countdown": "Spring Festival Countdown",
                "Qingming Festival Countdown": "Qingming Festival Countdown",
                "Labor Day Countdown": "Labor Day Countdown",
                "Dragon Boat Festival Countdown": "Dragon Boat Festival Countdown",
                "National Day Countdown": "National Day Countdown",
                "Mid-Autumn Festival Countdown": "Mid-Autumn Festival Countdown",
                "Unnamed": "Unnamed",
                "days": "days",
                "Passed": "Passed",
                "Done": "Done",
                "Cancel": "Cancel",
                "Confirm": "OK",
                "Warning": "Warning",
                "Deleted": "Deleted",
                "Undo": "Undo",
                "weeks": "weeks",
                "months": "months",
                "years": "years",
                "Categories": "Categories",
                "Add Category": "Add Category",
                "Category Name": "Category Name",
                "Work": "Work",
                "Personal": "Personal",
                "Family": "Family",
                "Category": "Category",
                "All": "All",
                "All Categories": "All",
                "None": "None",
                "Delete Category": "Delete Category",
                "Are you sure you want to delete this category?": "Are you sure you want to delete this category?",
                "Category name cannot be empty": "Category name cannot be empty",
                "Category name already exists": "Category name already exists",
                "Color": "Color",
                "Theme Color": "Theme Color",
                "Pin": "Pin",
                "Unpin": "Unpin",
                "Copy Title": "Copy Title",
                "Theme Orange": "Orange",
                "Theme Blue": "Blue",
                "Theme Purple": "Purple",
                "Theme Green": "Green",
                "Theme Red": "Red",
                "Theme Pink": "Pink",
                "Remind me one day before": "Remind me one day before",
                "Memorial Day Reminder": "Memorial Day Reminder",
                "Tomorrow is %@": "Tomorrow is %@",
                "Notification Permission Required": "Notification Permission Required",
                "Please allow notifications in Settings to enable reminders.": "Please allow notifications in Settings to enable reminders.",
                "Go to Settings": "Go to Settings"
            ]
        ]
    }
    
    private func updateLocale() {
        // 立即更新界面
        DispatchQueue.main.async {
            self.objectWillChange.send()
            // 发送全局刷新通知
            NotificationCenter.default.post(name: NSNotification.Name("refreshAllViews"), object: nil)
        }
    }
    
    func localizedString(_ key: String) -> String {
        let language = currentLanguage == .system ? getSystemLanguage() : currentLanguage
        return localizedStrings[language]?[key] ?? key
    }
    
    private func getSystemLanguage() -> AppLanguage {
        let systemLanguage = Locale.current.languageCode ?? "en"
        let systemRegion = Locale.current.region?.identifier ?? "US"
        
        switch systemLanguage {
        case "zh":
            return ["TW", "HK", "MO"].contains(systemRegion) ? .traditionalChinese : .simplifiedChinese
        case "en":
            return .english
        default:
            return .english
        }
    }
}

// 地区管理器
class RegionManager: ObservableObject {
    static let shared = RegionManager()
    
    @Published var currentRegion: String
    @Published var isChina: Bool
    
    // 记录用户手动删除的考试倒计时
    private let deletedExamsKey = "user_deleted_exams"
    
    private init() {
        let region = Locale.current.region?.identifier ?? "US"
        self.currentRegion = region
        self.isChina = RegionManager.checkIsChina(region: region)
        
        // 监听地区变化
        NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateRegion()
        }
    }
    
    private static func checkIsChina(region: String) -> Bool {
        return ["CN", "HK", "MO", "TW"].contains(region)
    }
    
    private func updateRegion() {
        let newRegion = Locale.current.region?.identifier ?? "US"
        let wasChina = isChina
        
        currentRegion = newRegion
        isChina = RegionManager.checkIsChina(region: newRegion)
        
        // 如果地区改变了，通知应用更新考试倒计时
        if wasChina != isChina {
            NotificationCenter.default.post(
                name: .regionChanged, 
                object: nil, 
                userInfo: ["wasChina": wasChina, "isChina": isChina]
            )
        }
    }
    
    // 记录用户删除的考试倒计时
    func markExamAsDeleted(_ examType: ExamType) {
        var deletedExams = getDeletedExams()
        deletedExams.insert(examType.rawValue)
        UserDefaults.standard.set(Array(deletedExams), forKey: deletedExamsKey)
    }
    
    // 检查考试是否被用户删除过
    func isExamDeleted(_ examType: ExamType) -> Bool {
        let deletedExams = getDeletedExams()
        return deletedExams.contains(examType.rawValue)
    }
    
    private func getDeletedExams() -> Set<String> {
        let array = UserDefaults.standard.array(forKey: deletedExamsKey) as? [String] ?? []
        return Set(array)
    }
}

enum ExamType: String, CaseIterable {
    case gaokao = "gaokao"
    case zhongkao = "zhongkao"
}

// 临时 HolidayService（如果无法找到独立文件）
class HolidayService: ObservableObject {
    static let shared = HolidayService()
    @Published var isLoading = false
    @Published var lastSyncYear: Int?
    
    private init() {
        self.lastSyncYear = UserDefaults.standard.object(forKey: "lastSyncYear") as? Int
    }
    
    func shouldSync() -> Bool {
        let currentYear = Calendar.current.component(.year, from: Date())
        return lastSyncYear != currentYear
    }
    
    @MainActor
    func autoSyncIfNeeded() async {
        guard shouldSync() else { return }
        let currentYear = Calendar.current.component(.year, from: Date())
        print("需要同步 \(currentYear) 年的法定节假日")
        // 这里可以添加实际的网络同步逻辑
        lastSyncYear = currentYear
        UserDefaults.standard.set(currentYear, forKey: "lastSyncYear")
    }
}

// 添加全局异常处理
func setupGlobalErrorHandling() {
	// 拦截NSException异常
	NSSetUncaughtExceptionHandler { exception in
		let logger = Logger(subsystem: "com.memorialday.app", category: "UncaughtException")
		logger.error("捕获到未处理的异常: \(exception.name.rawValue), 原因: \(exception.reason ?? "未知")")
		
		// 检查是否是JSON序列化错误
		let exceptionReason = exception.reason ?? ""
		if exceptionReason.contains("JSONSerialization") || 
		   exceptionReason.contains("JSON") ||
		   exceptionReason.contains("NSCoding") {
			
			logger.error("检测到JSON序列化错误，尝试恢复...")
			
			// 强制重置所有数据 - 在主线程中执行
			DispatchQueue.main.async {
				// 清除所有相关的UserDefaults键
				let keysToRemove = ["MemorialDays", "SortOption", "ShowPastEvents"]
				for key in keysToRemove {
					UserDefaults.standard.removeObject(forKey: key)
				}
				
				// 清除共享UserDefaults
				let sharedDefaults = UserDefaults(suiteName: "group.com.tongcheng.anniversaryapp")
				for key in keysToRemove {
					sharedDefaults?.removeObject(forKey: key)
				}
				
                // 系统会自动同步，无需显式调用 synchronize()
            }
        }
    }
}

// 应用委托处理快速操作
class AppDelegate: NSObject, UIApplicationDelegate {
	private let logger = Logger(subsystem: "com.memorialday.app", category: "AppDelegate")
	
	// 处理场景配置，并从连接选项中获取快速操作
	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// 检查是否有快速操作（使用 shortcutItem 而不是 shortcutItems）
		if let shortcutItem = options.shortcutItem {
			logger.log("应用启动时检测到快速操作：\(shortcutItem.type)")
			// 延迟处理以确保视图已加载
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
				self.handleShortcutItem(shortcutItem)
			}
		}
		
		let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
		configuration.delegateClass = SceneDelegate.self
		return configuration
	}
	
	// 处理快速操作的辅助方法
	private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
		if shortcutItem.type == "com.memorialday.add" {
			NotificationCenter.default.post(name: .showAddMemorialDay, object: nil)
			logger.log("已发送显示添加纪念日通知")
		}
	}
}

// Scene委托处理运行时的快速操作
class SceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
	var window: UIWindow?
	private let logger = Logger(subsystem: "com.memorialday.app", category: "SceneDelegate")
	
	// 当应用已经在运行时，用户触发快速操作
	func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		logger.log("应用运行中处理快速操作：\(shortcutItem.type)")
		
		if shortcutItem.type == "com.memorialday.add" {
			// 立即发送通知
			NotificationCenter.default.post(name: .showAddMemorialDay, object: nil)
			logger.log("已发送显示添加纪念日通知")
			completionHandler(true)
		} else {
			completionHandler(false)
		}
	}
	
	// 场景连接时的处理
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		// 检查是否有待处理的快速操作
		if let shortcutItem = connectionOptions.shortcutItem {
			logger.log("Scene连接时检测到快速操作：\(shortcutItem.type)")
			// 延迟处理，确保ContentView已经完全加载
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
				if shortcutItem.type == "com.memorialday.add" {
					NotificationCenter.default.post(name: .showAddMemorialDay, object: nil)
					self.logger.log("已发送显示添加纪念日通知")
				}
			}
		}
	}
}

@main
struct MemorialDayApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	@Environment(\.scenePhase) private var scenePhase
	@StateObject private var memorialDayStore = MemorialDayStore()
	@StateObject private var languageManager = LanguageManager.shared
	@StateObject private var regionManager = RegionManager.shared
	@StateObject private var holidayService = HolidayService.shared
	@StateObject private var phoneConnectivityManager = PhoneConnectivityManager.shared
	private let logger = Logger(subsystem: "com.memorialday.app", category: "AppDelegate")
	
	init() {
		logger.log("应用启动初始化")
		setupGlobalErrorHandling() // 添加全局错误处理
		attemptDataRecovery() // 添加数据恢复功能
		// 设定默认：法定节假日开关为开启
		UserDefaults.standard.register(defaults: ["showHolidayCountdown": true])
		
		// 请求网络权限（在Info.plist中添加说明）
		logger.log("应用启动，准备进行网络同步")
	}
	
	// 报告Swift错误的辅助函数
	static func reportError(_ error: Error, file: String = #file, line: Int = #line, function: String = #function) {
		let logger = Logger(subsystem: "com.memorialday.app", category: "ErrorReporter")
		logger.error("错误: \(error.localizedDescription), 位置: \(file):\(line), 函数: \(function)")
	}
	
	// 尝试修复可能损坏的数据
	private func attemptDataRecovery() {
		logger.log("尝试修复数据...")
		
		// 已移除小组件
		
		// 检查UserDefaults中的数据
		let saveKey = "MemorialDays"
		if let data = UserDefaults.standard.data(forKey: saveKey) {
			do {
				// 尝试解码数据，如果能正常解码，说明数据没有问题
				let decoder = JSONDecoder()
				let _ = try decoder.decode([MemorialDay].self, from: data)
				logger.log("数据检查正常")
			} catch {
				// 数据损坏，移除
				logger.error("数据损坏，正在重置: \(error.localizedDescription)")
				UserDefaults.standard.removeObject(forKey: saveKey)
				logger.log("已重置数据，将在下次启动时创建默认数据")
			}
		}
	}
	
	// 已移除小组件
	private func cleanWidgetData() { }
	
	var body: some Scene {
		WindowGroup {
			ContentView()
				.environmentObject(memorialDayStore)
				.environmentObject(languageManager)
				.environmentObject(regionManager)
				.environmentObject(holidayService)
				.tint(.appOrange)
				.onAppear {
					// 应用启动时自动同步法定节假日
					Task {
						await holidayService.autoSyncIfNeeded()
					}
					
					// 配置Watch连接管理器
					phoneConnectivityManager.setDataSources(
						store: memorialDayStore,
						categoryManager: CategoryManager.shared
					)
					logger.log("Watch连接管理器已配置")
				}
				.onReceive(memorialDayStore.$changeToken.dropFirst()) { token in
					// 数据变化时通知Watch
					phoneConnectivityManager.dataDidChange(changeToken: token)
				}
				.onChange(of: scenePhase) { phase in
					if phase == .background {
						memorialDayStore.trimTransientMemory()
					}
				}
		}
	}
}
