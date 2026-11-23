//
//  AddRecordViewModelTests.swift
//  mennikkiTests
//

import Testing
import Foundation
import CoreData
@testable import mennikki

/// AddRecordViewModel のテスト。記録の読み書きにはインメモリのストアを使い、端末上の実データには書き込まない
@MainActor
struct AddRecordViewModelTests {

    // MARK: - 入力の検証

    @Test("すべての入力が正しければ、エラーにならない")
    func validInputHasNoError() {
        let viewModel = makeValidNewViewModel()

        #expect(viewModel.validate() == nil)
    }

    @Test("店舗名が空白だけなら、店舗名が空のエラーになる")
    func blankStoreNameIsError() {
        let viewModel = makeValidNewViewModel()
        viewModel.storeName = "   "

        #expect(viewModel.validate() == .storeNameEmpty)
    }

    @Test("店舗名は 100 文字まで通り、101 文字なら長すぎるエラーになる")
    func storeNameLengthLimit() {
        let viewModel = makeValidNewViewModel()

        viewModel.storeName = String(repeating: "あ", count: 100)
        #expect(viewModel.validate() == nil)

        viewModel.storeName = String(repeating: "あ", count: 101)
        #expect(viewModel.validate() == .storeNameTooLong)
    }

    @Test("種類を選んでいなければ、種類のエラーになる")
    func missingRamenTypeIsError() {
        let viewModel = makeValidNewViewModel()
        viewModel.ramenType = nil

        #expect(viewModel.validate() == .ramenTypeNotSelected)
    }

    @Test("評価が 0 なら、評価のエラーになる")
    func zeroRatingIsError() {
        let viewModel = makeValidNewViewModel()
        viewModel.rating = 0

        #expect(viewModel.validate() == .ratingNotSelected)
    }

    @Test("コメントは前後の空白を除いて 500 文字まで通り、501 文字なら長すぎるエラーになる")
    func commentLengthLimit() {
        let viewModel = makeValidNewViewModel()

        viewModel.comment = "  " + String(repeating: "あ", count: 500) + "\n"
        #expect(viewModel.validate() == nil)

        viewModel.comment = String(repeating: "あ", count: 501)
        #expect(viewModel.validate() == .commentTooLong)
    }

    @Test("問題が複数あるときは、店舗名 → 種類 → 評価 → コメントの順で、最初の 1 つのエラーになる")
    func firstErrorInFieldOrderIsReturned() {
        let viewModel = AddRecordViewModel(dataManager: CoreDataManager(inMemory: true))
        viewModel.comment = String(repeating: "あ", count: 501)
        #expect(viewModel.validate() == .storeNameEmpty)

        viewModel.storeName = "テスト軒"
        #expect(viewModel.validate() == .ramenTypeNotSelected)

        viewModel.ramenType = .shoyu
        #expect(viewModel.validate() == .ratingNotSelected)

        viewModel.rating = 4
        #expect(viewModel.validate() == .commentTooLong)
    }

    @Test("エラーの文言は、移行前と同じ")
    func errorMessagesAreUnchanged() {
        #expect(AddRecordViewModel.ValidationError.storeNameEmpty.message == "店舗名を入力してください")
        #expect(AddRecordViewModel.ValidationError.storeNameTooLong.message == "店舗名は100文字以内で入力してください")
        #expect(AddRecordViewModel.ValidationError.ramenTypeNotSelected.message == "ラーメンの種類を選択してください")
        #expect(AddRecordViewModel.ValidationError.ratingNotSelected.message == "評価を選択してください")
        #expect(AddRecordViewModel.ValidationError.commentTooLong.message == "コメントは500文字以内で入力してください")
    }

    // MARK: - 費用の入力

    @Test("費用は、空と、数字で 9999 以下を受け付け、10000 以上と数字以外は受け付けない")
    func acceptableCostText() {
        #expect(AddRecordViewModel.isAcceptableCostText(""))
        #expect(AddRecordViewModel.isAcceptableCostText("9999"))
        #expect(AddRecordViewModel.isAcceptableCostText("10000") == false)
        #expect(AddRecordViewModel.isAcceptableCostText("12a") == false)
    }

    // MARK: - 新規作成

    @Test("新規作成で、入力どおりの記録が、お気に入りではない状態でできる")
    func createSavesInputAsNewRecord() throws {
        let manager = CoreDataManager(inMemory: true)
        let visitDate = Date(timeIntervalSince1970: 1_700_000_000)
        let photoData = Data([0x01, 0x02, 0x03])
        let viewModel = AddRecordViewModel(dataManager: manager)
        viewModel.storeName = "  テスト軒  "
        viewModel.ramenType = .miso
        viewModel.visitDate = visitDate
        viewModel.costText = "900"
        viewModel.rating = 4
        viewModel.comment = "あっさり"
        viewModel.prefecture = .tokyo

        let result = viewModel.save(photoData: photoData)

        #expect(result == .saved(shouldRequestReview: false))
        let record = try #require(manager.fetchAllRecords().first)
        #expect(record.storeName == "テスト軒")
        #expect(record.ramenType == RamenType.miso.rawValue)
        #expect(record.visitDate == visitDate)
        #expect(record.cost == 900)
        #expect(record.rating == 4)
        #expect(record.comment == "あっさり")
        #expect(record.prefecture == Prefecture.tokyo.rawValue)
        #expect(record.photo == photoData)
        #expect(record.isFavorite == false)
    }

