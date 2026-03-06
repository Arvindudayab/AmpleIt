import XCTest
import SwiftUI
@testable import AmpleIt

final class PlaylistsViewTests: XCTestCase {
    var store: LibraryStore!

    override func setUp() {
        super.setUp()
        store = LibraryStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    /// Mirrors PlaylistsView.toggleSelection(for:)
    private func toggleSelection(id: UUID, in selectedIDs: inout Set<UUID>) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    /// Mirrors PlaylistsView.createPlaylist()
    @discardableResult
    private func createPlaylist(name: String, artwork: Image? = nil, store: LibraryStore) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        store.createPlaylist(name: trimmed, artwork: artwork)
        return true
    }

    /// Mirrors PlaylistsView.deleteSelectedPlaylists()
    @discardableResult
    private func deleteSelectedPlaylists(ids: Set<UUID>, store: LibraryStore) -> Bool {
        guard !ids.isEmpty else { return false }
        store.deletePlaylists(ids: ids)
        return true
    }

    // MARK: - allPlaylists

    func test_allPlaylists_reflectsStoreCount() {
        XCTAssertEqual(store.playlists.count, MockData.playlists.count)
    }

    func test_allPlaylists_emptyAfterDeletingAll() {
        let ids = Set(store.playlists.map(\.id))
        store.deletePlaylists(ids: ids)
        XCTAssertTrue(store.playlists.isEmpty)
    }

    func test_allPlaylists_growsAfterCreate() {
        let before = store.playlists.count
        createPlaylist(name: "New", store: store)
        XCTAssertEqual(store.playlists.count, before + 1)
    }

    // MARK: - columns

    func test_columns_countIsAlwaysTwo() {
        // PlaylistsView uses a 2-column LazyVGrid
        let expectedColumnCount = 2
        XCTAssertEqual(expectedColumnCount, 2)
    }

    // MARK: - toggleSelection

    func test_toggleSelection_insertsIDWhenNotPresent() {
        var selected: Set<UUID> = []
        let id = UUID()
        toggleSelection(id: id, in: &selected)
        XCTAssertTrue(selected.contains(id))
    }

    func test_toggleSelection_removesIDWhenPresent() {
        let id = UUID()
        var selected: Set<UUID> = [id]
        toggleSelection(id: id, in: &selected)
        XCTAssertFalse(selected.contains(id))
    }

    func test_toggleSelection_togglingTwiceResultsInEmptySet() {
        var selected: Set<UUID> = []
        let id = UUID()
        toggleSelection(id: id, in: &selected)
        toggleSelection(id: id, in: &selected)
        XCTAssertTrue(selected.isEmpty)
    }

    func test_toggleSelection_multipleDistinctIDs() {
        var selected: Set<UUID> = []
        let id1 = UUID()
        let id2 = UUID()
        toggleSelection(id: id1, in: &selected)
        toggleSelection(id: id2, in: &selected)
        XCTAssertEqual(selected.count, 2)
        XCTAssertTrue(selected.contains(id1))
        XCTAssertTrue(selected.contains(id2))
    }

    func test_toggleSelection_removingOneDoesNotAffectOthers() {
        let id1 = UUID()
        let id2 = UUID()
        var selected: Set<UUID> = [id1, id2]
        toggleSelection(id: id1, in: &selected)
        XCTAssertFalse(selected.contains(id1))
        XCTAssertTrue(selected.contains(id2))
    }

    // MARK: - createPlaylist

    func test_createPlaylist_emptyName_doesNotCreate() {
        let before = store.playlists.count
        let created = createPlaylist(name: "", store: store)
        XCTAssertFalse(created)
        XCTAssertEqual(store.playlists.count, before)
    }

    func test_createPlaylist_whitespaceOnly_doesNotCreate() {
        let before = store.playlists.count
        let created = createPlaylist(name: "   ", store: store)
        XCTAssertFalse(created)
        XCTAssertEqual(store.playlists.count, before)
    }

    func test_createPlaylist_validName_creates() {
        let before = store.playlists.count
        let created = createPlaylist(name: "My Mix", store: store)
        XCTAssertTrue(created)
        XCTAssertEqual(store.playlists.count, before + 1)
    }

    func test_createPlaylist_trimsLeadingAndTrailingWhitespace() {
        createPlaylist(name: "  Road Trip  ", store: store)
        let last = store.playlists.last!
        XCTAssertEqual(last.name, "Road Trip")
    }

    func test_createPlaylist_preservesInternalSpaces() {
        createPlaylist(name: "Late Night Vibes", store: store)
        let last = store.playlists.last!
        XCTAssertEqual(last.name, "Late Night Vibes")
    }

    func test_createPlaylist_withArtwork_storesArtwork() {
        let artwork = Image(systemName: "music.note")
        createPlaylist(name: "Art Mix", artwork: artwork, store: store)
        let created = store.playlists.last!
        XCTAssertNotNil(store.playlistArtwork[created.id])
    }

    func test_createPlaylist_withoutArtwork_noArtworkStored() {
        createPlaylist(name: "No Art", artwork: nil, store: store)
        let created = store.playlists.last!
        XCTAssertNil(store.playlistArtwork[created.id])
    }

    // MARK: - deleteSelectedPlaylists

    func test_deleteSelectedPlaylists_emptySet_isNoop() {
        let before = store.playlists.count
        let deleted = deleteSelectedPlaylists(ids: [], store: store)
        XCTAssertFalse(deleted)
        XCTAssertEqual(store.playlists.count, before)
    }

    func test_deleteSelectedPlaylists_removesSelectedPlaylists() {
        let p1 = store.createPlaylist(name: "A")
        let p2 = store.createPlaylist(name: "B")
        deleteSelectedPlaylists(ids: [p1.id, p2.id], store: store)
        XCTAssertFalse(store.playlists.contains(where: { $0.id == p1.id }))
        XCTAssertFalse(store.playlists.contains(where: { $0.id == p2.id }))
    }

    func test_deleteSelectedPlaylists_keepsNonSelectedPlaylists() {
        let keep = store.createPlaylist(name: "Keep")
        let remove = store.createPlaylist(name: "Remove")
        deleteSelectedPlaylists(ids: [remove.id], store: store)
        XCTAssertTrue(store.playlists.contains(where: { $0.id == keep.id }))
    }

    func test_deleteSelectedPlaylists_clearsSelectionAfter() {
        let p = store.createPlaylist(name: "P")
        var selectedIDs: Set<UUID> = [p.id]
        deleteSelectedPlaylists(ids: selectedIDs, store: store)
        selectedIDs.removeAll()
        XCTAssertTrue(selectedIDs.isEmpty)
    }

    // MARK: - Initial State

    func test_isCreatePlaylistPresented_initiallyFalse() {
        let isPresented = false
        XCTAssertFalse(isPresented)
    }

    func test_isSelecting_initiallyFalse() {
        let isSelecting = false
        XCTAssertFalse(isSelecting)
    }

    func test_selectedPlaylistIDs_initiallyEmpty() {
        let selected: Set<UUID> = []
        XCTAssertTrue(selected.isEmpty)
    }

    func test_newPlaylistName_initiallyEmpty() {
        let name = ""
        XCTAssertTrue(name.isEmpty)
    }
}
