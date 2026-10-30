//
//  UITabBar+App.swift
//  mennikki
//

import UIKit

extension UITabBar {
    /// アプリ共通のスタイルを適用
    func applyAppStyle() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        // 上にハードなボーダーライン
        appearance.shadowColor = .appBorder

        // アイテムのフォントを Rounded に
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.appTabBarItem,
            .foregroundColor: UIColor.appSecondaryText
        ]
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.appTabBarItemSelected,
            .foregroundColor: UIColor.appPrimary
        ]

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs

        standardAppearance = appearance
        scrollEdgeAppearance = appearance

        tintColor = .appPrimary
        unselectedItemTintColor = .appSecondaryText
    }
}