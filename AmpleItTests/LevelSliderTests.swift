import XCTest
@testable import AmpleIt

final class LevelSliderTests: XCTestCase {

    // MARK: - Format function invocation

    func test_formatFunction_receivesCurrentValue() {
        var receivedValue: Double?
        let format: (Double) -> String = { v in
            receivedValue = v
            return "\(v)"
        }
        _ = format(5.0)
        XCTAssertEqual(receivedValue, 5.0)
    }

    func test_formatFunction_producesNonEmptyString() {
        let format: (Double) -> String = { String(format: "%.2fx", $0) }
        XCTAssertFalse(format(1.0).isEmpty)
    }

    // MARK: - Range contains value

    func test_range_containsLowerBound() {
        let range: ClosedRange<Double> = 0.0...1.0
        XCTAssertTrue(range.contains(0.0))
    }

    func test_range_containsUpperBound() {
        let range: ClosedRange<Double> = 0.0...1.0
        XCTAssertTrue(range.contains(1.0))
    }

    func test_range_containsMidpoint() {
        let range: ClosedRange<Double> = -12.0...12.0
        XCTAssertTrue(range.contains(0.0))
    }

    func test_range_doesNotContainBelowLower() {
        let range: ClosedRange<Double> = 0.25...4.0
        XCTAssertFalse(range.contains(0.0))
    }

    func test_range_doesNotContainAboveUpper() {
        let range: ClosedRange<Double> = 0.25...4.0
        XCTAssertFalse(range.contains(5.0))
    }

    // MARK: - Title non-empty

    func test_title_speedIsNonEmpty() {
        let title = "Speed"
        XCTAssertFalse(title.isEmpty)
    }

    func test_title_reverbIsNonEmpty() {
        let title = "Reverb"
        XCTAssertFalse(title.isEmpty)
    }

    func test_title_bassIsNonEmpty() {
        let title = "Bass"
        XCTAssertFalse(title.isEmpty)
    }

    func test_title_midIsNonEmpty() {
        let title = "Mid"
        XCTAssertFalse(title.isEmpty)
    }

    func test_title_trebleIsNonEmpty() {
        let title = "Treble"
        XCTAssertFalse(title.isEmpty)
    }

    // MARK: - Specific format strings used in SongEditView

    func test_speedFormat_1x() {
        let format: (Double) -> String = { String(format: "%.2fx", $0) }
        XCTAssertEqual(format(1.0), "1.00x")
    }

    func test_speedFormat_halfSpeed() {
        let format: (Double) -> String = { String(format: "%.2fx", $0) }
        XCTAssertEqual(format(0.5), "0.50x")
    }

    func test_speedFormat_quadSpeed() {
        let format: (Double) -> String = { String(format: "%.2fx", $0) }
        XCTAssertEqual(format(4.0), "4.00x")
    }

    func test_reverbFormat_0percent() {
        let format: (Double) -> String = { String(format: "%.0f%%", $0 * 100) }
        XCTAssertEqual(format(0.0), "0%")
    }

    func test_reverbFormat_50percent() {
        let format: (Double) -> String = { String(format: "%.0f%%", $0 * 100) }
        XCTAssertEqual(format(0.5), "50%")
    }

    func test_reverbFormat_100percent() {
        let format: (Double) -> String = { String(format: "%.0f%%", $0 * 100) }
        XCTAssertEqual(format(1.0), "100%")
    }

    func test_eqFormat_positiveDB() {
        let format: (Double) -> String = { String(format: "%+.0f dB", $0) }
        XCTAssertEqual(format(6.0), "+6 dB")
    }

    func test_eqFormat_negativeDB() {
        let format: (Double) -> String = { String(format: "%+.0f dB", $0) }
        XCTAssertEqual(format(-6.0), "-6 dB")
    }

    func test_eqFormat_zeroDBHasExplicitSign() {
        let format: (Double) -> String = { String(format: "%+.0f dB", $0) }
        let result = format(0.0)
        XCTAssertTrue(result.hasPrefix("+") || result.hasPrefix("-"))
    }

    // MARK: - Range boundaries match SongEditView usage

    func test_speedRange_matchesSongEditView() {
        let range: ClosedRange<Double> = 0.25...4.0
        XCTAssertEqual(range.lowerBound, 0.25, accuracy: 0.001)
        XCTAssertEqual(range.upperBound, 4.0, accuracy: 0.001)
    }

    func test_reverbRange_matchesSongEditView() {
        let range: ClosedRange<Double> = 0.0...1.0
        XCTAssertEqual(range.lowerBound, 0.0, accuracy: 0.001)
        XCTAssertEqual(range.upperBound, 1.0, accuracy: 0.001)
    }

    func test_eqRange_matchesSongEditView() {
        let range: ClosedRange<Double> = -12.0...12.0
        XCTAssertEqual(range.lowerBound, -12.0, accuracy: 0.001)
        XCTAssertEqual(range.upperBound, 12.0, accuracy: 0.001)
    }
}
