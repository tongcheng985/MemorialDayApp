import SwiftUI

struct CategorySelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Binding var selectedCategoryId: UUID?
    @EnvironmentObject var categoryManager: CategoryManager
    @State private var showingAddCategory = false
    
    // iPad适配：最大内容宽度
    private var maxContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 720 : .infinity
    }
    
    var body: some View {
        ZStack {
            // 自适应背景
            Color.adaptiveFormBackground
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        HapticManager.shared.lightTap()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.appOrange)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddCategory = true
                        HapticManager.shared.lightTap()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.appOrange)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .frame(maxWidth: maxContentWidth)
                
                // 分类列表
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // 无分类选项
                        NoCategoryRow(
                            isSelected: selectedCategoryId == nil,
                            onSelect: {
                                selectedCategoryId = nil
                                presentationMode.wrappedValue.dismiss()
                            }
                        )
                        
                        // 分类选项
                        ForEach(categoryManager.categories) { category in
                            CategorySelectionRow(
                                category: category,
                                isSelected: selectedCategoryId == category.id,
                                onSelect: {
                                    selectedCategoryId = category.id
                                    presentationMode.wrappedValue.dismiss()
                                },
                                onDeselect: {
                                    selectedCategoryId = nil
                                }
                            )
                            .environmentObject(categoryManager)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    .frame(maxWidth: maxContentWidth)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView { newCategoryId in
                // 自动选中新创建的分类
                selectedCategoryId = newCategoryId
            }
            .environmentObject(categoryManager)
        }
        .swipeBackGesture {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct NoCategoryRow: View {
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 颜色圆圈
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 28, height: 28)
            
            // 分类名称
            Text(LanguageManager.shared.localizedString("None"))
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.adaptivePrimaryText)
            
            Spacer()
            
            // 选中状态
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.appOrange)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.appOrange.opacity(0.08) : Color.adaptiveCardBackground)
                .shadow(color: Color.adaptiveShadow(opacity: 0.06), radius: 8, x: 0, y: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

struct CategorySelectionRow: View {
    let category: Category
    let isSelected: Bool
    let onSelect: () -> Void
    let onDeselect: () -> Void
    
    @EnvironmentObject var categoryManager: CategoryManager
    @State private var dragOffset: CGSize = .zero
    @State private var showingDeleteButton = false
    
    var body: some View {
        ZStack {
            // 删除按钮背景
            HStack {
                Spacer()
                Button(action: deleteCategory) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .medium))
                        Text("删除")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color.red)
                .cornerRadius(12)
            }
            .opacity(showingDeleteButton ? 1 : 0)
            
            // 主要内容
            HStack(spacing: 16) {
                // 颜色圆圈
                Circle()
                    .fill(category.swiftUIColor)
                    .frame(width: 28, height: 28)
                
                // 分类名称（只显示，不可编辑）
                Text(category.name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.adaptivePrimaryText)
                
                Spacer()
                
                // 选中状态
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.appOrange)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.appOrange.opacity(0.08) : Color.adaptiveCardBackground)
                    .shadow(color: Color.adaptiveShadow(opacity: 0.06), radius: 8, x: 0, y: 2)
            )
            .offset(x: dragOffset.width)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // 只允许向左拖动
                        if value.translation.width < 0 {
                            dragOffset = value.translation
                            // 当拖动超过50像素时显示删除按钮
                            showingDeleteButton = value.translation.width < -50
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if value.translation.width < -100 {
                                // 拖动超过100像素时删除
                                deleteCategory()
                            } else if value.translation.width < -50 {
                                // 拖动超过50像素时保持显示删除按钮
                                dragOffset = CGSize(width: -80, height: 0)
                                showingDeleteButton = true
                            } else {
                                // 否则恢复原位
                                dragOffset = .zero
                                showingDeleteButton = false
                            }
                        }
                    }
            )
            .contentShape(Rectangle())
        }
        .onTapGesture {
            // 如果显示删除按钮，点击时隐藏删除按钮
            if showingDeleteButton {
                withAnimation(.spring()) {
                    dragOffset = .zero
                    showingDeleteButton = false
                }
            } else {
                // 如果没有显示删除按钮，点击卡片进行选择/取消选择
                if isSelected {
                    onDeselect()
                } else {
                    onSelect()
                }
            }
        }
    }
    
    private func deleteCategory() {
        categoryManager.deleteCategory(with: category.id)
        HapticManager.shared.warning()
    }
}

#Preview {
    CategorySelectionView(selectedCategoryId: .constant(nil))
        .environmentObject(CategoryManager.shared)
}
