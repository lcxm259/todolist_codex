import SwiftUI

struct NotchNotesView: View {
    @ObservedObject var store: NoteStore
    let onDismiss: () -> Void

    @State private var draft = ""
    @FocusState private var captureFocused: Bool

    private let coral = Color(red: 0.98, green: 0.35, blue: 0.28)
    private let mint = Color(red: 0.24, green: 0.76, blue: 0.62)

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(.black)
                .frame(width: 96, height: 9)
                .padding(.top, 7)

            header
            captureBar
            controls

            Divider().opacity(0.45)

            if store.filteredNotes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(store.filteredNotes) { note in
                            NoteRow(noteID: note.id, store: store, coral: coral, mint: mint)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
            }

            footer
        }
        .frame(width: 420, height: 560)
        .background(.regularMaterial)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: PanelAppearance.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PanelAppearance.cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.13), lineWidth: 1)
        )
        .onAppear { captureFocused = true }
        .onExitCommand(perform: onDismiss)
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(coral)
                    .frame(width: 30, height: 30)
                Image(systemName: "checklist")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("todo list")
                    .font(.system(size: 15, weight: .semibold))
                Text("随手记录，稍后整理。")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("关闭")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }

    private var captureBar: some View {
        HStack(spacing: 9) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(coral)

            TextField("记录需要关注的事项", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium))
                .focused($captureFocused)
                .onSubmit(addDraft)

            Button(action: addDraft) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(coral, in: RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            .help("添加事项")
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 9))
        .padding(.horizontal, 14)
    }

    private var controls: some View {
        HStack(spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                TextField("搜索", text: $store.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 9)
            .frame(height: 30)
            .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 7))

            Picker("筛选", selection: $store.filter) {
                ForEach(NoteFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 176)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: store.searchText.isEmpty ? "sparkles" : "text.magnifyingglass")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(coral)
            Text(store.searchText.isEmpty ? "还没有记录" : "没有找到相关事项")
                .font(.system(size: 14, weight: .semibold))
            Text(store.searchText.isEmpty ? "在上方输入，按回车即可添加。" : "试试缩短关键词或切换筛选条件。")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Label("\(store.activeCount) 项待办", systemImage: "circle.dashed")
                .foregroundStyle(mint)
            Spacer()
            Text("回车添加  ·  Esc 关闭")
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 10, weight: .medium))
        .padding(.horizontal, 16)
        .frame(height: 34)
        .background(.primary.opacity(0.025))
    }

    private func addDraft() {
        guard store.add(draft) != nil else { return }
        draft = ""
        captureFocused = true
    }
}

private struct NoteRow: View {
    let noteID: UUID
    @ObservedObject var store: NoteStore
    let coral: Color
    let mint: Color

    private var note: NoteItem? { store.note(withID: noteID) }

    var body: some View {
        if let note {
            HStack(spacing: 10) {
                Button {
                    store.toggleCompleted(id: noteID)
                } label: {
                    Image(systemName: note.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(note.isCompleted ? mint : .secondary)
                }
                .buttonStyle(.plain)
                .help(note.isCompleted ? "标记为待办" : "标记为已完成")

                TextField("事项", text: Binding(
                    get: { store.note(withID: noteID)?.text ?? "" },
                    set: { store.updateText(id: noteID, text: $0) }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: note.isPinned ? .semibold : .regular))
                .strikethrough(note.isCompleted, color: .secondary)
                .foregroundStyle(note.isCompleted ? .secondary : .primary)
                .accessibilityLabel("事项内容")

                Button {
                    store.togglePinned(id: noteID)
                } label: {
                    Image(systemName: note.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(note.isPinned ? coral : .secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .help(note.isPinned ? "取消置顶" : "置顶")

                Button(role: .destructive) {
                    store.delete(id: noteID)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .help("删除")
            }
            .padding(.horizontal, 11)
            .frame(minHeight: 43)
            .background(
                note.isPinned ? coral.opacity(0.075) : Color.primary.opacity(0.035),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(alignment: .leading) {
                if note.isPinned {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(coral)
                        .frame(width: 3, height: 23)
                        .padding(.leading, 1)
                }
            }
        }
    }
}
