import Combine
import Foundation

final class NoteStore: ObservableObject {
    @Published private(set) var notes: [NoteItem]
    @Published var searchText = ""
    @Published var filter: NoteFilter = .all

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL = NoteStore.defaultFileURL()) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        notes = []
        load()
    }

    var filteredNotes: [NoteItem] {
        notes
            .filter { note in
                switch filter {
                case .all: true
                case .active: !note.isCompleted
                case .completed: note.isCompleted
                }
            }
            .filter { note in
                searchText.isEmpty || note.text.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { lhs, rhs in
                if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
                if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    var activeCount: Int { notes.lazy.filter { !$0.isCompleted }.count }
    var completedCount: Int { notes.count - activeCount }

    @discardableResult
    func add(_ text: String, now: Date = Date()) -> NoteItem? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let note = NoteItem(text: trimmed, createdAt: now, updatedAt: now)
        notes.append(note)
        save()
        return note
    }

    func note(withID id: UUID) -> NoteItem? {
        notes.first { $0.id == id }
    }

    func updateText(id: UUID, text: String, now: Date = Date()) {
        mutate(id: id, now: now) { $0.text = text }
    }

    func togglePinned(id: UUID, now: Date = Date()) {
        mutate(id: id, now: now) { $0.isPinned.toggle() }
    }

    func toggleCompleted(id: UUID, now: Date = Date()) {
        mutate(id: id, now: now) { $0.isCompleted.toggle() }
    }

    func delete(id: UUID) {
        notes.removeAll { $0.id == id }
        save()
    }

    private func mutate(id: UUID, now: Date, change: (inout NoteItem) -> Void) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        change(&notes[index])
        notes[index].updatedAt = now
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            notes = try decoder.decode([NoteItem].self, from: Data(contentsOf: fileURL))
        } catch {
            notes = []
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try encoder.encode(notes).write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Unable to persist notes: \(error)")
        }
    }

    static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("NotchNotes", isDirectory: true)
            .appendingPathComponent("notes.json")
    }
}
