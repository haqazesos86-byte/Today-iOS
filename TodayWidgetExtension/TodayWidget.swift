import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), taskCount: 0, doneCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), taskCount: 3, doneCount: 1)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            let count = await TodayDataProvider.fetchTodayCounts()
            let entry = SimpleEntry(date: Date(), taskCount: count.total, doneCount: count.done)
            let timeline = Timeline(entries: [entry], policy: .timelineEntry)
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let taskCount: Int
    let doneCount: Int
}

struct TodayWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今 天")
                .font(.system(size: 20, weight: .semibold))

            if entry.taskCount > 0 {
                Text("\(entry.doneCount)/\(entry.taskCount)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.green)

                Text(entry.doneCount == entry.taskCount ? "全部完成 🎉" : "进行中...")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                Text("—")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.secondary)

                Text("今天可以偷个懒了 ☕️")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

struct TodayWidget: Widget {
    let kind: String = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("今天")
        .description("查看今天的任务进度")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

actor TodayDataProvider {
    static func fetchTodayCounts() -> (total: Int, done: Int) {
        do {
            let schema = Schema([TaskItem.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = container.mainContext

            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let predicate = #Predicate<TaskItem> { item in
                item.date >= startOfDay && item.date < endOfDay
            }
            let descriptor = FetchDescriptor<TaskItem>(predicate: predicate)

            let tasks = try context.fetch(descriptor)
            let done = tasks.filter { $0.isDone }.count
            return (tasks.count, done)
        } catch {
            return (0, 0)
        }
    }
}
