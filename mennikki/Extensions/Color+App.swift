//
//  Color+App.swift
//  mennikki
//

import SwiftUI

/// SwiftUI の画面で使う、アプリの色。
/// UIKit の定義（UIColor+App.swift）にもある色は、同じ名前・同じ値にする（Color+AppTests で確かめる）。
/// UIKit の定義は、#27 で UIKit の画面がなくなったときに消す
extension Color {
    /// 起動画面（LaunchScreen.storyboard）の背景と同じベージュ。起動画面から自然につなぐ画面で使う。
    /// 起動画面は Storyboard で色を指定しているので、UIKit の定義にはない
    static let appLaunchBackground = Color(.displayP3, red: 235/255, green: 234/255, blue: 213/255)

    static let appPrimary    = Color(red: 255/255, green: 75/255,  blue: 75/255)   // red
    static let appSecondary  = Color(red: 28/255,  green: 176/255, blue: 246/255)  // blue
    static let appSuccess    = Color(red: 88/255,  green: 204/255, blue: 2/255)    // green
    static let appBackground = Color(red: 247/255, green: 247/255, blue: 247/255)
    static let appCardBackground = Color.white
    static let appText       = Color(red: 60/255,  green: 60/255,  blue: 60/255)
    static let appSecondaryText = Color(red: 175/255, green: 175/255, blue: 175/255)
    static let appBorder     = Color(red: 229/255, green: 229/255, blue: 229/255)
    static let appFieldBorder = Color(red: 149/255, green: 165/255, blue: 166/255, opacity: 0.2)
    static let appCardBorder  = Color(red: 235/255, green: 235/255, blue: 235/255)

    // MARK: - Ramen Type Colors

    /// RamenTypeに対応するカラー（タグ・カード上部の背景）
    static func colorForRamenType(_ type: RamenType) -> Color {
        switch type {
        case .shoyu:    return Color(red: 212/255, green: 133/255, blue: 42/255)  // amber
        case .shio:     return Color(red: 28/255,  green: 176/255, blue: 246/255) // blue
        case .miso:     return Color(red: 245/255, green: 166/255, blue: 35/255)  // yellow-amber
        case .tonkotsu: return Color(red: 240/255, green: 128/255, blue: 128/255) // light coral
        case .niboshi:  return Color(red: 70/255,  green: 100/255, blue: 150/255) // dark navy
        case .paitan:   return Color(red: 247/255, green: 197/255, blue: 159/255) // warm cream
        case .tsukemen: return Color(red: 232/255, green: 131/255, blue: 12/255)  // orange
        case .mazemen:  return Color(red: 120/255, green: 80/255,  blue: 40/255)  // dark brown
        case .jiro:     return Color(red: 139/255, green: 115/255, blue: 85/255)  // tan brown
        case .iekei:    return Color(red: 192/255, green: 57/255,  blue: 43/255)  // deep red
        case .other:    return Color(red: 175/255, green: 175/255, blue: 175/255) // gray
        }
    }
}
