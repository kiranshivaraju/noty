import SwiftUI

struct NoteListView: View {
    @ObservedObject private var store = NoteStore.shared
    @State private var path: [String] = []
    @State private var showArchive = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(showArchive ? store.archived : store.active) { note in
                    NavigationLink(value: note.id) { NoteRow(note: note) }
                        .listRowBackground(note.palette.paper.opacity(0.35))
                }
                .onDelete(perform: archive)
            }
            .listStyle(.insetGrouped)
            .navigationTitle(showArchive ? "Archive" : "Noty")
            .navigationDestination(for: String.self) { NoteDetailView(noteID: $0) }
            .onOpenURL(perform: open)
            .overlay { if visible.isEmpty { empty } }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showArchive.toggle()
                    } label: {
                        Image(systemName: showArchive ? "tray.full" : "archivebox")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { newNote() } label: { Image(systemName: "square.and.pencil") }
                }
            }
        }
    }

    private var visible: [Note] { showArchive ? store.archived : store.active }

    private var empty: some View {
        ContentUnavailableView(
            showArchive ? "Nothing archived" : "No notes",
            systemImage: showArchive ? "archivebox" : "note.text",
            description: Text(showArchive ? "Archived notes land here."
                                          : "Tap the pencil to start one."))
    }

    private func newNote() {
        let note = store.create()
        path.append(note.id)
    }

    /// noty:// — the same automation surface the Mac exposes, minus the windows
    /// this platform does not have. The Control Center button lands here.
    ///
    ///   noty://new?text=…   create a note and open it
    ///   noty://capture      the same thing, empty
    ///   noty://all          back to the list
    private func open(_ url: URL) {
        switch NotyURL.route(url) {
        case .newNote(let text):
            showArchive = false
            path = [store.create(body: text).id]
        case .allNotes:
            showArchive = false
            path = []
        case .settings, .unknown:
            break
        }
    }

    /// Swipe deletes archive rather than destroy, matching the Mac app — a note
    /// is only ever really gone through the editor's Delete.
    private func archive(_ offsets: IndexSet) {
        let list = visible
        for i in offsets where list.indices.contains(i) {
            store.setArchived(id: list[i].id, !showArchive)
        }
    }
}

struct NoteRow: View {
    let note: Note

    /// RelativeDateTimeFormatter renders a just-saved note as "in 0s", since the
    /// timestamp lands a hair in the future. Under a minute simply reads "now".
    static func age(of date: Date) -> String {
        let elapsed = Date().timeIntervalSince(date)
        if elapsed < 60 { return "now" }
        return Fmt.relative.localizedString(for: date, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(note.palette.dash)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    if note.pinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(note.palette.dash)
                    }
                    Text(note.displayTitle)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                }

                if !note.preview.isEmpty {
                    Text(note.preview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if let p = note.taskProgress {
                        Label("\(p.done)/\(p.total)", systemImage: "checklist")
                            .font(.caption2)
                            .foregroundStyle(p.done == p.total ? .green : .secondary)
                    }
                    Text(Self.age(of: note.modified))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 3)
    }
}
