import SwiftUI

struct ContentView: View {
    @State private var viewModel = NotesViewModel()
    @State private var editorContent = ""

    private var selectedNote: Note? {
        guard let id = viewModel.selectedNoteID else { return nil }
        return viewModel.notes.first { $0.id == id }
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationSplitView {
            List(viewModel.filteredNotes, selection: $viewModel.selectedNoteID) { note in
                NoteRowView(note: note)
                    .tag(note.id)
                    .contextMenu {
                        Button("删除", role: .destructive) {
                            self.viewModel.deleteNote(note.id)
                        }
                    }
            }
            .onDeleteCommand {
                self.viewModel.deleteSelectedNote()
            }
            .searchable(text: $viewModel.searchText, prompt: "搜索便签")
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
            .toolbar {
                ToolbarItem {
                    Button(action: { self.viewModel.createNote() }) {
                        Label("新建便签", systemImage: "square.and.pencil")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
        } detail: {
            if let note = selectedNote {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("创建: \(note.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        Spacer()
                        Text("更新: \(note.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    Divider()

                    TextEditor(text: $editorContent)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(8)
                }
            } else {
                EmptyStateView()
            }
        }
        .navigationTitle("便签")
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            if let id = self.viewModel.selectedNoteID {
                editorContent = self.viewModel.notes.first { $0.id == id }?.content ?? ""
            }
        }
        .onChange(of: self.viewModel.selectedNoteID) { _, newID in
            if let id = newID {
                editorContent = self.viewModel.notes.first { $0.id == id }?.content ?? ""
            }
        }
        .onChange(of: editorContent) { _, newContent in
            if let id = self.viewModel.selectedNoteID {
                self.viewModel.updateContent(newContent, for: id)
            }
        }
    }
}
