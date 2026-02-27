import SwiftUI

struct CategoryManagementView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @StateObject private var categoryManager = CategoryManager.shared
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
                        ForEach(categoryManager.categories) { category in
                            CategoryRowView(category: category)
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
            AddCategoryView()
                .environmentObject(categoryManager)
        }
        .swipeBackGesture {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct CategoryRowView: View {
    let category: Category
    @EnvironmentObject var categoryManager: CategoryManager
    @State private var showingEditSheet = false
    
    var body: some View {
        Button(action: {
            showingEditSheet = true
            HapticManager.shared.lightTap()
        }) {
            HStack(spacing: 16) {
                // 颜色圆圈
                Circle()
                    .fill(category.swiftUIColor)
                    .frame(width: 24, height: 24)
                
                // 分类名称
                Text(category.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.adaptivePrimaryText)
                
                Spacer()
                
                // 右箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.adaptiveSecondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.adaptiveCardBackground)
                    .shadow(color: Color.adaptiveShadow(opacity: 0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingEditSheet) {
            EditCategoryView(category: category)
                .environmentObject(categoryManager)
        }
    }
}

struct AddCategoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var categoryManager: CategoryManager
    @State private var categoryName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @FocusState private var nameFieldFocused: Bool
    
    var onCategoryCreated: ((UUID) -> Void)?
    
    init(onCategoryCreated: ((UUID) -> Void)? = nil) {
        self.onCategoryCreated = onCategoryCreated
    }
    
    // iPad适配：最大内容宽度
    private var maxContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 720 : .infinity
    }
    
    var body: some View {
        ZStack {
            Color.adaptiveFormBackground
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    nameFieldFocused = false
                }
            
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .frame(maxWidth: maxContentWidth)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 标题输入
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack(alignment: .leading) {
                                if categoryName.isEmpty {
                                    Text(LanguageManager.shared.localizedString("Category Name"))
                                        .foregroundColor(.adaptiveSecondaryText.opacity(0.6))
                                        .padding(.horizontal, 16)
                                }
                                TextEditor(text: Binding(
                                    get: { String(categoryName.prefix(20)) },
                                    set: { newValue in
                                        categoryName = String(newValue.prefix(20))
                                    }
                                ))
                                .font(.body)
                                .frame(minHeight: 52)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .background(Color.clear)
                                .scrollContentBackground(.hidden)
                                .focused($nameFieldFocused)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color(UIColor.separator).opacity(0.35), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    .padding(.bottom, 30)
                    .frame(maxWidth: maxContentWidth)
                }
                
                // 底部保存按钮
                Button(action: {
                    saveCategory()
                }) {
                    Text(LanguageManager.shared.localizedString("Save"))
                }
                .buttonStyle(PrimaryButtonStyle(font: Font.body))
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: maxContentWidth)
            }
            .frame(maxWidth: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(LanguageManager.shared.localizedString("Done")) {
                    nameFieldFocused = false
                }
                .foregroundColor(.appOrange)
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(LanguageManager.shared.localizedString("Warning")), message: Text(alertMessage), dismissButton: .default(Text(LanguageManager.shared.localizedString("Confirm"))))
        }
        .swipeBackGesture {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    func saveCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            alertMessage = LanguageManager.shared.localizedString("Category name cannot be empty")
            showingAlert = true
            HapticManager.shared.error()
            return
        }
        
        // 检查名称是否重复
        if categoryManager.categories.contains(where: { $0.name == trimmedName }) {
            alertMessage = LanguageManager.shared.localizedString("Category name already exists")
            showingAlert = true
            HapticManager.shared.error()
            return
        }
        
        let newCategory = Category(name: trimmedName)
        categoryManager.addCategory(newCategory)
        
        // 调用回调通知分类创建完成
        onCategoryCreated?(newCategory.id)
        
        HapticManager.shared.success()
        presentationMode.wrappedValue.dismiss()
    }
}

struct EditCategoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var categoryManager: CategoryManager
    let category: Category
    @State private var categoryName: String
    @State private var showingDeleteAlert = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @FocusState private var nameFieldFocused: Bool
    
    init(category: Category) {
        self.category = category
        _categoryName = State(initialValue: category.name)
    }
    
    // iPad适配：最大内容宽度
    private var maxContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 720 : .infinity
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.98)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    nameFieldFocused = false
                }
            
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
                        showingDeleteAlert = true
                        HapticManager.shared.warning()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .frame(maxWidth: maxContentWidth)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 颜色预览
                        HStack {
                            Text(LanguageManager.shared.localizedString("Color"))
                                .font(.body)
                                .foregroundColor(.adaptivePrimaryText)
                            
                            Spacer()
                            
                            Circle()
                                .fill(category.swiftUIColor)
                                .frame(width: 32, height: 32)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // 标题输入
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack(alignment: .leading) {
                                if categoryName.isEmpty {
                                    Text(LanguageManager.shared.localizedString("Category Name"))
                                        .foregroundColor(Color(UIColor.systemGray3))
                                        .padding(.horizontal, 16)
                                }
                                TextEditor(text: Binding(
                                    get: { String(categoryName.prefix(20)) },
                                    set: { newValue in
                                        categoryName = String(newValue.prefix(20))
                                    }
                                ))
                                .font(.body)
                                .frame(minHeight: 52)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .background(Color.clear)
                                .scrollContentBackground(.hidden)
                                .focused($nameFieldFocused)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color(UIColor.separator).opacity(0.35), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                    .frame(maxWidth: maxContentWidth)
                }
                
                // 底部保存按钮
                Button(action: {
                    saveCategory()
                }) {
                    Text(LanguageManager.shared.localizedString("Save"))
                }
                .buttonStyle(PrimaryButtonStyle(font: Font.body))
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: maxContentWidth)
            }
            .frame(maxWidth: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(LanguageManager.shared.localizedString("Done")) {
                    nameFieldFocused = false
                }
                .foregroundColor(.appOrange)
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(LanguageManager.shared.localizedString("Warning")), message: Text(alertMessage), dismissButton: .default(Text(LanguageManager.shared.localizedString("Confirm"))))
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text(LanguageManager.shared.localizedString("Delete Category")),
                message: Text(LanguageManager.shared.localizedString("Are you sure you want to delete this category?")),
                primaryButton: .destructive(Text(LanguageManager.shared.localizedString("Delete"))) {
                    deleteCategory()
                },
                secondaryButton: .cancel(Text(LanguageManager.shared.localizedString("Cancel")))
            )
        }
        .swipeBackGesture {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    func saveCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            alertMessage = LanguageManager.shared.localizedString("Category name cannot be empty")
            showingAlert = true
            HapticManager.shared.error()
            return
        }
        
        // 检查名称是否与其他分类重复
        if categoryManager.categories.contains(where: { $0.name == trimmedName && $0.id != category.id }) {
            alertMessage = LanguageManager.shared.localizedString("Category name already exists")
            showingAlert = true
            HapticManager.shared.error()
            return
        }
        
        var updatedCategory = category
        updatedCategory.name = trimmedName
        categoryManager.updateCategory(updatedCategory)
        
        HapticManager.shared.success()
        presentationMode.wrappedValue.dismiss()
    }
    
    func deleteCategory() {
        categoryManager.deleteCategory(with: category.id)
        HapticManager.shared.warning()
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    CategoryManagementView()
        .environmentObject(CategoryManager.shared)
}
