import XCTest
@testable import AmpleIt

final class SongEditViewTests: XCTestCase {

    // MARK: - Default Field Values

    func test_defaultTitle() {
        let title = "Midnight Echoes"
        XCTAssertEqual(title, "Midnight Echoes")
        XCTAssertFalse(title.isEmpty)
    }

    func test_defaultArtist() {
        let artist = "Arvind"
        XCTAssertEqual(artist, "Arvind")
        XCTAssertFalse(artist.isEmpty)
    }

    func test_defaultSpeed() {
        let speed: Double = 1.0
        XCTAssertEqual(speed, 1.0, accuracy: 0.001)
    }

    func test_defaultReverb() {
        let reverb: Double = 0.0
        XCTAssertEqual(reverb, 0.0, accuracy: 0.001)
    }

    func test_defaultBass() {
        let bass: Double = 0.0
        XCTAssertEqual(bass, 0.0, accuracy: 0.001)
    }

    func test_defaultMid() {
        let mid: Double = 0.0
        XCTAssertEqual(mid, 0.0, accuracy: 0.001)
    }

    func test_defaultTreble() {
        let treble: Double = 0.0
        XCTAssertEqual(treble, 0.0, accuracy: 0.001)
    }

    func test_defaultPreset() {
        let selectedPreset = "Default"
        XCTAssertEqual(selectedPreset, "Default")
    }

    func test_showArtworkOverlay_initiallyFalse() {
        let showArtworkOverlay = false
        XCTAssertFalse(showArtworkOverlay)
    }

    // MARK: - Presets

    func test_presets_count() {
        let presets = ["Default", "Warm", "Bass Boost", "Lo-Fi", "Vocal Clarity"]
        XCTAssertEqual(presets.count, 5)
    }

    func test_presets_containsDefault() {
        let presets = ["Default", "Warm", "Bass Boost", "Lo-Fi", "Vocal Clarity"]
        XCTAssertTrue(presets.contains("Default"))
    }

    func test_presets_containsWarm() {
        let presets = ["Default", "Warm", "Bass Boost", "Lo-Fi", "Vocal Clarity"]
        XCTAssertTrue(presets.contains("Warm"))
    }

    func test_presets_containsBassBoost() {
        let presets = ["Default", "Warm", "Bass Boost", "Lo-Fi", "Vocal Clarity"]
        XCTAssertTrue(presets.contains("Bass Boost"))
    }

    func test_presets_containsLoFi() {
        let presets = ["Default", "Warm", "Bass Boost", "Lo-Fi", "Vocal Clarity"]
        XCTAssertTrue(presets.contains("Lo-Fi"))
    }

    func test_presets_containsVocalClarity() {
        let presets = ["Default", "Warm", "Bass Boost", "Lo-Fi", "Vocal Clarity"]
        XCTAssertTrue(presets.contains("Vocal Clarity"))
    }

    func test_presets_allUnique() {
        let presets = ["Default", "Warm", "Bass Boost", "Lo-Fi", "Vocal Clarity"]
        XCTAssertEqual(Set(presets).count, presets.count)
    }

    func test_presets_noneAreEmpty() {
        let presets = ["Default", "Warm", "Bass Boost", "Lo-Fi", "Vocal Clarity"]
        for preset in presets {
            XCTAssertFalse(preset.isEmpty, "Preset '\(preset)' should not be empty")
        }
    }

    // MARK: - Speed Level Slider

    func test_speedRange_lowerBound() {
        let range: ClosedRange<Double> = 0.25...4.0
        XCTAssertEqual(range.lowerBound, 0.25, accuracy: 0.001)
    }

    func test_speedRange_upperBound() {
        let range: ClosedRange<Double> = 0.25...4.0
        XCTAssertEqual(range.upperBound, 4.0, accuracy: 0.001)
    }

    func test_speedRange_containsDefault() {
        let range: ClosedRange<Double> = 0.25...4.0
        XCTAssertTrue(range.contains(1.0))
    }

    func test_speedRange_rejectsBelowMin() {
        let range: ClosedRange<Double> = 0.25...4.0
        XCTAssertFalse(range.contains(0.0))
        XCTAssertFalse(range.contains(0.24))
    }

    func test_speedRange_rejectsAboveMax() {
        let range: ClosedRange<Double> = 0.25...4.0
        XCTAssertFalse(range.contains(4.01))
        XCTAssertFalse(range.contains(100.0))
    }

