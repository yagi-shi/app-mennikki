//
//  RecordDetailViewModel.swift
//  mennikki
//

import Foundation
import CoreData
import Observation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.mennikki", category: "RecordDetail")

/// 記録詳細画面の ViewModel。
/// 記録の読み込み、画面に出す値の組み立て、お気に入りの切り替え、削除を受け持つ。画面の部品や色は扱わない
@Observable
final class RecordDetailViewModel {

    /// 情報の 1 行（都道府県・訪問日・費用）
    struct InfoRow: Equatable {
        enum Kind {
            case prefecture
            case visitDate
            case cost
        }

        let kind: Kind
        let title: String
        let value: String
    }

    // MARK: - 画面に出す値

    /// 記録が見つからない（削除された）ため、画面を閉じる必要があるか
    private(set) var shouldClose = false
    private(set) var storeName = ""
    /// 記録の種類。定義にない値のときは「その他」
    private(set) var ramenType: RamenType = .other
    /// 出す評価。評価がない（0 の）ときは nil
    private(set) var ratingToShow: Int?
    /// 値がある項目だけの、情報の行
    private(set) var infoRows: [InfoRow] = []
    /// 出すコメント。空のときは nil
    private(set) var commentToShow: String?
    private(set) var photoData: Data?
    private(set) var isFavorite = false

    /// 編集画面に渡す記録。読み込めていないときは nil
    private(set) var record: Record?

    // MARK: - Properties

    private static let visitDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日（E）"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()

    @ObservationIgnored private let recordID: NSManagedObjectID
    @ObservationIgnored private let dataManager: CoreDataManager

    /// - Parameters:
    ///   - recordID: 表示する記録の ID
    ///   - dataManager: 記録の読み書きに使う。アプリ本体では省いて `shared` を使い、テストではインメモリのものを渡す。
    ///     本番の保存ファイルを 2 か所から開かないように、ここで新しく作らない
    init(recordID: NSManagedObjectID, dataManager: CoreDataManager = .shared) {
        self.recordID = recordID
        self.dataManager = dataManager
    }

    // MARK: - Actions

    /// 記録を読み直し、画面に出す値を更新する。記録がなければ、画面を閉じることにする
    func reload() {
        guard let loadedRecord = try? dataManager.viewContext?.existingObject(with: recordID) as? Record else {
            shouldClose = true
            return
        }

        record = loadedRecord
        storeName = loadedRecord.storeName ?? ""
        ramenType = Self.ramenType(fromRawValue: loadedRecord.ramenType ?? "")
        ratingToShow = loadedRecord.rating > 0 ? Int(loadedRecord.rating) : nil
        infoRows = Self.makeInfoRows(for: loadedRecord)
        let comment = loadedRecord.comment ?? ""
        commentToShow = comment.isEmpty ? nil : comment
        photoData = loadedRecord.photo
        isFavorite = loadedRecord.isFavorite
    }

    /// お気に入りを切り替える。保存できたら true
    func toggleFavorite() -> Bool {
        guard let record else { return false }
        guard dataManager.toggleFavorite(record) else { return false }

        isFavorite = record.isFavorite
        return true
    }

    /// 記録を削除する。削除できたら true
    func deleteRecord() -> Bool {
        guard let record else { return false }
        return dataManager.deleteRecord(record)
    }

    // MARK: - 値の組み立て

    private static func ramenType(fromRawValue rawValue: String) -> RamenType {
        if let ramenType = RamenType(rawValue: rawValue) {
            return ramenType
        }
        logger.warning("不明なラーメン種類: \"\(rawValue, privacy: .public)\" → .other にフォールバック")
        return .other
    }

    private static func makeInfoRows(for record: Record) -> [InfoRow] {
        var rows: [InfoRow] = []

        if let prefecture = record.prefecture.flatMap(Prefecture.init(rawValue:)) {
            rows.append(InfoRow(kind: .prefecture, title: "都道府県", value: prefecture.rawValue))
        }

        if let visitDate = record.visitDate {
            rows.append(InfoRow(kind: .visitDate, title: "訪問日", value: visitDateFormatter.string(from: visitDate)))
        }

        if record.cost > 0 {
            rows.append(InfoRow(kind: .cost, title: "費用", value: "¥\(record.cost)"))
        }

        return rows
    }
}
