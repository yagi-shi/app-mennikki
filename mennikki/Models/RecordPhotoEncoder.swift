//
//  RecordPhotoEncoder.swift
//  mennikki
//

import UIKit

/// 選んだ写真を、記録に保存するデータ（JPEG）にする。
/// 写真のデータが大きくなりすぎないように、長辺を 800px 以下に縮めてから変換する
nonisolated enum RecordPhotoEncoder {

    /// 保存する写真の長辺の最大（px）
    static let maxPixelLength: CGFloat = 800
    /// JPEG の画質（0〜1）
    static let jpegQuality: CGFloat = 0.75

    /// 写真を縮めて、JPEG のデータにする。変換できなければ nil
    static func jpegData(from photo: UIImage) -> Data? {
        resized(photo).jpegData(compressionQuality: jpegQuality)
    }

    /// 長辺を 800px 以下に縮める（縦横の比は保つ）。長辺が 800px 以下なら、そのまま返す。
    /// UIGraphicsImageRenderer を使用（iOS 17+ 非推奨APIを回避）
    static func resized(_ photo: UIImage) -> UIImage {
        let size = photo.size
        let longer = max(size.width, size.height)
        guard longer > maxPixelLength else { return photo }

        let scale = maxPixelLength / longer
        let newSize = CGSize(width: (size.width * scale).rounded(),
                             height: (size.height * scale).rounded())

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            photo.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
