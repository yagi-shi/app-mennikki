//
//  UIFont+App.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import UIKit

extension UIFont {
    /// ナビゲーションバーのタイトル（Dynamic Type対応）
    static var appNavigationTitle: UIFont {
        let font = UIFont.systemFont(ofSize: 20, weight: .bold)
        return UIFontMetrics(forTextStyle: .headline).scaledFont(for: font)
    }

    /// セクションヘッダー（Dynamic Type対応）
    static var appSectionHeader: UIFont {
        let font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return UIFontMetrics(forTextStyle: .headline).scaledFont(for: font)
    }

    /// 店舗名（一覧・詳細、Dynamic Type対応）
    static var appStoreName: UIFont {
        let font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
    }

    /// ラーメンの種類（Dynamic Type対応）
    static var appRamenType: UIFont {
        let font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: font)
    }

    /// 本文、説明文（Dynamic Type対応）
    static var appBody: UIFont {
        let font = UIFont.systemFont(ofSize: 15, weight: .regular)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
    }

    /// 補足情報、日付（Dynamic Type対応）
    static var appCaption: UIFont {
        let font = UIFont.systemFont(ofSize: 13, weight: .regular)
        return UIFontMetrics(forTextStyle: .caption1).scaledFont(for: font)
    }

    /// 詳細画面の店舗名（Dynamic Type対応）
    static var appDetailTitle: UIFont {
        let font = UIFont.systemFont(ofSize: 24, weight: .bold)
        return UIFontMetrics(forTextStyle: .title1).scaledFont(for: font)
    }
}
