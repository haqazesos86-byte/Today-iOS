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
        // Seed sample data only when SEED_SAMPLE_DATA=1 is set (used for CI screenshots)
        if ProcessInfo.processInfo.environment["SEED_SAMPLE_DATA"] == "1" {
            seedSampleData()
        }
        fetchTasks()
    }

    private func seedSampleData() {
        guard let context = modelContext else { return }
        // Only seed if today's tasks are empty
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = #Predicate<TaskItem> { item in
            item.date >= startOfDay && item.date < endOfDay
        }
        let existing = (try? context.fetch(FetchDescriptor<TaskItem>(predicate: predicate))) ?? []
        guard existing.isEmpty else { return }

        let samples: [(String, Bool)] = [
            ("☀️ 早起晨跑 30 分钟", false),
            ("📧 回复重要邮件", false),
            ("☕️ 买一杯美式", true),
            ("📚 读完《代码大全》第 3 章", false),
            ("💻 完成 Today App 上架准备", true),
            ("🧘 冥想 10 分钟", false)
        ]
        for (index, item) in samples.enumerated() {
            let task = TaskItem(text: item.0, date: startOfDay, order: index)
            task.isDone = item.1
            task.doneAt = item.1 ? Date().addingTimeInterval(-Double(index * 600)) : nil
            context.insert(task)
        }
        try? context.save()
        print("✅ Seeded \(samples.count) sample tasks for demo")
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
