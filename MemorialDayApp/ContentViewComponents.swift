import SwiftUI
import Foundation

struct MemorialDayCardViewModel: Identifiable, Equatable {
    let id: UUID
    let title: String
    let isPinned: Bool
    let days: Int
    let themeId: String
    let categoryColorHex: String?
    let daysText: String
    let passedText: String
    let isSelected: Bool
    
    var isOverdue: Bool { days < 0 }
    
    var clampedTitle: String {
        let resolved = title.isEmpty ? "未命名纪念日" : title
        return resolved.count > 28 ? String(resolved.prefix(28)) : resolved
    }
}

struct MemorialDayCardView: View, Equatable {
    let viewModel: MemorialDayCardViewModel
    
    static func == (lhs: MemorialDayCardView, rhs: MemorialDayCardView) -> Bool {
        lhs.viewModel == rhs.viewModel
    }
    
    private var themeColor: Color {
        AppTheme(rawValue: viewModel.themeId)?.color ?? Color.appOrange
    }
    
    private var categoryColor: Color {
        if let hex = viewModel.categoryColorHex {
            return Color(hex: hex) ?? .clear
        }
        return .clear
    }
    
    var body: some View {
        let days = viewModel.days
        let isOverdue = viewModel.isOverdue
        let statusColor = isOverdue ? Color.adaptiveOverdueText : themeColor
        let cardBase = isOverdue ? Color.adaptiveOverdueBackground : Color.adaptiveCardBackground
        let metaText = isOverdue ? viewModel.passedText.uppercased() : "COUNTDOWN"
        
        HStack(spacing: 12) {
            if categoryColor != .clear {
                RoundedRectangle(cornerRadius: 4)
                    .fill(categoryColor)
                    .frame(width: 6)
                    .padding(.vertical, 6)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                if viewModel.isPinned {
                    Text(LanguageManager.shared.localizedString("Pin").uppercased())
                        .font(.system(size: 10, weight: .black))
                        .kerning(1.0)
                        .foregroundColor(statusColor)
                }
                
                Text(viewModel.clampedTitle)
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundColor(.adaptivePrimaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(metaText)
                    .font(.system(size: 10, weight: .black))
                    .kerning(1.2)
                    .foregroundColor(statusColor.opacity(0.9))
            }
            
            Spacer(minLength: 4)
            
            VStack(alignment: .trailing, spacing: 2) {
                if isOverdue {
                    Text("\(abs(days))")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(statusColor)
                    Text(viewModel.daysText.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .kerning(1.0)
                        .foregroundColor(statusColor.opacity(0.85))
                } else {
                    Text("\(days)")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(statusColor)
                    Text(viewModel.daysText.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .kerning(1.0)
                        .foregroundColor(.adaptiveSecondaryText)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBase)
                .shadow(color: Color.adaptiveShadow(opacity: 0.07), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [statusColor.opacity(0.08), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    viewModel.isSelected ? statusColor.opacity(0.45) : Color.adaptiveSeparator.opacity(0.16),
                    lineWidth: viewModel.isSelected ? 2 : 1
                )
        )
        .frame(minHeight: 88)
    }
}

class ContentViewController: ObservableObject {
    var memorialDayStore: MemorialDayStore?
    @Published var showingAddView = false
    @Published var showingSettingsView = false
    @Published var showUndoBar = false
    
    private var undoDismissWorkItem: DispatchWorkItem? = nil
    
    init(memorialDayStore: MemorialDayStore? = nil) {
        self.memorialDayStore = memorialDayStore
    }
    
    func presentUndoBar(store: MemorialDayStore) {
        undoDismissWorkItem?.cancel()
        withAnimation(.spring()) {
            showUndoBar = true
        }
        let work = DispatchWorkItem { [weak self] in
            DispatchQueue.main.async {
                withAnimation(.spring()) {
                    self?.showUndoBar = false
                }
            }
        }
        undoDismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
    }
    
    func undoDelete(store: MemorialDayStore) {
        store.undoLastDelete()
        withAnimation(.spring()) {
            showUndoBar = false
        }
        HapticManager.shared.success()
    }
}
