import SwiftUI
import UIKit

// 移除重复的 swipeBackGesture 定义，使用 ContentView 中的版本

struct AddMemorialDayView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var store: MemorialDayStore
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State private var draft = MemorialDayDraft()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .frame(maxWidth: maxContentWidth)
                
                ScrollView {
                    // 统一的表单视图
                    MemorialDayFormView(
                        title: $draft.title,
                        date: $draft.date,
                        repeatType: $draft.repeatType,
                        repeatInterval: $draft.repeatInterval,
                        isPinned: $draft.isPinned,
                        categoryId: $draft.categoryId,
                        isNotificationEnabled: $draft.isNotificationEnabled
                    )
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
    }
    
    func saveMemorialDay() {
        if let validationError = draft.validationErrorMessage {
            alertMessage = validationError
            showingAlert = true
            HapticManager.shared.error()
            return
        }
        
        HapticManager.shared.success()
        let newMemorialDay = draft.buildMemorialDay()
        store.addMemorialDay(newMemorialDay)
        
        presentationMode.wrappedValue.dismiss()
            
        if draft.isNotificationEnabled {
            DispatchQueue.global(qos: .utility).async {
                NotificationManager.shared.scheduleNotificationForMemorialDay(newMemorialDay)
            }
        }
    }
}

// 重复选项设置视图
struct RepeatOptionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Binding var repeatType: RepeatType
    @Binding var repeatInterval: Int
    @State private var selectedType: RepeatType
    @State private var selectedInterval: Int
    @FocusState private var intervalFieldFocused: Bool
    // 新增：自定义间隔的文本缓存，用于实现点击全选/清空
    @State private var customIntervalText: String = ""
    // 新增：记录是否已在本次聚焦时清空
    @State private var didClearOnFocus: Bool = false
    
    init(repeatType: Binding<RepeatType>, repeatInterval: Binding<Int>) {
        _repeatType = repeatType
        _repeatInterval = repeatInterval
        _selectedType = State(initialValue: repeatType.wrappedValue)
        _selectedInterval = State(initialValue: repeatInterval.wrappedValue)
        _customIntervalText = State(initialValue: String(repeatInterval.wrappedValue))
    }
    
    // iPad适配：最大内容宽度
    private var maxContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 720 : .infinity
    }
    
    var body: some View {
        ZStack {
            // 自适应背景
            Color.adaptiveFormBackground
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // 顶部导航栏，保持与创建/编辑页一致
                HStack {
                    Button(action: {
                        // 返回时自动保存
                        repeatType = selectedType
                        repeatInterval = selectedInterval
                        HapticManager.shared.lightTap()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.appOrange)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .frame(maxWidth: maxContentWidth)

                VStack(spacing: 24) {
                // 纵向单选列表
                VStack(spacing: 14) {
                    Button(action: { selectedType = .none; selectedInterval = 1 }) { row(LanguageManager.shared.localizedString("No Repeat"), isOn: selectedType == .none) }
                    Button(action: { selectedType = .daily; selectedInterval = 1 }) { row(LanguageManager.shared.localizedString("Daily"), isOn: selectedType == .daily) }
                    Button(action: { selectedType = .weekly; selectedInterval = 1 }) { row(LanguageManager.shared.localizedString("Weekly"), isOn: selectedType == .weekly) }
                    Button(action: { selectedType = .monthly; selectedInterval = 1 }) { row(LanguageManager.shared.localizedString("Monthly"), isOn: selectedType == .monthly) }
                    Button(action: { selectedType = .yearly; selectedInterval = 1 }) { row(LanguageManager.shared.localizedString("Yearly"), isOn: selectedType == .yearly) }
                    Button(action: { selectedType = .custom }) { row(LanguageManager.shared.localizedString("Custom"), isOn: selectedType == .custom) }
                }
                .padding(.horizontal, 20)
                
                // 间隔输入：所有非不重复类型都显示
                if selectedType != .none {
                    VStack(spacing: 14) {
                        if selectedType == .custom {
                            HStack {
                                Text("间隔")
                                    .font(.body)
                                    .foregroundColor(.adaptivePrimaryText)
                                Spacer()
                                TextField("1-999", text: Binding(
                                    get: { customIntervalText },
                                    set: { newValue in
                                        // 替换输入：只保留数字
                                        let filtered = newValue.filter { $0.isNumber }
                                        customIntervalText = filtered
                                        if let val = Int(filtered) {
                                            selectedInterval = min(max(val, 1), 999)
                                        }
                                    }
                                ))
                                .keyboardType(.numberPad)
                                .submitLabel(.done)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 90)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                                .focused($intervalFieldFocused)
                                .onAppear { customIntervalText = String(selectedInterval) }
                                .onChange(of: intervalFieldFocused) { focused in
                                    if focused && !didClearOnFocus {
                                        // 聚焦时清空，用户直接输入即替换原内容
                                        customIntervalText = ""
                                        didClearOnFocus = true
                                    }
                                    if !focused {
                                        didClearOnFocus = false
                                    }
                                }
                                Text(unitText())
                                    .foregroundColor(.adaptiveSecondaryText)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(LanguageManager.shared.localizedString("Interval"))
                                    .font(.body)
                                    .foregroundColor(.adaptivePrimaryText)
                                Picker(LanguageManager.shared.localizedString("Interval"), selection: $selectedInterval) {
                                    ForEach(1...99, id: \.self) { i in
                                        Text("\(i)")
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 120)
                                .clipped()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .frame(maxWidth: maxContentWidth)
            }
            .frame(maxWidth: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(LanguageManager.shared.localizedString("Done")) {
                    intervalFieldFocused = false
                }
            }
        }
        // 兜底：下拉关闭也自动保存
        .onDisappear {
            repeatType = selectedType
            repeatInterval = selectedInterval
        }
        .swipeBackGesture {
            repeatType = selectedType
            repeatInterval = selectedInterval
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func intervalDescription() -> String {
        switch selectedType {
        case .daily: return selectedInterval == 1 ? "每天" : "每\(selectedInterval)天"
        case .weekly: return selectedInterval == 1 ? "每周" : "每\(selectedInterval)周"
        case .monthly: return selectedInterval == 1 ? "每月" : "每\(selectedInterval)个月"
        case .yearly: return selectedInterval == 1 ? "每年" : "每\(selectedInterval)年"
        case .none: return "不重复"
        case .custom: return "每\(selectedInterval)天"
        }
    }
    
    // helpers
    private func row(_ title: String, isOn: Bool) -> some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.adaptivePrimaryText)
            Spacer()
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .foregroundColor(.appOrange)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        
    }

    private func unitText() -> String {
        switch selectedType {
        case .daily: return "天"
        case .weekly: return "周"
        case .monthly: return "个月"
        case .yearly: return "年"
        case .none: return ""
        case .custom: return "天"
        }
    }
} 
