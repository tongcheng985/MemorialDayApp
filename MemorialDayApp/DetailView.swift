import SwiftUI

struct DetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let memorialDay: MemorialDay
    @ObservedObject var store: MemorialDayStore
    var showsNavigationBackButton: Bool = true
    var onDelete: (() -> Void)? = nil
    @State private var showingEditView = false
    // 移除删除确认弹窗状态
    @State private var showingDebugInfo = false
    @State private var debugInfo = ""
    
    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }
    
    private var maxContentWidth: CGFloat {
        isRegularWidth ? 760 : .infinity
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color.adaptiveBackground
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题和日期
                    VStack(alignment: .leading, spacing: 5) {
                        Text(memorialDay.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.adaptivePrimaryText)
                        
                        HStack {
                            Text(formatDate(memorialDay.date))
                                .font(.system(size: 16))
                                .foregroundColor(.adaptiveSecondaryText)
                            
                            if memorialDay.repeatType != .none {
                                Text("・")
                                    .foregroundColor(.adaptiveSecondaryText)
                                
                                Text(MemorialDay.repeatTypeDescription(type: memorialDay.repeatType, interval: memorialDay.repeatInterval))
                                    .font(.system(size: 16))
                                    .foregroundColor(.appOrange)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // 倒计时
                    VStack(alignment: .center, spacing: 10) {
                        Text("\(memorialDay.daysRemaining())")
                            .font(.system(size: isRegularWidth ? 84 : 70, weight: .bold))
                            .foregroundColor(colorForDaysRemaining(memorialDay.daysRemaining()))
                        
                        Text("天")
                            .font(.system(size: 20))
                            .foregroundColor(.adaptiveSecondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.adaptiveCardBackground)
                    )
                    .padding(.horizontal, 20)
                    
                    // 下一个日期
                    if memorialDay.repeatType != .none {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("下一个日期")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.adaptiveSecondaryText)
                            
                            Text(memorialDay.nextDateDescription())
                                .font(.system(size: 18))
                                .foregroundColor(.adaptivePrimaryText)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 调试按钮 (仅在开发环境中显示)
                    #if DEBUG
                    Button(action: {
                        debugInfo = memorialDay.debugDateCalculation()
                        showingDebugInfo = true
                    }) {
                        HStack {
                            Image(systemName: "ladybug")
                            Text("调试日期计算")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                        )
                        .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    #endif
                    
                    Spacer(minLength: 50)
                    
                    // 操作按钮
                    Group {
                        if isRegularWidth {
                            HStack(spacing: 15) {
                                editButton
                                deleteButton
                            }
                        } else {
                            VStack(spacing: 15) {
                                editButton
                                deleteButton
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(!showsNavigationBackButton)
            .navigationBarItems(
                leading: Group {
                    if showsNavigationBackButton {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.appOrange)
                        }
                    }
                }
            )
            .sheet(isPresented: $showingEditView) {
                EditMemorialDayView(memorialDay: memorialDay, onDelete: onDelete)
                    .environmentObject(store)
                    .presentationDetents(isRegularWidth ? [.fraction(0.9), .large] : [.large])
                    .presentationDragIndicator(.visible)
            }
            // 移除删除确认弹窗
            .alert(isPresented: $showingDebugInfo) {
                Alert(
                    title: Text("日期计算调试信息"),
                    message: Text(debugInfo),
                    dismissButton: .default(Text("关闭"))
                )
            }
        }
    }
    
    private var editButton: some View {
        Button(action: {
            showingEditView = true
        }) {
            HStack {
                Image(systemName: "pencil")
                Text("编辑")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appOrange)
            )
            .foregroundColor(.white)
        }
    }
    
    private var deleteButton: some View {
        Button(action: {
            // 直接删除，不显示确认弹窗
            store.deleteMemorialDay(with: memorialDay.id)
            // 添加警告震动反馈
            HapticManager.shared.warning()
            onDelete?()
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "trash")
                Text("删除")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.red, lineWidth: 1)
            )
            .foregroundColor(.red)
        }
    }
    
    // 静态日期格式化器，避免重复创建
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    func formatDate(_ date: Date) -> String {
        return Self.dateFormatter.string(from: date)
    }
    
    func colorForDaysRemaining(_ days: Int) -> Color {
        switch days {
        case 0:
            return .red
        case 1...7:
            return .appOrange // 橙色
        case 8...30:
            return Color(red: 1.0, green: 0.5, blue: 0.1).opacity(0.8) // 浅橙色
        default:
            return Color(red: 0.5, green: 0.5, blue: 0.5)
        }
    }
}

struct DetailItemView: View {
    let icon: String
    let title: String
    let content: String
    var isMultiline: Bool = false
    
    var body: some View {
        HStack(alignment: isMultiline ? .top : .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.appOrange)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.appOrange.opacity(0.2))
                )
                .padding(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.adaptiveSecondaryText)
                
                if isMultiline {
                    Text(content)
                        .font(.body)
                        .foregroundColor(.adaptivePrimaryText.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                } else {
                    Text(content)
                        .font(.body)
                        .foregroundColor(.adaptivePrimaryText.opacity(0.8))
                }
            }
            
            Spacer()
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DetailView(
                memorialDay: MemorialDay(
                    title: "生日",
                    date: Date(),
                    repeatType: .yearly
                ),
                store: MemorialDayStore()
            )
        }
    }
} 
