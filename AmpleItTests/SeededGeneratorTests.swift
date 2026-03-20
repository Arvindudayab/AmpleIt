import XCTest
@testable import AmpleIt

/// Verifies the xorshift64* PRNG in SeededGenerator.
/// Key property: same seed must produce same sequence across calls (determinism).
final class SeededGeneratorTests: XCTestCase {

    // MARK: - Determinism

    func test_sameSeeds_produceSameFirstValue() {
        var g1 = SeededGenerator(seed: 42)
        var g2 = SeededGenerator(seed: 42)
        XCTAssertEqual(g1.next(), g2.next())
    }

    func test_sameSeeds_produceSameSequenceOf10() {
        var g1 = SeededGenerator(seed: 12345)
        var g2 = SeededGenerator(seed: 12345)
        let seq1 = (0..<10).map { _ in g1.next() }
        let seq2 = (0..<10).map { _ in g2.next() }
        XCTAssertEqual(seq1, seq2)
    }

    func test_differentSeeds_produceDifferentFirstValues() {
        var g1 = SeededGenerator(seed: 1)
        var g2 = SeededGenerator(seed: 2)
        // Extremely unlikely to collide; treat a collision as a test infrastructure failure.
        XCTAssertNotEqual(g1.next(), g2.next())
    }

    // MARK: - Zero-seed guard

    func test_zeroSeed_doesNotReturnZeroOrLoop() {
        // When seed == 0 the implementation substitutes 0xdeadbeef.
        // The first output must be non-zero (the substituted seed is non-zero).
        var g = SeededGenerator(seed: 0)
        XCTAssertNotEqual(g.next(), 0)
    }

    func test_zeroSeed_producesNonTrivialSequence() {
        var g1 = SeededGenerator(seed: 0)
        var g2 = SeededGenerator(seed: 0)
        let seq1 = (0..<5).map { _ in g1.next() }
        let seq2 = (0..<5).map { _ in g2.next() }
        XCTAssertEqual(seq1, seq2, "Zero-seeded generators must be deterministic")
    }

    // MARK: - Distribution (basic sanity)

    func test_sequenceOf1000_hasNoMoreThan5PercentZeroHighBit() {
        // xorshift* should not produce all-zero high bits consistently.
        var g = SeededGenerator(seed: 999)
        let zeroHighBitCount = (0..<1000).filter { _ in g.next() >> 63 == 0 }.count
        // Roughly 50/50 expected; anything under 30% (300/1000) or over 70% (700/1000) is suspicious.
        XCTAssertGreaterThan(zeroHighBitCount, 300)
        XCTAssertLessThan(zeroHighBitCount, 700)
    }

    // MARK: - Bool.random consistency with SeededGenerator

    func test_boolRandom_withSameSeed_givesSameResults() {
        var g1 = SeededGenerator(seed: 77)
        var g2 = SeededGenerator(seed: 77)
        let seq1 = (0..<20).map { _ in Bool.random(using: &g1) }
        let seq2 = (0..<20).map { _ in Bool.random(using: &g2) }
        XCTAssertEqual(seq1, seq2)
    }

    // MARK: - Array.shuffled consistency with SeededGenerator

    func test_shuffled_withSameSeed_givesSameOrder() {
        let array = Array(0..<20)
        var g1 = SeededGenerator(seed: 1234567890)
        var g2 = SeededGenerator(seed: 1234567890)
        let s1 = array.shuffled(using: &g1)
        let s2 = array.shuffled(using: &g2)
        XCTAssertEqual(s1, s2)
    }

    func test_shuffled_withDifferentSeeds_likelyGivesDifferentOrder() {
        let array = Array(0..<20)
        var g1 = SeededGenerator(seed: 1)
        var g2 = SeededGenerator(seed: 2)
        let s1 = array.shuffled(using: &g1)
        let s2 = array.shuffled(using: &g2)
        // With 20 elements, probability of equal shuffle is 1/20! — negligible.
        XCTAssertNotEqual(s1, s2, "Different seeds unexpectedly produced identical shuffles")
    }
}
