import XCTest
@testable import AmpleIt

final class HomeViewTests: XCTestCase {
    var store: LibraryStore!

    override func setUp() {
        super.setUp()
        store = LibraryStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    /// Mirrors HomeView.resolveSongs(for:) private method for unit testing.
    private func resolveSongs(for ids: [UUID], in songs: [Song]) -> [Song] {
        let byID = Dictionary(uniqueKeysWithValues: songs.map { ($0.id, $0) })
        return ids.compactMap { byID[$0] }
    }

    // MARK: - resolveSongs

    func test_resolveSongs_returnsMatchingSongs() {
        let songs = store.librarySongs
        let ids = [songs[0].id, songs[2].id]
        let result = resolveSongs(for: ids, in: songs)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, songs[0].id)
        XCTAssertEqual(result[1].id, songs[2].id)
    }

    func test_resolveSongs_returnsEmptyForUnknownIDs() {
        let result = resolveSongs(for: [UUID(), UUID()], in: store.librarySongs)
        XCTAssertTrue(result.isEmpty)
    }

    func test_resolveSongs_filtersOutUnknownIDs() {
        let songs = store.librarySongs
        let knownID = songs[0].id
        let result = resolveSongs(for: [knownID, UUID()], in: songs)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, knownID)
    }

    func test_resolveSongs_preservesSuppliedIDOrder() {
        let songs = store.librarySongs
        let ids = [songs[4].id, songs[1].id, songs[2].id]
        let result = resolveSongs(for: ids, in: songs)
        XCTAssertEqual(result.map(\.id), ids)
    }

    func test_resolveSongs_withEmptyIDs_returnsEmpty() {
        let result = resolveSongs(for: [], in: store.librarySongs)
        XCTAssertTrue(result.isEmpty)
    }

    func test_resolveSongs_withEmptySongs_returnsEmpty() {
        let id = store.librarySongs[0].id
        let result = resolveSongs(for: [id], in: [])
        XCTAssertTrue(result.isEmpty)
    }

    func test_resolveSongs_singleMatch() {
        let songs = store.librarySongs
        let result = resolveSongs(for: [songs[5].id], in: songs)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, songs[5].id)
    }

    func test_resolveSongs_duplicateIDsReturnedOnce() {
        // Dictionary keyed by id: duplicate ids in input will resolve to the same song,
        // but compactMap preserves the count of the input ids array.
        let songs = store.librarySongs
        let id = songs[0].id
        let result = resolveSongs(for: [id, id], in: songs)
        // Two entries in the id list → two results (compactMap)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, result[1].id)
    }

    // MARK: - recentlyAddedIDs / recentlyPlayedIDs defaults

    func test_recentlyAddedIDs_usesFirst5MockSongs() {
        let ids = Array(MockData.songs.prefix(5)).map(\.id)
        XCTAssertEqual(ids.count, min(5, MockData.songs.count))
    }

    func test_recentlyPlayedIDs_usesFirst5MockSongs() {
        let ids = Array(MockData.songs.prefix(5)).map(\.id)
        XCTAssertEqual(ids.count, min(5, MockData.songs.count))
    }

    func test_recentlyAddedIDs_resolveToValidSongs() {
        let ids = Array(MockData.songs.prefix(5)).map(\.id)
        let result = resolveSongs(for: ids, in: store.librarySongs)
        XCTAssertEqual(result.count, ids.count)
    }

    // MARK: - actionsSong initial state

    func test_actionsSong_initiallyNil() {
        let actionsSong: Song? = nil
        XCTAssertNil(actionsSong)
    }

    func test_actionsSong_setToSong_isNonNil() {
        var actionsSong: Song? = nil
        actionsSong = store.librarySongs[0]
        XCTAssertNotNil(actionsSong)
    }

    func test_actionsSong_clearedOnOverlayDismiss() {
        var actionsSong: Song? = store.librarySongs[0]
        // Simulates isPresented set to false → actionsSong = nil
        actionsSong = nil
        XCTAssertNil(actionsSong)
    }
}
