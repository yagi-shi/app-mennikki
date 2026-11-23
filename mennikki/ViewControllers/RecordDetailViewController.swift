//
//  RecordDetailViewController.swift
//  mennikki
//

import UIKit
import SwiftUI

/// 記録詳細画面（SwiftUI の RecordDetailView）を、UIKit のナビゲーションの中で出すための入れ物。
/// #27 の移行中だけのつなぎで、画面の移動にかかわる次のことだけを受け持つ。
/// 5 つ目の子 issue で、ナビゲーションを SwiftUI にするときに消す
/// - 編集画面（UIKit）を全画面で開く
/// - 画面が出るたびに記録を読み直す（編集画面から戻ったときに、変わった内容を出すため）
/// - 記録が削除されていたら、一覧に戻る
final class RecordDetailViewController: UIHostingController<RecordDetailView> {

    // MARK: - Properties

    private let viewModel: RecordDetailViewModel

    // MARK: - Init

    init(record: Record) {
        let viewModel = RecordDetailViewModel(recordID: record.objectID)
        viewModel.reload()
        self.viewModel = viewModel
        super.init(rootView: RecordDetailView(viewModel: viewModel, onEdit: {}, onDelete: {}))
        // ボタンを押したときの処理は self を使うので、super.init のあとに入れ直す
        rootView = RecordDetailView(
            viewModel: viewModel,
            onEdit: { [weak self] in self?.showEditScreen() },
            onDelete: { [weak self] in self?.close() }
        )
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 編集画面から戻ったときに、変わった内容を出す
        viewModel.reload()
        if viewModel.shouldClose {
            close()
        }
    }

    // MARK: - Navigation

    private func showEditScreen() {
        guard let record = viewModel.record else { return }
        let editVC = AddRecordViewController(recordToEdit: record)
        let nav = UINavigationController(rootViewController: editVC)
        nav.navigationBar.applyAppStyle()
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func close() {
        navigationController?.popViewController(animated: true)
    }
}
