//
//  RecordDetailHeader.swift
//  mennikki
//

import CoreGraphics

/// 詳細画面のヘッダー（写真か、種類の色の背景）の高さを決める
enum RecordDetailHeader {
    /// 写真がないときの高さ。写真があるときの、いちばん低い高さでもある
    static let minHeight: CGFloat = 220
    /// 縦長の写真で、店名などの情報が画面の下に押し出されすぎないようにする上限
    static let maxHeight: CGFloat = 400

    /// 写真を画面の幅いっぱいに出したときの高さを、minHeight〜maxHeight に収めて返す
    static func height(forPhotoSize photoSize: CGSize, width: CGFloat) -> CGFloat {
        guard photoSize.width > 0 else { return minHeight }

        let fittingHeight = width * photoSize.height / photoSize.width
        return min(max(fittingHeight, minHeight), maxHeight)
    }
}
