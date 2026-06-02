import SwiftUI
import SwiftData
import Observation

@Observable
final class TaskListViewModel {
    var modelContext: ModelContext?
    var tasks: [TaskItem] = []
    var currentDate: Date = Date() {
        didSet { fetchTasks() }
    }

    var undoneTasks: [TaskItem] {
        tasks.filter { !$0.isDone }.sorted { $0.order < $1.order }
    }

    var doneTasks: [TaskItem] {
        tasks.filter { $0.isDone }.sorted { $0.doneAt ?? $0.createdAt > $1.doneAt ?? $1.createdAt }
    }

    var isEmpty: Bool {
        tasks.isEmpty
    }

    var hasCompleted: Bool {
        tasks.contains(where: { $0.isDone })
    }

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchTasks()
    }

    func fetchTasks() {
        guard let context = modelContext else { return }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = #Predicate<TaskItem> { item in
            item.date >= startOfDay && item.date < endOfDay
        }
        let descriptor = FetchDescriptor<TaskItem>(predicate: predicate, sortBy: [SortDescriptor(\.order)])
        do {
            tasks = try context.fetch(descriptor)
        } catch {
            tasks = []
        }
    }

    @MainActor
    func addTask(text: String) {
        guard let context = modelContext, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let maxOrder = (tasks.map(\.order).max() ?? -1) + 1
        let task = TaskItem(text: text, date: currentDate, order: maxOrder)
        context.insert(task)
        try? context.save()
        fetchTasks()
    }

    @MainActor
    func toggleTask(_ task: TaskItem) {
        task.isDone.toggle()
        task.doneAt = task.isDone ? Date() : nil
        if task.isDone {
            task.order = (tasks.map(\.order).max() ?? 0) + 1
        }
        try? modelContext?.save()
        fetchTasks()
    }

    @MainActor
    func deleteTask(_ task: TaskItem) {
        modelContext?.delete(task)
        try? modelContext?.save()
        fetchTasks()
    }

    func goToNextDay() {
        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
    }

    func goToPreviousDay() {
        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
    }

    var isToday: Bool { Calendar.current.isDateInToday(currentDate) }
}
