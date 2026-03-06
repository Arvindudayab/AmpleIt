import XCTest
@testable import AmpleIt

final class AppLayoutTests: XCTestCase {

    // MARK: - Mini Player Constants

    func test_miniPlayerHeight() {
        XCTAssertEqual(AppLayout.miniPlayerHeight, 72)
    }

    func test_miniPlayerBottomSpacing() {
        XCTAssertEqual(AppLayout.miniPlayerBottomSpacing, 18)
    }

    func test_miniPlayerScrollInset() {
        XCTAssertEqual(AppLayout.miniPlayerScrollInset, 28)
    }

    // MARK: - Global Padding Constants

    func test_horizontalPadding() {
        XCTAssertEqual(AppLayout.horizontalPadding, 18)
    }

    func test_verticalRowSpacing() {
        XCTAssertEqual(AppLayout.verticalRowSpacing, 10)
    }

    // MARK: - Artwork Constants

    func test_artworkSmallCornerRadius() {
        XCTAssertEqual(AppLayout.artworkSmallCornerRadius, 5)
    }

    func test_artworkLargeCornerRadius() {
        XCTAssertEqual(AppLayout.artworkLargeCornerRadius, 10)
    }

    // MARK: - Card Constants

    func test_cardCornerRadius() {
        XCTAssertEqual(AppLayout.cardCornerRadius, 18)
    }

    // MARK: - Derived Values (used throughout the app)

    func test_miniPlayerTotalScrollInset() {
        // Padding for scroll views: miniPlayerHeight + miniPlayerScrollInset
        let inset = AppLayout.miniPlayerHeight + AppLayout.miniPlayerScrollInset
        XCTAssertEqual(inset, 100)
    }

    func test_miniPlayerTotalBottomPadding() {
        // Padding for FAB / non-scroll UI: miniPlayerHeight + miniPlayerBottomSpacing
        let padding = AppLayout.miniPlayerHeight + AppLayout.miniPlayerBottomSpacing
        XCTAssertEqual(padding, 90)
    }

    // MARK: - Logical Ordering

    func test_smallCornerRadius_isLessThanLargeCornerRadius() {
        XCTAssertLessThan(AppLayout.artworkSmallCornerRadius, AppLayout.artworkLargeCornerRadius)
    }

    func test_horizontalPadding_isPositive() {
        XCTAssertGreaterThan(AppLayout.horizontalPadding, 0)
    }

    func test_miniPlayerScrollInset_greaterThanBottomSpacing() {
        XCTAssertGreaterThan(AppLayout.miniPlayerScrollInset, AppLayout.miniPlayerBottomSpacing)
    }
}
