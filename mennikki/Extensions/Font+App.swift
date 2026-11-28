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

    /// 詳細画面の店舗名
    static var appDetailTitle: Font {
        rounded(.title2, weight: .heavy)
    }

    /// ボタンテキスト
    static var appButton: Font {
        rounded(.callout, weight: .bold)
    }

    /// 本文、説明文
    static var appBody: Font {
        rounded(.subheadline, weight: .medium)
    }

    /// 詳細画面の都道府県・訪問日・費用の値
    static var appInfoValue: Font {
        rounded(.subheadline, weight: .bold)
    }

    /// 詳細画面の項目名（「都道府県」など）
    static var appCaption: Font {
        rounded(.footnote, weight: .medium)
    }

    /// 記録画面の種類の選択ボタン
    static var appChip: Font {
        rounded(.footnote, weight: .bold)
    }

    /// 小さいタグ・バッジ
    static var appTag: Font {
        rounded(.caption, weight: .bold)
    }

    /// 記録画面の項目名（「店舗名」など）
    static var appFormLabel: Font {
        rounded(.caption, weight: .heavy)
    }
}
