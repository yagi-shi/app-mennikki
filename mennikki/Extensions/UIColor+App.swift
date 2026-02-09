//
//  UIColor+App.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import UIKit

extension UIColor {
    /// プライマリカラー（アクセント、お気に入りボタン）
    static let appPrimary = UIColor(red: 255/255, green: 107/255, blue: 107/255, alpha: 1.0)

    /// セカンダリカラー（評価星、ポジティブなアクション）
    static let appSecondary = UIColor(red: 78/255, green: 205/255, blue: 196/255, alpha: 1.0)

    /// サクセスカラー（保存成功時のフィードバック）
    static let appSuccess = UIColor(red: 149/255, green: 225/255, blue: 211/255, alpha: 1.0)

    /// 背景カラー（画面背景）
    static let appBackground = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1.0)

    /// カード背景カラー（セルやカードの背景）
    static let appCardBackground = UIColor.white

    /// テキストカラー（主要テキスト）
    static let appText = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1.0)

    /// セカンダリテキストカラー（補助テキスト、説明文）
    static let appSecondaryText = UIColor(red: 149/255, green: 165/255, blue: 166/255, alpha: 1.0)

    /// タグ背景カラー（ラーメン種類タグ）
    static let appTagBackground = UIColor(red: 255/255, green: 230/255, blue: 109/255, alpha: 1.0)
}
