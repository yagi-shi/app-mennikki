//
//  RecordDetailHeaderTests.swift
//  mennikkiTests
//

import Testing
import CoreGraphics
@testable import mennikki

/// RecordDetailHeader のテスト。写真の縦横の比から、詳細画面のヘッダーの高さ（220〜400pt）が決まることを確かめる
@MainActor
struct RecordDetailHeaderTests {

    /// テストで使う画面の幅
    private let screenWidth: CGFloat = 300

    @Test("写真を画面の幅に合わせた高さが 220pt より低い（とても横長の）写真では、220pt になる")
    func widePhotoUsesMinHeight() {
        // 画面の幅に合わせると 150pt
        let photoSize = CGSize(width: 600, height: 300)

        #expect(RecordDetailHeader.height(forPhotoSize: photoSize, width: screenWidth) == 220)
    }

    @Test("写真を画面の幅に合わせた高さが 400pt より高い（縦長の）写真では、400pt になる")
    func tallPhotoUsesMaxHeight() {
        // 画面の幅に合わせると 600pt
        let photoSize = CGSize(width: 300, height: 600)

        #expect(RecordDetailHeader.height(forPhotoSize: photoSize, width: screenWidth) == 400)
    }

    @Test("写真を画面の幅に合わせた高さが 220〜400pt の写真では、その高さになる")
    func photoBetweenLimitsFitsScreenWidth() {
        // 正方形の写真は、画面の幅と同じ 300pt
        let photoSize = CGSize(width: 1000, height: 1000)

        #expect(RecordDetailHeader.height(forPhotoSize: photoSize, width: screenWidth) == 300)
    }

    @Test("写真の幅が 0 なら、比を計算できないので 220pt になる")
    func zeroWidthPhotoUsesMinHeight() {
        let photoSize = CGSize(width: 0, height: 100)

        #expect(RecordDetailHeader.height(forPhotoSize: photoSize, width: screenWidth) == 220)
    }
}
