//
//  RecordListViewModel.swift
//  mennikki
//

import Foundation
import CoreData
import Observation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.mennikki", category: "RecordList")

/// 記録一覧とお気に入り一覧の ViewModel。
/// 記録の取り出し、絞り込み、フィルターの選択肢、空のときの表示の種類を受け持つ。画面の部品は扱わない
@Observable
final class RecordListViewModel {

    /// 一覧に出す記録の範囲
    enum Scope {
        case allRecords
        case favoritesOnly
    }

    /// 記録が 1 件もないときの表示の種類
    enum EmptyState {
        /// 記録がまだない
        case noRecords
        /// 絞り込みの条件に合う記録がない（記録が消えたと誤解されないように、記録がないときと分ける）
        case noMatchingRecords
        /// お気に入りがない
        case noFavorites
    }

    // MARK: - 画面に出す値

    /// 一覧に出す記録。訪問日の新しい順で、訪問日が同じ記録は作った日時の新しい順
    private(set) var records: [Record] = []
    /// 今の絞り込みの条件（店名の検索、種類、都道府県）
    private(set) var filter = RecordListFilter()

    var emptyState: EmptyState {
        if scope == .favoritesOnly { return .noFavorites }
        return filter.isNarrowing ? .noMatchingRecords : .noRecords
    }

    // MARK: - Properties

    @ObservationIgnored private let scope: Scope
    @ObservationIgnored private let dataManager: CoreDataManager
    @ObservationIgnored private var fetchedResultsController: NSFetchedResultsController<Record>?
    /// NSFetchedResultsController の変更の知らせを受け取る。受け取る側は NSObject である必要があるため、別に持つ
    @ObservationIgnored private let changeReceiver = FetchedResultsChangeReceiver()

    /// - Parameters:
    ///   - scope: 一覧に出す記録の範囲
    ///   - dataManager: 記録の読み書きに使う。テストでインメモリのものを渡せるように、外から受け取る
    init(scope: Scope, dataManager: CoreDataManager = .shared) {
        self.scope = scope
        self.dataManager = dataManager
    }

    // MARK: - 取り出し

    /// 記録を取り出し、記録の追加や削除を見つけて一覧を更新するようにする
    func load() {
        guard let context = dataManager.viewContext else { return }

        let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
        fetchRequest.sortDescriptors = RecordSort.newestFirst
        fetchRequest.predicate = makePredicate()

        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        changeReceiver.onChange = { [weak self] in
            guard let self else { return }
            // お気に入りや店名が変わったときは、記録の並びと件数が同じまま、中身だけが変わる。
            // records に同じ並びを入れても @Observable は知らせないので、ここでは必ず知らせる
            self.withMutation(keyPath: \.records) {
                self.records = controller.fetchedObjects ?? []
            }
        }
        controller.delegate = changeReceiver
        fetchedResultsController = controller

        performFetch()
    }

    /// 今の条件で、記録を取り出し直す。取り出しの準備（`load()`）がまだなら、準備から行う
    func reload() {
        guard let fetchedResultsController else {
            load()
            return
        }
        fetchedResultsController.fetchRequest.predicate = makePredicate()
        performFetch()
    }

    private func performFetch() {
        guard let fetchedResultsController else { return }
        do {
            try fetchedResultsController.performFetch()
        } catch {
            logger.error("Error fetching records: \(error.localizedDescription, privacy: .public)")
        }
        // @Observable は、前と同じ値を入れたときは知らせない（Swift 6.3 で確かめた。古い Swift では知らせていた）。
        // そのため、読み直して記録が同じなら、画面は描き直されない。この動きは RecordListViewModelTests で確かめている。
        // 記録の中身の変化は、load() の onChange で知らせる
        records = fetchedResultsController.fetchedObjects ?? []
    }

    private func makePredicate() -> NSPredicate? {
        var predicates: [NSPredicate] = []

        if scope == .favoritesOnly {
            predicates.append(NSPredicate(format: "isFavorite == true"))
        }
        if !filter.searchText.isEmpty {
            predicates.append(NSPredicate(format: "storeName CONTAINS[cd] %@", filter.searchText))
        }
        if !filter.selectedRamenTypes.isEmpty {
            let typeRawValues = filter.selectedRamenTypes.map(\.rawValue)
            predicates.append(NSPredicate(format: "ramenType IN %@", typeRawValues))
        }
        if let prefecture = filter.selectedPrefecture {
            predicates.append(NSPredicate(format: "prefecture == %@", prefecture.rawValue))
        }

        guard !predicates.isEmpty else { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    // MARK: - 絞り込み

    func setSearchText(_ searchText: String) {
        filter.searchText = searchText
        reload()
    }

    /// 種類を選ぶ。選んでいる種類なら外す
    func toggleRamenType(_ ramenType: RamenType) {
        if let index = filter.selectedRamenTypes.firstIndex(of: ramenType) {
            filter.selectedRamenTypes.remove(at: index)
        } else {
            filter.selectedRamenTypes.append(ramenType)
        }
        reload()
    }

    func clearRamenTypes() {
        filter.selectedRamenTypes.removeAll()
        reload()
    }

    /// 都道府県を選ぶ。選んでいる都道府県なら外す
    func togglePrefecture(_ prefecture: Prefecture) {
        filter.selectedPrefecture = (filter.selectedPrefecture == prefecture) ? nil : prefecture
        reload()
    }

    func clearPrefecture() {
        filter.selectedPrefecture = nil
        reload()
    }

    // MARK: - フィルターの選択肢

    /// 種類の選択肢。記録にある種類に、選んでいる種類（記録がなくなったものを含む）を加え、定義の順に並べる
    func ramenTypeOptions() -> [RamenType] {
        RamenType.filterOptions(
            registered: dataManager.fetchRegisteredRamenTypes(),
            selected: filter.selectedRamenTypes
        )
    }

    /// 都道府県の選択肢。記録にある都道府県だけを、定義の順に並べる
    func prefectureOptions() -> [Prefecture] {
        let registeredRawValues = Set(dataManager.fetchDistinctPrefectures())
        return Prefecture.allCases.filter { registeredRawValues.contains($0.rawValue) }
    }
}

/// NSFetchedResultsController の「中身が変わった」という知らせを、クロージャに渡す
private final class FetchedResultsChangeReceiver: NSObject, NSFetchedResultsControllerDelegate {
    var onChange: (() -> Void)?

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        onChange?()
    }
}
