import SwiftUI
import UIKit

// 移除重复的 swipeBackGesture 定义，使用 ContentView 中的版本


struct EditMemorialDayView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let memorialDay: MemorialDay
    @EnvironmentObject var store: MemorialDayStore
    @EnvironmentObject var regionManager: RegionManager
    var onDelete: (() -> Void)? = nil
    
    @State private var draft: MemorialDayDraft
    @State private var showingAlert = false
    @State private var alertMessage = ""
    // 移除删除确认弹窗状态
    
    init(memorialDay: MemorialDay, onDelete: (() -> Void)? = nil) {
        self.memorialDay = memorialDay
        self.onDelete = onDelete
        _draft = State(initialValue: MemorialDayDraft(memorialDay: memorialDay))
    }
    
    // iPad适配：最大内容宽度
    private var maxContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 720 : .infinity
    }
    
    var body: some View {
        ZStack {
            // 使用自适应颜色
            Color.adaptiveFormBackground
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // 点击背景区域收回键盘
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        // 添加轻微震动反馈
                        HapticManager.shared.lightTap()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.appOrange)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // 直接删除，不显示确认弹窗
                        deleteMemorialDay()
                        // 添加警告震动反馈
                        HapticManager.shared.warning()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .frame(maxWidth: maxContentWidth)
                
                ScrollView {
                    MemorialDayFormView(
                        title: $draft.title,
                        date: $draft.date,
                        repeatType: $draft.repeatType,
                        repeatInterval: $draft.repeatInterval,
                        isPinned: $draft.isPinned,
                        categoryId: $draft.categoryId,
                        isNotificationEnabled: $draft.isNotificationEnabled
                    )
                    .onChange(of: draft.isPinned) { _ in
                        persistDraftChange()
                        HapticManager.shared.lightTap()
                    }
                    .onChange(of: draft.categoryId) { _ in
                        persistDraftChange()
                        HapticManager.shared.lightTap()
                    }
                    .onChange(of: draft.isNotificationEnabled) { _ in
                        let updated = persistDraftChange()
                        // 更新通知调度
                        NotificationManager.shared.updateNotificationForMemorialDay(updated)
                        HapticManager.shared.lightTap()
                    }
                    .padding(.bottom, 16)
                    .frame(maxWidth: maxContentWidth)
                }
                
                // 底部保存按钮
                Button(action: {
                    saveMemorialDay()
                }) {
                    Text(LanguageManager.shared.localizedString("Save"))
                }
                .buttonStyle(PrimaryButtonStyle(font: Font.body))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: maxContentWidth)
                
                // 已移除小组件功能
            }
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .swipeBackGesture {
            presentationMode.wrappedValue.dismiss()
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(LanguageManager.shared.localizedString("Warning")), message: Text(alertMessage), dismissButton: .default(Text(LanguageManager.shared.localizedString("Confirm"))))
        }
        // 移除删除确认弹窗
    }
    
    // 保存编辑后的纪念日 - 快速响应版
    func saveMemorialDay() {
        if let validationError = draft.validationErrorMessage {
            alertMessage = validationError
            showingAlert = true
            HapticManager.shared.error()
            return
        }
        
        // 立即反馈
        HapticManager.shared.success()
        
        let updatedMemorialDay = draft.buildMemorialDay(id: memorialDay.id)
        
        // 立即更新数据
        store.updateMemorialDay(updatedMemorialDay)
        
        // 立即关闭视图
        presentationMode.wrappedValue.dismiss()
            
        // 异步更新通知
        DispatchQueue.global(qos: .utility).async {
            NotificationManager.shared.updateNotificationForMemorialDay(updatedMemorialDay)
        }
    }
    
    @discardableResult
    private func persistDraftChange() -> MemorialDay {
        let updated = draft.buildMemorialDay(id: memorialDay.id)
        store.updateMemorialDay(updated)
        return updated
    }
    
    // 删除纪念日
    func deleteMemorialDay() {
        // 检查是否为考试倒计时，如果是则标记为用户删除
        let gaokaoID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
        let zhongkaoID = UUID(uuidString: "00000000-0000-0000-0000-000000000003") ?? UUID()
        
        if memorialDay.id == gaokaoID {
            regionManager.markExamAsDeleted(.gaokao)
            print("用户删除了高考倒计时，已标记")
        } else if memorialDay.id == zhongkaoID {
            regionManager.markExamAsDeleted(.zhongkao)
            print("用户删除了中考倒计时，已标记")
        }
        
        // 删除相关通知
        NotificationManager.shared.removeNotificationForMemorialDay(memorialDay)
        
        store.deleteMemorialDay(with: memorialDay.id)
        // 触发警告震动反馈
        HapticManager.shared.warning()
        onDelete?()
        presentationMode.wrappedValue.dismiss()
    }
} 
