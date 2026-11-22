//
//  RecordListViewModelTests.swift
//  mennikkiTests
//

import Testing
import Foundation
import CoreData
@testable import mennikki

/// RecordListViewModel のテスト。記録の読み書きにはインメモリのストアを使い、端末上の実データには書き込まない
@MainActor
struct RecordListViewModelTests {

    // MARK: - 取り出しと並び順

    @Test("条件がなければ、すべての記録が訪問日の新しい順に出る")
    func showsAllRecordsNewestFirst() throws {
        let manager = CoreDataManager(inMemory: true)
        try makeRecord(in: manager, storeName: "古い店", visitDate: makeDate(day: 1))
        try makeRecord(in: manager, storeName: "新しい店", visitDate: makeDate(day: 2))
        let viewModel = RecordListViewModel(scope: .allRecords, dataManager: manager)

        viewModel.load()

        #expect(storeNames(of: viewModel) == ["新しい店", "古い店"])
    }

    // MARK: - 絞り込み

    @Test("店名で検索すると、店名にその文字を含む記録だけが出る（英字の大文字・小文字は区別しない）")
    func searchKeepsRecordsWhoseStoreNameContainsText() throws {
        let manager = CoreDataManager(inMemory: true)
        try makeRecord(in: manager, storeName: "Ramen Taro")
        try makeRecord(in: manager, storeName: "中華そば 山田")
        let viewModel = RecordListViewModel(scope: .allRecords, dataManager: manager)
        viewModel.load()

        viewModel.setSearchText("ramen")

        #expect(storeNames(of: viewModel) == ["Ramen Taro"])
    }

    @Test("種類を選ぶと、選んだ種類のどれかに合う記録だけが出る")
    func ramenTypeFilterKeepsSelectedTypes() throws {
        let manager = CoreDataManager(inMemory: true)
        try makeRecord(in: manager, storeName: "醤油の店", ramenType: .shoyu)
        try makeRecord(in: manager, storeName: "味噌の店", ramenType: .miso)
        try makeRecord(in: manager, storeName: "塩の店", ramenType: .shio)
        let viewModel = RecordListViewModel(scope: .allRecords, dataManager: manager)
        viewModel.load()

        viewModel.toggleRamenType(.shoyu)
        viewModel.toggleRamenType(.miso)

        #expect(Set(storeNames(of: viewModel)) == ["醤油の店", "味噌の店"])
    }

    @Test("都道府県を選ぶと、その都道府県の記録だけが出る")
    func prefectureFilterKeepsSelectedPrefecture() throws {
        let manager = CoreDataManager(inMemory: true)
        try makeRecord(in: manager, storeName: "東京の店", prefecture: .tokyo)
        try makeRecord(in: manager, storeName: "大阪の店", prefecture: .osaka)
        let viewModel = RecordListViewModel(scope: .allRecords, dataManager: manager)
        viewModel.load()

        viewModel.togglePrefecture(.tokyo)

        #expect(storeNames(of: viewModel) == ["東京の店"])
    }

    @Test("条件を組み合わせると、すべての条件に合う記録だけが出る")
    func combinedConditionsKeepRecordsMatchingAll() throws {
        let manager = CoreDataManager(inMemory: true)
        try makeRecord(in: manager, storeName: "麺屋 東京 醤油", ramenType: .shoyu, prefecture: .tokyo)
        try makeRecord(in: manager, storeName: "麺屋 東京 味噌", ramenType: .miso, prefecture: .tokyo)
        try makeRecord(in: manager, storeName: "麺屋 大阪 醤油", ramenType: .shoyu, prefecture: .osaka)
        try makeRecord(in: manager, storeName: "中華そば 東京 醤油", ramenType: .shoyu, prefecture: .tokyo)
        let viewModel = RecordListViewModel(scope: .allRecords, dataManager: manager)
        viewModel.load()

        viewModel.setSearchText("麺屋")
        viewModel.toggleRamenType(.shoyu)
        viewModel.togglePrefecture(.tokyo)

        #expect(storeNames(of: viewModel) == ["麺屋 東京 醤油"])
    }

    // MARK: - お気に入り

    @Test("お気に入り一覧には、お気に入りの記録だけが出る")
    func favoritesScopeShowsOnlyFavorites() throws {
        let manager = CoreDataManager(inMemory: true)
        try makeRecord(in: manager, storeName: "お気に入りの店", isFavorite: true)
        try makeRecord(in: manager, storeName: "ふつうの店", isFavorite: false)
        let viewModel = RecordListViewModel(scope: .favoritesOnly, dataManager: manager)

        viewModel.load()

        #expect(storeNames(of: viewModel) == ["お気に入りの店"])
    }

    // MARK: - 自動の更新

