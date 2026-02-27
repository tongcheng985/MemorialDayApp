import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.adaptiveBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.appOrange)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        Spacer()
                        Text("隐私政策")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.adaptivePrimaryText)
                        Spacer().frame(width: 44)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    .background(
                        Color.adaptiveCardBackground
                            .shadow(color: Color.adaptiveShadow(opacity: 0.05), radius: 5, x: 0, y: 3)
                    )
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Group {
                                Text("最后更新：2024年12月")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                
                                Text("1. 数据收集与使用")
                                    .font(.headline)
                                Text("本应用仅在您使用功能时存储必要的纪念日数据于本地设备，不会收集、上传或共享任何可识别个人身份的信息。所有数据仅用于提供倒计时和提醒功能。")
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text("2. 权限使用")
                                    .font(.headline)
                                Text("• 通知权限：仅用于发送纪念日提醒，完全在本地设备生成\n• Apple Watch 同步：仅在您的设备间传输数据，不经过外部服务器\n• 网络访问：仅在必要时获取公开的节假日信息，不包含任何个人数据")
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text("3. 通知功能")
                                    .font(.headline)
                                Text("当您开启通知功能时，应用会在纪念日前一天发送本地通知提醒。通知完全在您的设备上生成，不会向任何外部服务器发送您的纪念日信息。您可以随时在应用设置或系统设置中关闭通知功能。")
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text("4. Apple Watch 同步")
                                    .font(.headline)
                                Text("如果您使用 Apple Watch 版本，纪念日数据会通过苹果的 WatchConnectivity 框架在您的 iPhone 和 Apple Watch 之间同步。此同步完全在您的设备之间进行，不会经过任何外部服务器。")
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text("5. 本地存储")
                                    .font(.headline)
                                Text("纪念日数据保存在本地 UserDefaults，用于在应用内展示与排序。您可以随时在应用中删除这些数据。")
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text("6. 数据安全")
                                    .font(.headline)
                                Text("所有数据均存储在您的设备本地，我们采用苹果推荐的安全存储方式。应用不会将您的个人纪念日信息发送到任何外部服务器或第三方服务。")
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text("7. 变更通知")
                                    .font(.headline)
                                Text("如本政策发生变更，我们将在应用内更新本页面并标注最新日期。重大变更会在应用更新时通知用户。")
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text("8. 联系方式")
                                    .font(.headline)
                                Text("如对本隐私政策有任何疑问或建议，请通过 App Store 开发者联系方式与我们取得联系。我们承诺在收到反馈后及时回复。")
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .foregroundColor(.adaptivePrimaryText)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.adaptiveCardBackground)
                                .shadow(color: Color.adaptiveShadow(opacity: 0.05), radius: 4, x: 0, y: 2)
                        )
                        .padding(20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}


