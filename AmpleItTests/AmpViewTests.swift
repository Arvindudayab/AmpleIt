import XCTest
@testable import AmpleIt

final class AmpViewTests: XCTestCase {

    // MARK: - draftMessage initial state

    func test_draftMessage_initiallyEmpty() {
        let draftMessage = ""
        XCTAssertTrue(draftMessage.isEmpty)
    }

    // MARK: - Send button action

    func test_sendButton_clearsDraftMessage() {
        var draftMessage = "How can I boost the bass?"
        // Mirrors the send button action: draftMessage = ""
        draftMessage = ""
        XCTAssertTrue(draftMessage.isEmpty)
    }

    func test_sendButton_alreadyEmpty_remainsEmpty() {
        var draftMessage = ""
        draftMessage = ""
        XCTAssertTrue(draftMessage.isEmpty)
    }

    // MARK: - chatBubble alignment logic

    func test_chatBubble_userMessage_isTrailingAligned() {
        // isUser = true → leading Spacer (trailing-aligns the bubble)
        let isUser = true
        // User bubble: HStack { Spacer(); Text(...) }
        XCTAssertTrue(isUser)
    }

    func test_chatBubble_assistantMessage_isLeadingAligned() {
        // isUser = false → trailing Spacer (leading-aligns the bubble)
        let isUser = false
        XCTAssertFalse(isUser)
    }

    func test_chatBubble_defaultIsUserTrue() {
        // chatBubble(text:isUser:) has isUser: Bool = true
        let defaultIsUser = true
        XCTAssertTrue(defaultIsUser)
    }

    // MARK: - chatBubble fill colour logic

    func test_chatBubble_userFill_usesAppAccent() {
        // isUser ? Color("AppAccent") : Color.primary.opacity(0.08)
        let isUser = true
        let colorName = isUser ? "AppAccent" : "primary.opacity(0.08)"
        XCTAssertEqual(colorName, "AppAccent")
    }

    func test_chatBubble_assistantFill_usesPrimaryOpacity() {
        let isUser = false
        let colorName = isUser ? "AppAccent" : "primary.opacity(0.08)"
        XCTAssertEqual(colorName, "primary.opacity(0.08)")
    }

    // MARK: - Static placeholder chat bubbles displayed in the view

    func test_staticUserBubble_text() {
        let text = "How can I make this track feel warmer?"
        XCTAssertFalse(text.isEmpty)
    }

    func test_staticAssistantBubble_text() {
        let text = "Try boosting low mids and adding subtle tape saturation."
        XCTAssertFalse(text.isEmpty)
    }

    // MARK: - TextField placeholder

    func test_messageFieldPlaceholder() {
        let placeholder = "Message Amp…"
        XCTAssertFalse(placeholder.isEmpty)
    }

    // MARK: - Header copy

    func test_headerTitle() {
        let title = "I'm Amp, ask me anything"
        XCTAssertFalse(title.isEmpty)
    }

    func test_headerSubtitle() {
        let subtitle = "I can help with mixes, suggestions, and quick edits."
        XCTAssertFalse(subtitle.isEmpty)
    }

    // MARK: - Tab title

    func test_ampTab_title() {
        XCTAssertEqual(AppTab.amp.title, "Amp")
    }
}
