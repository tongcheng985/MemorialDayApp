import SwiftUI

// 左滑返回手势修饰符
struct SwipeBackGesture: ViewModifier {
    @Environment(\.presentationMode) var presentationMode
    let onSwipeBack: (() -> Void)?
    
    init(onSwipeBack: (() -> Void)? = nil) {
        self.onSwipeBack = onSwipeBack
    }
    
    func body(content: Content) -> some View {
        content
            .highPriorityGesture(
                DragGesture(minimumDistance: 12)
                    .onEnded { value in
                        let fromLeftEdge = value.startLocation.x < 120
                        let horizontalEnough = value.translation.width > 35 || value.predictedEndTranslation.width > 80
                        let mostlyHorizontal = abs(value.translation.height) < 180
                        
                        if fromLeftEdge && horizontalEnough && mostlyHorizontal {
                            HapticManager.shared.lightTap()
                            if let customAction = onSwipeBack {
                                customAction()
                            } else {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
            )
    }
}

extension View {
    func swipeBackGesture(onSwipeBack: (() -> Void)? = nil) -> some View {
        self.modifier(SwipeBackGesture(onSwipeBack: onSwipeBack))
    }
}

// 专门用于NavigationView的左滑返回
struct NavigationSwipeBackGesture: ViewModifier {
    let onSwipeBack: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .highPriorityGesture(
                DragGesture(minimumDistance: 12)
                    .onEnded { value in
                        let fromLeftEdge = value.startLocation.x < 120
                        let horizontalEnough = value.translation.width > 35 || value.predictedEndTranslation.width > 80
                        let mostlyHorizontal = abs(value.translation.height) < 180
                        
                        if fromLeftEdge && horizontalEnough && mostlyHorizontal {
                            HapticManager.shared.lightTap()
                            onSwipeBack?()
                        }
                    }
            )
    }
}

extension View {
    func navigationSwipeBack(action: @escaping () -> Void) -> some View {
        self.modifier(NavigationSwipeBackGesture(onSwipeBack: action))
    }
}
