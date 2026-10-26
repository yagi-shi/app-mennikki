//
//  ReviewRequestPolicy.swift
//  mennikki
//

import Foundation

/// ストア評価を依頼する条件
enum ReviewRequestPolicy {

    /// 新規登録後の記録の総数が、ストア評価を依頼する節目かどうか。
    /// 節目は 3 件と、10 件から 100 件までの 10 件ごと（実際に表示するかは iOS が決める）
    static func shouldRequestReview(recordCount: Int) -> Bool {
        if recordCount == 3 { return true }
        return (10...100).contains(recordCount) && recordCount % 10 == 0
    }
}
