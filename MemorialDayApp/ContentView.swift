import SwiftUI
import UIKit
import Foundation

// ContentView 关键部分重构
struct ContentView: View {
    @EnvironmentObject var store: MemorialDayStore
    @EnvironmentObject var regionManager: RegionManager
    @StateObject private var viewController: ContentViewController
    @StateObject private var categoryManager = CategoryManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var editingMemorialDay: MemorialDay? = nil
    @State private var selectedMemorialDayId: UUID? = nil
    @State private var selectedCategoryId: UUID? = nil
    @State private var didSetup = false
    
    // 添加场景生命周期监听
    @Environment(\.scenePhase) var scenePhase
    // 添加设备尺寸类检测
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // 添加AppStorage属性，自动响应UserDefaults变化
    @AppStorage("floatingButtonIsLeftSide") private var isButtonOnLeft: Bool = false
    
    // 在ContentView顶部添加@AppStorage属性
    @AppStorage("showHolidayCountdown") private var showHolidayCountdown: Bool = false
    
    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }
    
    private var topContentMaxWidth: CGFloat {
        isRegularWidth ? 960 : .infinity
    }
    
    private var selectedMemorialDay: MemorialDay? {
        guard let selectedMemorialDayId else { return nil }
        return store.memorialDays.first(where: { $0.id == selectedMemorialDayId })
    }
    
    init() {
        _viewController = StateObject(wrappedValue: ContentViewController())
    }
    
    var body: some View {
        Group {
            if isRegularWidth {
                ipadSplitView
            } else {
                compactNavigationView
            }
        }
        .sheet(isPresented: $viewController.showingAddView) {
            AddMemorialDayView()
                .environmentObject(store)
                .presentationDetents(isRegularWidth ? [.fraction(0.9), .large] : [.large])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $viewController.showingSettingsView) {
            SettingsView()
                .environmentObject(store)
                .presentationDetents(isRegularWidth ? [.fraction(0.85), .large] : [.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: regularWidthEditingBinding) { memorialDay in
            EditMemorialDayView(
                memorialDay: memorialDay,
                onDelete: {
                    handleDeletedItem(resetSelection: true)
                }
            )
            .background(Color.adaptiveFormBackground.ignoresSafeArea())
            .presentationDetents([.fraction(0.9), .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: compactWidthEditingBinding) { memorialDay in
            EditMemorialDayView(
                memorialDay: memorialDay,
                onDelete: {
                    handleDeletedItem(resetSelection: false)
                }
            )
            .background(Color.adaptiveFormBackground.ignoresSafeArea())
        }
        .onAppear {
            if viewController.memorialDayStore !== store {
                viewController.memorialDayStore = store
            }
        }
        .task {
            guard !didSetup else { return }
            didSetup = true
            createSpecialCountdowns()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("holidaysUpdated"))) { notification in
            if let userInfo = notification.userInfo,
               let holidays = userInfo["holidays"] as? [(name: String, date: Date)] {
                updateHolidaysFromNetwork(holidays)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .regionChanged)) { notification in
            if let userInfo = notification.userInfo,
               let wasChina = userInfo["wasChina"] as? Bool,
               let isChina = userInfo["isChina"] as? Bool {
                handleRegionChange(wasChina: wasChina, isChina: isChina)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddMemorialDay)) { _ in
            viewController.showingAddView = true
            print("DEBUG: 收到快速操作通知，正在打开添加视图")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("refreshAllViews"))) { _ in
            store.objectWillChange.send()
            updateBuiltInMemorialDayTitles()
        }
        
        // 当设置开关变化时，立即刷新特殊倒计时
        .onChange(of: showHolidayCountdown) { _ in
            if showHolidayCountdown {
                createOrUpdateHolidaysForCurrentYear()
            } else {
                removeHolidayCountdowns()
            }
        }
        .onChange(of: selectedMemorialDayId) { newValue in
            if isRegularWidth, newValue == nil {
                editingMemorialDay = nil
            }
        }
        .onChange(of: store.changeToken) { _ in
            if let selectedMemorialDayId,
               !store.memorialDays.contains(where: { $0.id == selectedMemorialDayId }) {
                self.selectedMemorialDayId = nil
            }
        }
        // 监听应用生命周期，当app从后台恢复到前台时刷新数据
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // 清除缓存，强制重新计算天数
                store.refreshData()
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if viewController.showUndoBar {
                    HStack(spacing: 12) {
                        Text(LanguageManager.shared.localizedString("Deleted"))
                            .foregroundColor(.adaptivePrimaryText)
                        Spacer()
                        Button(LanguageManager.shared.localizedString("Undo")) {
                            viewController.undoDelete(store: store)
                        }
                        .foregroundColor(.appOrange)
                        .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.adaptiveCardBackground)
                    .cornerRadius(14)
                    .shadow(color: Color.adaptiveShadow(opacity: 0.08), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: topContentMaxWidth)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                HStack {
                    if isButtonOnLeft {
                        VoiceFloatingButtonView(
                            onTap: {
                                // 立即显示，无延迟
                                viewController.showingAddView = true
                            }
                        )
                        .padding(.leading, 24)
                        Spacer()
                    } else {
                        Spacer()
                        VoiceFloatingButtonView(
                            onTap: {
                                // 立即显示，无延迟
                                viewController.showingAddView = true
                            }
                        )
                        .padding(.trailing, 24)
                    }
                }
                .padding(.bottom, 12)
                .animation(.spring(), value: isButtonOnLeft)
            }
            .background( Color.clear )
        }
    }
    
    private var compactNavigationView: some View {
        NavigationView {
            mainListPane
        }
    }
    
    private var ipadSplitView: some View {
        NavigationSplitView {
            mainListPane
                .navigationTitle("")
                .navigationBarHidden(true)
        } detail: {
            Group {
                if let selectedMemorialDay {
                    DetailView(
                        memorialDay: selectedMemorialDay,
                        store: store,
                        showsNavigationBackButton: false,
                        onDelete: {
                            selectedMemorialDayId = nil
                            viewController.presentUndoBar(store: store)
                        }
                    )
                } else {
                    splitDetailPlaceholder
                }
            }
            .background(Color.adaptiveBackground.ignoresSafeArea())
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    private var mainListPane: some View {
        ZStack {
            // 检查是否有数据错误
            if store.isDataError {
                dataErrorView
            } else {
                // 正常内容视图
                VStack(spacing: 0) {
                    // 顶部标题和设置按钮
                    HStack {
                        Text(LanguageManager.shared.localizedString("Memorial Days"))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.adaptivePrimaryText)
                        Spacer()
                            
                        // 设置按钮 - 添加快速响应
                        Button(action: {
                            viewController.showingSettingsView = true
                            HapticManager.shared.lightTap()
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.adaptiveSecondaryText)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(FastScaleButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 8)
                    .frame(maxWidth: topContentMaxWidth)

                    Divider()
                        .background(Color.adaptiveSeparator)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 6)
                        .frame(maxWidth: topContentMaxWidth)
                    
                    // 分类过滤器 - 只有当有分类时才显示
                    if !categoryManager.categories.isEmpty {
                        CategoryFilterView(selectedCategoryId: $selectedCategoryId)
                            .environmentObject(categoryManager)
                            .padding(.top, 4)
                            .padding(.bottom, 8)
                            .frame(maxWidth: topContentMaxWidth)
                    }

                    // 列表区域
                    listContent
                }
            }
        }
        .background(Color.adaptiveBackground.ignoresSafeArea())
        .navigationBarHidden(true)
    }
    
    private var splitDetailPlaceholder: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.on.rectangle")
                .font(.system(size: 38))
                .foregroundColor(.adaptiveSecondaryText.opacity(0.65))
            Text(LanguageManager.shared.localizedString("Memorial Days"))
                .font(.headline)
                .foregroundColor(.adaptivePrimaryText)
            Text("在左侧选择一个纪念日查看详情")
                .font(.subheadline)
                .foregroundColor(.adaptiveSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.adaptiveBackground)
    }
    
    private var regularWidthEditingBinding: Binding<MemorialDay?> {
        Binding(
            get: { isRegularWidth ? editingMemorialDay : nil },
            set: { editingMemorialDay = $0 }
        )
    }
    
    private var compactWidthEditingBinding: Binding<MemorialDay?> {
        Binding(
            get: { isRegularWidth ? nil : editingMemorialDay },
            set: { editingMemorialDay = $0 }
        )
    }
    
    // 列表内容视图 - 支持iPad多列布局 - 优化版
    private var listContent: some View {
        GeometryReader { proxy in
            ScrollView {
                ZStack {
                    let allItems = store.sortedMemorialDays()
                    let items = filteredMemorialDays(allItems)
                    let themeId = themeManager.currentTheme.rawValue
                    let daysText = LanguageManager.shared.localizedString("days")
                    let passedText = LanguageManager.shared.localizedString("Passed")
                    if items.isEmpty {
                        emptyListView
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    } else {
                        let layoutWidth = min(proxy.size.width, topContentMaxWidth)
                        let columns = gridColumns(for: layoutWidth)
                        
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(items) { memorialDay in
                                    let days = store.daysRemaining(for: memorialDay)
                                    let categoryColorHex = categoryManager.getCategoryById(memorialDay.categoryId)?.color
                                    MemorialDayCardView(
                                        viewModel: MemorialDayCardViewModel(
                                            id: memorialDay.id,
                                            title: memorialDay.title,
                                            isPinned: memorialDay.isPinned,
                                            days: days,
                                            themeId: themeId,
                                            categoryColorHex: categoryColorHex,
                                            daysText: daysText,
                                            passedText: passedText,
                                            isSelected: isRegularWidth && selectedMemorialDayId == memorialDay.id
                                        )
                                    )
                                    .equatable()
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if isRegularWidth {
                                            selectedMemorialDayId = memorialDay.id
                                        } else {
                                            editingMemorialDay = memorialDay
                                        }
                                }
                                // 添加长按菜单功能
                                .contextMenu {
                                    Button(role: .destructive, action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            store.deleteMemorialDay(with: memorialDay.id)
                                            viewController.presentUndoBar(store: store)
                                        }
                                        HapticManager.shared.warning()
                                    }) {
                                        Label(LanguageManager.shared.localizedString("Delete"), systemImage: "trash")
                                    }
                                    
                                    Button(action: {
                                        var updatedDay = memorialDay
                                        updatedDay.isPinned.toggle()
                                        store.updateMemorialDay(updatedDay)
                                        HapticManager.shared.success()
                                    }) {
                                        Label(
                                            memorialDay.isPinned ?
                                                LanguageManager.shared.localizedString("Unpin") :
                                                LanguageManager.shared.localizedString("Pin"),
                                            systemImage: memorialDay.isPinned ? "pin.slash" : "pin"
                                        )
                                    }
                                    
                                    Button(action: {
                                        // 复制标题
                                        UIPasteboard.general.string = memorialDay.title
                                        HapticManager.shared.lightTap()
                                    }) {
                                        Label(LanguageManager.shared.localizedString("Copy Title"), systemImage: "doc.on.doc")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            store.deleteMemorialDay(with: memorialDay.id)
                                            viewController.presentUndoBar(store: store)
                                        }
                                        HapticManager.shared.warning()
                                    } label: {
                                        Label(LanguageManager.shared.localizedString("Delete"), systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        var updatedDay = memorialDay
                                        updatedDay.isPinned.toggle()
                                        store.updateMemorialDay(updatedDay)
                                        HapticManager.shared.success()
                                    } label: {
                                        Label(
                                            memorialDay.isPinned ?
                                                LanguageManager.shared.localizedString("Unpin") :
                                                LanguageManager.shared.localizedString("Pin"),
                                            systemImage: memorialDay.isPinned ? "pin.slash" : "pin"
                                        )
                                    }
                                    .tint(.appOrange)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 12)
                        .frame(maxWidth: topContentMaxWidth)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .refreshable {
                await refreshListContent()
            }
        }
        .scrollDismissesKeyboard(.immediately) // 滚动时立即收起键盘
    }
    
    private var emptyListView: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 34))
                .foregroundColor(.adaptiveSecondaryText.opacity(0.7))
            Text("还没有纪念日")
                .font(.headline)
                .foregroundColor(.adaptivePrimaryText)
            Button(LanguageManager.shared.localizedString("Add Memorial Day")) {
                viewController.showingAddView = true
                HapticManager.shared.lightTap()
            }
            .buttonStyle(PrimaryButtonStyle(font: .body))
            .frame(maxWidth: 240)
        }
    }
    
    // 根据设备尺寸返回网格列配置
    private func gridColumns(for width: CGFloat) -> [GridItem] {
        if !isRegularWidth {
            return [GridItem(.flexible(), spacing: 12)]
        }
        
        let columnCount: Int
        if width >= 980 {
            columnCount = 3
        } else {
            columnCount = 2
        }
        
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount)
    }
    
    // 创建特殊倒计时纪念日（高考和放假）
    private func createSpecialCountdowns() {
        // 只在中国地区创建考试倒计时
        if regionManager.isChina {
            // 检查用户是否删除过，如果没删除过才创建
            if !regionManager.isExamDeleted(.gaokao) {
                createOrUpdateGaokaoCountdown()
            }
            if !regionManager.isExamDeleted(.zhongkao) {
                createZhongkaoCountdownIfNeeded()
            }
        }
        
        // 如果设置了显示放假倒计时，确保存在放假纪念日
        if showHolidayCountdown {
            createOrUpdateHolidaysForCurrentYear()
        }
    }
    
    // 创建或更新高考倒计时（若已存在则不覆盖用户设置的日期）
    private func createOrUpdateGaokaoCountdown() {
        // 计算下一个高考日期（每年6月7日）
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        var gaokaoDate = calendar.date(from: DateComponents(year: year, month: 6, day: 7))!
        
        // 如果今年的高考已经过了，则使用明年的日期
        if now > gaokaoDate {
            gaokaoDate = calendar.date(from: DateComponents(year: year + 1, month: 6, day: 7))!
        }
        
        // 检查是否已存在高考倒计时纪念日
        let gaokaoID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
        if store.memorialDays.firstIndex(where: { $0.id == gaokaoID }) == nil {
            // 创建新的高考倒计时
            let gaokaoCountdown = MemorialDay(
                id: gaokaoID,
                title: LanguageManager.shared.localizedString("Gaokao Countdown"),
                date: gaokaoDate,
                repeatType: .none,
                repeatInterval: 1
            )
            store.addMemorialDay(gaokaoCountdown)
        }
    }
    
    // 创建中考倒计时（仅在不存在时创建，不会覆盖用户修改）
    private func createZhongkaoCountdownIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        var zhongkaoDate = calendar.date(from: DateComponents(year: year, month: 6, day: 15))!
        if now > zhongkaoDate {
            zhongkaoDate = calendar.date(from: DateComponents(year: year + 1, month: 6, day: 15))!
        }
        // 固定ID，便于唯一识别
        let zhongkaoID = UUID(uuidString: "00000000-0000-0000-0000-000000000003") ?? UUID()
        if store.memorialDays.firstIndex(where: { $0.id == zhongkaoID }) == nil {
            let item = MemorialDay(
                id: zhongkaoID,
                title: LanguageManager.shared.localizedString("Zhongkao Countdown"),
                date: zhongkaoDate,
                repeatType: .none,
                repeatInterval: 1
            )
            store.addMemorialDay(item)
        }
    }
    
    // 为当年创建或更新所有法定节假日
    private func createOrUpdateHolidaysForCurrentYear() {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let holidays = holidayList(for: currentYear)
        
        // 读取/初始化ID映射（节日名称 -> UUIDString），保证重复开启不会新增重复项
        var idMap = (UserDefaults.standard.dictionary(forKey: "HolidayCountdownIDs") as? [String: String]) ?? [:]
        
        for item in holidays {
            let countdownKey = getHolidayCountdownKey(for: item.name)
            let title = LanguageManager.shared.localizedString(countdownKey)
            let id: UUID
            if let idString = idMap[item.name], let fixedId = UUID(uuidString: idString) {
                id = fixedId
            } else {
                let newId = UUID()
                idMap[item.name] = newId.uuidString
                id = newId
            }
            
            if let existingIndex = store.memorialDays.firstIndex(where: { $0.id == id }) {
                var updated = store.memorialDays[existingIndex]
                updated.title = title
                updated.date = item.date
                updated.repeatType = .none
                updated.repeatInterval = 1
                store.updateMemorialDay(updated)
            } else {
                let newItem = MemorialDay(
                    id: id,
                    title: title,
                    date: item.date,
                    repeatType: .none,
                    repeatInterval: 1
                )
                store.addMemorialDay(newItem)
            }
        }
        
        UserDefaults.standard.set(idMap, forKey: "HolidayCountdownIDs")
        
        // 兼容清理历史的单一假期ID（旧实现）
        if let legacyId = UUID(uuidString: "00000000-0000-0000-0000-000000000002"),
           store.memorialDays.contains(where: { $0.id == legacyId }) {
            store.deleteMemorialDay(with: legacyId)
        }
    }
    
    private func holidayList(for year: Int) -> [(name: String, date: Date)] {
        let c = Calendar.current
        switch year {
        case 2024:
            return [
                ("元旦", c.date(from: DateComponents(year: 2024, month: 1, day: 1))!),
                ("春节", c.date(from: DateComponents(year: 2024, month: 2, day: 10))!),
                ("清明节", c.date(from: DateComponents(year: 2024, month: 4, day: 4))!),
                ("劳动节", c.date(from: DateComponents(year: 2024, month: 5, day: 1))!),
                ("端午节", c.date(from: DateComponents(year: 2024, month: 6, day: 10))!),
                ("中秋节", c.date(from: DateComponents(year: 2024, month: 9, day: 17))!),
                ("国庆节", c.date(from: DateComponents(year: 2024, month: 10, day: 1))!)
            ]
        case 2025:
            return [
                ("元旦", c.date(from: DateComponents(year: 2025, month: 1, day: 1))!),
                ("春节", c.date(from: DateComponents(year: 2025, month: 1, day: 29))!),
                ("清明节", c.date(from: DateComponents(year: 2025, month: 4, day: 4))!),
                ("劳动节", c.date(from: DateComponents(year: 2025, month: 5, day: 1))!),
                ("端午节", c.date(from: DateComponents(year: 2025, month: 5, day: 31))!),
                ("国庆节", c.date(from: DateComponents(year: 2025, month: 10, day: 1))!),
                ("中秋节", c.date(from: DateComponents(year: 2025, month: 10, day: 6))!)
            ]
        default:
            return [
                ("元旦", c.date(from: DateComponents(year: year, month: 1, day: 1))!),
                ("春节", c.date(from: DateComponents(year: year, month: 2, day: 10))!),
                ("清明节", c.date(from: DateComponents(year: year, month: 4, day: 4))!),
                ("劳动节", c.date(from: DateComponents(year: year, month: 5, day: 1))!),
                ("端午节", c.date(from: DateComponents(year: year, month: 6, day: 10))!),
                ("中秋节", c.date(from: DateComponents(year: year, month: 9, day: 17))!),
                ("国庆节", c.date(from: DateComponents(year: year, month: 10, day: 1))!)
            ]
        }
    }

    // 关闭开关时移除所有由功能生成的节假日
    private func removeHolidayCountdowns() {
        if let idMap = UserDefaults.standard.dictionary(forKey: "HolidayCountdownIDs") as? [String: String] {
            for (_, idString) in idMap {
                if let id = UUID(uuidString: idString) {
                    store.deleteMemorialDay(with: id)
                }
            }
        }
        // 清空映射
        UserDefaults.standard.removeObject(forKey: "HolidayCountdownIDs")
        
        // 同时清理旧实现的单项假期
        if let legacyId = UUID(uuidString: "00000000-0000-0000-0000-000000000002") {
            store.deleteMemorialDay(with: legacyId)
        }
    }
    
    // 从网络同步更新法定节假日
    private func updateHolidaysFromNetwork(_ holidays: [(name: String, date: Date)]) {
        guard showHolidayCountdown else { return }
        
        print("收到网络同步的法定节假日，共 \(holidays.count) 个")
        
        // 清除现有的法定节假日
        removeHolidayCountdowns()
        
        // 使用网络数据创建新的法定节假日
        var idMap: [String: String] = [:]
        
        for holiday in holidays {
            let countdownKey = getHolidayCountdownKey(for: holiday.name)
            let title = LanguageManager.shared.localizedString(countdownKey)
            let newId = UUID()
            idMap[holiday.name] = newId.uuidString
            
            let newItem = MemorialDay(
                id: newId,
                title: title,
                date: holiday.date,
                repeatType: .none,
                repeatInterval: 1
            )
            store.addMemorialDay(newItem)
        }
        
        // 保存新的ID映射
        UserDefaults.standard.set(idMap, forKey: "HolidayCountdownIDs")
        
        print("成功更新了 \(holidays.count) 个法定节假日倒计时")
    }
    
    // 处理地区变化
    private func handleRegionChange(wasChina: Bool, isChina: Bool) {
        if wasChina && !isChina {
            // 从中国地区切换到非中国地区：删除考试倒计时
            removeExamCountdowns()
            print("地区切换到非中国，已删除考试倒计时")
        } else if !wasChina && isChina {
            // 从非中国地区切换到中国地区：恢复未被用户删除的考试倒计时
            if !regionManager.isExamDeleted(.gaokao) {
                createOrUpdateGaokaoCountdown()
            }
            if !regionManager.isExamDeleted(.zhongkao) {
                createZhongkaoCountdownIfNeeded()
            }
            print("地区切换到中国，已恢复考试倒计时")
        }
    }
    
    // 删除所有考试倒计时
    private func removeExamCountdowns() {
        let gaokaoID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
        let zhongkaoID = UUID(uuidString: "00000000-0000-0000-0000-000000000003") ?? UUID()
        
        store.deleteMemorialDay(with: gaokaoID)
        store.deleteMemorialDay(with: zhongkaoID)
    }
    
    // 更新内置纪念日的标题（语言切换时调用）
    private func updateBuiltInMemorialDayTitles() {
        // 更新高考倒计时标题
        let gaokaoID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
        if let index = store.memorialDays.firstIndex(where: { $0.id == gaokaoID }) {
            var updatedGaokao = store.memorialDays[index]
            updatedGaokao.title = LanguageManager.shared.localizedString("Gaokao Countdown")
            store.updateMemorialDay(updatedGaokao)
        }
        
        // 更新中考倒计时标题
        let zhongkaoID = UUID(uuidString: "00000000-0000-0000-0000-000000000003") ?? UUID()
        if let index = store.memorialDays.firstIndex(where: { $0.id == zhongkaoID }) {
            var updatedZhongkao = store.memorialDays[index]
            updatedZhongkao.title = LanguageManager.shared.localizedString("Zhongkao Countdown")
            store.updateMemorialDay(updatedZhongkao)
        }
        
        // 更新节假日倒计时标题
        if let idMap = UserDefaults.standard.dictionary(forKey: "HolidayCountdownIDs") as? [String: String] {
            for (holidayName, idString) in idMap {
                if let id = UUID(uuidString: idString),
                   let index = store.memorialDays.firstIndex(where: { $0.id == id }) {
                    var updatedHoliday = store.memorialDays[index]
                    let countdownKey = getHolidayCountdownKey(for: holidayName)
                    updatedHoliday.title = LanguageManager.shared.localizedString(countdownKey)
                    store.updateMemorialDay(updatedHoliday)
                }
            }
        }
    }
    
    // 获取节假日倒计时的多语言键值
    private func getHolidayCountdownKey(for holidayName: String) -> String {
        switch holidayName {
        case "元旦":
            return "New Year Countdown"
        case "春节":
            return "Spring Festival Countdown"
        case "清明节":
            return "Qingming Festival Countdown"
        case "劳动节":
            return "Labor Day Countdown"
        case "端午节":
            return "Dragon Boat Festival Countdown"
        case "中秋节":
            return "Mid-Autumn Festival Countdown"
        case "国庆节":
            return "National Day Countdown"
        default:
            return "\(holidayName) Countdown"
        }
    }
    
    // 数据错误视图
    // 过滤纪念日
    private func filteredMemorialDays(_ allItems: [MemorialDay]) -> [MemorialDay] {
        if let selectedCategoryId = selectedCategoryId {
            return allItems.filter { $0.categoryId == selectedCategoryId }
        }
        return allItems
    }
    
    private var dataErrorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.appOrange)
                .padding(.bottom, 10)
            
            Text("数据加载错误")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.adaptivePrimaryText)
            
            Text("应用遇到了数据加载问题，需要重置数据才能继续使用")
                .font(.body)
                .foregroundColor(.adaptiveSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                // 调用store中的数据重置方法
                store.resetAllData()
            }) {
                Text("重置数据")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 20)
        }
        .padding(30)
        .background(RoundedRectangle(cornerRadius: 20)
            .fill(Color.adaptiveCardBackground)
            .shadow(color: Color.adaptiveShadow(opacity: 0.1), radius: 10))
        .padding(20)
    }
    
    private func handleDeletedItem(resetSelection: Bool) {
        editingMemorialDay = nil
        if resetSelection {
            selectedMemorialDayId = nil
        }
        viewController.presentUndoBar(store: store)
    }
    
    private func refreshListContent() async {
        await MainActor.run {
            store.refreshData()
            createSpecialCountdowns()
            updateBuiltInMemorialDayTitles()
            HapticManager.shared.lightTap()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MemorialDayStore())
    }
}
