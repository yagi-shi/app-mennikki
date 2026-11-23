//
//  StoreLoadErrorView.swift
//  mennikki
//

import SwiftUI

/// 保存したデータを開けなかったときに、タブの画面の代わりに出す画面。
/// 記録が 0 件の画面を出すと、利用者が「消えた」と思ってアプリを削除し、本当にデータが消えるおそれがある。
/// そのため、データが端末に残っていることと、アプリを削除しないでほしいことを伝える
struct StoreLoadErrorView: View {

    /// アプリをもう一度開く前に、試してほしいこと
    private static let thingsToTry = [
        "空き容量を増やす",
        "端末を再起動する",
        "App Store でアプリを最新の版にする",
    ]

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                content
                    .padding(Layout.contentPadding)
                    .frame(maxWidth: Layout.maxContentWidth)
                    // 文字が少ないときは画面の中央に置き、文字を大きくして収まらないときはスクロールできるようにする
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.appBackground)
    }

    private var content: some View {
        VStack(spacing: Layout.sectionSpacing) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: Layout.iconSize, height: Layout.iconSize)
                .foregroundStyle(Color.appPrimary)
                .accessibilityHidden(true)

            Text("記録を読み込めませんでした")
                .font(.appNoticeTitle)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                wrappingText("記録のデータは、端末に残っています。アプリを削除すると、このデータも消えてしまうので、削除しないでください。")

                VStack(alignment: .leading, spacing: Layout.itemSpacing) {
                    // 裏から戻しただけでは読み込み直さないので、アプリを終了してから開いてもらう
                    wrappingText("次のことを試したあと、アプリを終了してから、もう一度開いてください。")
                    ForEach(Self.thingsToTry, id: \.self) { thingToTry in
                        bulletItem(thingToTry)
                    }
                }
            }
            .font(.appBody)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Color.appText)
    }

    /// 折り返す文。入れ子の VStack の中では、日本語の文に 1 行分の高さしか割り当てられず、
    /// 2 行目以降が「…」で省略されることがあったので、必要な高さを必ず取るようにする
    private func wrappingText(_ text: String) -> some View {
        Text(text)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// 行頭に「・」を付けた項目。2 行になったときも、2 行目の頭を 1 行目の文字にそろえる
    private func bulletItem(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Layout.bulletSpacing) {
            Text("・")
                .accessibilityHidden(true)
            wrappingText(text)
        }
    }

    private enum Layout {
        static let iconSize: CGFloat = 64
        static let sectionSpacing: CGFloat = 24
        static let itemSpacing: CGFloat = 8
        static let bulletSpacing: CGFloat = 4
        static let contentPadding: CGFloat = 24
        /// iPad や横向きで、1 行が長くなりすぎて読みにくくならないようにする幅
        static let maxContentWidth: CGFloat = 480
    }
}

#Preview {
    StoreLoadErrorView()
}
