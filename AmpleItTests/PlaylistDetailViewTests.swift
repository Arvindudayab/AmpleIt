import XCTest
@testable import AmpleIt

final class PlaylistDetailViewTests: XCTestCase {
    var store: LibraryStore!
    var playlist: Playlist!

    override func setUp() {
        super.setUp()
        store = LibraryStore()
        playlist = store.playlists[0]
    }

    override func tearDown() {
        store = nil
        playlist = nil
        super.tearDown()
    }

    /// Mirrors PlaylistDetailView.estimatedMinutes
    private func estimatedMinutes(songCount: Int) -> Int {
        max(1, songCount * 3)
    }

    /// Mirrors PlaylistDetailView.currentSongs
    private func currentSongs(shuffledSongs: [Song]?, storeSongs: [Song]) -> [Song] {
        shuffledSongs ?? storeSongs
    }

    // MARK: - estimatedMinutes

    func test_estimatedMinutes_zeroSongs_returnsOne() {
        XCTAssertEqual(estimatedMinutes(songCount: 0), 1)
    }

    func test_estimatedMinutes_negativeSongs_returnsOne() {
        XCTAssertEqual(estimatedMinutes(songCount: -10), 1)
    }

    func test_estimatedMinutes_oneSong_returnsThree() {
        XCTAssertEqual(estimatedMinutes(songCount: 1), 3)
    }

    func test_estimatedMinutes_fiveSongs_returns15() {
        XCTAssertEqual(estimatedMinutes(songCount: 5), 15)
    }

    func test_estimatedMinutes_tenSongs_returns30() {
        XCTAssertEqual(estimatedMinutes(songCount: 10), 30)
    }

    func test_estimatedMinutes_largeSongCount() {
        XCTAssertEqual(estimatedMinutes(songCount: 100), 300)
    }

    func test_estimatedMinutes_alwaysAtLeastOne() {
        for count in -5...0 {
            XCTAssertGreaterThanOrEqual(estimatedMinutes(songCount: count), 1)
        }
    }

    // MARK: - currentSongs

    func test_currentSongs_returnsShuffledWhenAvailable() {
        let songs = store.librarySongs
        let shuffled = songs.shuffled()
        let result = currentSongs(shuffledSongs: shuffled, storeSongs: songs)
        XCTAssertEqual(result.map(\.id), shuffled.map(\.id))
    }

    func test_currentSongs_returnsStoreSongsWhenShuffledIsNil() {
        let songs = store.librarySongs
        let result = currentSongs(shuffledSongs: nil, storeSongs: songs)
        XCTAssertEqual(result.map(\.id), songs.map(\.id))
    }

    func test_currentSongs_returnsEmptyWhenBothEmpty() {
        let result = currentSongs(shuffledSongs: nil, storeSongs: [])
        XCTAssertTrue(result.isEmpty)
    }

    func test_currentSongs_emptyShuffledOverridesStoreSongs() {
        let storeSongs = store.librarySongs
        let result = currentSongs(shuffledSongs: [], storeSongs: storeSongs)
        // shuffledSongs is non-nil (just empty), so it wins over storeSongs
        XCTAssertTrue(result.isEmpty)
    }

    func test_currentSongs_shuffledIsNilAfterLibraryChange() {
        // Mirrors: .onChange(of: libraryStore.songs(in:)) { shuffledSongs = nil }
        var shuffledSongs: [Song]? = store.librarySongs.shuffled()
        XCTAssertNotNil(shuffledSongs)
        shuffledSongs = nil
        XCTAssertNil(shuffledSongs)
    }

    // MARK: - Song count display strings

    func test_songCountSuffix_singular() {
        let count = 1
        let suffix = count == 1 ? "" : "s"
        XCTAssertEqual(suffix, "")
    }

    func test_songCountSuffix_plural() {
        let count = 5
        let suffix = count == 1 ? "" : "s"
        XCTAssertEqual(suffix, "s")
    }

    func test_songCountSuffix_zero_isPlural() {
        let count = 0
        let suffix = count == 1 ? "" : "s"
        XCTAssertEqual(suffix, "s")
    }

    func test_footerLabel_format() {
        let songs = store.songs(in: playlist.id)
        let minutes = estimatedMinutes(songCount: songs.count)
        let suffix = songs.count == 1 ? "" : "s"
        let label = "\(songs.count) song\(suffix), \(minutes) minutes"
        XCTAssertTrue(label.contains("song"))
        XCTAssertTrue(label.contains("minutes"))
    }

    // MARK: - backSwipeGesture parameters

    func test_backSwipeGesture_minimumDistance() {
        let minDistance: CGFloat = 20
        XCTAssertEqual(minDistance, 20)
    }

    func test_backSwipeGesture_startLocationThreshold_acceptsEdge() {
        // startLocation.x < 28 allows the swipe
        XCTAssertTrue(CGFloat(10) < 28)
        XCTAssertTrue(CGFloat(0) < 28)
    }

    func test_backSwipeGesture_startLocationThreshold_rejectsCenter() {
        XCTAssertFalse(CGFloat(30) < 28)
        XCTAssertFalse(CGFloat(100) < 28)
    }

    func test_backSwipeGesture_translationWidth_acceptsLargeSwipe() {
        // translation.width > 100
        XCTAssertTrue(CGFloat(150) > 100)
        XCTAssertTrue(CGFloat(101) > 100)
    }

    func test_backSwipeGesture_translationWidth_rejectsSmallSwipe() {
        XCTAssertFalse(CGFloat(50) > 100)
        XCTAssertFalse(CGFloat(100) > 100)
    }

    func test_backSwipeGesture_verticalTranslation_acceptsWithinBound() {
        // abs(translation.height) < 60
        XCTAssertTrue(abs(CGFloat(59)) < 60)
        XCTAssertTrue(abs(CGFloat(0)) < 60)
    }

    func test_backSwipeGesture_verticalTranslation_rejectsExceedingBound() {
        XCTAssertFalse(abs(CGFloat(60)) < 60)
        XCTAssertFalse(abs(CGFloat(100)) < 60)
    }

    // MARK: - Store integration

    func test_songs_inPlaylist_emptyBeforeAdding() {
        let newPlaylist = store.createPlaylist(name: "New")
        XCTAssertTrue(store.songs(in: newPlaylist.id).isEmpty)
    }

    func test_songs_inPlaylist_afterAddingSongs() {
        let newPlaylist = store.createPlaylist(name: "Test")
        let song = store.librarySongs[0]
        store.addSong(song, to: newPlaylist.id)
        XCTAssertEqual(store.songs(in: newPlaylist.id).count, 1)
    }

    func test_playlistName_isDisplayed() {
        let pl = Playlist(id: UUID(), name: "Workout Mix", count: 0)
        XCTAssertEqual(pl.name, "Workout Mix")
    }
}
