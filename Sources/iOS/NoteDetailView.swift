import SwiftUI

struct NoteDetailView: View {
    let noteID: String

    @ObservedObject private var store = NoteStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var body_ = ""
    @State private var loaded = false

    private var note: Note? { store.note(id: noteID) }

    var body: some View {
        Group {
            if let note {
                MarkdownTextView(text: $body_,
                                 ink: UIColor(note.palette.ink),
                                 paper: UIColor(note.palette.paper),
                                 fontSize: 17)
                    .background(note.palette.paper)
                    .ignoresSafeArea(.container, edges: .bottom)
                    .navigationTitle(note.displayTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { toolbar(for: note) }
                    .onAppear {
                        guard !loaded else { return }
                        body_ = note.body
                        loaded = true
                    }
                    .onChange(of: body_) { _, new in
                        store.updateBody(id: noteID, body: new)
                    }
            } else {
                // The note was deleted or archived out from under this screen.
                Color.clear.onAppear { dismiss() }
            }
        }
    }

    @ToolbarContentBuilder
    private func toolbar(for note: Note) -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                toggleTask()
            } label: {
                Image(systemName: "checklist")
            }

            Button {
                store.cycleColor(id: noteID)
            } label: {
                Image(systemName: "paintpalette")
            }

            Menu {
                Button {
                    store.togglePin(id: noteID)
                } label: {
                    Label(note.pinned ? "Unpin" : "Pin",
                          systemImage: note.pinned ? "pin.slash" : "pin")
                }
                Button {
                    store.setArchived(id: noteID, true)
                    dismiss()
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                Button(role: .destructive) {
                    store.delete(id: noteID)
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    /// Mirrors the Mac's ⌘T: put a checkbox on the last line, or strip it off.
    private func toggleTask() {
        var lines = body_.components(separatedBy: "\n")
        guard let i = lines.indices.last else { return }
        let line = lines[i]
        if Tasks.isTask(line) {
            lines[i] = Tasks.stripped(line)
        } else {
            lines[i] = Tasks.openPrefix + line
        }
        body_ = lines.joined(separator: "\n")
    }
}