    @Test("コメントが空白だけ、費用が空なら、コメントなし、費用 0 で保存する")
    func blankCommentAndEmptyCostAreSavedAsNothing() throws {
        let manager = CoreDataManager(inMemory: true)
        let viewModel = makeValidNewViewModel(dataManager: manager)
        viewModel.comment = "  \n "
        viewModel.costText = ""

        _ = viewModel.save(photoData: nil)

        let record = try #require(manager.fetchAllRecords().first)
        #expect(record.comment == nil)
        #expect(record.cost == 0)
    }

    // MARK: - 更新

    @Test("更新で、その記録だけが変わり、お気に入りの状態は保たれる")
    func updateChangesOnlyThatRecordAndKeepsFavorite() throws {
        let manager = CoreDataManager(inMemory: true)
        let editedRecord = try #require(manager.createRecord(storeName: "編集する店", ramenType: .shoyu, visitDate: Date(), rating: 3, isFavorite: true))
        _ = try #require(manager.createRecord(storeName: "ほかの店", ramenType: .shio, visitDate: Date(), rating: 2))
        let viewModel = AddRecordViewModel(recordToEdit: editedRecord, dataManager: manager)
        viewModel.storeName = "新しい店名"

        _ = viewModel.save(photoData: nil)

        let storeNames = Set(manager.fetchAllRecords().map { $0.storeName ?? "" })
        #expect(storeNames == ["新しい店名", "ほかの店"])
        #expect(editedRecord.isFavorite)
    }

    @Test("保存に渡した写真のデータが、変換されずにそのまま保存される")
    func photoDataIsSavedAsGiven() throws {
        let manager = CoreDataManager(inMemory: true)
        let existingPhotoData = Data([0x0A, 0x0B, 0x0C])
        let record = try #require(manager.createRecord(storeName: "テスト軒", ramenType: .shoyu, visitDate: Date(), rating: 3, photo: existingPhotoData))
        let viewModel = AddRecordViewModel(recordToEdit: record, dataManager: manager)

        _ = viewModel.save(photoData: viewModel.existingPhotoData)

        #expect(record.photo == existingPhotoData)
    }

    // MARK: - ストア評価の依頼

    @Test("新規作成で記録の総数が 3 件になったら、ストア評価を頼む")
    func createReachingMilestoneRequestsReview() throws {
        let manager = CoreDataManager(inMemory: true)
        _ = try #require(manager.createRecord(storeName: "1 件目", ramenType: .shoyu, visitDate: Date()))
        _ = try #require(manager.createRecord(storeName: "2 件目", ramenType: .shoyu, visitDate: Date()))
        let viewModel = makeValidNewViewModel(dataManager: manager)

        #expect(viewModel.save(photoData: nil) == .saved(shouldRequestReview: true))
    }

    @Test("更新では、記録の総数が節目でも、ストア評価を頼まない")
    func updateDoesNotRequestReview() throws {
        let manager = CoreDataManager(inMemory: true)
        _ = try #require(manager.createRecord(storeName: "1 件目", ramenType: .shoyu, visitDate: Date()))
        _ = try #require(manager.createRecord(storeName: "2 件目", ramenType: .shoyu, visitDate: Date()))
        let record = try #require(manager.createRecord(storeName: "3 件目", ramenType: .shoyu, visitDate: Date(), rating: 3))
        let viewModel = AddRecordViewModel(recordToEdit: record, dataManager: manager)

        #expect(viewModel.save(photoData: nil) == .saved(shouldRequestReview: false))
    }

    // MARK: - 編集のときの初期値

    @Test("編集のときは、記録の値が入力の初期値になる")
    func editModeStartsWithRecordValues() throws {
        let manager = CoreDataManager(inMemory: true)
        let visitDate = Date(timeIntervalSince1970: 1_700_000_000)
        let photoData = Data([0x01])
        let record = try #require(manager.createRecord(
            storeName: "テスト軒",
            ramenType: .tonkotsu,
            visitDate: visitDate,
            cost: 1200,
            rating: 5,
            comment: "こってり",
            photo: photoData,
            prefecture: .fukuoka
        ))

        let viewModel = AddRecordViewModel(recordToEdit: record, dataManager: manager)

        #expect(viewModel.isEditMode)
        #expect(viewModel.storeName == "テスト軒")
        #expect(viewModel.ramenType == .tonkotsu)
        #expect(viewModel.visitDate == visitDate)
        #expect(viewModel.costText == "1200")
        #expect(viewModel.rating == 5)
        #expect(viewModel.comment == "こってり")
        #expect(viewModel.prefecture == .fukuoka)
        #expect(viewModel.existingPhotoData == photoData)
    }

    @Test("費用が 0 の記録を編集するときは、費用の初期値が空になる")
    func editModeWithZeroCostStartsWithEmptyCost() throws {
        let manager = CoreDataManager(inMemory: true)
        let record = try #require(manager.createRecord(storeName: "テスト軒", ramenType: .shoyu, visitDate: Date(), cost: 0))

        let viewModel = AddRecordViewModel(recordToEdit: record, dataManager: manager)

        #expect(viewModel.costText == "")
    }

    // MARK: - ヘルパー

    /// すべての入力が正しい、新規作成の ViewModel を作る。テストでは、確かめたい入力だけを変える
    /// - Parameter dataManager: 省いたときは、新しいインメモリのストアを使う
    private func makeValidNewViewModel(dataManager: CoreDataManager? = nil) -> AddRecordViewModel {
        let viewModel = AddRecordViewModel(dataManager: dataManager ?? CoreDataManager(inMemory: true))
        viewModel.storeName = "テスト軒"
        viewModel.ramenType = .shoyu
        viewModel.rating = 4
        return viewModel
    }
}
