import Foundation
import SwiftUI

struct Category: Identifiable, Codable {
    var id = UUID()
    var name: String
    var color: String // 存储颜色的十六进制字符串
    var createdAt: Date
    
    // 可用的预定义颜色
    static let availableColors: [String] = [
        "FF6B6B", // 红色
        "4ECDC4", // 青色
        "45B7D1", // 蓝色
        "96CEB4", // 绿色
        "FECA57", // 黄色
        "FF9FF3", // 粉色
        "54A0FF", // 亮蓝色
        "5F27CD", // 紫色
        "00D2D3", // 青绿色
        "FF9F43", // 橙色
        "EE5A6F", // 深红色
        "6C5CE7", // 深紫色
        "A55EEA", // 淡紫色
        "26DE81", // 亮绿色
        "FD79A8", // 粉红色
        "FDCB6E", // 金黄色
        "6C5CE7", // 蓝紫色
        "E17055", // 橙红色
        "00B894", // 深绿色
        "0984E3"  // 深蓝色
    ]
    
    // 获取SwiftUI颜色
    var swiftUIColor: Color {
        return Color(hex: color) ?? .gray
    }
    
    init(name: String, color: String? = nil) {
        self.name = name
        self.color = color ?? Category.getRandomAvailableColor()
        self.createdAt = Date()
    }
    
    // 获取随机可用颜色（避免重复）
    static func getRandomAvailableColor(excluding usedColors: [String] = []) -> String {
        let availableColors = Category.availableColors.filter { !usedColors.contains($0) }
        return availableColors.randomElement() ?? Category.availableColors.randomElement() ?? "FF6B6B"
    }
}

// 颜色扩展，支持十六进制字符串
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hex.count == 6 {
            let scanner = Scanner(string: hex)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                let r = Double((hexNumber & 0xff0000) >> 16) / 255
                let g = Double((hexNumber & 0x00ff00) >> 8) / 255
                let b = Double(hexNumber & 0x0000ff) / 255
                
                self.init(red: r, green: g, blue: b)
                return
            }
        }
        return nil
    }
}

// 分类管理器
class CategoryManager: ObservableObject {
    static let shared = CategoryManager()
    
    @Published var categories: [Category] = []
    private var categoryIndex: [UUID: Category] = [:]
    private let saveKey = "Categories"
    
    private init() {
        loadCategories()
    }
    
    func addCategory(_ category: Category) {
        var newCategory = category
        // 确保颜色不重复
        let usedColors = categories.map { $0.color }
        if usedColors.contains(newCategory.color) {
            newCategory.color = Category.getRandomAvailableColor(excluding: usedColors)
        }
        categories.append(newCategory)
        categoryIndex[newCategory.id] = newCategory
        saveCategories()
    }
    
    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            categoryIndex[category.id] = category
            saveCategories()
        }
    }
    
    func deleteCategory(with id: UUID) {
        categories.removeAll { $0.id == id }
        categoryIndex.removeValue(forKey: id)
        saveCategories()
    }
    
    func getCategoryById(_ id: UUID?) -> Category? {
        guard let id = id else { return nil }
        if let cached = categoryIndex[id] {
            return cached
        }
        if let found = categories.first(where: { $0.id == id }) {
            categoryIndex[id] = found
            return found
        }
        return nil
    }
    
    private func saveCategories() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(categories)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("保存分类失败: \(error)")
        }
    }
    
    private func loadCategories() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            // 不创建默认分类，让用户自己创建
            categories = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            categories = try decoder.decode([Category].self, from: data)
            rebuildIndex()
        } catch {
            print("加载分类失败: \(error)")
            // 加载失败时也不创建默认分类
            categories = []
            categoryIndex = [:]
        }
    }
    
    private func rebuildIndex() {
        var index: [UUID: Category] = [:]
        index.reserveCapacity(categories.count)
        for category in categories {
            index[category.id] = category
        }
        categoryIndex = index
    }
}
