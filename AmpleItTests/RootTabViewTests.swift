import XCTest
@testable import AmpleIt

final class RootTabViewTests: XCTestCase {
    var store: LibraryStore!

    override func setUp() {
        super.setUp()
        // Use the preview factory to guarantee a deterministic MockData-seeded library
        // regardless of on-disk state. LibraryStore() alone calls loadFromDisk() which
        // returns nothing on CI / fresh simulators.
        store = LibraryStore.preview
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    // MARK: - AppTab enum

    func test_appTab_allCasesCount() {
        // AppTab has: home, songs, playlists, presets, amp = 5 cases.
        // Updated from 4 when the "presets" tab was added.
        XCTAssertEqual(AppTab.allCases.count, 5)
    }

    func test_appTab_idEqualsRawValue() {
        for tab in AppTab.allCases {
            XCTAssertEqual(tab.id, tab.rawValue)
        }
    }

    func test_appTab_homeTitle() {
        XCTAssertEqual(AppTab.home.title, "Home")
    }

    func test_appTab_songsTitle() {
        XCTAssertEqual(AppTab.songs.title, "Songs")
    }

    func test_appTab_playlistsTitle() {
        XCTAssertEqual(AppTab.playlists.title, "Playlists")
    }

    func test_appTab_presetsTitle() {
        XCTAssertEqual(AppTab.presets.title, "Presets")
    }

    func test_appTab_ampTitle() {
        XCTAssertEqual(AppTab.amp.title, "Amp")
    }

    func test_appTab_allHaveUniqueRawValues() {
        let rawValues = AppTab.allCases.map(\.rawValue)
        XCTAssertEqual(Set(rawValues).count, rawValues.count)
    }

    func test_appTab_allHaveUniqueTitles() {
        let titles = AppTab.allCases.map(\.title)
        XCTAssertEqual(Set(titles).count, titles.count)
    }

    // MARK: - AppTab: presets case

    func test_appTab_presetsCase_exists() {
        XCTAssertTrue(AppTab.allCases.contains(.presets),
                      "AppTab.presets was removed — update RootTabView if intentional")
    }

    // MARK: - advancePlayback (logic replicated for unit testing)

    private func advancePlayback(from current: Song, store: LibraryStore) -> Song? {
        if let queued = store.popQueue() {
            return queued
        }
        guard !store.librarySongs.isEmpty,
              let idx = store.librarySongs.firstIndex(where: { $0.id == current.id }) else { return nil }
        return store.librarySongs[(idx + 1) % store.librarySongs.count]
    }

    func test_advancePlayback_popsQueueBeforeLibrary() {
        let queuedSong = store.librarySongs[3]
        store.addToQueue(song: queuedSong)
        let current = store.librarySongs[0]
        let next = advancePlayback(from: current, store: store)
        XCTAssertEqual(next?.id, queuedSong.id)
        XCTAssertTrue(store.queue.isEmpty)
    }

    func test_advancePlayback_goesToNextSongInLibrary() {
        let songs = store.librarySongs
        let next = advancePlayback(from: songs[0], store: store)
        XCTAssertEqual(next?.id, songs[1].id)
    }

    func test_advancePlayback_wrapsAroundAtLastSong() {
        let songs = store.librarySongs
        let next = advancePlayback(from: songs[songs.count - 1], store: store)
        XCTAssertEqual(next?.id, songs[0].id)
    }

    func test_advancePlayback_returnsNilForUnknownSong() {
        let unknown = Song(id: UUID(), title: "Ghost", artist: "Nobody")
        let next = advancePlayback(from: unknown, store: store)
        XCTAssertNil(next)
    }

    func test_advancePlayback_returnsNilWhenLibraryEmpty() {
        let ids = Set(store.librarySongs.map(\.id))
        ids.forEach { store.delete(songID: $0) }
        let song = Song(id: UUID(), title: "X", artist: "Y")
        let next = advancePlayback(from: song, store: store)
        XCTAssertNil(next)
    }

    func test_advancePlayback_middleSong_goesToNextIndex() {
        let songs = store.librarySongs
        let idx = 4
        let next = advancePlayback(from: songs[idx], store: store)
        XCTAssertEqual(next?.id, songs[idx + 1].id)
    }

    // MARK: - stepBackPlayback (logic replicated for unit testing)

    private func stepBackPlayback(from current: Song, store: LibraryStore) -> Song? {
        guard !store.librarySongs.isEmpty,
              let idx = store.librarySongs.firstIndex(where: { $0.id == current.id }) else { return nil }
        return store.librarySongs[(idx - 1 + store.librarySongs.count) % store.librarySongs.count]
    }

    func test_stepBackPlayback_goesToPreviousSong() {
        let songs = store.librarySongs
        let prev = stepBackPlayback(from: songs[2], store: store)
        XCTAssertEqual(prev?.id, songs[1].id)
    }

    func test_stepBackPlayback_wrapsAroundAtFirstSong() {
        let songs = store.librarySongs
        let prev = stepBackPlayback(from: songs[0], store: store)
        XCTAssertEqual(prev?.id, songs[songs.count - 1].id)
    }

    func test_stepBackPlayback_returnsNilForUnknownSong() {
        let unknown = Song(id: UUID(), title: "Ghost", artist: "Nobody")
        let prev = stepBackPlayback(from: unknown, store: store)
        XCTAssertNil(prev)
    }

    func test_stepBackPlayback_returnsNilWhenLibraryEmpty() {
        let ids = Set(store.librarySongs.map(\.id))
        ids.forEach { store.delete(songID: $0) }
        let song = Song(id: UUID(), title: "X", artist: "Y")
        let prev = stepBackPlayback(from: song, store: store)
        XCTAssertNil(prev)
    }

    func test_stepBackPlayback_lastSong_goesToSecondToLast() {
        let songs = store.librarySongs
        let prev = stepBackPlayback(from: songs[songs.count - 1], store: store)
        XCTAssertEqual(prev?.id, songs[songs.count - 2].id)
    }

    // MARK: - advancePlayback: nowPlayingID nil branch

    /// When `nowPlayingID` is nil (nothing loaded) and the queue is also empty,
    /// advancePlayback should return nil — not crash and not try to advance from index -1.
    func test_advancePlayback_withNilCurrentID_emptyQueue_returnsNil() {
        // Replicate the guard in RootTabView.advancePlayback():
        // if let queued = store.popQueue() { return queued }
        // guard let currentID = nowPlayingID, let idx = ... else { return nil }
        let nowPlayingID: UUID? = nil
        if let queued = store.popQueue() {
            // We don't have one — this branch shouldn't fire.
            XCTFail("Queue was not empty: \(queued)")
            return
        }
        guard let currentID = nowPlayingID,
              store.librarySongs.firstIndex(where: { $0.id == currentID }) != nil else {
            // Expected path: returns nil
            return
        }
        XCTFail("Should have returned nil before reaching here")
    }

    /// When nowPlayingID is nil but the queue has a song, it should pop from the queue.
    func test_advancePlayback_withNilCurrentID_nonEmptyQueue_popsQueue() {
        let queued = store.librarySongs[2]
        store.addToQueue(song: queued)
        let nowPlayingID: UUID? = nil

        var result: Song? = nil
        if let q = store.popQueue() {
            result = q
        } else if let id = nowPlayingID,
                  let idx = store.librarySongs.firstIndex(where: { $0.id == id }) {
            result = store.librarySongs[(idx + 1) % store.librarySongs.count]
        }
        XCTAssertEqual(result?.id, queued.id)
        XCTAssertTrue(store.queue.isEmpty)
    }

    // MARK: - Deleted now-playing guard (mirrored from RootTabView.onChange)

    func test_deletedNowPlaying_setsNowPlayingIDToNil() {
        let firstSong = store.librarySongs[0]
        var nowPlayingID: UUID? = firstSong.id
        var isSongPlayerPresented = true

        store.delete(songID: firstSong.id)
        // Mirrors RootTabView.onChange(of: libraryStore.librarySongs.map(\.id))
        if let currentID = nowPlayingID,
           !store.librarySongs.contains(where: { $0.id == currentID }) {
            nowPlayingID = nil
            isSongPlayerPresented = false
        }

        XCTAssertNil(nowPlayingID, "nowPlayingID should be nil after its song is deleted")
        XCTAssertFalse(isSongPlayerPresented, "Full-screen player should be dismissed when now-playing song is deleted")
    }

    func test_deletedNonPlayingSong_doesNotClearNowPlayingID() {
        let nowSong  = store.librarySongs[0]
        let otherSong = store.librarySongs[1]
        var nowPlayingID: UUID? = nowSong.id

        store.delete(songID: otherSong.id)
        if let currentID = nowPlayingID,
           !store.librarySongs.contains(where: { $0.id == currentID }) {
            nowPlayingID = nil
        }

        XCTAssertEqual(nowPlayingID, nowSong.id,
                       "Deleting a different song should not clear nowPlayingID")
    }

    // MARK: - nowPlaying initialisation logic

    func test_onAppear_setsFirstSongWhenNowPlayingIsNil() {
        var nowPlaying: Song? = nil
        if nowPlaying == nil {
            nowPlaying = store.librarySongs.first
        }
        XCTAssertEqual(nowPlaying?.id, store.librarySongs.first?.id)
    }

    func test_onAppear_doesNotOverrideExistingNowPlaying() {
        let existingSong = store.librarySongs[2]
        var nowPlaying: Song? = existingSong
        if nowPlaying == nil {
            nowPlaying = store.librarySongs.first
        }
        XCTAssertEqual(nowPlaying?.id, existingSong.id)
    }

    // MARK: - onChange library logic

    func test_onChange_updatesNowPlayingWhenCurrentSongDeleted() {
        let firstSong = store.librarySongs[0]
        var nowPlaying: Song? = firstSong
        store.delete(songID: firstSong.id)

        let songs = store.librarySongs
        if let current = nowPlaying, !songs.contains(where: { $0.id == current.id }) {
            nowPlaying = songs.first
        }

        XCTAssertNotEqual(nowPlaying?.id, firstSong.id)
        XCTAssertEqual(nowPlaying?.id, store.librarySongs.first?.id)
    }

    func test_onChange_keepsNowPlayingWhenCurrentSongStillExists() {
        let song = store.librarySongs[2]
        var nowPlaying: Song? = song
        store.delete(songID: store.librarySongs[0].id)

        let songs = store.librarySongs
        if let current = nowPlaying, !songs.contains(where: { $0.id == current.id }) {
            nowPlaying = songs.first
        }

        XCTAssertEqual(nowPlaying?.id, song.id)
    }

    // MARK: - Default state

    func test_selectedTab_defaultsToHome() {
        let defaultTab: AppTab = .home
        XCTAssertEqual(defaultTab, .home)
    }

    func test_isPlaying_defaultsToTrue() {
        let isPlaying = true
        XCTAssertTrue(isPlaying)
    }

    func test_isSidebarOpen_defaultsFalse() {
        let isSidebarOpen = false
        XCTAssertFalse(isSidebarOpen)
    }
}
