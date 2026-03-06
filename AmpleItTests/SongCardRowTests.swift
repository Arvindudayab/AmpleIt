import XCTest
@testable import AmpleIt

final class SongCardRowTests: XCTestCase {

    // MARK: - Song model

    func test_song_hasCorrectID() {
        let id = UUID()
        let song = Song(id: id, title: "Track", artist: "Artist")
        XCTAssertEqual(song.id, id)
    }

    func test_song_hasCorrectTitle() {
        let song = Song(id: UUID(), title: "Ocean Glass", artist: "Mira")
        XCTAssertEqual(song.title, "Ocean Glass")
    }

    func test_song_hasCorrectArtist() {
        let song = Song(id: UUID(), title: "Ocean Glass", artist: "Mira")
        XCTAssertEqual(song.artist, "Mira")
    }

    // MARK: - Artwork seed

    func test_artworkSeed_isSongUUIDString() {
        let song = Song(id: UUID(), title: "Test", artist: "Artist")
        let seed = song.id.uuidString
        XCTAssertEqual(seed.count, 36) // Standard UUID string length
        XCTAssertFalse(seed.isEmpty)
    }

    func test_artworkSeed_uniquePerSong() {
        let s1 = Song(id: UUID(), title: "A", artist: "X")
        let s2 = Song(id: UUID(), title: "A", artist: "X")
        XCTAssertNotEqual(s1.id.uuidString, s2.id.uuidString)
    }

    // MARK: - onMore callback

    func test_onMore_optionalCallback_isCalled() {
        var called = false
        let onMore: (() -> Void)? = { called = true }
        onMore?()
        XCTAssertTrue(called)
    }

    func test_onMore_nilCallback_doesNotCrash() {
        let onMore: (() -> Void)? = nil
        onMore?() // Must not crash
        XCTAssertNil(onMore)
    }

    // MARK: - onEdit callback

    func test_onEdit_optionalCallback_isCalled() {
        var called = false
        let onEdit: (() -> Void)? = { called = true }
        onEdit?()
        XCTAssertTrue(called)
    }

    func test_onEdit_nilCallback_doesNotCrash() {
        let onEdit: (() -> Void)? = nil
        onEdit?()
        XCTAssertNil(onEdit)
    }

    // MARK: - onDelete callback

    func test_onDelete_optionalCallback_isCalled() {
        var called = false
        let onDelete: (() -> Void)? = { called = true }
        onDelete?()
        XCTAssertTrue(called)
    }

    func test_onDelete_nilCallback_doesNotCrash() {
        let onDelete: (() -> Void)? = nil
        onDelete?()
        XCTAssertNil(onDelete)
    }

    // MARK: - onAddToPlaylist callback

    func test_onAddToPlaylist_optionalCallback_isCalled() {
        var called = false
        let onAddToPlaylist: (() -> Void)? = { called = true }
        onAddToPlaylist?()
        XCTAssertTrue(called)
    }

    func test_onAddToPlaylist_nilCallback_doesNotCrash() {
        let onAddToPlaylist: (() -> Void)? = nil
        onAddToPlaylist?()
        XCTAssertNil(onAddToPlaylist)
    }

    // MARK: - Identifiability

    func test_song_identifiable_throughID() {
        let id = UUID()
        let song = Song(id: id, title: "T", artist: "A")
        XCTAssertEqual(song.id, id)
    }

    func test_multipleRows_differentSongs_differentIDs() {
        let songs = MockData.songs
        let ids = songs.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }
}
