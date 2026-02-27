import SwiftUI

struct CategoryFilterView: View {
    @Binding var selectedCategoryId: UUID?
    @EnvironmentObject var categoryManager: CategoryManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 所有选项 - 只有当有分类时才显示
                if !categoryManager.categories.isEmpty {
                    AllCategoriesButton(isSelected: selectedCategoryId == nil) {
                        selectedCategoryId = nil
                        HapticManager.shared.lightTap()
                    }
                }
                
                // 分类选项
                ForEach(categoryManager.categories) { category in
                    CategoryFilterButton(
                        title: category.name,
                        color: category.swiftUIColor,
                        isSelected: selectedCategoryId == category.id
                    ) {
                        selectedCategoryId = category.id
                        HapticManager.shared.lightTap()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
        }
    }
}

struct AllCategoriesButton: View {
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        Button(action: action) {
            Text(languageManager.localizedString("All Categories"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : .appOrange)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isSelected ? Color.appOrange : Color.appOrange.opacity(0.12))
                )
                .shadow(color: isSelected ? Color.appOrange.opacity(0.3) : Color.clear, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryFilterButton: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 背景圆圈
            Circle()
                    .fill(isSelected ? color : color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                // 选中时显示对勾
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .shadow(color: isSelected ? color.opacity(0.3) : Color.black.opacity(0.08), radius: isSelected ? 6 : 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CategoryFilterView(selectedCategoryId: .constant(nil))
        .environmentObject(CategoryManager.shared)
}
