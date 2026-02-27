import SwiftUI

struct LaunchIconGenerator: View {
    var body: some View {
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
            .frame(width: 512, height: 512)
            .cornerRadius(120)
            
            // 图标内容 - 日历和时钟的组合
            ZStack {
                // 日历背景
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white)
                    .frame(width: 240, height: 240)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // 日历顶部
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appOrange)
                    .frame(width: 240, height: 60)
                    .offset(y: -90)
                
                // 日历挂钩
                HStack(spacing: 80) {
                    Circle()
                        .fill(Color(red: 0.7, green: 0.3, blue: 0.0))
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(Color(red: 0.7, green: 0.3, blue: 0.0))
                        .frame(width: 20, height: 20)
                }
                .offset(y: -90)
                
                // 日历日期
                Text("纪念日")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.appOrange)
                    .offset(y: 10)
                
                // 装饰元素 - 小星星
                ForEach(0..<5) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.3))
                        .offset(
                            x: CGFloat.random(in: -100...100),
                            y: CGFloat.random(in: -100...100)
                        )
                        .rotationEffect(.degrees(Double.random(in: 0...360)))
                }
            }
        }
        .frame(width: 512, height: 512)
    }
}

struct LaunchIconGenerator_Previews: PreviewProvider {
    static var previews: some View {
        LaunchIconGenerator()
    }
} 