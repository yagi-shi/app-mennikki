//
//  CoreDataManager.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import Foundation
import CoreData
import UIKit

/// Core Dataの操作を管理するシングルトンクラス
class CoreDataManager {

    // MARK: - Singleton

    static let shared = CoreDataManager()

    private init() {}

    // MARK: - Core Data Stack

    /// Persistent Container（AppDelegateから取得）
    private var persistentContainer: NSPersistentContainer {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("AppDelegate not found")
        }
        return appDelegate.persistentContainer
    }

    /// View Context（メインスレッド用）
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
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
        isFavorite: Bool = false
    ) -> Record? {
        let context = viewContext

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
        record.createdAt = Date()

        do {
            try context.save()
            return record
        } catch {
            print("Error creating record: \(error)")
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
        isFavorite: Bool
    ) -> Bool {
        record.storeName = storeName
        record.ramenType = ramenType.rawValue
        record.visitDate = visitDate
        record.cost = cost
        record.rating = rating
        record.comment = comment
        record.photo = photo
        record.isFavorite = isFavorite

        return saveContext()
    }

    /// レコードを削除
    /// - Parameter record: 削除対象のRecord
    /// - Returns: 成功時true、失敗時false
    @discardableResult
    func deleteRecord(_ record: Record) -> Bool {
        let context = viewContext
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
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching records: \(error)")
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
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching favorite records: \(error)")
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
            return try viewContext.fetch(request)
        } catch {
            print("Error searching records: \(error)")
            return []
        }
    }

    // MARK: - Helper Methods

    /// コンテキストを保存
    /// - Returns: 成功時true、失敗時false
    @discardableResult
    private func saveContext() -> Bool {
        let context = viewContext

        if context.hasChanges {
            do {
                try context.save()
                return true
            } catch {
                print("Error saving context: \(error)")
                return false
            }
        }

        return true
    }
}
