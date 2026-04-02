//
//  UIFont+App.swift
//  mennikki
//

import UIKit

extension UIFont {

    /// 丸み（Rounded）システムフォントを生成
    static func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = systemFont.fontDescriptor.withDesign(.rounded) else {
            return systemFont
        }
        return UIFont(descriptor: descriptor, size: size)
    }

    // MARK: - App Fonts

    /// ナビゲーション大タイトル
    static var appLargeTitle: UIFont {
        let font = rounded(ofSize: 28, weight: .heavy)
        return UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)
    }

    /// ナビゲーションバーのタイトル
    static var appNavigationTitle: UIFont {
        let font = rounded(ofSize: 20, weight: .bold)
        return UIFontMetrics(forTextStyle: .headline).scaledFont(for: font)
    }

    /// セクションヘッダー
    static var appSectionHeader: UIFont {
        let font = rounded(ofSize: 18, weight: .bold)
        return UIFontMetrics(forTextStyle: .headline).scaledFont(for: font)
    }

    /// 店舗名（一覧・詳細）
    static var appStoreName: UIFont {
        let font = rounded(ofSize: 17, weight: .bold)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
    }

    /// ラーメンの種類
    static var appRamenType: UIFont {
        let font = rounded(ofSize: 15, weight: .semibold)
        return UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: font)
    }

    /// 本文、説明文
    static var appBody: UIFont {
        let font = rounded(ofSize: 15, weight: .medium)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
    }

    /// 補足情報、日付
    static var appCaption: UIFont {
        let font = rounded(ofSize: 13, weight: .medium)
        return UIFontMetrics(forTextStyle: .caption1).scaledFont(for: font)
    }

    /// 詳細画面の店舗名
    static var appDetailTitle: UIFont {
        let font = rounded(ofSize: 24, weight: .heavy)
        return UIFontMetrics(forTextStyle: .title1).scaledFont(for: font)
    }

    /// ボタンテキスト
    static var appButton: UIFont {
        let font = rounded(ofSize: 16, weight: .bold)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
    }

    /// 小さいタグ・バッジ
    static var appTag: UIFont {
        let font = rounded(ofSize: 12, weight: .bold)
        return UIFontMetrics(forTextStyle: .caption2).scaledFont(for: font)
    }
}
