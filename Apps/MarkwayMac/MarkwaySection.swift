import Foundation

enum MarkwaySection: String, CaseIterable, Identifiable {
    case general
    case journal
    case music

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .journal: "Journal"
        case .music: "Music"
        }
    }

    var symbolName: String {
        switch self {
        case .general: "gearshape"
        case .journal: "book.pages"
        case .music: "music.note.list"
        }
    }
}
