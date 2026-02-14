//
//  FavoriteListViewController.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import UIKit
import CoreData

/// お気に入り一覧画面
class FavoriteListViewController: BaseRecordListViewController {

    // MARK: - Base Class Configuration

    override var emptyStateIconName: String { "heart.circle" }
    override var emptyStateTitleText: String { "お気に入りがありません" }
    override var emptyStateSubTitleText: String { "気に入ったラーメンを記録してみましょう！" }

    override func fetchPredicate() -> NSPredicate? {
        NSPredicate(format: "isFavorite == true")
    }

    // MARK: - Setup

    override func setupAdditionalUI() {
        title = "お気に入り"
        navigationItem.largeTitleDisplayMode = .never
    }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // お気に入りの変更を反映するため、表示時にデータを再取得
        resetAnimatedCells()
        try? fetchedResultsController?.performFetch()
        collectionView.reloadData()
        updateEmptyState()
    }
}
