import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case songs
    case playlists
    case amp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .songs:
            return "Songs"
        case .playlists:
            return "Playlists"
        case .amp:
            return "Amp"
        }
    }
}
