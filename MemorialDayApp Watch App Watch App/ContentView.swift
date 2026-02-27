import SwiftUI

struct ContentView: View {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    
    var sortedMemorialDays: [WatchMemorialDay] {
        // 按照iPhone端的逻辑过滤
        let filteredDays = connectivityManager.showPastEvents 
            ? connectivityManager.memorialDays 
            : connectivityManager.memorialDays.filter { $0.daysFromNow >= 0 }
        
        // 分为未过期和已过期两组
        let unexpired = filteredDays.filter { $0.daysFromNow >= 0 }
        let expired = filteredDays.filter { $0.daysFromNow < 0 }
        
        // 每组内先置顶再未置顶，都按天数升序排序
        func sortWithPinnedFirst(_ arr: [WatchMemorialDay]) -> [WatchMemorialDay] {
            let pinned = arr.filter { $0.isPinned }
            let unpinned = arr.filter { !$0.isPinned }
            
            let sortedPinned = pinned.sorted { $0.daysFromNow < $1.daysFromNow }
            let sortedUnpinned = unpinned.sorted { $0.daysFromNow < $1.daysFromNow }
            
            return sortedPinned + sortedUnpinned
        }
        
        // 未过期在前，已过期在后
        return sortWithPinnedFirst(unexpired) + sortWithPinnedFirst(expired)
    }
    
    var body: some View {
        NavigationView {
            if connectivityManager.memorialDays.isEmpty {
                // 空状态视图
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 36))
                        .foregroundColor(.orange.opacity(0.6))
                    
                    VStack(spacing: 6) {
                        Text("暂无纪念日")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if !connectivityManager.isConnected {
                            Text("正在连接iPhone...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("请在iPhone上添加")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // 显示上次同步时间
                        if let lastSync = connectivityManager.lastSyncDate {
                            Text("上次同步: \(formatSyncDate(lastSync))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                        }
                    }
                    
                    Button(action: {
                        connectivityManager.requestMemorialDays()
                    }) {
                        HStack(spacing: 4) {
                            if connectivityManager.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.6)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12))
                            }
                            Text(connectivityManager.isSyncing ? "同步中..." : "刷新")
                                .font(.system(size: 13))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(connectivityManager.isSyncing)
                }
                .padding(.horizontal, 8)
            } else {
                // 有数据时显示列表
                ScrollView {
                    LazyVStack(spacing: 8) {
                        // 下拉刷新按钮
                        RefreshControlView(isRefreshing: connectivityManager.isSyncing) {
                            connectivityManager.requestMemorialDays()
                        }
                        .padding(.top, 4)
                        // 显示同步状态和上次同步时间
                        if connectivityManager.isSyncing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("同步中...")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 6)
                        } else if let lastSync = connectivityManager.lastSyncDate {
                            Text("上次同步: \(formatSyncDate(lastSync))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 6)
                        }
                        
                        ForEach(sortedMemorialDays) { memorialDay in
                            WatchMemorialDayCard(memorialDay: memorialDay)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 8)
                }
            }
        }
        .navigationTitle("纪念日")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 应用启动时尝试后台同步
            if connectivityManager.isConnected {
                connectivityManager.requestMemorialDays()
            }
        }
    }
    
    // 格式化同步时间
    private func formatSyncDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days)天前"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)小时前"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)分钟前"
        } else {
            return "刚刚"
        }
    }
}

// 下拉刷新控件
struct RefreshControlView: View {
    let isRefreshing: Bool
    let onRefresh: () -> Void
    
    var body: some View {
        Button(action: {
            if !isRefreshing {
                onRefresh()
            }
        }) {
            HStack(spacing: 4) {
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                Text(isRefreshing ? "同步中..." : "下拉刷新")
                    .font(.system(size: 11))
            }
            .foregroundColor(.orange.opacity(0.8))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .disabled(isRefreshing)
    }
}