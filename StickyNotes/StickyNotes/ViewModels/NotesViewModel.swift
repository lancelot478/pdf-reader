import Foundation
import Observation

@Observable
final class NotesViewModel {
    var notes: [Note] = []
    var selectedNoteID: UUID?
    var searchText: String = ""

    private let persistence = PersistenceService()

    var filteredNotes: [Note] {
        let sorted = notes.sorted { $0.updatedAt > $1.updatedAt }
        if searchText.isEmpty { return sorted }
        return sorted.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }

    var selectedNote: Note? {
        notes.first { $0.id == selectedNoteID }
    }

    init() {
        notes = persistence.load()
        selectedNoteID = notes.sorted(by: { $0.updatedAt > $1.updatedAt }).first?.id
    }

    func createNote() {
        let note = Note()
        notes.append(note)
        selectedNoteID = note.id
        save()
    }

    func updateContent(_ content: String, for noteID: UUID) {
        guard let index = notes.firstIndex(where: { $0.id == noteID }) else { return }
        guard notes[index].content != content else { return }
        notes[index].content = content
        notes[index].updatedAt = .now
        save()
    }

    func deleteNote(_ noteID: UUID) {
        notes.removeAll { $0.id == noteID }
        if selectedNoteID == noteID {
            selectedNoteID = filteredNotes.first?.id
        }
        save()
    }

    func deleteSelectedNote() {
        guard let id = selectedNoteID else { return }
        deleteNote(id)
    }

    private func save() {
        persistence.save(notes)
    }
}
