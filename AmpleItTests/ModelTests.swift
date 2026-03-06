import XCTest
import SwiftUI
@testable import AmpleIt

final class ModelTests: XCTestCase {

    // MARK: - Song

    func test_song_init_storesAllProperties() {
        let id = UUID()
        let song = Song(id: id, title: "Midnight Echoes", artist: "Nova")
        XCTAssertEqual(song.id, id)
        XCTAssertEqual(song.title, "Midnight Echoes")
        XCTAssertEqual(song.artist, "Nova")
    }

    func test_song_identifiable_idMatchesProperty() {
        let id = UUID()
        let song = Song(id: id, title: "T", artist: "A")
        XCTAssertEqual(song.id, id)
    }

    func test_song_differentInstances_canHaveSameContent() {
        let id = UUID()
        let s1 = Song(id: id, title: "Same", artist: "Artist")
        let s2 = Song(id: id, title: "Same", artist: "Artist")
        XCTAssertEqual(s1.id, s2.id)
        XCTAssertEqual(s1.title, s2.title)
        XCTAssertEqual(s1.artist, s2.artist)
    }

    func test_song_uniqueIDsForNewInstances() {
        let s1 = Song(id: UUID(), title: "A", artist: "X")
        let s2 = Song(id: UUID(), title: "A", artist: "X")
        XCTAssertNotEqual(s1.id, s2.id)
    }

    // MARK: - Playlist

    func test_playlist_init_storesAllProperties() {
        let id = UUID()
        let playlist = Playlist(id: id, name: "Gym Mix", count: 18)
        XCTAssertEqual(playlist.id, id)
        XCTAssertEqual(playlist.name, "Gym Mix")
        XCTAssertEqual(playlist.count, 18)
    }

    func test_playlist_identifiable_idMatchesProperty() {
        let id = UUID()
        let playlist = Playlist(id: id, name: "P", count: 0)
        XCTAssertEqual(playlist.id, id)
    }

    func test_playlist_zeroCount_isValid() {
        let playlist = Playlist(id: UUID(), name: "Empty", count: 0)
        XCTAssertEqual(playlist.count, 0)
    }

    // MARK: - MockData

    func test_mockData_songs_hasTenEntries() {
        XCTAssertEqual(MockData.songs.count, 10)
    }

    func test_mockData_playlists_hasSixEntries() {
        XCTAssertEqual(MockData.playlists.count, 6)
    }

    func test_mockData_songs_allHaveUniqueIDs() {
        let ids = MockData.songs.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func test_mockData_playlists_allHaveUniqueIDs() {
        let ids = MockData.playlists.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func test_mockData_songs_noEmptyTitles() {
        for song in MockData.songs {
            XCTAssertFalse(song.title.isEmpty, "Song '\(song.id)' has an empty title")
        }
    }

    func test_mockData_songs_noEmptyArtists() {
        for song in MockData.songs {
            XCTAssertFalse(song.artist.isEmpty, "Song '\(song.title)' has an empty artist")
        }
    }

    func test_mockData_playlists_noEmptyNames() {
        for playlist in MockData.playlists {
            XCTAssertFalse(playlist.name.isEmpty)
        }
    }

    func test_mockData_playlists_allHavePositiveCounts() {
        for playlist in MockData.playlists {
            XCTAssertGreaterThan(playlist.count, 0)
        }
    }

    func test_mockData_songs_staticPropertyReturnsSameInstance() {
        let first = MockData.songs
        let second = MockData.songs
        XCTAssertEqual(first.map(\.id), second.map(\.id))
    }

    // MARK: - PlaylistItem

    func test_playlistItem_idEqualsPlaylistId() {
        let id = UUID()
        let playlist = Playlist(id: id, name: "P", count: 0)
        let item = PlaylistItem(playlist: playlist, artwork: nil)
        XCTAssertEqual(item.id, id)
    }

    func test_playlistItem_storesPlaylistReference() {
        let playlist = Playlist(id: UUID(), name: "My Mix", count: 10)
        let item = PlaylistItem(playlist: playlist, artwork: nil)
        XCTAssertEqual(item.playlist.name, "My Mix")
        XCTAssertEqual(item.playlist.count, 10)
    }

    func test_playlistItem_nilArtwork() {
        let playlist = Playlist(id: UUID(), name: "P", count: 0)
        let item = PlaylistItem(playlist: playlist, artwork: nil)
        XCTAssertNil(item.artwork)
    }

    func test_playlistItem_nonNilArtwork() {
        let playlist = Playlist(id: UUID(), name: "P", count: 0)
        let artwork = Image(systemName: "music.note")
        let item = PlaylistItem(playlist: playlist, artwork: artwork)
        XCTAssertNotNil(item.artwork)
    }

    func test_playlistItem_isIdentifiable() {
        let id = UUID()
        let playlist = Playlist(id: id, name: "P", count: 0)
        let item = PlaylistItem(playlist: playlist, artwork: nil)
        // PlaylistItem conforms to Identifiable via id: UUID { playlist.id }
        XCTAssertEqual(item.id, id)
    }
}
