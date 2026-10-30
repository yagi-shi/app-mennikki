//
//  RecordListFilterTests.swift
//  mennikkiTests
//

import Testing
@testable import mennikki

/// RecordListFilter のテスト。フィルターが適用中か、絞り込み中かの判定を確かめる
@MainActor
struct RecordListFilterTests {

    @Test("種類が 1 つ以上選ばれているとき、種類フィルターは「適用中」と判定される")
    func ramenTypeFilterIsActiveWhenTypesSelected() {
        let filter = RecordListFilter(selectedRamenTypes: [.shoyu])

        #expect(filter.isRamenTypeFilterActive)
        #expect(filter.isPrefectureFilterActive == false)
    }

    @Test("都道府県が選ばれているとき、都道府県フィルターは「適用中」と判定される")
    func prefectureFilterIsActiveWhenPrefectureSelected() {
        let filter = RecordListFilter(selectedPrefecture: .tokyo)

        #expect(filter.isPrefectureFilterActive)
        #expect(filter.isRamenTypeFilterActive == false)
    }

    @Test("何も選ばれていないとき、どちらも「適用中ではない」と判定される")
    func filtersAreInactiveWhenNothingSelected() {
        let filter = RecordListFilter()

        #expect(filter.isRamenTypeFilterActive == false)
        #expect(filter.isPrefectureFilterActive == false)
    }

    @Test("種類、都道府県、店名検索のどれかで絞り込んでいるとき、「絞り込み中」と判定される")
    func isNarrowingWhenAnyConditionIsSet() {
        #expect(RecordListFilter(searchText: "家").isNarrowing)
        #expect(RecordListFilter(selectedRamenTypes: [.miso]).isNarrowing)
        #expect(RecordListFilter(selectedPrefecture: .osaka).isNarrowing)
        #expect(RecordListFilter(searchText: "家", selectedRamenTypes: [.iekei], selectedPrefecture: .kanagawa).isNarrowing)
    }

    @Test("何も条件がなければ、「絞り込み中」ではないと判定される")
    func isNotNarrowingWithoutConditions() {
        #expect(RecordListFilter().isNarrowing == false)
    }

    @Test("店名検索だけでは、どちらのフィルターも「適用中」にならない")
    func searchTextDoesNotActivateFilters() {
        let filter = RecordListFilter(searchText: "家")

        #expect(filter.isRamenTypeFilterActive == false)
        #expect(filter.isPrefectureFilterActive == false)
    }
}
