import SwiftUI

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
    static let regionChanged = Notification.Name("regionChanged")
}

class ColorUtil {
    static func color(from colorName: String) -> Color {
        let normalizedName = colorName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch normalizedName {
        case "红", "紅", "红色", "紅色", "虹", "red":
            return .red
        case "蓝", "藍", "蓝色", "藍色", "蘭", "lan", "blue":
            return .blue
        case "绿", "綠", "绿色", "綠色", "green":
            return .green
        case "黄", "黃", "黄色", "黃色", "皇", "yellow":
            return .yellow
        case "橙", "橙色", "orange":
            return .appOrange
        case "紫", "紫色", "purple":
            return .purple
        case "粉", "粉色", "pink":
            return .pink
        case "灰", "灰色", "gray", "grey":
            return .gray
        case "棕", "棕色", "brown":
            return .brown
        case "白", "白色", "white":
            return .white
        case "黑", "黑色", "black":
            return .black
        case "随机", "隨機", "random":
            return randomColor()
        default:
            return randomColor()
        }
    }
    
    static func randomColor() -> Color {
        let colors: [Color] = [.red, .blue, .green, .yellow, .appOrange, .purple, .pink]
        return colors.randomElement() ?? .appOrange
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var store: MemorialDayStore
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @AppStorage("showHolidayCountdown") private var showHolidayCountdown: Bool = false
    
    @State private var showingLanguageSheet = false
    @State private var showingThemeSheet = false
    
    private var maxContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 720 : .infinity
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                            HapticManager.shared.lightTap()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.appOrange)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .frame(maxWidth: maxContentWidth)
                    .background(
                        Color.adaptiveCardBackground
                            .shadow(color: Color.adaptiveShadow(opacity: 0.05), radius: 5, x: 0, y: 3)
                    )
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 6) {
                                VStack(spacing: 0) {
                                    Toggle(isOn: Binding(
                                        get: { store.showPastEvents },
                                        set: { newValue in
                                            store.setShowPastEvents(newValue)
                                            HapticManager.shared.lightTap()
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                presentationMode.wrappedValue.dismiss()
                                            }
                                        }
                                    )) {
                                        Text(LanguageManager.shared.localizedString("Past Events"))
                                            .font(.body)
                                            .foregroundColor(.adaptivePrimaryText)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    
                                    Divider().background(Color.adaptiveSeparator)
                                    
                                    Toggle(isOn: $showHolidayCountdown) {
                                        Text(LanguageManager.shared.localizedString("Legal Holidays"))
                                            .font(.body)
                                            .foregroundColor(.adaptivePrimaryText)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    
                                    Divider().background(Color.adaptiveSeparator)
                                    
                                    Button(action: {
                                        showingLanguageSheet = true
                                        HapticManager.shared.lightTap()
                                    }) {
                                        HStack {
                                            Text(LanguageManager.shared.localizedString("Language"))
                                                .font(.body)
                                                .foregroundColor(.adaptivePrimaryText)
                                            Spacer()
                                            Text(languageManager.currentLanguage.displayName)
                                                .font(.body)
                                                .foregroundColor(.adaptiveSecondaryText)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(.adaptiveSecondaryText)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    
                                    Divider().background(Color.adaptiveSeparator)
                                    
                                    Button(action: {
                                        showingThemeSheet = true
                                        HapticManager.shared.lightTap()
                                    }) {
                                        HStack {
                                            Text(LanguageManager.shared.localizedString("Theme Color"))
                                                .font(.body)
                                                .foregroundColor(.adaptivePrimaryText)
                                            Spacer()
                                            Circle()
                                                .fill(themeManager.currentTheme.color)
                                                .frame(width: 24, height: 24)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(.adaptiveSecondaryText)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.horizontal, 20)
                            .frame(maxWidth: maxContentWidth)
                            
                            Spacer(minLength: 40)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationBarHidden(true)
            .swipeBackGesture {
                presentationMode.wrappedValue.dismiss()
            }
            .onChange(of: showHolidayCountdown) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .sheet(isPresented: $showingLanguageSheet) {
                LanguageSettingsView()
                    .environmentObject(languageManager)
                    .presentationDetents(horizontalSizeClass == .regular ? [.fraction(0.75), .large] : [.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingThemeSheet) {
                ThemeSelectionView()
                    .environmentObject(themeManager)
                    .presentationDetents(horizontalSizeClass == .regular ? [.fraction(0.8), .large] : [.large])
                    .presentationDragIndicator(.visible)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("themeChanged"))) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct ThemeSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTheme: AppTheme
    
    private var maxContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 720 : .infinity
    }
    
    init() {
        _selectedTheme = State(initialValue: ThemeManager.shared.currentTheme)
    }
    
    var body: some View {
        ZStack {
            Color.adaptiveFormBackground
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        themeManager.currentTheme = selectedTheme
                        HapticManager.shared.lightTap()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(selectedTheme.color)
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
                        ForEach(AppTheme.allCases) { theme in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTheme = theme
                                    themeManager.currentTheme = theme
                                }
                                HapticManager.shared.lightTap()
                            }) {
                                themeRow(theme, isOn: selectedTheme == theme)
                            }
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
        .onDisappear {
            themeManager.currentTheme = selectedTheme
        }
    }
    
    private func themeRow(_ theme: AppTheme, isOn: Bool) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(theme.color)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(isOn ? Color.white : Color.clear, lineWidth: 3)
                )
                .shadow(color: isOn ? theme.color.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 2)
            
            Text(theme.displayName)
                .font(.body)
                .foregroundColor(.adaptivePrimaryText)
            
            Spacer()
            
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .foregroundColor(theme.color)
                .font(.system(size: 22))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isOn ? theme.color.opacity(0.08) : Color.clear)
        )
        .scaleEffect(isOn ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
    }
}
