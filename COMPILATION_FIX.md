# 编译错误修复指南

## 问题描述
出现以下编译错误：
- `Cannot find 'LanguageManager' in scope`
- `Cannot find 'HolidayService' in scope`
- `Value of type 'some View' has no member 'swipeBackGesture'`

## 解决方案

### 1. 确保所有新文件已添加到 Xcode 项目

需要手动将以下文件添加到 Xcode 项目中：

**必须添加的文件：**
- `LanguageManager.swift`
- `HolidayService.swift` (已更新版本)
- `LanguageSelectionView.swift`
- `SwipeBackGesture.swift`

### 2. 添加文件到 Xcode 项目的步骤

1. **打开 Xcode 项目**
2. **右键点击项目导航器中的 `MemorialDayApp` 文件夹**
3. **选择 "Add Files to 'MemorialDayApp'"**
4. **浏览到项目目录，选择以下文件：**
   - `LanguageManager.swift`
   - `LanguageSelectionView.swift`
   - `SwipeBackGesture.swift`
5. **确保在弹出的对话框中：**
   - ✅ "Copy items if needed" 被选中
   - ✅ "Add to target" 中的 `MemorialDayApp` 被选中
6. **点击 "Add"**

### 3. 验证文件已正确添加

在 Xcode 项目导航器中，确保你能看到所有新文件，并且它们显示为蓝色（不是灰色）。

### 4. 清理并重新构建

1. **按 `Cmd + Shift + K` 清理项目**
2. **按 `Cmd + B` 重新构建项目**

### 5. 如果问题仍然存在

如果上述步骤后仍有编译错误，可以尝试：

1. **重启 Xcode**
2. **删除 DerivedData：**
   - 关闭 Xcode
   - 打开 Finder，按 `Cmd + Shift + G`
   - 输入：`~/Library/Developer/Xcode/DerivedData`
   - 删除与项目相关的文件夹
   - 重新打开 Xcode 和项目

### 6. 检查 Target Membership

对于每个新添加的文件：
1. **选择文件**
2. **在右侧面板中找到 "Target Membership"**
3. **确保 `MemorialDayApp` 被选中**

## 文件位置确认

确保以下文件都在正确的位置：

```
MemorialDayApp/
├── MemorialDayApp/
│   ├── LanguageManager.swift         ← 新文件
│   ├── HolidayService.swift          ← 已更新
│   ├── LanguageSelectionView.swift   ← 新文件
│   ├── SwipeBackGesture.swift        ← 新文件
│   ├── MemorialDayApp.swift          ← 已更新
│   ├── ContentView.swift             ← 已更新
│   ├── EditMemorialDayView.swift     ← 已更新
│   └── AddMemorialDayView.swift      ← 已更新
```

## 完成后的功能

修复编译错误后，你将获得：
- ✅ 语言选择功能（英语、简体中文、繁体中文）
- ✅ 法定节假日网络同步
- ✅ 左滑返回手势
- ✅ 跟随系统语言设置

如果仍有问题，请检查 Xcode 控制台的具体错误信息。
