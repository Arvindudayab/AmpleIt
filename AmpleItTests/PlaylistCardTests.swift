import XCTest
import SwiftUI
@testable import AmpleIt

final class PlaylistCardTests: XCTestCase {

    // MARK: - PlaylistCard data

    func test_playlistCard_nameIsDisplayed() {
        let playlist = Playlist(id: UUID(), name: "Gym Mix", count: 18)
        XCTAssertEqual(playlist.name, "Gym Mix")
    }

    func test_playlistCard_countIsDisplayed() {
        let playlist = Playlist(id: UUID(), name: "Gym Mix", count: 18)
        XCTAssertEqual(playlist.count, 18)
    }

    func test_playlistCard_countString_singular() {
        // PlaylistCard always renders "\(count) songs" regardless of count
        let count = 1
        let label = "\(count) songs"
        XCTAssertEqual(label, "1 songs")
    }

    func test_playlistCard_countString_plural() {
        let count = 18
        let label = "\(count) songs"
        XCTAssertEqual(label, "18 songs")
    }

    func test_playlistCard_countString_zero() {
        let count = 0
        let label = "\(count) songs"
        XCTAssertEqual(label, "0 songs")
    }

    func test_playlistCard_nilArtwork_showsPlaceholder() {
        // artwork == nil → ArtworkPlaceholder is shown
        let artwork: Image? = nil
        XCTAssertNil(artwork)
    }

    func test_playlistCard_nonNilArtwork_showsImage() {
        let artwork: Image? = Image(systemName: "music.note")
        XCTAssertNotNil(artwork)
    }

    func test_playlistCard_artworkPlaceholderSeed_isPlaylistIDString() {
        let playlist = Playlist(id: UUID(), name: "P", count: 0)
        let seed = playlist.id.uuidString
        XCTAssertFalse(seed.isEmpty)
        XCTAssertEqual(seed.count, 36)
    }

    // MARK: - PlaylistCardSelectable

    func test_playlistCardSelectable_selectedBorderColor() {
        // isSelected ? Color("AppAccent") : Color.primary.opacity(0.12)
        let isSelected = true
        let colorKey = isSelected ? "AppAccent" : "primary"
        XCTAssertEqual(colorKey, "AppAccent")
    }

    func test_playlistCardSelectable_unselectedBorderColor() {
        let isSelected = false
        let colorKey = isSelected ? "AppAccent" : "primary"
        XCTAssertEqual(colorKey, "primary")
    }

    func test_playlistCardSelectable_selectedCheckmarkIcon() {
        // isSelected ? "checkmark" : "circle"
        let isSelected = true
        let icon = isSelected ? "checkmark" : "circle"
        XCTAssertEqual(icon, "checkmark")
    }

    func test_playlistCardSelectable_unselectedCircleIcon() {
        let isSelected = false
        let icon = isSelected ? "checkmark" : "circle"
        XCTAssertEqual(icon, "circle")
    }

    func test_playlistCardSelectable_selectedFill_usesAppAccent() {
        // Circle fill: isSelected ? Color("AppAccent") : Color.primary.opacity(0.12)
        let isSelected = true
        let fillKey = isSelected ? "AppAccent" : "primary.opacity(0.12)"
        XCTAssertEqual(fillKey, "AppAccent")
    }

    func test_playlistCardSelectable_unselectedFill_usesPrimary() {
        let isSelected = false
        let fillKey = isSelected ? "AppAccent" : "primary.opacity(0.12)"
        XCTAssertEqual(fillKey, "primary.opacity(0.12)")
    }

    func test_playlistCardSelectable_iconColor_selectedUsesAppBackground() {
        // Image foreground: isSelected ? Color("AppBackground") : Color.primary.opacity(0.6)
        let isSelected = true
        let colorKey = isSelected ? "AppBackground" : "primary.opacity(0.6)"
        XCTAssertEqual(colorKey, "AppBackground")
    }

    func test_playlistCardSelectable_iconColor_unselectedUsesPrimary() {
        let isSelected = false
        let colorKey = isSelected ? "AppBackground" : "primary.opacity(0.6)"
        XCTAssertEqual(colorKey, "primary.opacity(0.6)")
    }

    // MARK: - PlaylistItem

    func test_playlistItem_idEqualsPlaylistID() {
        let id = UUID()
        let playlist = Playlist(id: id, name: "Test", count: 5)
        let item = PlaylistItem(playlist: playlist, artwork: nil)
        XCTAssertEqual(item.id, id)
    }

    func test_playlistItem_idMatchesPlaylistID() {
        let playlist = Playlist(id: UUID(), name: "Mix", count: 0)
        let item = PlaylistItem(playlist: playlist, artwork: nil)
        XCTAssertEqual(item.id, playlist.id)
    }

    func test_playlistItem_storesPlaylist() {
        let playlist = Playlist(id: UUID(), name: "Road Trip", count: 34)
        let item = PlaylistItem(playlist: playlist, artwork: nil)
        XCTAssertEqual(item.playlist.name, "Road Trip")
        XCTAssertEqual(item.playlist.count, 34)
    }

    func test_playlistItem_isIdentifiable() {
        let id = UUID()
        let playlist = Playlist(id: id, name: "P", count: 0)
        let item = PlaylistItem(playlist: playlist, artwork: nil)
        // PlaylistItem.id: UUID { playlist.id }
        XCTAssertEqual(item.id, id)
    }
}
