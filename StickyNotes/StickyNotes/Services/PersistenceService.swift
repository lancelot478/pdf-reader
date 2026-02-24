import Foundation

final class PersistenceService {
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("StickyNotes", isDirectory: true)

        if !FileManager.default.fileExists(atPath: appDirectory.path) {
            try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        }

        fileURL = appDirectory.appendingPathComponent("notes.json")
    }

    func load() -> [Note] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Note].self, from: data)) ?? []
    }

    func save(_ notes: [Note]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(notes) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
