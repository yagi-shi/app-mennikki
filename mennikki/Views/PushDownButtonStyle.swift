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
        PushDownButton(configuration: configuration, shadowColor: shadowColor)
    }

    /// 一瞬だけ押したときも、沈み切ってから戻す。
    /// SwiftUI は指が触れている間しか「押している」と伝えないので、そのまま形を変えると、
    /// 一瞬押しでは沈む動きの途中で戻り始めて、沈んだように見えない
    private struct PushDownButton: View {

        let configuration: ButtonStyleConfiguration
        let shadowColor: Color

        /// 沈んだ形で見せているか。指が離れても、沈み切るまでは true のまま
        @State private var isSunk = false
        /// 沈む動きが終わる時刻
        @State private var sinkEndTime: ContinuousClock.Instant = .now
        @State private var riseTask: Task<Void, Never>?

        var body: some View {
            configuration.label
                // 影を、ボタンの文字ではなく、ボタン全体の形に付ける
                .compositingGroup()
                .shadow(color: shadowColor, radius: 0, x: 0, y: isSunk ? 0 : Layout.depth)
                .offset(y: isSunk ? Layout.depth : 0)
                .onChange(of: configuration.isPressed) { _, isPressed in
                    if isPressed {
                        sink()
                    } else {
                        riseAfterSinking()
                    }
                }
        }

        private func sink() {
            // 戻るのを待っている間に、また押されたときは、戻さない
            riseTask?.cancel()
            sinkEndTime = .now + .seconds(Layout.pressDuration)
            withAnimation(Layout.pressAnimation) {
                isSunk = true
            }
        }

        /// 沈む動きが終わるのを待ってから、弾ませて戻す
        private func riseAfterSinking() {
            riseTask = Task {
                try? await Task.sleep(until: sinkEndTime)
                guard !Task.isCancelled else { return }
                withAnimation(Layout.releaseAnimation) {
                    isSunk = false
                }
            }
        }
    }

    private enum Layout {
        /// 沈み込む深さ。影の高さと同じ
        static let depth: CGFloat = 5
        static let pressDuration: TimeInterval = 0.08
        static let pressAnimation = Animation.easeInOut(duration: pressDuration)
        /// 離したときは、ばねで弾ませて戻す（UIKit の画面の、ばねの減衰 0.5 に当たる）
        static let releaseAnimation = Animation.spring(duration: 0.15, bounce: 0.5)
    }
}
