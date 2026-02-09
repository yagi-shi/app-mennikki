//
//  UINavigationBar+App.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import UIKit

extension UINavigationBar {
    /// Duolingo風のスタイルを適用
    func applyAppStyle() {
        // 背景色を白に設定
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        // タイトルのフォントとカラー
        appearance.titleTextAttributes = [
            .font: UIFont.appNavigationTitle,
            .foregroundColor: UIColor.appText
        ]

        // シャドウの設定
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.05)

        // 各状態に適用
        standardAppearance = appearance
        scrollEdgeAppearance = appearance
        compactAppearance = appearance

        // tintColor（ボタンの色）
        tintColor = .appPrimary
    }
}
