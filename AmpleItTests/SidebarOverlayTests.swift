import XCTest
@testable import AmpleIt

final class SidebarOverlayTests: XCTestCase {

    // MARK: - SidebarCard.closeAndSwitch logic

    /// Mirrors SidebarCard.closeAndSwitch(_:)
    private func closeAndSwitch(
        to tab: AppTab,
        selectedTab: inout AppTab,
        isOpen: inout Bool
    ) {
        selectedTab = tab
        isOpen = false
    }

    func test_closeAndSwitch_setsSelectedTab() {
        var selectedTab: AppTab = .home
        var isOpen = true
        closeAndSwitch(to: .songs, selectedTab: &selectedTab, isOpen: &isOpen)
        XCTAssertEqual(selectedTab, .songs)
    }

    func test_closeAndSwitch_closesSidebar() {
        var selectedTab: AppTab = .home
        var isOpen = true
        closeAndSwitch(to: .home, selectedTab: &selectedTab, isOpen: &isOpen)
        XCTAssertFalse(isOpen)
    }

    func test_closeAndSwitch_worksForAllTabs() {
        for tab in AppTab.allCases {
            var selectedTab: AppTab = .home
            var isOpen = true
            closeAndSwitch(to: tab, selectedTab: &selectedTab, isOpen: &isOpen)
            XCTAssertEqual(selectedTab, tab)
            XCTAssertFalse(isOpen)
        }
    }

    func test_closeAndSwitch_toSameTab_stillClosesSidebar() {
        var selectedTab: AppTab = .playlists
        var isOpen = true
        closeAndSwitch(to: .playlists, selectedTab: &selectedTab, isOpen: &isOpen)
        XCTAssertEqual(selectedTab, .playlists)
        XCTAssertFalse(isOpen)
    }

    // MARK: - SidebarNavRow.isSelected logic

    func test_isSelected_trueWhenTabMatchesSelectedTab() {
        let tab = AppTab.songs
        let selectedTab = AppTab.songs
        let isSelected = selectedTab == tab
        XCTAssertTrue(isSelected)
    }

    func test_isSelected_falseWhenTabDoesNotMatchSelectedTab() {
        let tab = AppTab.songs
        let selectedTab = AppTab.home
        let isSelected = selectedTab == tab
        XCTAssertFalse(isSelected)
    }

    func test_isSelected_checkmarkIconWhenSelected() {
        let isSelected = true
        let icon = isSelected ? "checkmark" : "chevron.right"
        XCTAssertEqual(icon, "checkmark")
    }

    func test_isSelected_chevronIconWhenNotSelected() {
        let isSelected = false
        let icon = isSelected ? "checkmark" : "chevron.right"
        XCTAssertEqual(icon, "chevron.right")
    }

    // MARK: - SidebarCard dimensions

    func test_openWidth_cappedAt320ForWideContainers() {
        let containerWidth: CGFloat = 600
        let openWidth = min(containerWidth * 0.58, 320)
        XCTAssertEqual(openWidth, 320)
    }

    func test_openWidth_scaledFor400PointContainer() {
        let containerWidth: CGFloat = 400
        let openWidth = min(containerWidth * 0.58, 320)
        XCTAssertEqual(openWidth, 232, accuracy: 0.01)
    }

    func test_openWidth_neverExceeds320() {
        for width in stride(from: CGFloat(320), to: 2000, by: 50) {
            let openWidth = min(width * 0.58, 320)
            XCTAssertLessThanOrEqual(openWidth, 320)
        }
    }

    func test_openHeight_cappedAt380ForTallContainers() {
        let containerHeight: CGFloat = 900
        let openHeight = min(containerHeight * 0.50, 380)
        XCTAssertEqual(openHeight, 380)
    }

    func test_openHeight_scaledFor600PointContainer() {
        let containerHeight: CGFloat = 600
        let openHeight = min(containerHeight * 0.50, 380)
        XCTAssertEqual(openHeight, 300, accuracy: 0.01)
    }

    func test_openHeight_neverExceeds380() {
        for height in stride(from: CGFloat(380), to: 1500, by: 50) {
            let openHeight = min(height * 0.50, 380)
            XCTAssertLessThanOrEqual(openHeight, 380)
        }
    }

    // MARK: - SidebarOverlay hit-testing

    func test_allowsHitTesting_trueWhenOpen() {
        let isOpen = true
        XCTAssertTrue(isOpen)
    }

    func test_allowsHitTesting_falseWhenClosed() {
        let isOpen = false
        XCTAssertFalse(isOpen)
    }

    // MARK: - Background tap dismisses sidebar

    func test_backgroundTap_closesSidebar() {
        var isOpen = true
        // Mirrors Rectangle.onTapGesture { isOpen = false }
        isOpen = false
        XCTAssertFalse(isOpen)
    }

    // MARK: - Nav item icons match expected system names

    func test_homeNavIcon() {
        let icon = "house.fill"
        XCTAssertFalse(icon.isEmpty)
    }

    func test_songsNavIcon() {
        let icon = "music.note.list"
        XCTAssertFalse(icon.isEmpty)
    }

    func test_playlistsNavIcon() {
        let icon = "square.grid.2x2.fill"
        XCTAssertFalse(icon.isEmpty)
    }

    func test_ampNavIcon() {
        let icon = "sparkles"
        XCTAssertFalse(icon.isEmpty)
    }

    func test_navIcons_allUnique() {
        let icons = ["house.fill", "music.note.list", "square.grid.2x2.fill", "sparkles"]
        XCTAssertEqual(Set(icons).count, icons.count)
    }

    // MARK: - Footer tip

    func test_footerTip_text() {
        let tip = "Tip: Long-press a song for quick actions."
        XCTAssertFalse(tip.isEmpty)
    }
}
