//
//  Color+AppTests.swift
//  mennikkiTests
//

import Testing
import SwiftUI
import UIKit
@testable import mennikki

/// SwiftUI の色の定義（Color+App）のテスト。
/// #27 の移行中は UIKit の画面と SwiftUI の画面が混ざるので、UIKit の色の定義（UIColor+App）と同じ値であることを確かめる
@MainActor
struct ColorAppTests {

    @Test("SwiftUI の色の定義は、UIKit の色の定義と同じ値である")
    func swiftUIColorsMatchUIKitColors() {
        let colorPairs: [(name: String, swiftUIColor: Color, uiKitColor: UIColor)] = [
            ("appPrimary", .appPrimary, .appPrimary),
            ("appSecondary", .appSecondary, .appSecondary),
            ("appSuccess", .appSuccess, .appSuccess),
            ("appBackground", .appBackground, .appBackground),
            ("appCardBackground", .appCardBackground, .appCardBackground),
            ("appText", .appText, .appText),
            ("appSecondaryText", .appSecondaryText, .appSecondaryText),
            ("appBorder", .appBorder, .appBorder),
            ("appFieldBorder", .appFieldBorder, .appFieldBorder),
            ("appCardBorder", .appCardBorder, .appCardBorder),
        ]

        for colorPair in colorPairs {
            #expect(
                rgba255(of: UIColor(colorPair.swiftUIColor)) == rgba255(of: colorPair.uiKitColor),
                "\(colorPair.name)"
            )
        }
    }

    @Test("SwiftUI のラーメンの種類の色は、UIKit の定義と同じ値である")
    func ramenTypeColorsMatchUIKitColors() {
        for ramenType in RamenType.allCases {
            #expect(
                rgba255(of: UIColor(Color.colorForRamenType(ramenType))) == rgba255(of: UIColor.colorForRamenType(ramenType)),
                "\(ramenType.rawValue)"
            )
        }
    }

    // MARK: - Helper Methods

    /// 色の赤・緑・青・不透明度を、0〜255 の整数で返す。小数の誤差で比べられなくならないように、整数に丸める
    private func rgba255(of color: UIColor) -> [Int] {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue, alpha].map { Int(($0 * 255).rounded()) }
    }
}
