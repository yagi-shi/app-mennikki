//
//  UINavigationBar+App.swift
//  mennikki
//

import UIKit

extension UINavigationBar {
    /// Duolingo風のスタイルを適用
    func applyAppStyle() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        // タイトル: Rounded Bold
        appearance.titleTextAttributes = [
            .font: UIFont.appNavigationTitle,
            .foregroundColor: UIColor.appText
        ]

        // 大タイトル: Rounded Heavy
        appearance.largeTitleTextAttributes = [
            .font: UIFont.appLargeTitle,
            .foregroundColor: UIColor.appText
        ]

        // Duolingo風: 下にうっすらボーダー（ハードシャドウ）
        appearance.shadowColor = .appBorder

        standardAppearance = appearance
        scrollEdgeAppearance = appearance
        compactAppearance = appearance

        // 大タイトル表示
        prefersLargeTitles = true

        // ボタンの色
        tintColor = .appPrimary
    }
}
