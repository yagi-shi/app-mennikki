//
//  StarRatingInputView.swift
//  mennikki
//

import SwiftUI

/// 評価を入力する星（登録・編集画面）。
/// 押した星の数まで塗る。同じ星をもう一度押すと、評価を 0（未選択）に戻す
struct StarRatingInputView: View {

    /// 評価。0 は未選択
    @Binding var rating: Int

    /// 押したときに弾ませている星
    @State private var bouncingStar: Int?

    var body: some View {
        HStack(spacing: Layout.starSpacing) {
            ForEach(1...Layout.maxRating, id: \.self) { star in
                starButton(star)
            }
        }
    }

    private func starButton(_ star: Int) -> some View {
        let isFilled = star <= rating
        return Button {
            tapStar(star)
        } label: {
            Image(systemName: isFilled ? "star.fill" : "star")
                .font(.system(size: Layout.starSize))
                .foregroundStyle(isFilled ? Color.appSuccess : Color.appBorder)
                .scaleEffect(bouncingStar == star ? Layout.bounceScale : 1)
                // 今の UIKit の画面と同じく、星を横に均等に並べ、星のまわりを押しても反応するようにする
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(star)星")
        .accessibilityAddTraits(isFilled ? .isSelected : [])
    }

    private func tapStar(_ star: Int) {
        rating = (star == rating) ? 0 : star

        // 押した星を大きくしてから、元の大きさに戻す
        withAnimation(.easeInOut(duration: Layout.bounceDuration)) {
            bouncingStar = star
        } completion: {
            withAnimation(.easeInOut(duration: Layout.bounceDuration)) {
                bouncingStar = nil
            }
        }
    }

    private enum Layout {
        // SF Symbols のアイコンの大きさ。今の UIKit の画面と同じく、「テキストサイズ」の設定では変えない
        static let starSize: CGFloat = 32

        static let maxRating = 5
        static let starSpacing: CGFloat = 8

        /// 押したときに、星を何倍まで大きくするか
        static let bounceScale: CGFloat = 1.3
        static let bounceDuration: TimeInterval = 0.1
    }
}
