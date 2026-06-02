import SwiftUI
import SwiftData

@main
struct TodayWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
        .modelContainer(try! PersistenceService.shared.container)
    }
}

struct WatchContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TaskListViewModel()

    var body: some View {
        List {
            if viewModel.isEmpty {
                VStack(spacing: 4) {
                    Text("☕️")
                        .font(.system(size: 24))
                    Text("今天可以偷个懒了")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.undoneTasks) { task in
                    Button(action: { viewModel.toggleTask(task) }) {
                        HStack(spacing: 8) {
                            Circle()
                                .stroke(Color.green, lineWidth: 1.5)
                                .frame(width: 14, height: 14)
                            Text(task.text)
                                .font(.system(size: 14))
                                .strikethrough(false)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.hasCompleted {
                    ForEach(viewModel.doneTasks) { task in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                            Text(task.text)
                                .font(.system(size: 13))
                                .foregroundColor(.tertiaryLabel)
                                .strikethrough(true, color: .tertiaryLabel)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .onAppear { viewModel.setup(modelContext: modelContext) }
    }
}
