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
}
