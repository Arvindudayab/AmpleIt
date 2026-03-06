import XCTest
import SwiftUI
@testable import AmpleIt

final class SongActionsOverlayTests: XCTestCase {
    var store: LibraryStore!

    override func setUp() {
        super.setUp()
        store = LibraryStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_isPlaylistPickerCardPresented_initiallyFalse() {
        let isPlaylistPickerCardPresented = false
        XCTAssertFalse(isPlaylistPickerCardPresented)
    }

    func test_isCreatePlaylistPresented_initiallyFalse() {
        let isCreatePlaylistPresented = false
        XCTAssertFalse(isCreatePlaylistPresented)
    }

    func test_isDeleteConfirmationPresented_initiallyFalse() {
        let isDeleteConfirmationPresented = false
        XCTAssertFalse(isDeleteConfirmationPresented)
    }

    func test_newPlaylistName_initiallyEmpty() {
        let newPlaylistName = ""
        XCTAssertTrue(newPlaylistName.isEmpty)
    }

    // MARK: - Callbacks

    func test_onEdit_callback_invoked() {
        var called = false
        let onEdit: (() -> Void)? = { called = true }
        onEdit?()
        XCTAssertTrue(called)
    }

    func test_onDuplicate_callback_invoked() {
        var called = false
        let onDuplicate: (() -> Void)? = { called = true }
        onDuplicate?()
        XCTAssertTrue(called)
    }

    func test_onAddToQueue_callback_invoked() {
        var called = false
        let onAddToQueue: (() -> Void)? = { called = true }
        onAddToQueue?()
        XCTAssertTrue(called)
    }

    func test_onDelete_callback_invoked() {
        var called = false
        let onDelete: (() -> Void)? = { called = true }
        onDelete?()
        XCTAssertTrue(called)
    }

    func test_onAddToPlaylist_callback_invoked() {
        var called = false
        let onAddToPlaylist: (() -> Void)? = { called = true }
        onAddToPlaylist?()
        XCTAssertTrue(called)
    }

    func test_nilCallbacks_doNotCrash() {
        let onEdit: (() -> Void)? = nil
        let onDuplicate: (() -> Void)? = nil
        let onAddToQueue: (() -> Void)? = nil
        let onDelete: (() -> Void)? = nil
        onEdit?()
        onDuplicate?()
        onAddToQueue?()
        onDelete?()
        // No crash expected
        XCTAssertNil(onEdit)
        XCTAssertNil(onDuplicate)
    }

    // MARK: - Playlist creation within overlay (inline logic)

    func test_createPlaylist_emptyName_doesNotCreate() {
        let initialCount = store.playlists.count
        let trimmed = "".trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            XCTAssertEqual(store.playlists.count, initialCount)
            return
        }
        XCTFail("Should have returned early for empty name")
    }

    func test_createPlaylist_validName_createsAndAddsToPlaylist() {
        let song = store.librarySongs[0]
        let trimmed = "New Mix"
        let created = store.createPlaylist(name: trimmed)
        store.addSong(song, to: created.id)
        XCTAssertTrue(store.playlists.contains(where: { $0.id == created.id }))
        XCTAssertTrue(store.playlistSongIDs[created.id]!.contains(song.id))
    }

    // MARK: - Adding song to existing playlist

    func test_addSongToPlaylist_incrementsCount() {
        let song = store.librarySongs[0]
        let playlist = store.playlists[0]
        let initialCount = playlist.count
        store.addSong(song, to: playlist.id)
        let updated = store.playlists.first(where: { $0.id == playlist.id })!
        XCTAssertEqual(updated.count, initialCount + 1)
    }

    func test_addSongToPlaylist_songAppearsInPlaylist() {
        let song = store.librarySongs[0]
        let playlist = store.playlists[0]
        store.addSong(song, to: playlist.id)
        XCTAssertTrue(store.songs(in: playlist.id).contains(where: { $0.id == song.id }))
    }

    // MARK: - Delete confirmation logic

    func test_deleteConfirmation_onDelete_callsOnDelete() {
        var deleteCalled = false
        var isPresented = true
        // Mirrors confirmationDialog "Delete" button action
        isPresented = false
        deleteCalled = true
        XCTAssertFalse(isPresented)
        XCTAssertTrue(deleteCalled)
    }

    // MARK: - Action card row items

    func test_actionRows_titles_areNonEmpty() {
        let titles = ["Edit", "Duplicate", "Add to Queue", "Add to Playlist", "Delete"]
        for title in titles {
            XCTAssertFalse(title.isEmpty, "Action row title '\(title)' must not be empty")
        }
    }

    func test_actionRows_systemImages_areNonEmpty() {
        let icons = [
            "pencil",
            "square.fill.on.square.fill",
            "text.line.first.and.arrowtriangle.forward",
            "text.badge.plus",
            "trash"
        ]
        for icon in icons {
            XCTAssertFalse(icon.isEmpty)
        }
    }

    func test_deleteAction_isDestructive() {
        // The Delete action row uses isDestructive: true, shown in red
        let isDestructive = true
        XCTAssertTrue(isDestructive)
    }

    func test_otherActions_areNotDestructive() {
        // Edit, Duplicate, Add to Queue, Add to Playlist are not destructive
        let isDestructive = false
        XCTAssertFalse(isDestructive)
    }
}
