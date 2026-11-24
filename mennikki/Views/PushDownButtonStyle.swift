//
//  PushDownButtonStyle.swift
//  mennikki
//

import SwiftUI

/// 押すと沈み込み、離すと弾んで戻るボタン（3D の押し込み）。
/// ボタンの下に、ぼかさない影を出しておき、押している間は、影の高さの分だけボタンを下げて、影を消す
struct PushDownButtonStyle: ButtonStyle {

    /// ボタンの下に出す影の色
    let shadowColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // 影を、ボタンの文字ではなく、ボタン全体の形に付ける
            .compositingGroup()
            .shadow(color: shadowColor, radius: 0, x: 0, y: configuration.isPressed ? 0 : Layout.depth)
            .offset(y: configuration.isPressed ? Layout.depth : 0)
            .animation(configuration.isPressed ? Layout.pressAnimation : Layout.releaseAnimation,
                       value: configuration.isPressed)
    }

    private enum Layout {
        /// 沈み込む深さ。影の高さと同じ
        static let depth: CGFloat = 5
        static let pressAnimation = Animation.easeInOut(duration: 0.08)
        /// 離したときは、ばねで弾ませて戻す（UIKit の画面の、ばねの減衰 0.5 に当たる）
        static let releaseAnimation = Animation.spring(duration: 0.15, bounce: 0.5)
    }
}
