import SwiftData
import Foundation

@Model
final class TaskItem: Identifiable, Codable {
    var id: UUID = UUID()
    var text: String
    var isDone: Bool = false
    var createdAt: Date = Date()
    var doneAt: Date?
    var date: Date
    var order: Int

    init(text: String, date: Date, order: Int) {
        self.text = text
        self.date = date
        self.order = order
    }

    enum CodingKeys: String, CodingKey {
        case id, text, isDone, createdAt, doneAt, date, order
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        isDone = try container.decode(Bool.self, forKey: .isDone)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        doneAt = try container.decodeIfPresent(Date.self, forKey: .doneAt)
        date = try container.decode(Date.self, forKey: .date)
        order = try container.decode(Int.self, forKey: .order)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(isDone, forKey: .isDone)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(doneAt, forKey: .doneAt)
        try container.encode(date, forKey: .date)
        try container.encode(order, forKey: .order)
    }
}
