import Foundation

struct NoteItem: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var text: String
    var isPinned: Bool
    var isCompleted: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        text: String,
        isPinned: Bool = false,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.isPinned = isPinned
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum NoteFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case completed = "Done"

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "全部"
        case .active: "待办"
        case .completed: "已完成"
        }
    }
}
