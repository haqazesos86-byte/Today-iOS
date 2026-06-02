import SwiftUI

@main
struct TodayWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}

struct WatchTask: Identifiable {
    let id = UUID()
    let text: String
    var isDone: Bool = false
}

struct WatchContentView: View {
    @State private var tasks: [WatchTask] = [
        WatchTask(text: "晨跑 30 分钟"),
        WatchTask(text: "回复邮件"),
        WatchTask(text: "买咖啡 ☕️", isDone: true)
    ]

    var body: some View {
        List {
            if tasks.isEmpty {
                VStack(spacing: 4) {
                    Text("☕️").font(.system(size: 24))
                    Text("今天可以偷个懒了")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            } else {
                ForEach($tasks) { $task in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            task.isDone.toggle()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if task.isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.green)
                            } else {
                                Circle()
                                    .stroke(Color.green, lineWidth: 1.5)
                                    .frame(width: 14, height: 14)
                            }
                            Text(task.text)
                                .font(.system(size: 14))
                                .strikethrough(task.isDone, color: .secondary)
                                .foregroundColor(task.isDone ? .secondary : .primary)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
