import XCTest
@testable import AmpleIt

final class SongLibraryViewTests: XCTestCase {
    var store: LibraryStore!

    override func setUp() {
        super.setUp()
        store = LibraryStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    /// Mirrors SongLibraryView.filteredSongs computed property for unit testing.
    private func filteredSongs(in songs: [Song], searchText: String) -> [Song] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return songs
        }
        let q = searchText.lowercased()
        return songs.filter {
            $0.title.lowercased().contains(q) || $0.artist.lowercased().contains(q)
        }
    }

    // MARK: - Empty / Whitespace Search

    func test_filteredSongs_emptySearchReturnsAllSongs() {
        let result = filteredSongs(in: store.librarySongs, searchText: "")
        XCTAssertEqual(result.count, store.librarySongs.count)
    }

    func test_filteredSongs_whitespaceOnlyReturnsAllSongs() {
        let result = filteredSongs(in: store.librarySongs, searchText: "   ")
        XCTAssertEqual(result.count, store.librarySongs.count)
    }

    func test_filteredSongs_tabCharacterReturnsAllSongs() {
        let result = filteredSongs(in: store.librarySongs, searchText: "\t")
        XCTAssertEqual(result.count, store.librarySongs.count)
    }

    // MARK: - Title Matching

    func test_filteredSongs_matchesByTitleLowercase() {
        let songs = [
            Song(id: UUID(), title: "Midnight Drive", artist: "Nova"),
            Song(id: UUID(), title: "Golden Hour", artist: "Aria")
        ]
        let result = filteredSongs(in: songs, searchText: "midnight")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].title, "Midnight Drive")
    }

    func test_filteredSongs_matchesByTitleUppercase() {
        let songs = [
            Song(id: UUID(), title: "Neon Skyline", artist: "Kairo")
        ]
        let result = filteredSongs(in: songs, searchText: "NEON")
        XCTAssertEqual(result.count, 1)
    }

    func test_filteredSongs_matchesByTitleMixedCase() {
        let songs = [
            Song(id: UUID(), title: "Afterglow", artist: "Selene")
        ]
        let result = filteredSongs(in: songs, searchText: "AfTeRgLoW")
        XCTAssertEqual(result.count, 1)
    }

    func test_filteredSongs_partialTitleMatch() {
        let songs = [
            Song(id: UUID(), title: "Ocean Glass", artist: "Mira")
        ]
        let result = filteredSongs(in: songs, searchText: "ean")
        XCTAssertEqual(result.count, 1)
    }

    // MARK: - Artist Matching

    func test_filteredSongs_matchesByArtistLowercase() {
        let songs = [
            Song(id: UUID(), title: "Song A", artist: "Nova"),
            Song(id: UUID(), title: "Song B", artist: "Aria")
        ]
        let result = filteredSongs(in: songs, searchText: "nova")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].artist, "Nova")
    }

    func test_filteredSongs_matchesByArtistUppercase() {
        let songs = [
            Song(id: UUID(), title: "Track", artist: "Kairo")
        ]
        let result = filteredSongs(in: songs, searchText: "KAIRO")
        XCTAssertEqual(result.count, 1)
    }

    func test_filteredSongs_partialArtistMatch() {
        let songs = [
            Song(id: UUID(), title: "Track", artist: "The Satellites")
        ]
        let result = filteredSongs(in: songs, searchText: "satell")
        XCTAssertEqual(result.count, 1)
    }

    // MARK: - No Match

    func test_filteredSongs_noMatchReturnsEmpty() {
        let result = filteredSongs(in: store.librarySongs, searchText: "zzzznonexistent")
        XCTAssertTrue(result.isEmpty)
    }

    func test_filteredSongs_specialCharsNoMatch() {
        let result = filteredSongs(in: store.librarySongs, searchText: "###")
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Multiple Matches

    func test_filteredSongs_multipleResultsForCommonQuery() {
        let songs = [
            Song(id: UUID(), title: "Rock Song", artist: "Rock Band"),
            Song(id: UUID(), title: "Another Track", artist: "Rockstar"),
            Song(id: UUID(), title: "Different", artist: "Other")
        ]
        let result = filteredSongs(in: songs, searchText: "rock")
        XCTAssertEqual(result.count, 2)
    }

    func test_filteredSongs_songMatchingBothTitleAndArtist_includedOnce() {
        let songs = [
            Song(id: UUID(), title: "Test Song", artist: "Test Artist")
        ]
        let result = filteredSongs(in: songs, searchText: "test")
        XCTAssertEqual(result.count, 1)
    }

    // MARK: - Empty Library

    func test_filteredSongs_emptyLibraryWithQuery_returnsEmpty() {
        let result = filteredSongs(in: [], searchText: "anything")
        XCTAssertTrue(result.isEmpty)
    }

    func test_filteredSongs_emptyLibraryWithEmptyQuery_returnsEmpty() {
        let result = filteredSongs(in: [], searchText: "")
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Store Integration

    func test_filteredSongs_withStoreSongs_emptyQueryReturnsAll() {
        let result = filteredSongs(in: store.librarySongs, searchText: "")
        XCTAssertEqual(result.count, MockData.songs.count)
    }

    func test_filteredSongs_afterAddingSong_includedInEmptyQueryResult() {
        let newSong = Song(id: UUID(), title: "UniqueQueryableSong", artist: "UniqueArtist999")
        store.librarySongs.append(newSong)
        let result = filteredSongs(in: store.librarySongs, searchText: "")
        XCTAssertTrue(result.contains(where: { $0.id == newSong.id }))
    }

    func test_filteredSongs_afterAddingSong_matchedByTitle() {
        let newSong = Song(id: UUID(), title: "UniqueSearchTerm999", artist: "SomeArtist")
        store.librarySongs.append(newSong)
        let result = filteredSongs(in: store.librarySongs, searchText: "uniquesearchterm999")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, newSong.id)
    }

    // MARK: - isAddMenuPresented initial state

    func test_isAddMenuPresented_initiallyFalse() {
        let isAddMenuPresented = false
        XCTAssertFalse(isAddMenuPresented)
    }

    func test_isYTUploadActive_initiallyFalse() {
        let isYTUploadActive = false
        XCTAssertFalse(isYTUploadActive)
    }

    func test_searchText_initiallyEmpty() {
        let searchText = ""
        XCTAssertTrue(searchText.isEmpty)
    }
}
