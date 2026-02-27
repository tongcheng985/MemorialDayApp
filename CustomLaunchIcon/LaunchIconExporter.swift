import SwiftUI

struct LaunchIconExporter: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("启动图标预览")
                .font(.headline)
            
            // 图标预览
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.appOrange,
                        Color.appOrange
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 200, height: 200)
                .cornerRadius(46)
                
                // 日历图标
                VStack(spacing: 0) {
                    // 日历顶部
                    Rectangle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 100, height: 25)
                        .cornerRadius(8, corners: [.topLeft, .topRight])
                    
                    // 日历主体
                    ZStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 100, height: 90)
                            .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
                        
                        // 日期文本
                        Text("纪")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.appOrange)
                    }
                }
                
                // 装饰元素 - 小星星
                ForEach(0..<3) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .offset(
                            x: [-40, 40, 0][i],
                            y: [-40, 30, 50][i]
                        )
                }
            }
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            Spacer()
        }
        .padding()
    }
}

// 扩展用于圆角矩形的特定角
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct LaunchIconExporter_Previews: PreviewProvider {
    static var previews: some View {
        LaunchIconExporter()
    }
} 