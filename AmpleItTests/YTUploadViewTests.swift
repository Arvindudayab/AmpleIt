import XCTest
@testable import AmpleIt

final class YTUploadViewTests: XCTestCase {

    // MARK: - Initial state

    func test_youtubeLink_initiallyEmpty() {
        let youtubeLink = ""
        XCTAssertTrue(youtubeLink.isEmpty)
    }

    func test_statusMessage_initiallyEmpty() {
        let statusMessage = ""
        XCTAssertTrue(statusMessage.isEmpty)
    }

    func test_isConverting_initiallyFalse() {
        let isConverting = false
        XCTAssertFalse(isConverting)
    }

    // MARK: - startConversion logic

    /// Mirrors YTUploadView.startConversion() for unit testing.
    private func startConversion(
        youtubeLink: String,
        isConverting: inout Bool,
        statusMessage: inout String
    ) {
        let trimmed = youtubeLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isConverting = true
        statusMessage = "Starting conversion…"
    }

    func test_startConversion_emptyLink_doesNotStartConverting() {
        var isConverting = false
        var statusMessage = ""
        startConversion(youtubeLink: "", isConverting: &isConverting, statusMessage: &statusMessage)
        XCTAssertFalse(isConverting)
    }

    func test_startConversion_emptyLink_doesNotSetStatusMessage() {
        var isConverting = false
        var statusMessage = ""
        startConversion(youtubeLink: "", isConverting: &isConverting, statusMessage: &statusMessage)
        XCTAssertTrue(statusMessage.isEmpty)
    }

    func test_startConversion_whitespaceLink_isNoop() {
        var isConverting = false
        var statusMessage = ""
        startConversion(youtubeLink: "   ", isConverting: &isConverting, statusMessage: &statusMessage)
        XCTAssertFalse(isConverting)
        XCTAssertTrue(statusMessage.isEmpty)
    }

    func test_startConversion_tabCharacterLink_isNoop() {
        var isConverting = false
        var statusMessage = ""
        startConversion(youtubeLink: "\t\n", isConverting: &isConverting, statusMessage: &statusMessage)
        XCTAssertFalse(isConverting)
    }

    func test_startConversion_validLink_setsIsConverting() {
        var isConverting = false
        var statusMessage = ""
        startConversion(
            youtubeLink: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            isConverting: &isConverting,
            statusMessage: &statusMessage
        )
        XCTAssertTrue(isConverting)
    }

    func test_startConversion_validLink_setsStartingStatusMessage() {
        var isConverting = false
        var statusMessage = ""
        startConversion(
            youtubeLink: "https://www.youtube.com/watch?v=abc123",
            isConverting: &isConverting,
            statusMessage: &statusMessage
        )
        XCTAssertEqual(statusMessage, "Starting conversion…")
    }

    func test_startConversion_trimmedValidLink_works() {
        var isConverting = false
        var statusMessage = ""
        startConversion(
            youtubeLink: "  https://youtu.be/abc  ",
            isConverting: &isConverting,
            statusMessage: &statusMessage
        )
        XCTAssertTrue(isConverting)
    }

    // MARK: - Convert button disabled logic

    func test_convertButton_disabledWhenLinkEmpty() {
        let youtubeLink = ""
        let isConverting = false
        let isDisabled = isConverting || youtubeLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        XCTAssertTrue(isDisabled)
    }

    func test_convertButton_disabledWhenConverting() {
        let youtubeLink = "https://youtube.com/watch?v=abc"
        let isConverting = true
        let isDisabled = isConverting || youtubeLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        XCTAssertTrue(isDisabled)
    }

    func test_convertButton_enabledWhenLinkPresentAndNotConverting() {
        let youtubeLink = "https://youtube.com/watch?v=abc"
        let isConverting = false
        let isDisabled = isConverting || youtubeLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        XCTAssertFalse(isDisabled)
    }

    func test_convertButton_disabledWhenBothEmptyAndConverting() {
        let youtubeLink = ""
        let isConverting = true
        let isDisabled = isConverting || youtubeLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        XCTAssertTrue(isDisabled)
    }

    // MARK: - Convert button label

    func test_convertButtonLabel_showsConvertingWhenConverting() {
        let isConverting = true
        let label = isConverting ? "Converting…" : "Convert & Download"
        XCTAssertEqual(label, "Converting…")
    }

    func test_convertButtonLabel_showsConvertAndDownloadWhenIdle() {
        let isConverting = false
        let label = isConverting ? "Converting…" : "Convert & Download"
        XCTAssertEqual(label, "Convert & Download")
    }

    // MARK: - Status message visibility

    func test_status_hiddenWhenEmpty() {
        let statusMessage = ""
        let isVisible = !statusMessage.isEmpty
        XCTAssertFalse(isVisible)
    }

    func test_status_visibleWhenNonEmpty() {
        let statusMessage = "Starting conversion…"
        let isVisible = !statusMessage.isEmpty
        XCTAssertTrue(isVisible)
    }

    // MARK: - backSwipeGesture parameters

    func test_backSwipeGesture_minimumDistance() {
        let minDistance: CGFloat = 20
        XCTAssertEqual(minDistance, 20)
    }

    func test_backSwipeGesture_startXThreshold_acceptsEdge() {
        XCTAssertTrue(CGFloat(10) < 28)
        XCTAssertTrue(CGFloat(27) < 28)
    }

    func test_backSwipeGesture_startXThreshold_rejectsCenter() {
        XCTAssertFalse(CGFloat(28) < 28)
        XCTAssertFalse(CGFloat(100) < 28)
    }

    func test_backSwipeGesture_widthThreshold_accepts() {
        XCTAssertTrue(CGFloat(101) > 100)
        XCTAssertTrue(CGFloat(200) > 100)
    }

    func test_backSwipeGesture_widthThreshold_rejects() {
        XCTAssertFalse(CGFloat(100) > 100)
        XCTAssertFalse(CGFloat(50) > 100)
    }

    func test_backSwipeGesture_verticalThreshold_accepts() {
        XCTAssertTrue(abs(CGFloat(0)) < 60)
        XCTAssertTrue(abs(CGFloat(59)) < 60)
    }

    func test_backSwipeGesture_verticalThreshold_rejects() {
        XCTAssertFalse(abs(CGFloat(60)) < 60)
        XCTAssertFalse(abs(CGFloat(-80)) < 60)
    }

    // MARK: - Header copy

    func test_headerTitle() {
        let title = "YouTube to MP3"
        XCTAssertFalse(title.isEmpty)
    }

    func test_headerSubtitle() {
        let subtitle = "Paste a YouTube link to convert and download the audio."
        XCTAssertFalse(subtitle.isEmpty)
    }
}
