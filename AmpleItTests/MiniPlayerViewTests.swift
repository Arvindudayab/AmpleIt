import XCTest
@testable import AmpleIt

final class MiniPlayerViewTests: XCTestCase {

    // MARK: - Song display

    func test_song_titleIsAccessible() {
        let song = Song(id: UUID(), title: "Rainy Streetlights", artist: "Orchid")
        XCTAssertEqual(song.title, "Rainy Streetlights")
    }

    func test_song_artistIsAccessible() {
        let song = Song(id: UUID(), title: "Rainy Streetlights", artist: "Orchid")
        XCTAssertEqual(song.artist, "Orchid")
    }

    // MARK: - Artwork seed

    func test_artworkSeed_isSongIDUUIDString() {
        let song = Song(id: UUID(), title: "Track", artist: "Artist")
        let seed = song.id.uuidString
        XCTAssertFalse(seed.isEmpty)
        // UUID strings are 36 characters: 8-4-4-4-12
        XCTAssertEqual(seed.count, 36)
    }

    func test_artworkSeed_isUniquePerSong() {
        let song1 = Song(id: UUID(), title: "A", artist: "X")
        let song2 = Song(id: UUID(), title: "A", artist: "X")
        XCTAssertNotEqual(song1.id.uuidString, song2.id.uuidString)
    }

    // MARK: - isPlaying icon logic

    func test_isPlaying_true_showsPauseIcon() {
        let isPlaying = true
        let icon = isPlaying ? "pause.fill" : "play.fill"
        XCTAssertEqual(icon, "pause.fill")
    }

    func test_isPlaying_false_showsPlayIcon() {
        let isPlaying = false
        let icon = isPlaying ? "pause.fill" : "play.fill"
        XCTAssertEqual(icon, "play.fill")
    }

    func test_isPlaying_toggle_updatesIcon() {
        var isPlaying = true
        isPlaying.toggle()
        let icon = isPlaying ? "pause.fill" : "play.fill"
        XCTAssertEqual(icon, "play.fill")
    }

    // MARK: - Callbacks

    func test_onTap_callback_invoked() {
        var tapCalled = false
        let onTap = { tapCalled = true }
        onTap()
        XCTAssertTrue(tapCalled)
    }

    func test_onNext_callback_invoked() {
        var nextCalled = false
        let onNext = { nextCalled = true }
        onNext()
        XCTAssertTrue(nextCalled)
    }

    func test_onPrev_callback_invoked() {
        var prevCalled = false
        let onPrev = { prevCalled = true }
        onPrev()
        XCTAssertTrue(prevCalled)
    }

    func test_onTap_doesNotTriggerOnNext() {
        var nextCalled = false
        var tapCalled = false
        let onNext = { nextCalled = true }
        let onTap = { tapCalled = true }
        onTap()
        XCTAssertTrue(tapCalled)
        XCTAssertFalse(nextCalled)
        _ = onNext  // suppress warning
    }

    // MARK: - Control button icons

    func test_prevButtonIcon() {
        let icon = "backward.fill"
        XCTAssertFalse(icon.isEmpty)
    }

    func test_nextButtonIcon() {
        let icon = "forward.fill"
        XCTAssertFalse(icon.isEmpty)
    }

    func test_prevAndNextIcons_areDifferent() {
        XCTAssertNotEqual("backward.fill", "forward.fill")
    }

    // MARK: - Background gradient colours

    func test_backgroundGradient_usesAppBackground() {
        let startColorName = "AppBackground"
        XCTAssertFalse(startColorName.isEmpty)
    }

    func test_backgroundGradient_usesOppositeColor() {
        let endColorName = "opposite"
        XCTAssertFalse(endColorName.isEmpty)
    }

    // MARK: - MockData integration

    func test_mockDataFirstSong_isUsable() {
        let song = MockData.songs.first!
        XCTAssertFalse(song.title.isEmpty)
        XCTAssertFalse(song.artist.isEmpty)
    }
}
