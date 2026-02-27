import SwiftUI

// 主题色管理器
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
            // 通知所有视图刷新
            NotificationCenter.default.post(name: NSNotification.Name("themeChanged"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name("refreshAllViews"), object: nil)
        }
    }
    
    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "appTheme") ?? "orange"
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .orange
    }
}

// 主题色枚举
enum AppTheme: String, CaseIterable, Identifiable {
    case orange = "orange"
    case blue = "blue"
    case purple = "purple"
    case green = "green"
    case red = "red"
    case pink = "pink"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .orange: return Color(red: 0.95, green: 0.45, blue: 0.15)
        case .blue: return Color(red: 0.0, green: 0.48, blue: 1.0)
        case .purple: return Color(red: 0.69, green: 0.32, blue: 0.87)
        case .green: return Color(red: 0.2, green: 0.78, blue: 0.35)
        case .red: return Color(red: 1.0, green: 0.23, blue: 0.19)
        case .pink: return Color(red: 1.0, green: 0.18, blue: 0.33)
        }
    }
    
    var displayName: String {
        switch self {
        case .orange: return LanguageManager.shared.localizedString("Theme Orange")
        case .blue: return LanguageManager.shared.localizedString("Theme Blue")
        case .purple: return LanguageManager.shared.localizedString("Theme Purple")
        case .green: return LanguageManager.shared.localizedString("Theme Green")
        case .red: return LanguageManager.shared.localizedString("Theme Red")
        case .pink: return LanguageManager.shared.localizedString("Theme Pink")
        }
    }
}

// 深色模式适配的颜色主题
extension Color {
    // 动态主题色
    static var appOrange: Color {
        ThemeManager.shared.currentTheme.color
    }
    // 背景颜色 - 自适应深色模式
    static let adaptiveBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)  // 深色模式：纯黑
            : UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)  // 浅色模式：浅灰
    })
    
    // 卡片背景 - 自适应深色模式
    static let adaptiveCardBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)  // 深色模式：深灰
            : UIColor.white  // 浅色模式：白色
    })
    
    // 表单背景 - 自适应深色模式
    static let adaptiveFormBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)  // 深色模式：接近黑色
            : UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)  // 浅色模式：极浅灰
    })
    
    // 主要文本颜色 - 自适应深色模式
    static let adaptivePrimaryText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white  // 深色模式：白色
            : UIColor.black  // 浅色模式：黑色
    })
    
    // 次要文本颜色 - 自适应深色模式
    static let adaptiveSecondaryText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)  // 深色模式：中灰
            : UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)  // 浅色模式：灰色
    })
    
    // 过期事件文本颜色 - 自适应深色模式
    static let adaptiveOverdueText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)  // 深色模式：深灰
            : UIColor.gray  // 浅色模式：灰色
    })
    
    // 过期事件背景 - 自适应深色模式
    static let adaptiveOverdueBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)  // 深色模式：深灰
            : UIColor.systemGray6  // 浅色模式：浅灰
    })
    
    // 分隔线颜色 - 自适应深色模式
    static let adaptiveSeparator = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)  // 深色模式：深灰
            : UIColor.separator  // 浅色模式：系统分隔线
    })
    
    // 阴影颜色 - 自适应深色模式
    static func adaptiveShadow(opacity: Double = 0.05) -> Color {
        return Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: opacity * 0.3)  // 深色模式：浅色阴影，降低透明度
                : UIColor(white: 0.0, alpha: opacity)  // 浅色模式：深色阴影
        })
    }
    
    // 保持向后兼容的静态颜色（逐步迁移）
    static let backgroundGray = adaptiveBackground
    static let settingsCardBackground = adaptiveCardBackground
    static let lightGray = adaptiveSecondaryText
    static let lightBackground = adaptiveFormBackground
}
