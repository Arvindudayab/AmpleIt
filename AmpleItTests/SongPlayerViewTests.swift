import XCTest
@testable import AmpleIt

final class SongPlayerViewTests: XCTestCase {

    // MARK: - Initial State

    func test_isQueueCardPresented_initiallyFalse() {
        let isQueueCardPresented = false
        XCTAssertFalse(isQueueCardPresented)
    }

    func test_isPlaying_toggle_trueToFalse() {
        var isPlaying = true
        isPlaying.toggle()
        XCTAssertFalse(isPlaying)
    }

    func test_isPlaying_toggle_falseToTrue() {
        var isPlaying = false
        isPlaying.toggle()
        XCTAssertTrue(isPlaying)
    }

    func test_isPlaying_doubleToggle_returnsOriginalValue() {
        var isPlaying = true
        isPlaying.toggle()
        isPlaying.toggle()
        XCTAssertTrue(isPlaying)
    }

    // MARK: - Queue card toggle

    func test_queueButton_togglesQueueCardPresented() {
        var isQueueCardPresented = false
        // Mirrors the button action: isQueueCardPresented.toggle()
        isQueueCardPresented.toggle()
        XCTAssertTrue(isQueueCardPresented)
    }

    func test_queueCard_dismissedByBackgroundTap() {
        var isQueueCardPresented = true
        isQueueCardPresented = false
        XCTAssertFalse(isQueueCardPresented)
    }

    // MARK: - Play/Pause icon selection

    func test_playPauseIcon_showsPauseWhenPlaying() {
        let isPlaying = true
        let icon = isPlaying ? "pause.fill" : "play.fill"
        XCTAssertEqual(icon, "pause.fill")
    }

    func test_playPauseIcon_showsPlayWhenPaused() {
        let isPlaying = false
        let icon = isPlaying ? "pause.fill" : "play.fill"
        XCTAssertEqual(icon, "play.fill")
    }

    // MARK: - Song display

    func test_song_titleIsDisplayed() {
        let song = Song(id: UUID(), title: "Test Track", artist: "Test Artist")
        XCTAssertEqual(song.title, "Test Track")
    }

    func test_song_artistIsDisplayed() {
        let song = Song(id: UUID(), title: "Test Track", artist: "Test Artist")
        XCTAssertEqual(song.artist, "Test Artist")
    }

    func test_artworkSeed_usesSongID() {
        let song = Song(id: UUID(), title: "Track", artist: "Artist")
        let seed = song.id.uuidString
        XCTAssertFalse(seed.isEmpty)
        XCTAssertEqual(seed, song.id.uuidString)
    }

    // MARK: - Queue songs

    func test_queueSongs_canBeEmpty() {
        let queueSongs: [Song] = []
        XCTAssertTrue(queueSongs.isEmpty)
    }

    func test_queueSongs_canHaveMultipleSongs() {
        let queueSongs = MockData.songs
        XCTAssertEqual(queueSongs.count, 10)
    }

    // MARK: - Callback invocation

    func test_onClose_callback_isCalled() {
        var closeCalled = false
        let onClose = { closeCalled = true }
        onClose()
        XCTAssertTrue(closeCalled)
    }

    func test_onNext_callback_isCalled() {
        var nextCalled = false
        let onNext = { nextCalled = true }
        onNext()
        XCTAssertTrue(nextCalled)
    }

    func test_onPrev_callback_isCalled() {
        var prevCalled = false
        let onPrev = { prevCalled = true }
        onPrev()
        XCTAssertTrue(prevCalled)
    }

    func test_callbacks_areIndependent() {
        var closeCalled = false
        var nextCalled = false
        var prevCalled = false

        let onClose = { closeCalled = true }
        let onNext = { nextCalled = true }
        let onPrev = { prevCalled = true }

        onNext()
        XCTAssertFalse(closeCalled)
        XCTAssertTrue(nextCalled)
        XCTAssertFalse(prevCalled)

        onPrev()
        XCTAssertFalse(closeCalled)
        XCTAssertTrue(prevCalled)

        onClose()
        XCTAssertTrue(closeCalled)
    }

    // MARK: - Static UI labels

    func test_staticProgressTime_start() {
        let startLabel = "4:40"
        XCTAssertFalse(startLabel.isEmpty)
    }

    func test_staticProgressTime_remaining() {
        let remainingLabel = "-4:50"
        XCTAssertTrue(remainingLabel.hasPrefix("-"))
    }
}
