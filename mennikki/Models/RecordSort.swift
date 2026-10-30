//
//  RecordSort.swift
//  mennikki
//

import Foundation

/// 記録の並び順
enum RecordSort {

    /// 一覧の並び順。訪問日の新しい順で、訪問日が同じ記録は作成日時の新しい順。
    /// 訪問日が同じ記録どうしの順を決めておかないと、作った直後と読み直したあとで並びが入れ替わる
    static var newestFirst: [NSSortDescriptor] {
        [
            NSSortDescriptor(key: "visitDate", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
    }
}
