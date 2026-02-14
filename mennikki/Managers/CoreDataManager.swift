//
//  CoreDataManager.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import Foundation
import CoreData
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.mennikki", category: "CoreData")

/// Core Dataの操作を管理するシングルトンクラス
class CoreDataManager {

    // MARK: - Singleton

    static let shared = CoreDataManager()

    private init() {}

    // MARK: - Core Data Stack

    /// ストアが正常に読み込まれたかどうか
    private var isStoreLoaded = false

    /// Persistent Container
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "mennikki")
        // 端末ロック中のデータアクセスを防止
        let description = container.persistentStoreDescriptions.first
        description?.setOption(
            FileProtectionType.complete as NSObject,
            forKey: NSPersistentStoreFileProtectionKey
        )
        container.loadPersistentStores { [weak self] _, error in
            if let error = error as NSError? {
                logger.error("Persistent store load error: \(error.localizedDescription, privacy: .public)")
            } else {
                self?.isStoreLoaded = true
            }
        }
        return container
    }()

    /// View Context（メインスレッド用）。ストア未読み込み時は nil を返す。
    var viewContext: NSManagedObjectContext? {
        dispatchPrecondition(condition: .onQueue(.main))
        // persistentContainer へのアクセスで lazy 初期化 → loadPersistentStores → isStoreLoaded = true
        let container = persistentContainer
        guard isStoreLoaded else {
            logger.warning("Store not loaded — skipping operation")
            return nil
        }
        return container.viewContext
    }

    /// Background Context（バックグラウンド処理用）
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }

    // MARK: - CRUD Operations

    /// 新しいレコードを作成
    /// - Parameters:
    ///   - storeName: 店舗名
    ///   - ramenType: ラーメンの種類
    ///   - visitDate: 訪問日
    ///   - cost: 費用（オプション）
    ///   - rating: 評価（オプション、0-5）
    ///   - comment: コメント（オプション）
    ///   - photo: 写真データ（オプション）
    ///   - isFavorite: お気に入りフラグ（デフォルト: false）
    /// - Returns: 作成されたRecord、エラー時はnil
    @discardableResult
    func createRecord(
        storeName: String,
        ramenType: RamenType,
        visitDate: Date,
        cost: Int16 = 0,
        rating: Int16 = 0,
        comment: String? = nil,
        photo: Data? = nil,
        isFavorite: Bool = false,
        prefecture: Prefecture? = nil
    ) -> Record? {
        guard let context = viewContext else { return nil }

        let record = Record(context: context)
        record.id = UUID()
        record.storeName = storeName
        record.ramenType = ramenType.rawValue
        record.visitDate = visitDate
        record.cost = cost
        record.rating = rating
        record.comment = comment
        record.photo = photo
        record.isFavorite = isFavorite
        record.prefecture = prefecture?.rawValue
        record.createdAt = Date()

        do {
            try context.save()
            return record
        } catch {
            logger.error("Error creating record: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// レコードを更新
    /// - Parameters:
    ///   - record: 更新対象のRecord
    ///   - storeName: 店舗名
    ///   - ramenType: ラーメンの種類
    ///   - visitDate: 訪問日
    ///   - cost: 費用
    ///   - rating: 評価
    ///   - comment: コメント
    ///   - photo: 写真データ
    ///   - isFavorite: お気に入りフラグ
    /// - Returns: 成功時true、失敗時false
    @discardableResult
    func updateRecord(
        _ record: Record,
        storeName: String,
        ramenType: RamenType,
        visitDate: Date,
        cost: Int16,
        rating: Int16,
        comment: String?,
        photo: Data?,
        isFavorite: Bool,
        prefecture: Prefecture? = nil
    ) -> Bool {
        record.storeName = storeName
        record.ramenType = ramenType.rawValue
        record.visitDate = visitDate
        record.cost = cost
        record.rating = rating
        record.comment = comment
        record.photo = photo
        record.isFavorite = isFavorite
        record.prefecture = prefecture?.rawValue

        return saveContext()
    }

    /// レコードを削除
    /// - Parameter record: 削除対象のRecord
    /// - Returns: 成功時true、失敗時false
    @discardableResult
    func deleteRecord(_ record: Record) -> Bool {
        guard let context = viewContext else { return false }
        context.delete(record)
        return saveContext()
    }

    /// お気に入り状態を切り替え
    /// - Parameter record: 対象のRecord
    /// - Returns: 成功時true、失敗時false
    @discardableResult
    func toggleFavorite(_ record: Record) -> Bool {
        record.isFavorite.toggle()
        return saveContext()
    }

    /// 全てのレコードを取得
    /// - Parameter sortDescriptors: ソート条件（デフォルト: 訪問日の降順）
    /// - Returns: Recordの配列、エラー時は空配列
    func fetchAllRecords(sortDescriptors: [NSSortDescriptor]? = nil) -> [Record] {
        let request: NSFetchRequest<Record> = Record.fetchRequest()
        request.sortDescriptors = sortDescriptors ?? [NSSortDescriptor(key: "visitDate", ascending: false)]

        do {
            return try viewContext?.fetch(request) ?? []
        } catch {
            logger.error("Error fetching records: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    /// お気に入りのレコードを取得
    /// - Parameter sortDescriptors: ソート条件（デフォルト: 訪問日の降順）
    /// - Returns: お気に入りのRecordの配列
    func fetchFavoriteRecords(sortDescriptors: [NSSortDescriptor]? = nil) -> [Record] {
        let request: NSFetchRequest<Record> = Record.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == true")
        request.sortDescriptors = sortDescriptors ?? [NSSortDescriptor(key: "visitDate", ascending: false)]

        do {
            return try viewContext?.fetch(request) ?? []
        } catch {
            logger.error("Error fetching favorite records: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    /// 検索条件でレコードを取得
    /// - Parameters:
    ///   - searchText: 店舗名での検索文字列（部分一致）
    ///   - ramenTypes: フィルターするラーメンの種類（nilの場合は全種類）
    ///   - sortDescriptors: ソート条件
    /// - Returns: 検索条件に一致するRecordの配列
    func searchRecords(
        searchText: String? = nil,
        ramenTypes: [RamenType]? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) -> [Record] {
        let request: NSFetchRequest<Record> = Record.fetchRequest()

        var predicates: [NSPredicate] = []

        // 店舗名検索
        if let searchText = searchText, !searchText.isEmpty {
            predicates.append(NSPredicate(format: "storeName CONTAINS[cd] %@", searchText))
        }

        // ラーメン種類フィルター
        if let ramenTypes = ramenTypes, !ramenTypes.isEmpty {
            let typeStrings = ramenTypes.map { $0.rawValue }
            predicates.append(NSPredicate(format: "ramenType IN %@", typeStrings))
        }

        // 複数の条件を結合
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = sortDescriptors ?? [NSSortDescriptor(key: "visitDate", ascending: false)]

        do {
            return try viewContext?.fetch(request) ?? []
        } catch {
            logger.error("Error searching records: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    /// 記録済みの都道府県一覧を取得（軽量フェッチ）
    func fetchDistinctPrefectures() -> [String] {
        let request = NSFetchRequest<NSDictionary>(entityName: "Record")
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["prefecture"]
        request.returnsDistinctResults = true
        request.predicate = NSPredicate(format: "prefecture != nil")

        do {
            let results = try viewContext?.fetch(request) ?? []
            return results.compactMap { $0["prefecture"] as? String }
        } catch {
            logger.error("Error fetching distinct prefectures: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    // MARK: - Helper Methods

    /// 未保存の変更があれば保存する（バックグラウンド移行時など外部から呼ぶ用）
    func saveIfNeeded() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard isStoreLoaded else { return }
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                logger.error("Error saving on background: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// コンテキストを保存
    /// - Returns: 成功時true、失敗時false
    @discardableResult
    private func saveContext() -> Bool {
        guard let context = viewContext else { return false }

        if context.hasChanges {
            do {
                try context.save()
                return true
            } catch {
                logger.error("Error saving context: \(error.localizedDescription, privacy: .public)")
                return false
            }
        }

        return true
    }
}
