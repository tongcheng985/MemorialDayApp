import SwiftUI

struct GaokaoYearSettingView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var store: MemorialDayStore
    
    // 选择的高考日期时间
    @State private var selectedDate: Date
    
    // 高考日期ID
    private let gaokaoID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
    
    // 初始化：默认使用今年 6 月 7 日 08:00
    init() {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let defaultDate = calendar.date(from: DateComponents(year: year, month: 6, day: 7, hour: 8, minute: 0)) ?? now
        _selectedDate = State(initialValue: defaultDate)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color.adaptiveBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // 顶部导航栏
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                            // 添加轻微震动反馈
                            HapticManager.shared.lightTap()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.appOrange)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    .background(
                        Color.adaptiveCardBackground
                            .shadow(color: Color.adaptiveShadow(opacity: 0.05), radius: 5, x: 0, y: 3)
                    )
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // 日期时间选择器
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("选择高考日期与时间")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.adaptivePrimaryText)
                                    DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                        .datePickerStyle(.wheel)
                                        .labelsHidden()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.adaptiveCardBackground)
                                        .shadow(color: Color.adaptiveShadow(opacity: 0.05), radius: 4, x: 0, y: 2)
                                )
                                .padding(.horizontal, 20)
                                
                                // 说明文本
                                Text(formattedSelectedDate())
                                    .font(.system(size: 15))
                                    .foregroundColor(.adaptiveSecondaryText)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 10)
                                
                                // 保存按钮
                                Button(action: {
                                    updateGaokaoDate()
                                    presentationMode.wrappedValue.dismiss()
                                    // 添加成功震动反馈
                                    HapticManager.shared.success()
                                }) {
                                    Text("保存")
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .padding(.horizontal, 20)
                                .padding(.top, 30)
                            }
                            .padding(.vertical, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // 加载当前设置的高考日期
                loadCurrentGaokaoDate()
            }
        }
    }
    
    // 加载当前设置的高考日期
    private func loadCurrentGaokaoDate() {
        if let gaokaoMemorialDay = store.memorialDays.first(where: { $0.id == gaokaoID }) {
            selectedDate = gaokaoMemorialDay.date
        }
    }
    
    // 更新高考日期
    private func updateGaokaoDate() {
        // 检查是否已存在高考倒计时纪念日
        if let existingIndex = store.memorialDays.firstIndex(where: { $0.id == gaokaoID }) {
            // 更新现有的高考倒计时，仅更新日期，保留置顶等用户设置
            var updatedGaokao = store.memorialDays[existingIndex]
            updatedGaokao.date = selectedDate
            store.updateMemorialDay(updatedGaokao)
        } else {
            // 创建新的高考倒计时
            let gaokaoCountdown = MemorialDay(
                id: gaokaoID,
                title: LanguageManager.shared.localizedString("Gaokao Countdown"),
                date: selectedDate,
                repeatType: .none,
                repeatInterval: 1
            )
            store.addMemorialDay(gaokaoCountdown)
        }
    }

    // 静态日期格式化器，提升性能
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
    
    private func formattedSelectedDate() -> String {
        return Self.dateFormatter.string(from: selectedDate)
    }
} 