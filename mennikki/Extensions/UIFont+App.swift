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

    /// iOS の標準の文字サイズの段階（テキストスタイル）から、丸みのあるフォントを生成。
    /// 標準の文字サイズでの大きさを基準に、「テキストサイズ」の設定に合わせて拡大・縮小する
    static func rounded(_ style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let standardTraits = UITraitCollection(preferredContentSizeCategory: .large)
        let size = preferredFont(forTextStyle: style, compatibleWith: standardTraits).pointSize
        return UIFontMetrics(forTextStyle: style).scaledFont(for: rounded(ofSize: size, weight: weight))
    }

    // MARK: - App Fonts

    /// ナビゲーション大タイトル
    static var appLargeTitle: UIFont {
        rounded(.title1, weight: .heavy)
    }

    /// ナビゲーションバーのタイトル
    static var appNavigationTitle: UIFont {
        rounded(.title3, weight: .bold)
    }

    /// 詳細画面の店舗名
    static var appDetailTitle: UIFont {
        rounded(.title2, weight: .heavy)
    }

    /// 空の一覧の見出し（「まだラーメンの記録がありません」など）
    static var appEmptyStateTitle: UIFont {
        rounded(.headline, weight: .bold)
    }

    /// ボタンテキスト
    static var appButton: UIFont {
        rounded(.callout, weight: .bold)
    }

    /// 記録一覧の検索欄
    static var appSearchField: UIFont {
        rounded(.callout, weight: .regular)
    }

    /// 店舗名（一覧のカード）
    static var appStoreName: UIFont {
        rounded(.subheadline, weight: .bold)
    }

    /// 本文、説明文
    static var appBody: UIFont {
        rounded(.subheadline, weight: .medium)
    }

    /// 詳細画面の都道府県・訪問日・費用の値
    static var appInfoValue: UIFont {
        rounded(.subheadline, weight: .bold)
    }

    /// 詳細画面の項目名（「都道府県」など）
    static var appCaption: UIFont {
        rounded(.footnote, weight: .medium)
    }

    /// 記録画面の種類の選択ボタン
    static var appChip: UIFont {
        rounded(.footnote, weight: .bold)
    }

    /// 小さいタグ・バッジ
    static var appTag: UIFont {
        rounded(.caption1, weight: .bold)
    }

    /// 記録画面の項目名（「店舗名」など）
    static var appFormLabel: UIFont {
        rounded(.caption1, weight: .heavy)
    }

    // MARK: - App Fonts（テキストサイズの設定に追従しない）

    /// タブバーの項目（未選択）。iOS の標準のタブバーと同じく、大きさを固定する
    static var appTabBarItem: UIFont {
        rounded(ofSize: 10, weight: .semibold)
    }

    /// タブバーの項目（選択中）。iOS の標準のタブバーと同じく、大きさを固定する
    static var appTabBarItemSelected: UIFont {
        rounded(ofSize: 10, weight: .bold)
    }
}
