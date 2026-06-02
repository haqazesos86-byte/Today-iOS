import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let isCompleted: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(isCompleted ? Color.green : Color.tertiaryLabel, lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 20, height: 20)

            Text(task.text)
                .font(.system(size: 15))
                .foregroundColor(isCompleted ? .tertiaryLabel : .primary)
                .strikethrough(isCompleted, color: .tertiaryLabel)
                .lineLimit(2)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isCompleted)

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { onToggle() }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { onDelete() }
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .opacity(isCompleted ? 0.6 : 1)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
}

#Preview {
    TaskRowView(
        task: TaskItem(text: "示例任务", date: Date(), order: 0),
        isCompleted: false,
        onToggle: {},
        onDelete: {}
    )
}
