# Apple Watch 纪念日应用设置指南

## 📋 前置条件

- Xcode 14.0 或更高版本
- iOS 16.0+ 和 watchOS 9.0+
- Apple Developer 账号（用于在真机上测试）

## 🚀 在 Xcode 中配置 Watch App

### 1. 添加 Watch App Target

1. 打开 `MemorialDayApp.xcodeproj` 项目
2. 选择项目名称 > 点击 "+" 按钮添加新 target
3. 选择 "watchOS" > "Watch App"
4. 配置信息：
   - Product Name: `MemorialDayApp Watch App`
   - Bundle Identifier: `com.memorialday.app.watchkitapp`
   - Include Notification Scene: ❌ (不需要)

### 2. 配置 Bundle Identifier

#### iPhone App
- Bundle ID: `com.memorialday.app`

#### Watch App  
- Bundle ID: `com.memorialday.app.watchkitapp`

### 3. 添加文件到 Watch Target

将以下文件添加到 Watch App target：
- `MemorialDayWatchApp.swift`
- `ContentView.swift`
- `WatchMemorialDay.swift`
- `WatchMemorialDayCard.swift`
- `WatchConnectivityManager.swift`
- `Info.plist`
- `Assets.xcassets`

### 4. 配置 Capabilities

#### iPhone App 需要启用：
- ✅ Background Modes > Background App Refresh
- ✅ Inter-App Audio (用于 WatchConnectivity)

#### Watch App 需要启用：
- ✅ HealthKit (如果需要)

### 5. 更新部署目标

#### iPhone App
- iOS Deployment Target: `16.0`

#### Watch App  
- watchOS Deployment Target: `9.0`

## 📱 项目文件结构

```
MemorialDayApp/
├── MemorialDayApp/                    # iPhone App
│   ├── MemorialDayApp.swift          # 已更新：集成 Watch 连接
│   ├── PhoneConnectivityManager.swift # 新增：iPhone 端连接管理
│   └── ... (其他现有文件)
│
├── MemorialDayApp Watch App/          # Watch App (全新)
│   ├── MemorialDayWatchApp.swift     # Watch App 入口
│   ├── ContentView.swift             # 主视图和详情视图
│   ├── WatchMemorialDay.swift        # Watch 数据模型
│   ├── WatchMemorialDayCard.swift    # 卡片组件
│   ├── WatchConnectivityManager.swift # Watch 端连接管理
│   ├── Info.plist                    # Watch App 配置
│   └── Assets.xcassets/              # Watch App 图标
│
└── MemorialDayApp.xcodeproj          # Xcode 项目文件
```

## 🔧 编译和运行

### 运行 iPhone 版本
1. 选择 iPhone 模拟器或真机
2. 选择 "MemorialDayApp" scheme
3. 点击运行 ▶️

### 运行 Watch 版本  
1. 选择 Watch 模拟器或配对的 Apple Watch
2. 选择 "MemorialDayApp Watch App" scheme  
3. 点击运行 ▶️

## 🧪 测试数据同步

### 测试流程
1. **在 iPhone 上运行应用** 并创建几个纪念日
2. **在 Watch 上运行应用** 查看数据是否同步
3. **在 iPhone 上修改数据** （添加、编辑、删除纪念日）
4. **在 Watch 上下拉刷新** 验证数据更新

### 预期行为
- ✅ Watch 应显示与 iPhone 相同的纪念日列表
- ✅ 卡片设计应与 iPhone 版本保持一致
- ✅ iPhone 数据变化应自动推送到 Watch
- ✅ Watch 可以主动请求数据同步

## 🎯 Watch 应用功能

### ✅ 支持的功能
- 纪念日列表展示
- 卡片详情查看
- 置顶状态显示
- 分类颜色指示
- 天数倒计时计算
- 过期状态显示
- 数据同步状态显示
- 下拉刷新

### ❌ 不支持的功能（按设计要求）
- 创建新纪念日
- 编辑现有纪念日
- 删除纪念日
- 分类管理
- 设置修改

## 🐛 常见问题

### 问题：Watch 显示"未连接"
**解决方案**：
1. 确保 iPhone 和 Watch 都在运行对应的应用
2. 确保设备已配对
3. 重启两个应用

### 问题：数据不同步
**解决方案**：
1. 在 Watch 上下拉刷新
2. 检查 Xcode 控制台的连接日志
3. 重启 iPhone 应用

### 问题：编译错误
**解决方案**：
1. 确保所有文件都正确添加到对应的 target
2. 检查 Bundle Identifier 配置
3. 确保 Deployment Target 版本正确

## 📝 开发日志

查看日志输出：
```
// iPhone 端日志前缀
"Phone: ..."

// Watch 端日志前缀  
"Watch: ..."
```

## 🎨 自定义图标

当前使用的是临时图标文件。如需自定义：

1. 准备不同尺寸的 Watch 图标
2. 替换 `Assets.xcassets/AppIcon.appiconset/` 中的文件
3. 确保文件名与 `Contents.json` 中的配置一致

## 🚀 发布准备

1. **代码签名**：配置正确的开发者证书
2. **图标准备**：创建正式的 Watch 应用图标
3. **测试**：在真机上完整测试所有功能
4. **App Store 准备**：准备 Watch 应用的截图和描述

---

通过以上配置，您就可以成功运行 Apple Watch 版本的纪念日应用，享受与 iPhone 版本完美同步的手表体验！
