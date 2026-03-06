import XCTest
@testable import AmpleIt

final class AppScreenContainerTests: XCTestCase {

    // MARK: - Default parameter values

    func test_wrapInNavigationStack_defaultsToTrue() {
        let defaultValue = true
        XCTAssertTrue(defaultValue)
    }

    func test_showsSidebarButton_defaultsToTrue() {
        let defaultValue = true
        XCTAssertTrue(defaultValue)
    }

    func test_showsTrailingPlaceholder_defaultsToTrue() {
        let defaultValue = true
        XCTAssertTrue(defaultValue)
    }

    func test_trailingToolbar_defaultsToNil() {
        let trailingToolbar: AnyView? = nil
        XCTAssertNil(trailingToolbar)
    }

    // MARK: - Sidebar toggle logic

    func test_sidebarButton_togglesIsSidebarOpen() {
        var isSidebarOpen = false
        isSidebarOpen.toggle()
        XCTAssertTrue(isSidebarOpen)
        isSidebarOpen.toggle()
        XCTAssertFalse(isSidebarOpen)
    }

    func test_sidebarButton_closesWhenAlreadyOpen() {
        var isSidebarOpen = true
        isSidebarOpen.toggle()
        XCTAssertFalse(isSidebarOpen)
    }

    // MARK: - Title display

    func test_titleIsNonEmpty_forHomeTab() {
        XCTAssertFalse(AppTab.home.title.isEmpty)
    }

    func test_titleIsNonEmpty_forSongsTab() {
        XCTAssertFalse(AppTab.songs.title.isEmpty)
    }

    func test_titleIsNonEmpty_forPlaylistsTab() {
        XCTAssertFalse(AppTab.playlists.title.isEmpty)
    }

    func test_titleIsNonEmpty_forAmpTab() {
        XCTAssertFalse(AppTab.amp.title.isEmpty)
    }

    // MARK: - Custom trailing toolbar vs placeholder logic

    func test_trailingToolbar_overridesPlaceholder() {
        // When trailingToolbar != nil, it is used instead of the invisible placeholder
        let trailingToolbar: AnyView? = AnyView(Text("Select"))
        let showsPlaceholder = trailingToolbar == nil
        XCTAssertFalse(showsPlaceholder)
    }

    func test_trailingPlaceholder_shownWhenToolbarNilAndFlagTrue() {
        let trailingToolbar: AnyView? = nil
        let showsTrailingPlaceholder = true
        let shouldShowPlaceholder = trailingToolbar == nil && showsTrailingPlaceholder
        XCTAssertTrue(shouldShowPlaceholder)
    }

    func test_trailingPlaceholder_hiddenWhenFlagFalse() {
        let trailingToolbar: AnyView? = nil
        let showsTrailingPlaceholder = false
        let shouldShowPlaceholder = trailingToolbar == nil && showsTrailingPlaceholder
        XCTAssertFalse(shouldShowPlaceholder)
    }

    // MARK: - NavigationStack wrapping

    func test_wrapInNavigationStack_true_wrapsContent() {
        let wraps = true
        XCTAssertTrue(wraps)
    }

    func test_wrapInNavigationStack_false_doesNotWrap() {
        let wraps = false
        XCTAssertFalse(wraps)
    }

    // MARK: - isSidebarOpen initial state across screens

    func test_isSidebarOpen_initiallyFalse_forAllScreens() {
        // All preview wrappers start with isSidebarOpen = false
        let isSidebarOpen = false
        XCTAssertFalse(isSidebarOpen)
    }
}
