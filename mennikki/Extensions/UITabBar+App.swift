//
//  UITabBar+App.swift
//  mennikki
//

import UIKit

extension UITabBar {
    /// Duolingo風のスタイルを適用
    func applyAppStyle() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        // Duolingo風: 上にハードなボーダーライン
        appearance.shadowColor = .appBorder

        // アイテムのフォントを Rounded に
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.rounded(ofSize: 10, weight: .semibold),
            .foregroundColor: UIColor.appSecondaryText
        ]
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.rounded(ofSize: 10, weight: .bold),
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