import UIKit

/// 触觉反馈管理器
class HapticManager {
    static let shared = HapticManager()
    
    // 预加载反馈生成器，减少延迟
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        // 预热生成器，减少首次触觉反馈的延迟
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    /// 轻微触觉反馈 - 快速版
    func lightTap() {
        lightGenerator.impactOccurred()
        // 立即准备下次使用
        lightGenerator.prepare()
    }
    
    /// 中等触觉反馈 - 快速版
    func mediumTap() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }
    
    /// 重度触觉反馈 - 快速版
    func heavyTap() {
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }
    
    /// 成功反馈 - 快速版
    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    /// 错误反馈 - 快速版
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    /// 警告反馈 - 快速版
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    /// 自定义模式反馈
    func customPattern() {
        // 创建一个自定义的触觉反馈模式
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        
        // 执行一个短促的双击模式
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.impactOccurred()
        }
    }
}