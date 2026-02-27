# Xcode闪退和中文语言默认设置修复总结

## 问题描述

1. **Xcode打开项目时闪退**
2. **应用默认不是中文语言**
3. **构建错误：Multiple commands produce Info.plist**

## 修复方案

### 1. 修复Xcode闪退问题

**原因**：在PBXFileSystemSynchronizedRootGroup中使用了错误的explicitFileTypes语法

**修复**：
- 文件：`MemorialDayApp.xcodeproj/project.pbxproj`
- 将错误的explicitFileTypes语法改回正确的空字典格式
- 移除了可能导致Xcode解析错误的复杂文件引用

### 2. 设置应用默认为中文语言

**修改的文件和设置**：

#### A. 项目级别设置
- **文件**：`MemorialDayApp.xcodeproj/project.pbxproj`
- **修改**：
  - `developmentRegion` 从 `en` 改为 `"zh-Hans"`
  - `knownRegions` 添加 `"zh-Hans"` 并设为首位

#### B. 主应用Info.plist设置
- **文件**：`MemorialDayApp/Info.plist`
- **添加**：
  ```xml
  <key>CFBundleDevelopmentRegion</key>
  <string>zh-Hans</string>
  <key>CFBundleLocalizations</key>
  <array>
      <string>zh-Hans</string>
      <string>en</string>
  </array>
  ```

#### C. 应用代码层面设置
- **文件**：`MemorialDayApp/MemorialDayApp.swift`
- **修改**：LanguageManager初始化默认语言
  - 从 `AppLanguage.system.rawValue` 改为 `AppLanguage.simplifiedChinese.rawValue`
  - 从 `.system` 改为 `.simplifiedChinese`

#### D. Watch应用设置
- **文件**：`MemorialDayApp Watch App Watch App/Info.plist`
- **修改**：
  ```xml
  <key>CFBundleDevelopmentRegion</key>
  <string>zh-Hans</string>
  ```

### 3. 修复构建冲突问题

**原因**：文件系统同步组与自定义Info.plist文件产生冲突

**最终修复方案**：
- **文件**：`MemorialDayApp.xcodeproj/project.pbxproj`
- **改回自动生成Info.plist**：
  - `GENERATE_INFOPLIST_FILE = YES`
  - 删除自定义Info.plist文件
- **通过INFOPLIST_KEY设置所有必要的值**：
  - `INFOPLIST_KEY_CFBundleDisplayName = "MemorialDayApp Watch App"`
  - `INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown"`
  - `INFOPLIST_KEY_WKCompanionAppBundleIdentifier = com.tongcheng.anniversaryapp`
  - `INFOPLIST_KEY_WKRunsIndependentlyOfCompanionApp = YES`
  - `INFOPLIST_KEY_CFBundleIconName = AppIcon`
  - `INFOPLIST_KEY_CFBundleIconFiles` = 所有watch图标文件
  - `INFOPLIST_KEY_WKApplication = YES`
  - `INFOPLIST_KEY_CFBundleDevelopmentRegion = "zh-Hans"`

## 修复效果

1. ✅ **Xcode不再闪退** - 项目可以正常打开和编辑
2. ✅ **应用默认中文** - 首次安装时直接显示中文界面
3. ✅ **构建成功** - 解决了Info.plist冲突问题
4. ✅ **Watch应用图标** - 之前的CFBundleIconFiles问题也已解决

## 技术要点

### 语言优先级设置
应用会按以下优先级确定语言：
1. 用户手动选择的语言（保存在UserDefaults中）
2. 默认语言：简体中文（代码中设置）
3. 系统语言（作为备选）

### Info.plist vs INFOPLIST_KEY
- 使用自定义Info.plist文件时，不能同时使用INFOPLIST_KEY设置
- INFOPLIST_KEY只在GENERATE_INFOPLIST_FILE=YES时有效
- 自定义Info.plist提供了更好的控制和兼容性

### 本地化最佳实践
- 项目级developmentRegion设置影响Xcode的默认行为
- Info.plist中的CFBundleDevelopmentRegion影响应用运行时的语言选择
- 代码中的LanguageManager提供了用户级别的语言控制

## 验证方法

1. **Xcode打开测试**：确认Xcode能正常打开项目不闪退
2. **构建测试**：确认项目能成功构建，无Info.plist冲突
3. **语言测试**：
   - 删除应用重新安装，确认默认显示中文
   - 在语言设置中切换语言，确认功能正常
   - 确认Watch应用也使用正确的语言设置

所有问题现已修复，项目可以正常使用。
