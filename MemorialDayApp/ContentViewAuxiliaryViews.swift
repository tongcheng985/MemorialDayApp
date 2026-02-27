import SwiftUI
import UIKit

struct VoiceFloatingButtonView: View {
    let onTap: () -> Void
    @State private var isDragging = false
    @State private var showDraggableHint: Bool = false
    @State private var isPressing = false
    
    @AppStorage("floatingButtonIsLeftSide") var isLeftSide: Bool = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        buttonContent
            .scaleEffect(isPressing ? 0.95 : 1.0)
            .shadow(
                color: getShadowColor(),
                radius: isDragging ? 15 : (isPressing ? 12 : 10),
                x: 0,
                y: isDragging ? 8 : (isPressing ? 6 : 5)
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging && abs(value.translation.width) < 5 && abs(value.translation.height) < 5 {
                            isPressing = true
                        }
                        if abs(value.translation.width) > 10 || abs(value.translation.height) > 10 {
                            handleDragChange(value)
                        }
                    }
                    .onEnded { value in
                        isPressing = false
                        if abs(value.translation.width) > 10 {
                            handleDragEnd(value)
                        } else {
                            handleButtonTap()
                        }
                    }
            )
    }
    
    private var buttonContent: some View {
        ZStack {
            Circle()
                .fill(themeManager.currentTheme.color)
                .overlay(
                    Circle()
                        .stroke(getStrokeColor(), lineWidth: isDragging ? 3 : 1.5)
                )
            
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
            
            if isDragging || showDraggableHint {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 0)
            }
        }
        .frame(width: 70, height: 70)
    }
    
    private func getStrokeColor() -> Color {
        Color.white.opacity(isDragging || showDraggableHint ? 0.8 : 0.3)
    }
    
    private func getShadowColor() -> Color {
        themeManager.currentTheme.color.opacity(isDragging ? 0.5 : 0.35)
    }
    
    private func handleButtonTap() {
        onTap()
    }
    
    private func handleDragChange(_ value: DragGesture.Value) {
        isPressing = false
        withAnimation(.spring()) {
            isDragging = true
            showDraggableHint = true
        }
    }
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        let screenWidth = UIScreen.main.bounds.width
        let horizontalTranslation = value.translation.width
        let movementThreshold = screenWidth * 0.1
        
        if horizontalTranslation > movementThreshold {
            withAnimation(.spring()) {
                isLeftSide = false
            }
            provideSwitchFeedback()
        } else if horizontalTranslation < -movementThreshold {
            withAnimation(.spring()) {
                isLeftSide = true
            }
            provideSwitchFeedback()
        }
        
        withAnimation(.spring()) {
            isDragging = false
        }
    }
    
    private func provideSwitchFeedback() {
        DispatchQueue.main.async {
            let generator1 = UIImpactFeedbackGenerator(style: .rigid)
            generator1.impactOccurred(intensity: 1.0)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let generator2 = UIImpactFeedbackGenerator(style: .soft)
                generator2.impactOccurred(intensity: 0.8)
            }
        }
    }
}

struct FastScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct LanguageSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedLanguage: AppLanguage
    
    private var maxContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 720 : .infinity
    }
    
    init() {
        _selectedLanguage = State(initialValue: LanguageManager.shared.currentLanguage)
    }
    
    var body: some View {
        ZStack {
            Color.adaptiveFormBackground
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        languageManager.currentLanguage = selectedLanguage
                        HapticManager.shared.lightTap()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.appOrange)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .frame(maxWidth: maxContentWidth)

                VStack(spacing: 24) {
                    VStack(spacing: 14) {
                        Button(action: { selectedLanguage = .system }) {
                            languageRow(LanguageManager.shared.localizedString("Follow System"), subtitle: nil, isOn: selectedLanguage == .system)
                        }
                        Button(action: { selectedLanguage = .simplifiedChinese }) {
                            languageRow(LanguageManager.shared.localizedString("Simplified Chinese"), subtitle: nil, isOn: selectedLanguage == .simplifiedChinese)
                        }
                        Button(action: { selectedLanguage = .traditionalChinese }) {
                            languageRow(LanguageManager.shared.localizedString("Traditional Chinese"), subtitle: nil, isOn: selectedLanguage == .traditionalChinese)
                        }
                        Button(action: { selectedLanguage = .english }) {
                            languageRow(LanguageManager.shared.localizedString("English"), subtitle: nil, isOn: selectedLanguage == .english)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: maxContentWidth)
                    
                    Spacer()
                }
                .padding(.top, 20)
                .frame(maxWidth: .infinity)
            }
        }
        .swipeBackGesture {
            languageManager.currentLanguage = selectedLanguage
            presentationMode.wrappedValue.dismiss()
        }
        .onAppear {
            selectedLanguage = languageManager.currentLanguage
        }
        .onDisappear {
            languageManager.currentLanguage = selectedLanguage
        }
    }
    
    private func languageRow(_ title: String, subtitle: String?, isOn: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.adaptivePrimaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.adaptiveSecondaryText)
                }
            }
            
            Spacer()
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .foregroundColor(.appOrange)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}
