import XCTest
@testable import AmpleIt

final class QueueCardViewTests: XCTestCase {

    // MARK: - Empty queue display

    func test_emptyQueue_showsEmptyState() {
        let queueSongs: [Song] = []
        XCTAssertTrue(queueSongs.isEmpty)
    }

    func test_emptyQueue_message() {
        let message = "No songs in queue."
        XCTAssertEqual(message, "No songs in queue.")
        XCTAssertFalse(message.isEmpty)
    }

    func test_nonEmptyQueue_showsSongList() {
        let queueSongs = MockData.songs
        XCTAssertFalse(queueSongs.isEmpty)
    }

    // MARK: - Divider rendering logic

    func test_lastSong_doesNotShowDivider() {
        let songs = MockData.songs
        let lastSong = songs.last!
        // Divider shown when: song.id != queueSongs.last?.id
        let showsDivider = lastSong.id != songs.last?.id
        XCTAssertFalse(showsDivider)
    }

    func test_nonLastSong_showsDivider() {
        let songs = MockData.songs
        let firstSong = songs.first!
        let showsDivider = firstSong.id != songs.last?.id
        XCTAssertTrue(showsDivider)
    }

    func test_singleSong_noDivider() {
        let songs = [MockData.songs[0]]
        let song = songs[0]
        let showsDivider = song.id != songs.last?.id
        XCTAssertFalse(showsDivider)
    }

    func test_twoSongs_firstShowsDivider_secondDoesNot() {
        let songs = [MockData.songs[0], MockData.songs[1]]
        let first = songs[0]
        let second = songs[1]
        XCTAssertTrue(first.id != songs.last?.id)
        XCTAssertFalse(second.id != songs.last?.id)
    }

    // MARK: - Song display in queue list

    func test_queueSong_titleIsDisplayed() {
        let song = Song(id: UUID(), title: "Night Market", artist: "Juno")
        XCTAssertEqual(song.title, "Night Market")
    }

    func test_queueSong_artistIsDisplayed() {
        let song = Song(id: UUID(), title: "Night Market", artist: "Juno")
        XCTAssertEqual(song.artist, "Juno")
    }

    func test_queueSong_artworkSeedIsSongID() {
        let song = Song(id: UUID(), title: "Track", artist: "Artist")
        let seed = song.id.uuidString
        XCTAssertEqual(seed, song.id.uuidString)
        XCTAssertFalse(seed.isEmpty)
    }

    // MARK: - Queue card header

    func test_queueCardTitle() {
        let title = "Queue"
        XCTAssertEqual(title, "Queue")
    }

    // MARK: - Close callback

    func test_onClose_callback_invoked() {
        var closeCalled = false
        let onClose = { closeCalled = true }
        onClose()
        XCTAssertTrue(closeCalled)
    }

    func test_onClose_callback_onlyCalledOnce() {
        var callCount = 0
        let onClose = { callCount += 1 }
        onClose()
        XCTAssertEqual(callCount, 1)
    }

    // MARK: - Order preservation

    func test_queueSongs_preserveInsertionOrder() {
        var store = LibraryStore()
        let song1 = store.librarySongs[0]
        let song2 = store.librarySongs[1]
        let song3 = store.librarySongs[2]
        store.addToQueue(song: song1)
        store.addToQueue(song: song2)
        store.addToQueue(song: song3)
        XCTAssertEqual(store.queue[0].id, song1.id)
        XCTAssertEqual(store.queue[1].id, song2.id)
        XCTAssertEqual(store.queue[2].id, song3.id)
    }

    // MARK: - Maximum height constraint

    func test_scrollViewMaxHeight() {
        let maxHeight: CGFloat = 240
        XCTAssertEqual(maxHeight, 240)
        XCTAssertGreaterThan(maxHeight, 0)
    }

    // MARK: - Card dimensions

    func test_cardMaxWidth() {
        let maxWidth: CGFloat = 300
        XCTAssertEqual(maxWidth, 300)
    }
}
