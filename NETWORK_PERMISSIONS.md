# 网络权限配置说明

## 需要在 Info.plist 中添加的网络权限配置

为了支持法定节假日的自动同步功能，需要在 `Info.plist` 文件中添加以下配置：

### 1. 网络使用描述
```xml
<key>NSAppTransportSecurityExceptionDomains</key>
<dict>
    <key>date.nager.at</key>
    <dict>
        <key>NSExceptionAllowsInsecureHTTPLoads</key>
        <true/>
        <key>NSExceptionRequiresForwardSecrecy</key>
        <false/>
    </dict>
</dict>
```

### 2. 应用传输安全设置（可选，如果需要支持更多API）
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>date.nager.at</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.0</string>
        </dict>
    </dict>
</dict>
```

### 3. 在项目设置中启用网络功能
在 Xcode 项目的 "Signing & Capabilities" 标签页中，确保以下功能已启用：
- Outgoing Connections (Client)

### 4. 网络使用说明文字（用于App Store）
"应用需要网络权限以自动同步最新的法定节假日信息，为用户提供准确的假期倒计时功能。"

## 功能说明

1. **自动同步**：应用启动时自动检查是否需要同步当前年份的法定节假日
2. **年份检测**：当检测到年份变化时，自动同步新年份的法定节假日
3. **备用数据**：如果网络同步失败，使用本地预设的法定节假日数据
4. **用户控制**：用户可以通过设置开关控制是否显示法定节假日倒计时

## API 源
- 主要API：https://date.nager.at/api/v3/PublicHolidays/{year}/CN
- 备用方案：本地预设数据
