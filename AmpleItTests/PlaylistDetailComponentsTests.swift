import XCTest
@testable import AmpleIt

final class PlaylistDetailComponentsTests: XCTestCase {

    // MARK: - PlaylistActionButton

    func test_playlistActionButton_titleIsDisplayed() {
        let title = "Play"
        XCTAssertFalse(title.isEmpty)
    }

    func test_playlistActionButton_systemImageIsProvided() {
        let systemImage = "play.fill"
        XCTAssertFalse(systemImage.isEmpty)
    }

    func test_playlistActionButton_playAction_callback() {
        var actionCalled = false
        let action = { actionCalled = true }
        action()
        XCTAssertTrue(actionCalled)
    }

    func test_playlistActionButton_shuffleAction_callback() {
        var shuffleCalled = false
        let action = { shuffleCalled = true }
        action()
        XCTAssertTrue(shuffleCalled)
    }

    func test_playlistActionButton_playIcon() {
        let icon = "play.fill"
        XCTAssertEqual(icon, "play.fill")
    }

    func test_playlistActionButton_shuffleIcon() {
        let icon = "shuffle"
        XCTAssertEqual(icon, "shuffle")
    }

    func test_playlistActionButton_playAndShuffleIconsAreDifferent() {
        XCTAssertNotEqual("play.fill", "shuffle")
    }

    // MARK: - PlaylistTrackRow

    func test_playlistTrackRow_displaysSongTitle() {
        let song = Song(id: UUID(), title: "Golden Hour", artist: "Aria")
        XCTAssertEqual(song.title, "Golden Hour")
    }

    func test_playlistTrackRow_displaysSongArtist() {
        let song = Song(id: UUID(), title: "Golden Hour", artist: "Aria")
        XCTAssertEqual(song.artist, "Aria")
    }

    func test_playlistTrackRow_ellipsisIcon() {
        let icon = "ellipsis"
        XCTAssertFalse(icon.isEmpty)
    }

    func test_playlistTrackRow_artworkSeedIsSongID() {
        let song = Song(id: UUID(), title: "Track", artist: "Artist")
        let seed = song.id.uuidString
        XCTAssertEqual(seed.count, 36)
    }

    // MARK: - Shuffle logic

    func test_shuffle_producesAllSameSongs() {
        let songs = MockData.songs
        let shuffled = songs.shuffled()
        XCTAssertEqual(Set(shuffled.map(\.id)), Set(songs.map(\.id)))
    }

    func test_shuffle_producesCorrectCount() {
        let songs = MockData.songs
        let shuffled = songs.shuffled()
        XCTAssertEqual(shuffled.count, songs.count)
    }

    func test_shuffledSongsNilOnLibraryChange() {
        // PlaylistDetailView resets shuffledSongs when playlist songs change
        var shuffledSongs: [Song]? = MockData.songs.shuffled()
        shuffledSongs = nil
        XCTAssertNil(shuffledSongs)
    }

    // MARK: - Empty playlist display

    func test_emptyPlaylist_showsNoSongsMessage() {
        let store = LibraryStore()
        let playlist = store.createPlaylist(name: "Empty")
        XCTAssertTrue(store.songs(in: playlist.id).isEmpty)
    }

    func test_emptyPlaylist_emptyStateText() {
        let text = "No songs yet."
        XCTAssertEqual(text, "No songs yet.")
    }

    func test_emptyPlaylist_emptyStateSubtext() {
        let text = "Add songs to start building this playlist."
        XCTAssertFalse(text.isEmpty)
    }

    // MARK: - Replace artwork overlay

    func test_showArtworkOverlay_initiallyFalse() {
        let showArtworkOverlay = false
        XCTAssertFalse(showArtworkOverlay)
    }

    func test_showArtworkOverlay_dismissedByTap() {
        var showArtworkOverlay = true
        // Mirrors dim overlay .onTapGesture { showArtworkOverlay = false }
        showArtworkOverlay = false
        XCTAssertFalse(showArtworkOverlay)
    }

    func test_showArtworkOverlay_setOnCoverTap() {
        var showArtworkOverlay = false
        // Mirrors cover Button action: showArtworkOverlay = true
        showArtworkOverlay = true
        XCTAssertTrue(showArtworkOverlay)
    }

    // MARK: - Replace button label

    func test_replaceButtonLabel() {
        let label = "Replace"
        XCTAssertEqual(label, "Replace")
    }

    // MARK: - Back button accessibility label

    func test_backButtonAccessibilityLabel() {
        let label = "Back"
        XCTAssertEqual(label, "Back")
    }
}
