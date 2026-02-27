# 通知功能实现总结

## 功能描述
在置顶按钮下方添加了通知开关按钮，实现了以下功能：
1. 当按钮开启时自动保存
2. 在纪念日前一天上午9点自动提醒用户

## 添加的文件

### 1. NotificationManager.swift
新增的通知管理器，负责：
- 请求和管理通知权限
- 调度和管理纪念日通知
- 提供通知相关的工具方法

主要功能：
- `requestNotificationPermission()`: 请求通知权限
- `scheduleNotificationForMemorialDay()`: 为纪念日安排通知
- `updateNotificationForMemorialDay()`: 更新纪念日的通知状态
- `removeNotificationForMemorialDay()`: 移除纪念日的通知

## 修改的文件

### 1. MemorialDay.swift
- 添加了 `isNotificationEnabled: Bool` 属性来记录通知开关状态
- 更新了编码/解码方法以支持新字段

### 2. MemorialDayFormView.swift  
- 添加了通知开关UI（在置顶按钮下方）
- 添加了通知权限请求逻辑
- 当用户开启通知但权限未授予时，显示权限请求弹窗

### 3. AddMemorialDayView.swift
- 添加了 `isNotificationEnabled` 状态变量
- 在保存时调度通知（如果启用）
- 传递通知状态给 MemorialDayFormView

### 4. EditMemorialDayView.swift
- 添加了 `isNotificationEnabled` 状态变量并初始化
- 实现了通知开关变化时的自动保存
- 更新通知调度当开关状态改变时
- 删除纪念日时自动清除相关通知

### 5. MemorialDayApp.swift
- 添加了通知相关的多语言支持：
  - "Remind me one day before" / "提前一天提醒"
  - "Memorial Day Reminder" / "纪念日提醒" 
  - "Tomorrow is %@" / "明天是%@"
  - "Notification Permission Required" / "需要通知权限"
  - "Please allow notifications in Settings to enable reminders." / "请在设置中允许通知以启用提醒功能。"
  - "Go to Settings" / "去设置"

### 6. project.pbxproj
- 添加了 NotificationManager.swift 文件到Xcode项目中

## 功能特性

### 1. 自动保存
- 在编辑页面中，当用户切换通知开关时自动保存
- 无需手动点击保存按钮即可保存通知设置

### 2. 智能通知调度
- 通知在纪念日前一天上午9点发送
- 对于重复纪念日，自动计算下一个纪念日并调度通知
- 如果纪念日已过，不会调度通知

### 3. 权限管理
- 检查通知权限状态
- 引导用户授权通知权限
- 权限被拒绝时提示用户到设置中手动开启

### 4. 通知内容
- 通知标题："纪念日提醒"
- 通知内容："明天是[纪念日名称]"
- 支持多语言显示

### 5. 通知管理
- 开启通知时自动调度
- 关闭通知时自动取消
- 删除纪念日时自动清除相关通知
- 编辑纪念日时重新调度通知

## 用户体验

1. **一键开启**: 用户只需在编辑页面开启通知开关，所有设置自动完成
2. **无感保存**: 开关状态变化时自动保存，无需额外操作
3. **智能提醒**: 系统自动在合适的时间发送提醒
4. **多语言支持**: 界面和通知内容都支持中英文显示

## 技术实现

### 通知调度逻辑
```swift
// 计算提醒日期（纪念日前一天）
guard let reminderDate = calendar.date(byAdding: .day, value: -1, to: targetDate)

// 设置通知时间（上午9点）
var dateComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
dateComponents.hour = 9
dateComponents.minute = 0

// 创建触发器
let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
```

### 自动保存机制
```swift
.onChange(of: isNotificationEnabled) { newValue in
    // 通知开关改变时自动保存
    let updated = MemorialDay(/* 使用当前所有状态 */)
    store.updateMemorialDay(updated)
    // 更新通知调度
    NotificationManager.shared.updateNotificationForMemorialDay(updated)
}
```

这个功能实现了完整的通知管理系统，为用户提供了便捷的纪念日提醒服务。
