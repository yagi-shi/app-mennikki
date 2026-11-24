//
//  RecordPhotoEncoderTests.swift
//  mennikkiTests
//

import Testing
import UIKit
@testable import mennikki

/// RecordPhotoEncoder のテスト。選んだ写真が、長辺 800px 以下の JPEG のデータになることを確かめる
@MainActor
struct RecordPhotoEncoderTests {

    @Test("長辺が 800px より大きい横長の写真は、縦横の比を保って、長辺が 800px になる")
    func shrinksWidePhotoToMaxLength() {
        let photo = makePhoto(width: 1600, height: 1200)

        let resized = RecordPhotoEncoder.resized(photo)

        #expect(pixelSize(of: resized) == CGSize(width: 800, height: 600))
    }

    @Test("長辺が 800px より大きい縦長の写真は、縦横の比を保って、長辺が 800px になる")
    func shrinksTallPhotoToMaxLength() {
        let photo = makePhoto(width: 1200, height: 1600)

        let resized = RecordPhotoEncoder.resized(photo)

        #expect(pixelSize(of: resized) == CGSize(width: 600, height: 800))
    }

    @Test("長辺がちょうど 800px の写真は、大きさが変わらない")
    func keepsPhotoAtMaxLength() {
        let photo = makePhoto(width: 800, height: 600)

        let resized = RecordPhotoEncoder.resized(photo)

        #expect(pixelSize(of: resized) == CGSize(width: 800, height: 600))
    }

    @Test("長辺が 800px より小さい写真は、大きさが変わらない")
    func keepsSmallPhoto() {
        let photo = makePhoto(width: 400, height: 300)

        let resized = RecordPhotoEncoder.resized(photo)

        #expect(pixelSize(of: resized) == CGSize(width: 400, height: 300))
    }

    @Test("変換したデータは JPEG で、長辺 800px に縮めた写真として読める")
    func encodesResizedPhotoAsJPEG() throws {
        let photo = makePhoto(width: 1600, height: 1200)

        let data = try #require(RecordPhotoEncoder.jpegData(from: photo))

        // JPEG のデータは、0xFF 0xD8 で始まる
        #expect(Array(data.prefix(2)) == [0xFF, 0xD8])
        let decoded = try #require(UIImage(data: data))
        #expect(pixelSize(of: decoded) == CGSize(width: 800, height: 600))
    }

    // MARK: - Helper Methods

    /// 指定した大きさ（px）の、1 色で塗った写真を作る
    private func makePhoto(width: CGFloat, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    /// 写真の大きさを、pt ではなく px で返す
    private func pixelSize(of image: UIImage) -> CGSize {
        CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
    }
}
