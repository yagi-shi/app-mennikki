//
//  CoreDataManagerTests.swift
//  mennikkiTests
//

import Testing
import Foundation
import CoreData
@testable import mennikki

/// CoreDataManager のテスト。記録の読み書きにはインメモリのストアを使い、端末上の実データには書き込まない
@MainActor
struct CoreDataManagerTests {

    // MARK: - 記録の読み書き

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

    // MARK: - 登録済みの種類

    @Test("登録済みの記録に含まれる種類だけを、重複なく取得できる")
    func fetchRegisteredRamenTypesWithoutDuplicates() {
        let manager = CoreDataManager(inMemory: true)
        manager.createRecord(storeName: "一軒目", ramenType: .shoyu, visitDate: Date())
        manager.createRecord(storeName: "二軒目", ramenType: .shoyu, visitDate: Date())
        manager.createRecord(storeName: "三軒目", ramenType: .miso, visitDate: Date())

        #expect(manager.fetchRegisteredRamenTypes() == [.shoyu, .miso])
    }

    @Test("記録が 0 件のときは、登録済みの種類の取得結果が空になる")
    func fetchRegisteredRamenTypesWhenEmpty() {
        let manager = CoreDataManager(inMemory: true)

        #expect(manager.fetchRegisteredRamenTypes().isEmpty)
    }

    @Test("取得した種類の並び順が、RamenType の定義順になっている")
    func fetchRegisteredRamenTypesInDefinitionOrder() {
        let manager = CoreDataManager(inMemory: true)
        manager.createRecord(storeName: "一軒目", ramenType: .iekei, visitDate: Date())
        manager.createRecord(storeName: "二軒目", ramenType: .shoyu, visitDate: Date())
        manager.createRecord(storeName: "三軒目", ramenType: .tonkotsu, visitDate: Date())

        #expect(manager.fetchRegisteredRamenTypes() == [.shoyu, .tonkotsu, .iekei])
    }

    // MARK: - ストアの保存先

    @Test("アプリ本体のストアは、既定の場所の mennikki.sqlite に保存される SQLite ストアである")
    func sharedStoreIsSQLiteFileAtDefaultLocation() throws {
        let store = try sharedStore()
        let expectedURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("mennikki.sqlite")

        #expect(store.type == NSSQLiteStoreType)
        #expect(store.url?.standardizedFileURL == expectedURL.standardizedFileURL)
    }

    @Test("アプリ本体のストアのファイル保護は complete である")
    func sharedStoreUsesCompleteFileProtection() throws {
        let store = try sharedStore()

        #expect(store.options?[NSPersistentStoreFileProtectionKey] as? FileProtectionType == .complete)
    }

    @Test("インメモリのストアは、端末上のファイルを保存先にしない")
    func inMemoryStoreDoesNotUseFileOnDevice() throws {
        let manager = CoreDataManager(inMemory: true)
        let store = try #require(manager.viewContext?.persistentStoreCoordinator?.persistentStores.first)

        #expect(store.url?.path == "/dev/null")
    }

    // MARK: - Helper Methods

    /// アプリ本体が使うストア。設定の確認だけに使い、書き込まない
    private func sharedStore() throws -> NSPersistentStore {
        try #require(CoreDataManager.shared.viewContext?.persistentStoreCoordinator?.persistentStores.first)
    }
}
