//
//  CoreDataManagerTests.swift
//  mennikkiTests
//

import Testing
import Foundation
@testable import mennikki

/// CoreDataManager のテスト。インメモリのストアを使い、端末上の実データには触れない
@MainActor
struct CoreDataManagerTests {

    @Test("インメモリのストアで、記録の作成と取得ができる")
    func createAndFetchRecord() throws {
        let manager = CoreDataManager(inMemory: true)
        let visitDate = Date(timeIntervalSince1970: 1_700_000_000)

        let created = manager.createRecord(
            storeName: "テスト軒",
            ramenType: .shoyu,
            visitDate: visitDate,
            cost: 900,
            rating: 4,
            comment: "あっさり",
            prefecture: .tokyo
        )
        #expect(created != nil)

        let records = manager.fetchAllRecords()
        #expect(records.count == 1)
        let record = try #require(records.first)
        #expect(record.storeName == "テスト軒")
        #expect(record.ramenType == RamenType.shoyu.rawValue)
        #expect(record.visitDate == visitDate)
        #expect(record.cost == 900)
        #expect(record.rating == 4)
        #expect(record.comment == "あっさり")
        #expect(record.prefecture == Prefecture.tokyo.rawValue)
        #expect(record.isFavorite == false)
    }

    @Test("新しく作ったインメモリのストアは、空の状態から始まる")
    func newStoreStartsEmpty() {
        let manager = CoreDataManager(inMemory: true)

        #expect(manager.fetchAllRecords().isEmpty)
    }

    @Test("インメモリのストア同士で、データが共有されない")
    func storesAreIsolated() {
        let first = CoreDataManager(inMemory: true)
        first.createRecord(storeName: "一軒目", ramenType: .miso, visitDate: Date())

        let second = CoreDataManager(inMemory: true)

        #expect(first.fetchAllRecords().count == 1)
        #expect(second.fetchAllRecords().isEmpty)
    }
}
