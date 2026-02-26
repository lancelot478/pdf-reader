import SwiftUI
import AppKit

struct ContentView: View {
    @State private var viewModel = NotesViewModel()
    @State private var editorContent = ""
    @State private var isPreviewMode = false

    private var selectedNote: Note? {
        guard let id = viewModel.selectedNoteID else { return nil }
        return viewModel.notes.first { $0.id == id }
    }

    var body: some View {
        let _ = print("[ContentView] body evaluated, isPreviewMode=\(isPreviewMode)")
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

                        Divider().frame(height: 12)

                        Button(action: {
                            print("[ContentView] toggle pressed, will set isPreviewMode=\(!isPreviewMode)")
                            isPreviewMode.toggle()
                        }) {
                            Image(systemName: isPreviewMode ? "pencil" : "eye")
                        }
                        .buttonStyle(.borderless)
                        .keyboardShortcut("p", modifiers: [.command, .shift])
                        .help(isPreviewMode ? "切换到编辑模式 (⇧⌘P)" : "切换到预览模式 (⇧⌘P)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    Divider()

                    if isPreviewMode {
                        MarkdownPreviewView(content: editorContent)
                    } else {
                        RawTextEditor(text: $editorContent)
                    }
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
            isPreviewMode = false
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

// MARK: - NSTextView wrapper with smart substitutions disabled

private struct RawTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.drawsBackground = false

        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.delegate = context.coordinator
        textView.string = text
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        init(text: Binding<String>) { self.text = text }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}
