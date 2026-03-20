import XCTest
import UIKit
@testable import AmpleIt

/// Tests for ArtworkAsset encoding/decoding and nil-handling paths.
final class ArtworkAssetTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a 4x4 white JPEG as minimal valid test image data.
    private func syntheticJPEGData(color: UIColor = .white,
                                   size: CGSize = CGSize(width: 4, height: 4)) -> Data {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.jpegData(withCompressionQuality: 0.88) { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - init?(data:) — normalizing initializer

    func test_initData_validJPEG_returnsNonNil() {
        let data = syntheticJPEGData()
        XCTAssertNotNil(ArtworkAsset(data: data))
    }

    func test_initData_emptyData_returnsNil() {
        XCTAssertNil(ArtworkAsset(data: Data()))
    }

    func test_initData_invalidData_returnsNil() {
        let garbage = Data([0x00, 0xFF, 0xAB, 0xCD])
        XCTAssertNil(ArtworkAsset(data: garbage))
    }

    func test_initData_storesNonEmptyImageData() {
        let data = syntheticJPEGData()
        guard let asset = ArtworkAsset(data: data) else {
            XCTFail("Expected non-nil ArtworkAsset")
            return
        }
        XCTAssertFalse(asset.imageData.isEmpty)
    }

    // MARK: - init(imageData:) — pre-normalized initializer (disk load path)

    func test_initImageData_alwaysSucceeds() {
        let data = syntheticJPEGData()
        // This initializer must never fail — it trusts the data is already normalized.
        let asset = ArtworkAsset(imageData: data)
        XCTAssertEqual(asset.imageData, data)
    }

    // MARK: - uiImage

    func test_uiImage_returnsNonNilForValidAsset() {
        let data = syntheticJPEGData()
        guard let asset = ArtworkAsset(data: data) else { return }
        XCTAssertNotNil(asset.uiImage)
    }

    func test_uiImage_returnsNilForCorruptImageData() {
        let garbage = Data([0x00, 0x01, 0x02])
        let asset = ArtworkAsset(imageData: garbage)
        // UIImage(data:) will fail silently; uiImage must return nil, not crash.
        XCTAssertNil(asset.uiImage)
    }

    // MARK: - image (SwiftUI.Image?)

    func test_image_returnsNonNilForValidAsset() {
        let data = syntheticJPEGData()
        guard let asset = ArtworkAsset(data: data) else { return }
        XCTAssertNotNil(asset.image)
    }

    func test_image_returnsNilForCorruptData() {
        let garbage = Data([0x00, 0x01])
        let asset = ArtworkAsset(imageData: garbage)
        XCTAssertNil(asset.image)
    }

    // MARK: - Round-trip: init(data:) → imageData → init(imageData:) → uiImage

    func test_roundTrip_dataToAssetToUIImage() {
        let data = syntheticJPEGData()
        guard let asset1 = ArtworkAsset(data: data) else {
            XCTFail("First init failed")
            return
        }
        // Simulate disk load: save imageData and reload via pre-normalized initializer.
        let asset2 = ArtworkAsset(imageData: asset1.imageData)
        XCTAssertNotNil(asset2.uiImage, "uiImage from round-tripped asset should not be nil")
    }

    func test_roundTrip_imageDataPreservedBetweenInits() {
        let data = syntheticJPEGData()
        guard let asset = ArtworkAsset(data: data) else { return }
        let reloaded = ArtworkAsset(imageData: asset.imageData)
        XCTAssertEqual(asset.imageData, reloaded.imageData)
    }

    // MARK: - Large image normalization (exceeds 1600px cap)

    func test_initData_largeImage_normalizedToAtMost1600px() {
        // Create a 2000x2000 image — should be scaled down.
        let largeSize = CGSize(width: 2000, height: 2000)
        let renderer  = UIGraphicsImageRenderer(size: largeSize)
        let largeData = renderer.jpegData(withCompressionQuality: 0.88) { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: largeSize))
        }

        guard let asset = ArtworkAsset(data: largeData) else {
            XCTFail("Expected non-nil ArtworkAsset for large image")
            return
        }
        guard let img = asset.uiImage else {
            XCTFail("Expected non-nil uiImage")
            return
        }
        XCTAssertLessThanOrEqual(img.size.width,  1600,
                                  "Width \(img.size.width) exceeds 1600px cap after normalization")
        XCTAssertLessThanOrEqual(img.size.height, 1600,
                                  "Height \(img.size.height) exceeds 1600px cap after normalization")
    }

    func test_initData_smallImage_notUpscaled() {
        // A 10x10 image must stay at 10x10 (scaleRatio = 1).
        let smallSize = CGSize(width: 10, height: 10)
        let renderer  = UIGraphicsImageRenderer(size: smallSize)
        let smallData = renderer.jpegData(withCompressionQuality: 0.88) { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: smallSize))
        }

        guard let asset = ArtworkAsset(data: smallData) else {
            XCTFail("Expected non-nil ArtworkAsset for small image")
            return
        }
        guard let img = asset.uiImage else {
            XCTFail("Expected non-nil uiImage")
            return
        }
        XCTAssertLessThanOrEqual(img.size.width,  smallSize.width  + 1,  // +1 JPEG rounding
                                  "Small image was unexpectedly upscaled (width)")
        XCTAssertLessThanOrEqual(img.size.height, smallSize.height + 1,
                                  "Small image was unexpectedly upscaled (height)")
    }

    // MARK: - Equatable

    func test_equatable_sameImageDataEqual() {
        let data = syntheticJPEGData()
        guard let a1 = ArtworkAsset(data: data), let a2 = ArtworkAsset(data: data) else { return }
        // Both go through the same normalization pipeline with the same input,
        // so their imageData bytes must be identical.
        XCTAssertEqual(a1, a2)
    }

    func test_equatable_differentImageDataNotEqual() {
        let d1 = syntheticJPEGData(color: .white)
        let d2 = syntheticJPEGData(color: .black)
        guard let a1 = ArtworkAsset(data: d1), let a2 = ArtworkAsset(data: d2) else { return }
        XCTAssertNotEqual(a1, a2)
    }

    // MARK: - Codable

    func test_codable_encodeDecodePreservesImageData() throws {
        let data  = syntheticJPEGData()
        guard let asset = ArtworkAsset(data: data) else {
            XCTFail("Expected non-nil ArtworkAsset")
            return
        }
        let encoded = try JSONEncoder().encode(asset)
        let decoded = try JSONDecoder().decode(ArtworkAsset.self, from: encoded)
        XCTAssertEqual(asset.imageData, decoded.imageData)
    }
}