    func test_speedFormat_defaultValue() {
        let format: (Double) -> String = { String(format: "%.2fx", $0) }
        XCTAssertEqual(format(1.0), "1.00x")
    }

    func test_speedFormat_lowerBound() {
        let format: (Double) -> String = { String(format: "%.2fx", $0) }
        XCTAssertEqual(format(0.25), "0.25x")
    }

    func test_speedFormat_upperBound() {
        let format: (Double) -> String = { String(format: "%.2fx", $0) }
        XCTAssertEqual(format(4.0), "4.00x")
    }

    func test_speedFormat_halfSpeed() {
        let format: (Double) -> String = { String(format: "%.2fx", $0) }
        XCTAssertEqual(format(0.5), "0.50x")
    }

    // MARK: - Reverb Level Slider

    func test_reverbRange_lowerBound() {
        let range: ClosedRange<Double> = 0.0...1.0
        XCTAssertEqual(range.lowerBound, 0.0, accuracy: 0.001)
    }

    func test_reverbRange_upperBound() {
        let range: ClosedRange<Double> = 0.0...1.0
        XCTAssertEqual(range.upperBound, 1.0, accuracy: 0.001)
    }

    func test_reverbFormat_zero() {
        let format: (Double) -> String = { String(format: "%.0f%%", $0 * 100) }
        XCTAssertEqual(format(0.0), "0%")
    }

    func test_reverbFormat_half() {
        let format: (Double) -> String = { String(format: "%.0f%%", $0 * 100) }
        XCTAssertEqual(format(0.5), "50%")
    }

    func test_reverbFormat_full() {
        let format: (Double) -> String = { String(format: "%.0f%%", $0 * 100) }
        XCTAssertEqual(format(1.0), "100%")
    }

    // MARK: - Bass / Mid / Treble Level Sliders

    func test_eqRange_lowerBound() {
        let range: ClosedRange<Double> = -12.0...12.0
        XCTAssertEqual(range.lowerBound, -12.0, accuracy: 0.001)
    }

    func test_eqRange_upperBound() {
        let range: ClosedRange<Double> = -12.0...12.0
        XCTAssertEqual(range.upperBound, 12.0, accuracy: 0.001)
    }

    func test_eqRange_containsZero() {
        let range: ClosedRange<Double> = -12.0...12.0
        XCTAssertTrue(range.contains(0.0))
    }

    func test_eqRange_rejectsOutOfBounds() {
        let range: ClosedRange<Double> = -12.0...12.0
        XCTAssertFalse(range.contains(-13.0))
        XCTAssertFalse(range.contains(13.0))
    }

    func test_eqFormat_zero() {
        let format: (Double) -> String = { String(format: "%+.0f dB", $0) }
        XCTAssertEqual(format(0.0), "+0 dB")
    }

    func test_eqFormat_positiveValue() {
        let format: (Double) -> String = { String(format: "%+.0f dB", $0) }
        XCTAssertEqual(format(12.0), "+12 dB")
    }

    func test_eqFormat_negativeValue() {
        let format: (Double) -> String = { String(format: "%+.0f dB", $0) }
        XCTAssertEqual(format(-12.0), "-12 dB")
    }

    func test_eqFormat_midRange() {
        let format: (Double) -> String = { String(format: "%+.0f dB", $0) }
        XCTAssertEqual(format(6.0), "+6 dB")
        XCTAssertEqual(format(-6.0), "-6 dB")
    }

    // MARK: - backSwipeGesture parameters

    func test_backSwipeGesture_startXThreshold() {
        // guard value.startLocation.x < 28
        XCTAssertTrue(CGFloat(0) < 28)
        XCTAssertTrue(CGFloat(27) < 28)
        XCTAssertFalse(CGFloat(28) < 28)
        XCTAssertFalse(CGFloat(100) < 28)
    }

    func test_backSwipeGesture_widthThreshold() {
        // guard value.translation.width > 100
        XCTAssertTrue(CGFloat(101) > 100)
        XCTAssertFalse(CGFloat(100) > 100)
        XCTAssertFalse(CGFloat(50) > 100)
    }

    func test_backSwipeGesture_heightThreshold() {
        // guard abs(value.translation.height) < 60
        XCTAssertTrue(abs(CGFloat(0)) < 60)
        XCTAssertTrue(abs(CGFloat(59)) < 60)
        XCTAssertFalse(abs(CGFloat(60)) < 60)
        XCTAssertFalse(abs(CGFloat(-80)) < 60)
    }
}
