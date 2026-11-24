//
//  UIImage+App.swift
//  mennikki
//

import UIKit

extension UIImage {

    /// 写真のデータを、表示できる画像にする。大きい写真で画面が止まらないように、メインスレッドの外で行う
    @concurrent
    nonisolated static func decodedForDisplay(from photoData: Data) async -> UIImage? {
        guard let image = UIImage(data: photoData) else { return nil }
        return image.preparingForDisplay() ?? image
    }
}
