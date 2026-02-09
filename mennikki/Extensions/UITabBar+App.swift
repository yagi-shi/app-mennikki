//
//  UITabBar+App.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import UIKit

extension UITabBar {
    /// Duolingo風のスタイルを適用
    func applyAppStyle() {
        // 背景色を白に設定
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        // シャドウの設定
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)

        // 各状態に適用
        standardAppearance = appearance
        if #available(iOS 15.0, *) {
            scrollEdgeAppearance = appearance
        }

        // tintColor（選択時の色）
        tintColor = .appPrimary

        // unselectedItemTintColor（未選択時の色）
        unselectedItemTintColor = .appSecondaryText
    }
}
