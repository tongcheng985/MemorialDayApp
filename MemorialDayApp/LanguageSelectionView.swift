import SwiftUI

struct LanguageSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        NavigationView {
            mainContent
        }
        .swipeBackGesture()
    }
    
    private var mainContent: some View {
        ZStack {
            backgroundColor
            contentView
        }
        .navigationBarHidden(true)
    }
    
    private var backgroundColor: some View {
        Color(red: 0.98, green: 0.98, blue: 0.98)
            .edgesIgnoringSafeArea(.all)
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            navigationBar
            scrollContent
        }
    }
    
    private var navigationBar: some View {
        HStack {
            backButton
            Spacer()
            titleText
            Spacer()
            placeholderView
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(navigationBackground)
    }
    
    private var backButton: some View {
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
    }
    
    private var titleText: some View {
        Text(LanguageManager.shared.localizedString("Language"))
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.black)
    }
    
    private var placeholderView: some View {
        Color.clear
            .frame(width: 44, height: 44)
    }
    
    private var navigationBackground: some View {
        Color.white
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
    }
    
    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                languageList
                descriptionSection
                Spacer(minLength: 40)
            }
        }
    }
    
    private var languageList: some View {
        VStack(spacing: 0) {
            ForEach(AppLanguage.allCases, id: \.rawValue) { language in
                languageRow(for: language)
                if language != AppLanguage.allCases.last {
                    Divider()
                        .padding(.leading, 20)
                }
            }
        }
        .background(listBackground)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private func languageRow(for language: AppLanguage) -> some View {
        Button(action: {
            selectLanguage(language)
        }) {
            HStack {
                languageInfo(for: language)
                Spacer()
                selectionIndicator(for: language)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func languageInfo(for language: AppLanguage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(language.displayName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
            
            if language == .system {
                Text("Follow system language settings")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func selectionIndicator(for language: AppLanguage) -> some View {
        Group {
            if languageManager.currentLanguage == language {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appOrange)
            }
        }
    }
    
    private var listBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
            
            Text("• Select \"Follow System\" to automatically use device language settings")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Text("• Manual language selection will override system settings")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Text("• Language changes will take effect the next time you launch the app")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }
    
    private func selectLanguage(_ language: AppLanguage) {
        guard languageManager.currentLanguage != language else { return }
        
        languageManager.currentLanguage = language
        HapticManager.shared.success()
        
        // 延迟关闭，让用户看到选中状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    LanguageSelectionView()
        .environmentObject(LanguageManager.shared)
}
