//
//  RecordDetailViewModelTests.swift
//  mennikkiTests
//

import Testing
import Foundation
import CoreData
@testable import mennikki

/// RecordDetailViewModel のテスト。記録の読み書きにはインメモリのストアを使い、端末上の実データには書き込まない
@MainActor
struct RecordDetailViewModelTests {

    // MARK: - 読み込み

    @Test("記録の ID から読み込むと、その記録の店名が表示する値になる")
    func reloadLoadsRecordByID() throws {
        let manager = CoreDataManager(inMemory: true)
        let record = try makeRecord(in: manager, storeName: "テスト軒")
        let viewModel = RecordDetailViewModel(recordID: record.objectID, dataManager: manager)

        viewModel.reload()

        #expect(viewModel.storeName == "テスト軒")
        #expect(viewModel.shouldClose == false)
    }

    @Test("ない記録の ID で読み込むと、画面を閉じることになる")
    func reloadWithMissingRecordClosesScreen() throws {
        let manager = CoreDataManager(inMemory: true)
        let record = try makeRecord(in: manager)
        let missingRecordID = record.objectID
        manager.deleteRecord(record)
        let viewModel = RecordDetailViewModel(recordID: missingRecordID, dataManager: manager)

        viewModel.reload()

        #expect(viewModel.shouldClose)
    }

    // MARK: - 表示する値

    @Test("都道府県・訪問日・費用があると、この順に 3 つの行が出て、費用は「¥」付きになる")
    func infoRowsIncludeAllValues() throws {
        let manager = CoreDataManager(inMemory: true)
        let record = try makeRecord(
            in: manager,
            visitDate: makeDate(year: 2026, month: 11, day: 22),
            cost: 900,
            prefecture: .tokyo
        )
        let viewModel = RecordDetailViewModel(recordID: record.objectID, dataManager: manager)

        viewModel.reload()

        #expect(viewModel.infoRows == [
            RecordDetailViewModel.InfoRow(kind: .prefecture, title: "都道府県", value: "東京都"),
            RecordDetailViewModel.InfoRow(kind: .visitDate, title: "訪問日", value: "2026年11月22日（日）"),
            RecordDetailViewModel.InfoRow(kind: .cost, title: "費用", value: "¥900")
        ])
    }

    @Test("都道府県がなく、費用が 0 なら、訪問日の行だけが出る")
    func infoRowsSkipMissingValues() throws {
        let manager = CoreDataManager(inMemory: true)
        let record = try makeRecord(in: manager, cost: 0, prefecture: nil)
        let viewModel = RecordDetailViewModel(recordID: record.objectID, dataManager: manager)

        viewModel.reload()

        #expect(viewModel.infoRows.map(\.kind) == [.visitDate])
    }

    @Test("種類が不明な値なら、「その他」になる")
    func unknownRamenTypeFallsBackToOther() throws {
        let manager = CoreDataManager(inMemory: true)
        let record = try makeRecord(in: manager)
        record.ramenType = "定義にない種類"
        try #require(manager.viewContext).save()
        let viewModel = RecordDetailViewModel(recordID: record.objectID, dataManager: manager)

        viewModel.reload()

        #expect(viewModel.ramenType == .other)
    }

    @Test("評価が 0 なら、評価を出さない")
    func zeroRatingIsHidden() throws {
        let manager = CoreDataManager(inMemory: true)
        let record = try makeRecord(in: manager, rating: 0)
        let viewModel = RecordDetailViewModel(recordID: record.objectID, dataManager: manager)

        viewModel.reload()

        #expect(viewModel.ratingToShow == nil)
    }

    @Test("評価が 1 以上なら、その評価を出す")
    func positiveRatingIsShown() throws {
        let manager = CoreDataManager(inMemory: true)
        let record = try makeRecord(in: manager, rating: 4)
        let viewModel = RecordDetailViewModel(recordID: record.objectID, dataManager: manager)

        viewModel.reload()

        #expect(viewModel.ratingToShow == 4)
    }

    @Test("コメントが空なら、コメントを出さない")
    func emptyCommentIsHidden() throws {
        let manager = CoreDataManager(inMemory: true)
        let record = try makeRecord(in: manager, comment: "")
        let viewModel = RecordDetailViewModel(recordID: record.objectID, dataManager: manager)

        viewModel.reload()

        #expect(viewModel.commentToShow == nil)
    }

    // MARK: - お気に入り

    @Test("お気に入りを切り替えると、状態が反転して保存される")
    func toggleFavoriteFlipsAndSaves() throws {
        let manager = CoreDataManager(inMemory: true)
        let record = try makeRecord(in: manager)
        let viewModel = RecordDetailViewModel(recordID: record.objectID, dataManager: manager)
        viewModel.reload()

        let isSaved = viewModel.toggleFavorite()

        #expect(isSaved)
        #expect(viewModel.isFavorite)
        #expect(manager.fetchFavoriteRecords().count == 1)
    }

    // MARK: - 削除

    @Test("削除すると記録がなくなり、読み直すと画面を閉じることになる")
    func deleteRemovesRecordAndClosesOnReload() throws {
        let manager = CoreDataManager(inMemory: true)
        let record = try makeRecord(in: manager)
        let viewModel = RecordDetailViewModel(recordID: record.objectID, dataManager: manager)
        viewModel.reload()

        let isDeleted = viewModel.deleteRecord()
        viewModel.reload()

        #expect(isDeleted)
        #expect(manager.fetchAllRecords().isEmpty)
        #expect(viewModel.shouldClose)
    }

    // MARK: - ヘルパー

    /// テスト用の記録を作る。引数を省いた項目は、表示に影響しない値にする
    private func makeRecord(
        in manager: CoreDataManager,
        storeName: String = "テスト軒",
        visitDate: Date = Date(timeIntervalSince1970: 1_700_000_000),
        cost: Int16 = 0,
        rating: Int16 = 0,
        comment: String? = nil,
        prefecture: Prefecture? = nil
    ) throws -> Record {
        try #require(manager.createRecord(
            storeName: storeName,
            ramenType: .shoyu,
            visitDate: visitDate,
            cost: cost,
            rating: rating,
            comment: comment,
            prefecture: prefecture
        ))
    }

    /// 端末のタイムゾーンでの、その日の 0 時
    private func makeDate(year: Int, month: Int, day: Int) throws -> Date {
        let calendar = Calendar(identifier: .gregorian)
        return try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }
}