    @Test("記録を足すと、一覧が自動で更新される")
    func addingRecordUpdatesList() throws {
        let manager = CoreDataManager(inMemory: true)
        let viewModel = RecordListViewModel(scope: .allRecords, dataManager: manager)
        viewModel.load()

        try makeRecord(in: manager, storeName: "足した店")

        #expect(storeNames(of: viewModel) == ["足した店"])
    }

    @Test("記録を消すと、一覧が自動で更新される")
    func deletingRecordUpdatesList() throws {
        let manager = CoreDataManager(inMemory: true)
        let record = try makeRecord(in: manager, storeName: "消す店")
        let viewModel = RecordListViewModel(scope: .allRecords, dataManager: manager)
        viewModel.load()

        manager.deleteRecord(record)

        #expect(viewModel.records.isEmpty)
    }

    // MARK: - 空のときの表示

    @Test("記録がなく、絞り込んでいなければ、「記録がない」表示になる")
    func emptyStateWithoutRecords() {
        let viewModel = RecordListViewModel(scope: .allRecords, dataManager: CoreDataManager(inMemory: true))

        viewModel.load()

        #expect(viewModel.emptyState == .noRecords)
    }

    @Test("絞り込んで 0 件なら、「条件に合う記録がない」表示になる")
    func emptyStateWhenNarrowedToZero() throws {
        let manager = CoreDataManager(inMemory: true)
        try makeRecord(in: manager, storeName: "中華そば 山田")
        let viewModel = RecordListViewModel(scope: .allRecords, dataManager: manager)
        viewModel.load()

        viewModel.setSearchText("どこにもない店")

        #expect(viewModel.records.isEmpty)
        #expect(viewModel.emptyState == .noMatchingRecords)
    }

    @Test("お気に入り一覧では、「お気に入りがない」表示になる")
    func emptyStateForFavorites() {
        let viewModel = RecordListViewModel(scope: .favoritesOnly, dataManager: CoreDataManager(inMemory: true))

        viewModel.load()

        #expect(viewModel.emptyState == .noFavorites)
    }

    // MARK: - フィルターの選択肢と切り替え

    @Test("都道府県の選択肢は、記録にある都道府県だけが、定義の順に出る")
    func prefectureOptionsAreRegisteredOnesInDefinitionOrder() throws {
        let manager = CoreDataManager(inMemory: true)
        try makeRecord(in: manager, prefecture: .osaka)
        try makeRecord(in: manager, prefecture: .tokyo)
        try makeRecord(in: manager, prefecture: .tokyo)
        try makeRecord(in: manager, prefecture: nil)
        let viewModel = RecordListViewModel(scope: .allRecords, dataManager: manager)
        viewModel.load()

        #expect(viewModel.prefectureOptions() == [.tokyo, .osaka])
    }

    @Test("同じ種類をもう一度選ぶと外れ、クリアすると種類の条件がなくなる")
    func togglingAndClearingRamenTypes() {
        let viewModel = RecordListViewModel(scope: .allRecords, dataManager: CoreDataManager(inMemory: true))
        viewModel.load()

        viewModel.toggleRamenType(.shoyu)
        viewModel.toggleRamenType(.miso)
        viewModel.toggleRamenType(.shoyu)
        #expect(viewModel.filter.selectedRamenTypes == [.miso])

        viewModel.clearRamenTypes()
        #expect(viewModel.filter.selectedRamenTypes.isEmpty)
    }

    @Test("同じ都道府県をもう一度選ぶと外れ、クリアすると都道府県の条件がなくなる")
    func togglingAndClearingPrefecture() {
        let viewModel = RecordListViewModel(scope: .allRecords, dataManager: CoreDataManager(inMemory: true))
        viewModel.load()

        viewModel.togglePrefecture(.tokyo)
        viewModel.togglePrefecture(.tokyo)
        #expect(viewModel.filter.selectedPrefecture == nil)

        viewModel.togglePrefecture(.osaka)
        viewModel.clearPrefecture()
        #expect(viewModel.filter.selectedPrefecture == nil)
    }

    // MARK: - ヘルパー

    /// テスト用の記録を作る。引数を省いた項目は、絞り込みに影響しない値にする
    @discardableResult
    private func makeRecord(
        in manager: CoreDataManager,
        storeName: String = "テスト軒",
        ramenType: RamenType = .shoyu,
        visitDate: Date = Date(timeIntervalSince1970: 1_700_000_000),
        isFavorite: Bool = false,
        prefecture: Prefecture? = nil
    ) throws -> Record {
        try #require(manager.createRecord(
            storeName: storeName,
            ramenType: ramenType,
            visitDate: visitDate,
            isFavorite: isFavorite,
            prefecture: prefecture
        ))
    }

    /// 2026 年 11 月のその日の 0 時（端末のタイムゾーン）
    private func makeDate(day: Int) throws -> Date {
        let calendar = Calendar(identifier: .gregorian)
        return try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: day)))
    }

    private func storeNames(of viewModel: RecordListViewModel) -> [String] {
        viewModel.records.map { $0.storeName ?? "" }
    }
}
