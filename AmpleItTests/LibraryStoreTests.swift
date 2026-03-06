import XCTest
import SwiftUI
@testable import AmpleIt

final class LibraryStoreTests: XCTestCase {
    var store: LibraryStore!

    override func setUp() {
        super.setUp()
        store = LibraryStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_loadsMockSongs() {
        XCTAssertEqual(store.librarySongs.count, MockData.songs.count)
        XCTAssertFalse(store.librarySongs.isEmpty)
    }

    func test_init_loadsMockPlaylists() {
        XCTAssertEqual(store.playlists.count, MockData.playlists.count)
        XCTAssertFalse(store.playlists.isEmpty)
    }

    func test_init_queueIsEmpty() {
        XCTAssertTrue(store.queue.isEmpty)
    }

    func test_init_playlistSongIDsInitializedEmpty() {
        for playlist in store.playlists {
            XCTAssertNotNil(store.playlistSongIDs[playlist.id])
            XCTAssertTrue(store.playlistSongIDs[playlist.id]!.isEmpty)
        }
    }

    func test_init_playlistArtworkIsEmpty() {
        XCTAssertTrue(store.playlistArtwork.isEmpty)
    }

    // MARK: - duplicate

    func test_duplicate_appendsCopyToLibrary() {
        let initialCount = store.librarySongs.count
        store.duplicate(song: store.librarySongs[0])
        XCTAssertEqual(store.librarySongs.count, initialCount + 1)
    }

    func test_duplicate_copyHasNewID() {
        let original = store.librarySongs[0]
        store.duplicate(song: original)
        let copy = store.librarySongs.last!
        XCTAssertNotEqual(copy.id, original.id)
    }

    func test_duplicate_copyTitleHasCopySuffix() {
        let original = store.librarySongs[0]
        store.duplicate(song: original)
        let copy = store.librarySongs.last!
        XCTAssertEqual(copy.title, "\(original.title) Copy")
    }

    func test_duplicate_copyPreservesArtist() {
        let original = store.librarySongs[0]
        store.duplicate(song: original)
        let copy = store.librarySongs.last!
        XCTAssertEqual(copy.artist, original.artist)
    }

    func test_duplicate_multipleTimes_appendsMultipleCopies() {
        let original = store.librarySongs[0]
        let initialCount = store.librarySongs.count
        store.duplicate(song: original)
        store.duplicate(song: original)
        XCTAssertEqual(store.librarySongs.count, initialCount + 2)
    }

    // MARK: - delete

    func test_delete_removesSongFromLibrary() {
        let song = store.librarySongs[0]
        let initialCount = store.librarySongs.count
        store.delete(songID: song.id)
        XCTAssertEqual(store.librarySongs.count, initialCount - 1)
        XCTAssertFalse(store.librarySongs.contains(where: { $0.id == song.id }))
    }

    func test_delete_removesSongFromQueue() {
        let song = store.librarySongs[0]
        store.addToQueue(song: song)
        store.delete(songID: song.id)
        XCTAssertFalse(store.queue.contains(where: { $0.id == song.id }))
    }

    func test_delete_removesSongIDFromAllPlaylists() {
        let song = store.librarySongs[0]
        let playlist = store.playlists[0]
        store.addSong(song, to: playlist.id)
        store.delete(songID: song.id)
        XCTAssertFalse(store.playlistSongIDs[playlist.id]!.contains(song.id))
    }

    func test_delete_nonExistentID_isNoop() {
        let initialCount = store.librarySongs.count
        store.delete(songID: UUID())
        XCTAssertEqual(store.librarySongs.count, initialCount)
    }

    func test_delete_doesNotAffectOtherSongs() {
        let song0 = store.librarySongs[0]
        let song1 = store.librarySongs[1]
        store.delete(songID: song0.id)
        XCTAssertTrue(store.librarySongs.contains(where: { $0.id == song1.id }))
    }

    // MARK: - addToQueue

    func test_addToQueue_appendsSong() {
        let song = store.librarySongs[0]
        store.addToQueue(song: song)
        XCTAssertEqual(store.queue.count, 1)
        XCTAssertEqual(store.queue[0].id, song.id)
    }

    func test_addToQueue_maintainsInsertionOrder() {
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

    func test_addToQueue_sameSongMultipleTimes() {
        let song = store.librarySongs[0]
        store.addToQueue(song: song)
        store.addToQueue(song: song)
        XCTAssertEqual(store.queue.count, 2)
    }

    // MARK: - popQueue

    func test_popQueue_returnsNilWhenEmpty() {
        XCTAssertNil(store.popQueue())
    }

    func test_popQueue_returnsFirstSong() {
        let song1 = store.librarySongs[0]
        let song2 = store.librarySongs[1]
        store.addToQueue(song: song1)
        store.addToQueue(song: song2)
        let popped = store.popQueue()
        XCTAssertEqual(popped?.id, song1.id)
    }

    func test_popQueue_removesSongFromQueue() {
        let song = store.librarySongs[0]
        store.addToQueue(song: song)
        _ = store.popQueue()
        XCTAssertTrue(store.queue.isEmpty)
    }

    func test_popQueue_isFIFO() {
        let song1 = store.librarySongs[0]
        let song2 = store.librarySongs[1]
        let song3 = store.librarySongs[2]
        store.addToQueue(song: song1)
        store.addToQueue(song: song2)
        store.addToQueue(song: song3)
        XCTAssertEqual(store.popQueue()?.id, song1.id)
        XCTAssertEqual(store.popQueue()?.id, song2.id)
        XCTAssertEqual(store.popQueue()?.id, song3.id)
        XCTAssertNil(store.popQueue())
    }

    func test_popQueue_afterAllPopped_returnsNil() {
        store.addToQueue(song: store.librarySongs[0])
        _ = store.popQueue()
        XCTAssertNil(store.popQueue())
    }

    // MARK: - addSong to playlist

    func test_addSong_appendsSongIDToPlaylist() {
        let song = store.librarySongs[0]
        let playlist = store.playlists[0]
        store.addSong(song, to: playlist.id)
        XCTAssertTrue(store.playlistSongIDs[playlist.id]!.contains(song.id))
    }

    func test_addSong_incrementsPlaylistCount() {
        let song = store.librarySongs[0]
        let playlist = store.playlists[0]
        let initialCount = playlist.count
        store.addSong(song, to: playlist.id)
        let updated = store.playlists.first(where: { $0.id == playlist.id })!
        XCTAssertEqual(updated.count, initialCount + 1)
    }

    func test_addSong_toNonExistentPlaylist_isNoop() {
        let song = store.librarySongs[0]
        let fakeID = UUID()
        store.addSong(song, to: fakeID)
        XCTAssertNil(store.playlistSongIDs[fakeID])
    }

    func test_addSong_multiplesongsToSamePlaylist() {
        let song1 = store.librarySongs[0]
        let song2 = store.librarySongs[1]
        let playlist = store.playlists[0]
        store.addSong(song1, to: playlist.id)
        store.addSong(song2, to: playlist.id)
        XCTAssertEqual(store.playlistSongIDs[playlist.id]!.count, 2)
    }

    func test_addSong_preservesInsertionOrder() {
        let song1 = store.librarySongs[0]
        let song2 = store.librarySongs[1]
        let playlist = store.playlists[0]
        store.addSong(song1, to: playlist.id)
        store.addSong(song2, to: playlist.id)
        let ids = store.playlistSongIDs[playlist.id]!
        XCTAssertEqual(ids[0], song1.id)
        XCTAssertEqual(ids[1], song2.id)
    }

    // MARK: - createPlaylist

    func test_createPlaylist_appendsToPlaylists() {
        let initialCount = store.playlists.count
        store.createPlaylist(name: "New Mix")
        XCTAssertEqual(store.playlists.count, initialCount + 1)
    }

    func test_createPlaylist_returnsPlaylistWithCorrectName() {
        let playlist = store.createPlaylist(name: "My Playlist")
        XCTAssertEqual(playlist.name, "My Playlist")
    }

    func test_createPlaylist_startsWithZeroCount() {
        let playlist = store.createPlaylist(name: "Empty")
        XCTAssertEqual(playlist.count, 0)
    }

    func test_createPlaylist_initializesEmptySongIDArray() {
        let playlist = store.createPlaylist(name: "New")
        XCTAssertNotNil(store.playlistSongIDs[playlist.id])
        XCTAssertTrue(store.playlistSongIDs[playlist.id]!.isEmpty)
    }

    func test_createPlaylist_storesArtworkWhenProvided() {
        let artwork = Image(systemName: "music.note")
        let playlist = store.createPlaylist(name: "Art Mix", artwork: artwork)
        XCTAssertNotNil(store.playlistArtwork[playlist.id])
    }

    func test_createPlaylist_doesNotStoreArtworkWhenNil() {
        let playlist = store.createPlaylist(name: "No Art", artwork: nil)
        XCTAssertNil(store.playlistArtwork[playlist.id])
    }

    func test_createPlaylist_newPlaylistHasUniqueID() {
        let p1 = store.createPlaylist(name: "A")
        let p2 = store.createPlaylist(name: "B")
        XCTAssertNotEqual(p1.id, p2.id)
    }

    // MARK: - deletePlaylists

    func test_deletePlaylists_removesSpecifiedPlaylists() {
        let p1 = store.createPlaylist(name: "P1")
        let p2 = store.createPlaylist(name: "P2")
        store.deletePlaylists(ids: [p1.id, p2.id])
        XCTAssertFalse(store.playlists.contains(where: { $0.id == p1.id }))
        XCTAssertFalse(store.playlists.contains(where: { $0.id == p2.id }))
    }

    func test_deletePlaylists_keepsNonSelectedPlaylists() {
        let p1 = store.createPlaylist(name: "Keep")
        let p2 = store.createPlaylist(name: "Delete")
        store.deletePlaylists(ids: [p2.id])
        XCTAssertTrue(store.playlists.contains(where: { $0.id == p1.id }))
    }

    func test_deletePlaylists_removesSongIDsForDeletedPlaylist() {
        let playlist = store.createPlaylist(name: "P")
        let song = store.librarySongs[0]
        store.addSong(song, to: playlist.id)
        store.deletePlaylists(ids: [playlist.id])
        XCTAssertNil(store.playlistSongIDs[playlist.id])
    }

    func test_deletePlaylists_removesArtworkForDeletedPlaylist() {
        let artwork = Image(systemName: "music.note")
        let playlist = store.createPlaylist(name: "P", artwork: artwork)
        store.deletePlaylists(ids: [playlist.id])
        XCTAssertNil(store.playlistArtwork[playlist.id])
    }

    func test_deletePlaylists_withEmptySet_isNoop() {
        let initialCount = store.playlists.count
        store.deletePlaylists(ids: [])
        XCTAssertEqual(store.playlists.count, initialCount)
    }

    // MARK: - songs(in:)

    func test_songsInPlaylist_emptyWhenPlaylistHasNoSongs() {
        let playlist = store.createPlaylist(name: "Empty")
        XCTAssertTrue(store.songs(in: playlist.id).isEmpty)
    }

    func test_songsInPlaylist_returnsAddedSongs() {
        let playlist = store.createPlaylist(name: "Mix")
        let song1 = store.librarySongs[0]
        let song2 = store.librarySongs[1]
        store.addSong(song1, to: playlist.id)
        store.addSong(song2, to: playlist.id)
        let result = store.songs(in: playlist.id)
        XCTAssertEqual(result.count, 2)
    }

    func test_songsInPlaylist_preservesInsertionOrder() {
        let playlist = store.createPlaylist(name: "Mix")
        let song1 = store.librarySongs[0]
        let song2 = store.librarySongs[1]
        store.addSong(song1, to: playlist.id)
        store.addSong(song2, to: playlist.id)
        let result = store.songs(in: playlist.id)
        XCTAssertEqual(result[0].id, song1.id)
        XCTAssertEqual(result[1].id, song2.id)
    }

    func test_songsInPlaylist_returnsEmptyForUnknownID() {
        XCTAssertTrue(store.songs(in: UUID()).isEmpty)
    }

    func test_songsInPlaylist_excludesSongDeletedFromLibrary() {
        let playlist = store.createPlaylist(name: "Mix")
        let song = store.librarySongs[0]
        store.addSong(song, to: playlist.id)
        store.delete(songID: song.id)
        XCTAssertTrue(store.songs(in: playlist.id).isEmpty)
    }

    func test_songsInPlaylist_afterDeletion_correctCount() {
        let playlist = store.createPlaylist(name: "Mix")
        let song1 = store.librarySongs[0]
        let song2 = store.librarySongs[1]
        store.addSong(song1, to: playlist.id)
        store.addSong(song2, to: playlist.id)
        store.delete(songID: song1.id)
        let result = store.songs(in: playlist.id)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, song2.id)
    }
}
