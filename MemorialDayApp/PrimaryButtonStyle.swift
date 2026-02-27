import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 12
    var font: Font = .system(size: 17, weight: .semibold)
    init(cornerRadius: CGFloat = 12, font: Font = .system(size: 17, weight: .semibold)) {
        self.cornerRadius = cornerRadius
        self.font = font
    }
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.appOrange)
            .cornerRadius(cornerRadius)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
} 