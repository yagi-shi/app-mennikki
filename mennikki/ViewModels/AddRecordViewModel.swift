//
//  AddRecordViewModel.swift
//  mennikki
//

import Foundation
import Observation

/// 登録・編集画面の ViewModel。
/// 入力の値、入力の検証、保存、ストア評価を頼むかどうかの判定を受け持つ。画面の部品や写真の変換は扱わない
@Observable
final class AddRecordViewModel {

    /// 入力のエラー。保存しなかった理由
    enum ValidationError: Equatable {
        case storeNameEmpty
        case storeNameTooLong
        case ramenTypeNotSelected
        case ratingNotSelected
        case commentTooLong

        var message: String {
            switch self {
            case .storeNameEmpty: return "店舗名を入力してください"
            case .storeNameTooLong: return "店舗名は\(AddRecordViewModel.maxStoreNameLength)文字以内で入力してください"
            case .ramenTypeNotSelected: return "ラーメンの種類を選択してください"
            case .ratingNotSelected: return "評価を選択してください"
            case .commentTooLong: return "コメントは\(AddRecordViewModel.maxCommentLength)文字以内で入力してください"
            }
        }
    }

    enum SaveResult: Equatable {
        case saved(shouldRequestReview: Bool)
        case failed
    }

    static let maxStoreNameLength = 100
    static let maxCommentLength = 500
    static let maxCost = 9999

    // MARK: - 入力の値（画面から、入力が変わるたびに入れる）

    var storeName = ""
    var ramenType: RamenType?
    var visitDate = Date()
    /// 費用の欄の文字。保存のときに数に直す
    var costText = ""
    /// 評価。0 は未選択
    var rating = 0
    var comment = ""
    var prefecture: Prefecture?

    // MARK: - Properties

    /// 編集する記録。新規作成のときは nil
    @ObservationIgnored let recordToEdit: Record?
    @ObservationIgnored private let dataManager: CoreDataManager

    var isEditMode: Bool { recordToEdit != nil }

    /// 編集する記録の、保存済みの写真のデータ
    var existingPhotoData: Data? { recordToEdit?.photo }

    /// - Parameters:
    ///   - recordToEdit: 編集する記録。新規作成のときは省く
    ///   - dataManager: 記録の読み書きに使う。テストでインメモリのものを渡せるように、外から受け取る
    init(recordToEdit: Record? = nil, dataManager: CoreDataManager = .shared) {
        self.recordToEdit = recordToEdit
        self.dataManager = dataManager

        guard let recordToEdit else { return }
        storeName = recordToEdit.storeName ?? ""
        ramenType = RamenType(rawValue: recordToEdit.ramenType ?? "")
        visitDate = recordToEdit.visitDate ?? Date()
        costText = recordToEdit.cost > 0 ? "\(recordToEdit.cost)" : ""
        rating = Int(recordToEdit.rating)
        comment = recordToEdit.comment ?? ""
        prefecture = recordToEdit.prefecture.flatMap(Prefecture.init(rawValue:))
    }

    // MARK: - 入力の検証

    /// 入力を、店舗名 → 種類 → 評価 → コメントの順に確かめ、最初に見つかったエラーを返す。問題がなければ nil
    func validate() -> ValidationError? {
        if trimmedStoreName.isEmpty { return .storeNameEmpty }
        if trimmedStoreName.count > Self.maxStoreNameLength { return .storeNameTooLong }
        if ramenType == nil { return .ramenTypeNotSelected }
        if rating <= 0 { return .ratingNotSelected }
        if trimmedComment.count > Self.maxCommentLength { return .commentTooLong }
        return nil
    }

    /// 費用の欄に入れてよい文字か。空か、数字で上限以下なら受け付ける
    static func isAcceptableCostText(_ text: String) -> Bool {
        if text.isEmpty { return true }
        guard let cost = Int(text) else { return false }
        return cost <= maxCost
    }

    // MARK: - 保存

    /// 記録を保存する。`validate()` でエラーがないことを確かめてから呼ぶ
    /// - Parameter photoData: 保存する写真のデータ。写真を選び直していなければ、保存済みのデータ（`existingPhotoData`）を渡す
    func save(photoData: Data?) -> SaveResult {
        guard let ramenType else { return .failed }

        let cost = Int16(costText) ?? 0
        let ratingValue = Int16(rating)
        let commentToSave = trimmedComment.isEmpty ? nil : trimmedComment

        if let recordToEdit {
            let isUpdated = dataManager.updateRecord(
                recordToEdit,
                storeName: trimmedStoreName,
                ramenType: ramenType,
                visitDate: visitDate,
                cost: cost,
                rating: ratingValue,
                comment: commentToSave,
                photo: photoData,
                isFavorite: recordToEdit.isFavorite,
                prefecture: prefecture
            )
            // 更新では、ストア評価を頼まない（新規登録の節目だけで頼むため）
            return isUpdated ? .saved(shouldRequestReview: false) : .failed
        }

        let createdRecord = dataManager.createRecord(
            storeName: trimmedStoreName,
            ramenType: ramenType,
            visitDate: visitDate,
            cost: cost,
            rating: ratingValue,
            comment: commentToSave,
            photo: photoData,
            prefecture: prefecture
        )
        guard createdRecord != nil else { return .failed }

        let shouldRequestReview = ReviewRequestPolicy.shouldRequestReview(recordCount: dataManager.fetchAllRecords().count)
        return .saved(shouldRequestReview: shouldRequestReview)
    }

    // MARK: - 値の組み立て

    private var trimmedStoreName: String {
        storeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedComment: String {
        comment.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
