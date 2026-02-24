import Foundation

struct Note: Identifiable, Codable, Hashable {
    let id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date

    var title: String {
        let firstLine = content.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? ""
        return firstLine.trimmingCharacters(in: .whitespaces).isEmpty ? "新建便签" : String(firstLine.prefix(50))
    }

    init(id: UUID = UUID(), content: String = "", createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
