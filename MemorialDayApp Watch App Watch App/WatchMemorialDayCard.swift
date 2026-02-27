import SwiftUI

struct WatchMemorialDayCard: View {
    let memorialDay: WatchMemorialDay
    @Environment(\.colorScheme) var colorScheme
    
    // 根据深浅色模式选择背景色
    private var backgroundColor: Color {
        colorScheme == .dark 
            ? Color(white: 0.15) 
            : Color(red: 1.0, green: 0.98, blue: 0.96)
    }
    
    private var borderColor: Color {
        colorScheme == .dark
            ? Color.orange.opacity(0.3)
            : Color.orange.opacity(0.15)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧：纪念日名称
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    // 置顶图标
                    if memorialDay.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                    }
                    
                    Text(memorialDay.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                
                // 如果是今天，显示特殊文字
                if memorialDay.daysFromNow == 0 {
                    Text("今天")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 右侧：天数显示（与手机端颜色风格一致）
            VStack(spacing: 2) {
                Text("\(abs(memorialDay.daysFromNow))")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(memorialDay.daysFromNow == 0 ? .orange : 
                                   (memorialDay.daysFromNow > 0 ? .orange : .secondary))
                
                Text(memorialDay.daysFromNow == 0 ? "今天" : 
                     (memorialDay.daysFromNow > 0 ? "天后" : "天前"))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 44)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}