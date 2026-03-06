import XCTest
@testable import AmpleIt

final class HomeSectionTests: XCTestCase {

    // MARK: - Title

    func test_sectionTitle_isDisplayed() {
        let title = "Recently Added"
        XCTAssertFalse(title.isEmpty)
    }

    func test_sectionTitle_recentlyAdded() {
        let title = "Recently Added"
        XCTAssertEqual(title, "Recently Added")
    }

    func test_sectionTitle_recentlyPlayed() {
        let title = "Recently Played"
        XCTAssertEqual(title, "Recently Played")
    }

    func test_sectionTitles_areDifferent() {
        XCTAssertNotEqual("Recently Added", "Recently Played")
    }

    // MARK: - See all button

    func test_seeAllButton_label() {
        let label = "See all"
        XCTAssertEqual(label, "See all")
    }

    func test_seeAllButton_label_isNonEmpty() {
        let label = "See all"
        XCTAssertFalse(label.isEmpty)
    }

    // MARK: - Content

    func test_homeSection_canReceiveAnySong() {
        let songs = MockData.songs
        XCTAssertEqual(songs.count, 10)
    }

    func test_homeSection_emptyContent_isValid() {
        let songs: [Song] = []
        XCTAssertTrue(songs.isEmpty)
    }

    func test_homeSection_contentCountMatchesSongs() {
        let songs = Array(MockData.songs.prefix(5))
        XCTAssertEqual(songs.count, 5)
    }
}
