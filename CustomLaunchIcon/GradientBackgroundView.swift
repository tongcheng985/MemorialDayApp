import SwiftUI

struct GradientBackgroundView: View {
    var body: some View {
        // 创建一个渐变背景，带有动态效果
        ZStack {
            // 主渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.5, blue: 0.0),
                    Color(red: 1.0, green: 0.35, blue: 0.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            // 装饰圆形1
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 300, height: 300)
                .offset(x: -150, y: -200)
            
            // 装饰圆形2
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 200)
                .offset(x: 150, y: 250)
            
            // 装饰圆形3
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 400, height: 400)
                .offset(x: 100, y: -150)
            
            // 底部装饰波浪
            WaveShape()
                .fill(Color.white.opacity(0.1))
                .frame(height: 100)
                .offset(y: 350)
        }
    }
}

// 波浪形状
struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height * 0.50))
        
        // 创建波浪曲线
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * 4)
            let y = height * 0.50 + sine * height * 0.25
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // 完成路径
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct GradientBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        GradientBackgroundView()
    }
} 