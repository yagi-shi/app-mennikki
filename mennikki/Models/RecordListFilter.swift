//
//  RecordListFilter.swift
//  mennikki
//

import Foundation

/// 記録一覧の絞り込み条件（店名検索、種類、都道府県）
struct RecordListFilter {
    var searchText: String = ""
    var selectedRamenTypes: [RamenType] = []
    var selectedPrefecture: Prefecture?

    /// 種類フィルターが適用中か
    var isRamenTypeFilterActive: Bool { !selectedRamenTypes.isEmpty }

    /// 都道府県フィルターが適用中か
    var isPrefectureFilterActive: Bool { selectedPrefecture != nil }

    /// 店名検索、種類、都道府県のどれかで絞り込んでいるか
    var isNarrowing: Bool {
        !searchText.isEmpty || isRamenTypeFilterActive || isPrefectureFilterActive
    }
}
