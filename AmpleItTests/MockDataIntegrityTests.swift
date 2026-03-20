import XCTest
@testable import AmpleIt

/// Verifies that MockData's seeded data is self-consistent.
final class MockDataIntegrityTests: XCTestCase {

    // MARK: - Song catalog

    func test_songs_count_isTen() {
        XCTAssertEqual(MockData.songs.count, 10)
    }

    func test_songs_allIDsUnique() {
        let ids = MockData.songs.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "MockData.songs contains duplicate IDs")
    }

    func test_songs_noEmptyTitles() {
        for song in MockData.songs {
            XCTAssertFalse(song.title.isEmpty, "Song has empty title: \(song.id)")
        }
    }

    func test_songs_noEmptyArtists() {
        for song in MockData.songs {
            XCTAssertFalse(song.artist.isEmpty, "Song '\(song.title)' has empty artist")
        }
    }

    func test_songs_dateAddedInPast() {
        for song in MockData.songs {
            XCTAssertLessThan(song.dateAdded, Date(), "dateAdded is in the future for '\(song.title)'")
        }
    }

    func test_songs_staticPropertyReturnsSameIDs() {
        // Accessing the static property twice must yield the same UUID sequence
        // (i.e. it really is a static stored property).
        let first  = MockData.songs.map(\.id)
        let second = MockData.songs.map(\.id)
        XCTAssertEqual(first, second,
                       "MockData.songs is not stable — different UUIDs on successive accesses. It must be a 'static let'.")
    }

    // MARK: - Playlist catalog

    func test_playlists_count_isSix() {
        XCTAssertEqual(MockData.playlists.count, 6)
    }

    func test_playlists_allIDsUnique() {
        let ids = MockData.playlists.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "MockData.playlists contains duplicate IDs")
    }

    func test_playlists_noEmptyNames() {
        for pl in MockData.playlists {
            XCTAssertFalse(pl.name.isEmpty, "Playlist has empty name: \(pl.id)")
        }
    }

    func test_playlists_allCountsPositive() {
        for pl in MockData.playlists {
            XCTAssertGreaterThan(pl.count, 0, "Playlist '\(pl.name)' has a non-positive count")
        }
    }

    func test_playlists_staticPropertyReturnsSameIDs() {
        let first  = MockData.playlists.map(\.id)
        let second = MockData.playlists.map(\.id)
        XCTAssertEqual(first, second,
                       "MockData.playlists is not stable — different UUIDs on successive accesses.")
    }

    // MARK: - seededPlaylistSongIDs

    func test_seededPlaylistSongIDs_hasEntryForEveryPlaylist() {
        let songs     = MockData.songs
        let playlists = MockData.playlists
        let mapping   = MockData.seededPlaylistSongIDs(songs: songs, playlists: playlists)
        for pl in playlists {
            XCTAssertNotNil(mapping[pl.id], "No entry for playlist '\(pl.name)' in seededPlaylistSongIDs")
        }
    }

    func test_seededPlaylistSongIDs_entryLengthMatchesPlaylistCount() {
        let songs     = MockData.songs
        let playlists = MockData.playlists
        let mapping   = MockData.seededPlaylistSongIDs(songs: songs, playlists: playlists)
        for pl in playlists {
            let ids = mapping[pl.id] ?? []
            XCTAssertEqual(ids.count, pl.count,
                           "seededPlaylistSongIDs count \(ids.count) != playlist.count \(pl.count) for '\(pl.name)'")
        }
    }

    func test_seededPlaylistSongIDs_allReferencedIDsAreValid() {
        let songs     = MockData.songs
        let playlists = MockData.playlists
        let mapping   = MockData.seededPlaylistSongIDs(songs: songs, playlists: playlists)
        let validIDs  = Set(songs.map(\.id))
        for (_, ids) in mapping {
            for id in ids {
                XCTAssertTrue(validIDs.contains(id),
                              "Playlist references song ID \(id) which is not in MockData.songs")
            }
        }
    }

    func test_seededPlaylistSongIDs_emptyLibrary_returnsEmptyArraysForAllPlaylists() {
        let mapping = MockData.seededPlaylistSongIDs(songs: [], playlists: MockData.playlists)
        for pl in MockData.playlists {
            XCTAssertEqual(mapping[pl.id], [], "Expected empty array for '\(pl.name)' with empty library")
        }
    }

    // MARK: - Preview store consistency after sync

    /// After `LibraryStore.preview` calls `syncAllPlaylistCounts()`, each playlist's
    /// `.count` must equal the number of IDs in `playlistSongIDs`.
    /// This guards against the MockData hardcoded-count / seeded-length divergence bug.
    func test_previewStore_playlistCounts_matchPlaylistSongIDsAfterSync() {
        let store = LibraryStore.preview
        for pl in store.playlists {
            let actualCount = store.playlistSongIDs[pl.id]?.count ?? 0
            XCTAssertEqual(pl.count, actualCount,
                           "After sync, playlist '\(pl.name)' count \(pl.count) != actual IDs \(actualCount)")
        }
    }

    // MARK: - No song / no playlist edge cases

    func test_seededPlaylistSongIDs_emptyPlaylists_returnsEmptyDictionary() {
        let mapping = MockData.seededPlaylistSongIDs(songs: MockData.songs, playlists: [])
        XCTAssertTrue(mapping.isEmpty)
    }
}
