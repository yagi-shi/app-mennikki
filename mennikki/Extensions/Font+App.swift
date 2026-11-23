//
//  Font+App.swift
//  mennikki
//

import SwiftUI

/// SwiftUI の画面で使う、アプリのフォント。
/// UIKit の定義（UIFont+App.swift）と同じく、iOS の標準の文字サイズの段階（テキストスタイル）から丸い書体で作る。
/// テキストスタイルから作ったフォントは、「テキストサイズ」の設定に合わせて自動で拡大・縮小する
extension Font {

    /// iOS の標準の文字サイズの段階（テキストスタイル）から、丸みのあるフォントを作る
    static func rounded(_ style: Font.TextStyle, weight: Font.Weight) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    // MARK: - App Fonts

    /// データを開けなかったときに知らせる画面の見出し
    static var appNoticeTitle: Font {
        rounded(.title2, weight: .heavy)
    }

    /// 本文、説明文
    static var appBody: Font {
        rounded(.subheadline, weight: .medium)
    }
}
