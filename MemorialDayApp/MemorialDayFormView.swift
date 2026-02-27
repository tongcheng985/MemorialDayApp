import SwiftUI

struct MemorialDayDraft {
    var title: String = ""
    var date: Date = Date()
    var repeatType: RepeatType = .none
    var repeatInterval: Int = 1
    var isPinned: Bool = false
    var categoryId: UUID? = nil
    var isNotificationEnabled: Bool = false
    
    init() {}
    
    init(memorialDay: MemorialDay) {
        title = memorialDay.title
        date = memorialDay.date
        repeatType = memorialDay.repeatType
        repeatInterval = memorialDay.repeatInterval
        isPinned = memorialDay.isPinned
        categoryId = memorialDay.categoryId
        isNotificationEnabled = memorialDay.isNotificationEnabled
    }
    
    var validationErrorMessage: String? {
        title.count > 100 ? "标题最多100个字" : nil
    }
    
    var normalizedTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? LanguageManager.shared.localizedString("Unnamed") : trimmed
    }
    
    func buildMemorialDay(id: UUID = UUID()) -> MemorialDay {
        MemorialDay(
            id: id,
            title: normalizedTitle,
            date: date,
            repeatType: repeatType,
            repeatInterval: repeatInterval,
            isPinned: isPinned,
            categoryId: categoryId,
            isNotificationEnabled: isNotificationEnabled
        )
    }
}

