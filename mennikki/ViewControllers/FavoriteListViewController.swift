//
//  FavoriteListViewController.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import UIKit

/// お気に入り一覧画面
class FavoriteListViewController: BaseRecordListViewController {

    // MARK: - Init

    init() {
        super.init(scope: .favoritesOnly)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    override func setupAdditionalUI() {
        title = "お気に入り"
        navigationItem.largeTitleDisplayMode = .never
    }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // お気に入りの変更を反映するため、表示時にデータを再取得する。
        // observeChanges の描き直しは次の順番になり、表示した直後に古い一覧が一瞬見えることがあるので、ここですぐ描き直す
        viewModel.reload()
        renderRecords()
    }
}
