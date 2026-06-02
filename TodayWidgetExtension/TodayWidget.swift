import WidgetKit
import SwiftUI

// MARK: - TimelineProvider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), taskCount: 0, doneCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), taskCount: 3, doneCount: 1)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = SimpleEntry(date: Date(), taskCount: 5, doneCount: 2)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let taskCount: Int
    let doneCount: Int
}

// MARK: - Widget View

struct TodayWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今 天")
                .font(.system(size: 18, weight: .semibold))

            if entry.taskCount > 0 {
                Text("\(entry.doneCount)/\(entry.taskCount)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.green)

                Text(entry.doneCount == entry.taskCount ? "全部完成 🎉" : "进行中...")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } else {
                Text("—")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.secondary)

                Text("今天可以偷个懒了 ☕️")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Widget Configuration

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