struct MemorialDayFormView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Binding var title: String
    @Binding var date: Date
    @Binding var repeatType: RepeatType
    @Binding var repeatInterval: Int
    @Binding var isPinned: Bool
    @Binding var categoryId: UUID?
    @Binding var isNotificationEnabled: Bool
    
    @State private var showingRepeatOptions = false
    @State private var showingCategorySelection = false
    @FocusState private var titleFieldFocused: Bool
    
    // 使用 ObservedObject 而不是 StateObject，避免重复创建单例
    @ObservedObject private var categoryManager = CategoryManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    @State private var showingNotificationPermissionAlert = false
    @State private var showingNotificationExplanation = false
    
    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if isRegularWidth {
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 16) {
                        titleSection
                        dateSection
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    
                    VStack(spacing: 16) {
                        repeatSection
                        categorySection
                        togglesSection
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
            } else {
                titleSection
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                
                dateSection
                    .padding(.horizontal, 18)
                
                repeatSection
                    .padding(.horizontal, 18)
                
                categorySection
                    .padding(.horizontal, 18)
                
                togglesSection
                    .padding(.horizontal, 18)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(languageManager.localizedString("Done")) {
                    titleFieldFocused = false
                }
                .foregroundColor(.appOrange)
            }
        }
        .onTapGesture {
            // 点击空白区域收回键盘
            titleFieldFocused = false
        }
        .alert("开启通知提醒", isPresented: $showingNotificationExplanation) {
            Button("开启通知") {
                requestNotificationPermissionAfterExplanation()
            }
            Button("暂不开启", role: .cancel) {
                // 用户选择暂不开启，什么都不做
            }
        } message: {
            Text("开启通知后，我们会在纪念日前一天提醒您，帮助您不错过任何重要的日子。通知完全在您的设备本地生成，保护您的隐私。")
        }
        .alert(isPresented: $showingNotificationPermissionAlert) {
            Alert(
                title: Text(languageManager.localizedString("Notification Permission Required")),
                message: Text(languageManager.localizedString("Please allow notifications in Settings to enable reminders.")),
                primaryButton: .default(Text(languageManager.localizedString("Go to Settings"))) {
                    openAppSettings()
                },
                secondaryButton: .cancel(Text(languageManager.localizedString("Cancel"))) {
                    isNotificationEnabled = false
                }
            )
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                if title.isEmpty {
                    Text(languageManager.localizedString("Enter title..."))
                        .foregroundColor(.adaptiveSecondaryText.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                }
                TextEditor(text: Binding(
                    get: { String(title.prefix(100)) },
                    set: { newValue in
                        title = String(newValue.prefix(100))
                    }
                ))
                .font(.system(size: 17))
                .frame(minHeight: isRegularWidth ? 96 : 56)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .focused($titleFieldFocused)
                .autocorrectionDisabled(false)
                .textInputAutocapitalization(.sentences)
                .environment(\.locale, Locale(identifier: languageManager.currentLanguage.localeIdentifier))
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(titleFieldFocused ? Color.adaptiveCardBackground : Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(titleFieldFocused ? Color.appOrange.opacity(0.5) : Color(UIColor.separator).opacity(0.2), lineWidth: titleFieldFocused ? 2 : 1)
            )
            .overlay(alignment: .bottomTrailing) {
                Text("\(title.count)/100")
                    .font(.caption)
                    .foregroundColor(title.count > 90 ? .red : .adaptiveSecondaryText.opacity(0.6))
                    .padding(.trailing, 12)
                    .padding(.bottom, 10)
            }
        }
    }
    
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            DatePicker("", selection: $date, displayedComponents: [.date])
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .frame(height: isRegularWidth ? 180 : 140)
                .frame(maxWidth: .infinity)
                .accentColor(Color.appOrange)
                .environment(\.locale, Locale(identifier: languageManager.currentLanguage.localeIdentifier))
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.adaptiveCardBackground)
                )
        }
    }
    
    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                showingRepeatOptions = true
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.appOrange.opacity(0.12))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: repeatType == .none ? "nosign" : "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.appOrange)
                    }
                    
                    Text(MemorialDay.repeatTypeDescription(type: repeatType, interval: repeatInterval))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.adaptivePrimaryText)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.adaptiveSecondaryText.opacity(0.5))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.adaptiveCardBackground)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showingRepeatOptions) {
                RepeatOptionsView(
                    repeatType: $repeatType,
                    repeatInterval: $repeatInterval
                )
                .presentationDetents(isRegularWidth ? [.fraction(0.75), .large] : [.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                showingCategorySelection = true
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(getCategoryColor().opacity(0.12))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "tag.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(getCategoryColor())
                    }
                    
                    Text(getCategoryName())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.adaptivePrimaryText)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.adaptiveSecondaryText.opacity(0.5))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.adaptiveCardBackground)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showingCategorySelection) {
                CategorySelectionView(selectedCategoryId: $categoryId)
                    .environmentObject(categoryManager)
                    .presentationDetents(isRegularWidth ? [.fraction(0.8), .large] : [.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var togglesSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.appOrange.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "pin.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appOrange)
                }
                Text(languageManager.localizedString("Pin this memorial day"))
                    .font(.system(size: 16))
                    .foregroundColor(.adaptivePrimaryText)
                Spacer()
                Toggle("", isOn: $isPinned)
                    .labelsHidden()
                    .tint(.appOrange)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.leading, 66)
        
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.appOrange.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appOrange)
                }
                Text(languageManager.localizedString("Remind me one day before"))
                    .font(.system(size: 16))
                    .foregroundColor(.adaptivePrimaryText)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { isNotificationEnabled },
                    set: { newValue in
                        handleNotificationToggle(newValue)
                    }
                ))
                .labelsHidden()
                .tint(.appOrange)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.adaptiveCardBackground)
        )
    }
    
    private func getCategoryName() -> String {
        if let categoryId = categoryId,
           let category = categoryManager.getCategoryById(categoryId) {
            return category.name
        }
        return languageManager.localizedString("None")
    }
    
    private func getCategoryColor() -> Color {
        if let categoryId = categoryId,
           let category = categoryManager.getCategoryById(categoryId) {
            return category.swiftUIColor
        }
        return .gray
    }
    
    private func handleNotificationToggle(_ isEnabled: Bool) {
        if isEnabled {
            // 检查通知权限
            if notificationManager.notificationPermissionGranted {
                isNotificationEnabled = true
            } else {
                // 先显示解释，再请求权限（符合苹果最佳实践）
                showingNotificationExplanation = true
            }
        } else {
            isNotificationEnabled = false
        }
    }
    
    private func requestNotificationPermissionAfterExplanation() {
        notificationManager.requestNotificationPermission { granted in
            if granted {
                isNotificationEnabled = true
            } else {
                showingNotificationPermissionAlert = true
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
} 
