import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TaskListViewModel()
    @State private var newTaskText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            DateHeaderView(
                date: viewModel.currentDate,
                isToday: viewModel.isToday,
                onPrev: { viewModel.goToPreviousDay() },
                onNext: { viewModel.goToNextDay() }
            )
            .padding(.horizontal, 4)

            mainList

            HStack(spacing: 8) {
                Text("+")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isInputFocused ? .green : .secondary)
                    .animation(.easeInOut(duration: 0.2), value: isInputFocused)
                TextField("写下来", text: $newTaskText)
                    .font(.system(size: 15))
                    .focused($isInputFocused)
                    .onSubmit { addTask() }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(Color(.systemBackground))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color(.systemBackground))
        .onAppear { viewModel.setup(modelContext: modelContext) }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = abs(value.translation.height)
                    guard vertical < horizontal * 0.5 else { return }
                    if horizontal > 50 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.goToPreviousDay()
                        }
                    } else if horizontal < -50 {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.goToNextDay()
                        }
                    }
                }
        )
    }

    @ViewBuilder
    private var mainList: some View {
        if viewModel.isEmpty {
            Spacer()
            EmptyStateView()
            Spacer()
        } else {
            List {
                ForEach(viewModel.undoneTasks) { task in
                    TaskRowView(
                        task: task,
                        isCompleted: false,
                        onToggle: { viewModel.toggleTask(task) },
                        onDelete: { viewModel.deleteTask(task) }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .transition(.opacity)
                }

                if viewModel.hasCompleted {
                    DividerView()
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)

                    ForEach(viewModel.doneTasks) { task in
                        TaskRowView(
                            task: task,
                            isCompleted: true,
                            onToggle: { viewModel.toggleTask(task) },
                            onDelete: { viewModel.deleteTask(task) }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.undoneTasks.count)
        }
    }

    private func addTask() {
        let text = newTaskText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            viewModel.addTask(text: text)
        }
        newTaskText = ""
        isInputFocused = false
    }
}

#Preview {
    ContentView()
}
