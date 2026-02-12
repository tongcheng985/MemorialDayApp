import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 状态栏
                if !connectivityManager.isConnected {
                    HStack {
                        Image(systemName: "iphone.slash")
                            .foregroundColor(.red)
                        Text("未连接")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.bottom, 8)
                }
                
                // 纪念日列表
                if connectivityManager.memorialDays.isEmpty {
                    emptyStateView
                } else {
                    memorialDaysList
                }
            }
            .navigationTitle("纪念日")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await refreshData()
            }
            .onAppear {
                // 视图出现时请求同步数据
                connectivityManager.requestDataSync()
            }
        }
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("暂无纪念日")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("请在iPhone上添加纪念日")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("同步数据") {
                connectivityManager.requestDataSync()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
    }
    
    // 纪念日列表
    private var memorialDaysList: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(connectivityManager.sortedMemorialDays()) { memorialDay in
                    NavigationLink(destination: WatchDetailView(memorialDay: memorialDay)) {
                        WatchMemorialDayCard(memorialDay: memorialDay)
                            .environmentObject(connectivityManager)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
    
    // 刷新数据
    @MainActor
    private func refreshData() async {
        isRefreshing = true
        connectivityManager.requestDataSync()
        
        // 等待一秒以提供反馈
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }
}

// Watch详情视图
struct WatchDetailView: View {
    let memorialDay: WatchMemorialDay
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    
    private var categoryName: String {
        if let categoryId = memorialDay.categoryId,
           let category = connectivityManager.getCategoryById(categoryId) {
            return category.name
        }
        return "无分类"
    }
    
    private var repeatDescription: String {
        switch memorialDay.repeatType {
        case .none:
            return "不重复"
        case .daily:
            return memorialDay.repeatInterval == 1 ? "每天" : "每\(memorialDay.repeatInterval)天"
        case .weekly:
            return memorialDay.repeatInterval == 1 ? "每周" : "每\(memorialDay.repeatInterval)周"
        case .monthly:
            return memorialDay.repeatInterval == 1 ? "每月" : "每\(memorialDay.repeatInterval)个月"
        case .yearly:
            return memorialDay.repeatInterval == 1 ? "每年" : "每\(memorialDay.repeatInterval)年"
        case .custom:
            return "每\(memorialDay.repeatInterval)天"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 标题
                VStack(alignment: .leading, spacing: 4) {
                    Text(memorialDay.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    
                    if memorialDay.isPinned {
                        HStack {
                            Image(systemName: "pin.fill")
                                .foregroundColor(.orange)
                            Text("已置顶")
                                .foregroundColor(.orange)
                        }
                        .font(.caption)
                    }
                }
                
                // 天数显示
                VStack(alignment: .center, spacing: 8) {
                    let days = memorialDay.daysRemaining()
                    let isOverdue = days < 0
                    
                    if isOverdue {
                        VStack {
                            Text("已过")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("\(abs(days))")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.gray)
                            
                            Text("天")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    } else {
                        VStack {
                            Text("还有")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\(days)")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.orange)
                            
                            Text("天")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 详细信息
                VStack(alignment: .leading, spacing: 12) {
                    DetailRowView(title: "日期", value: formatDate(memorialDay.date))
                    DetailRowView(title: "重复", value: repeatDescription)
                    DetailRowView(title: "分类", value: categoryName)
                    
                    if memorialDay.isNotificationEnabled {
                        DetailRowView(title: "通知", value: "已开启")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("详情")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}

// 详情行视图
struct DetailRowView: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}

// 预览
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let connectivityManager = WatchConnectivityManager()
        
        // 添加示例数据
        let sampleData1: [String: Any] = [
            "id": UUID().uuidString,
            "title": "生日纪念",
            "date": Date().addingTimeInterval(86400 * 30).timeIntervalSince1970,
            "repeatType": "每年",
            "repeatInterval": 1,
            "isPinned": true,
            "categoryId": UUID().uuidString,
            "isNotificationEnabled": true
        ]
        
        let sampleData2: [String: Any] = [
            "id": UUID().uuidString,
            "title": "重要会议",
            "date": Date().addingTimeInterval(86400 * 7).timeIntervalSince1970,
            "repeatType": "不重复",
            "repeatInterval": 1,
            "isPinned": false,
            "categoryId": nil,
            "isNotificationEnabled": false
        ]
        
        connectivityManager.memorialDays = [
            WatchMemorialDay(from: sampleData1),
            WatchMemorialDay(from: sampleData2)
        ]
        
        return ContentView()
            .environmentObject(connectivityManager)
    }
}
#endif
