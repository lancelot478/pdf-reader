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
        @Bindable var viewModel = viewModel

        NavigationSplitView {
            sidebarContent(viewModel: viewModel)
        } detail: {
            detailContent
        }
        .navigationTitle("")
        .frame(minWidth: 700, minHeight: 450)
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

    // MARK: - Sidebar

    @ViewBuilder
    private func sidebarContent(viewModel: NotesViewModel) -> some View {
        @Bindable var viewModel = viewModel
        List(viewModel.filteredNotes, selection: $viewModel.selectedNoteID) { note in
            NoteRowView(note: note, isSelected: note.id == self.viewModel.selectedNoteID)
                .tag(note.id)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
                .contextMenu {
                    Button(role: .destructive) {
                        self.viewModel.deleteNote(note.id)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
        }
        .listStyle(.sidebar)
        .onDeleteCommand {
            self.viewModel.deleteSelectedNote()
        }
        .searchable(text: $viewModel.searchText, prompt: "搜索便签...")
        .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { self.viewModel.createNote() }) {
                    Label("新建便签", systemImage: "square.and.pencil")
                }
                .keyboardShortcut("n", modifiers: .command)
                .help("新建便签 (⌘N)")
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailContent: some View {
        if let note = selectedNote {
            VStack(spacing: 0) {
                detailHeader(note: note)
                editorArea
            }
            .background(.ultraThinMaterial)
        } else {
            EmptyStateView()
                .background(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private func detailHeader(note: Note) -> some View {
        HStack(spacing: 12) {
            Label(
                note.createdAt.formatted(date: .abbreviated, time: .shortened),
                systemImage: "calendar"
            )

            Spacer()

            Label(
                note.updatedAt.formatted(date: .abbreviated, time: .shortened),
                systemImage: "clock"
            )

            Divider()
                .frame(height: 14)
                .opacity(0.5)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPreviewMode.toggle()
                }
            } label: {
                Image(systemName: isPreviewMode ? "pencil.line" : "eye")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isPreviewMode ? .accentColor : .secondary)
                    .frame(width: 26, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isPreviewMode ? Color.accentColor.opacity(0.12) : .clear)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .help(isPreviewMode ? "切换到编辑模式 (⇧⌘P)" : "切换到预览模式 (⇧⌘P)")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    @ViewBuilder
    private var editorArea: some View {
        Divider().opacity(0.5)

        if isPreviewMode {
            MarkdownPreviewView(content: editorContent)
                .transition(.opacity)
        } else {
            RawTextEditor(text: $editorContent)
                .transition(.opacity)
        }
    }
}

// MARK: - NSTextView Wrapper

private struct RawTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.drawsBackground = false
        scrollView.scrollerStyle = .overlay
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true

        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = NSSize(width: 12, height: 14)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.insertionPointColor = .controlAccentColor
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor.controlAccentColor.withAlphaComponent(0.2)
        ]
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
