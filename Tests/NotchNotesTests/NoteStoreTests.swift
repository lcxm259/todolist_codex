import XCTest
@testable import NotchNotes

final class NoteStoreTests: XCTestCase {
    private var directory: URL!
    private var fileURL: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("notes.json")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testAddMutateSortAndDelete() throws {
        let store = NoteStore(fileURL: fileURL)
        let older = try XCTUnwrap(store.add("Older", now: Date(timeIntervalSince1970: 10)))
        let newer = try XCTUnwrap(store.add("Newer", now: Date(timeIntervalSince1970: 20)))

        XCTAssertEqual(store.filteredNotes.map(\.id), [newer.id, older.id])

        store.togglePinned(id: older.id, now: Date(timeIntervalSince1970: 30))
        XCTAssertEqual(store.filteredNotes.first?.id, older.id)

        store.toggleCompleted(id: older.id)
        XCTAssertTrue(try XCTUnwrap(store.note(withID: older.id)).isCompleted)
        XCTAssertEqual(store.activeCount, 1)

        store.delete(id: newer.id)
        XCTAssertEqual(store.notes.map(\.id), [older.id])
    }

    func testPersistenceRoundTrip() throws {
        let store = NoteStore(fileURL: fileURL)
        let note = try XCTUnwrap(store.add("Persist me"))
        store.togglePinned(id: note.id)
        store.toggleCompleted(id: note.id)

        let reloaded = NoteStore(fileURL: fileURL)
        let persisted = try XCTUnwrap(reloaded.note(withID: note.id))
        XCTAssertEqual(persisted.text, "Persist me")
        XCTAssertTrue(persisted.isPinned)
        XCTAssertTrue(persisted.isCompleted)
    }

    func testSearchAndFilters() throws {
        let store = NoteStore(fileURL: fileURL)
        let first = try XCTUnwrap(store.add("Book design review"))
        let second = try XCTUnwrap(store.add("Send weekly summary"))
        store.toggleCompleted(id: second.id)

        store.searchText = "design"
        XCTAssertEqual(store.filteredNotes.map(\.id), [first.id])

        store.searchText = ""
        store.filter = .completed
        XCTAssertEqual(store.filteredNotes.map(\.id), [second.id])

        store.filter = .active
        XCTAssertEqual(store.filteredNotes.map(\.id), [first.id])
    }

    func testEmptyNotesAreIgnored() {
        let store = NoteStore(fileURL: fileURL)
        XCTAssertNil(store.add("   \n"))
        XCTAssertTrue(store.notes.isEmpty)
    }

    func testPanelGeometryForNotchAndFallbackScreens() {
        let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)
        let visible = CGRect(x: 0, y: 0, width: 1512, height: 944)
        let size = CGSize(width: 420, height: 560)

        let notchFrame = PanelGeometry.frame(
            screenFrame: screen,
            visibleFrame: visible,
            safeTop: 38,
            hasNotch: true,
            size: size
        )
        let fallbackFrame = PanelGeometry.frame(
            screenFrame: screen,
            visibleFrame: visible,
            safeTop: 0,
            hasNotch: false,
            size: size
        )

        XCTAssertEqual(notchFrame.midX, screen.midX)
        XCTAssertEqual(notchFrame.maxY, 936)
        XCTAssertEqual(fallbackFrame.maxY, 936)
    }

    func testChineseFilterTitlesAndSharedCornerRadius() {
        XCTAssertEqual(NoteFilter.all.title, "全部")
        XCTAssertEqual(NoteFilter.active.title, "待办")
        XCTAssertEqual(NoteFilter.completed.title, "已完成")
        XCTAssertEqual(PanelAppearance.cornerRadius, 18)
    }
}
