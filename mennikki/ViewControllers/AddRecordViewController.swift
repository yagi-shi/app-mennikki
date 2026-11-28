//
//  AddRecordViewController.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import UIKit
import SwiftUI
import StoreKit

/// 新規記録・編集画面（SwiftUI の AddRecordView）を、UIKit の画面から全画面で開くための入れ物。
/// #27 の移行中だけのつなぎで、画面を閉じることにかかわる次のことだけを受け持つ。
/// 5 つ目の子 issue で、ナビゲーションを SwiftUI にするときに消す
/// - ✕ を押したら、保存せずに閉じる
/// - 保存したら閉じ、閉じたあとに、ストア評価を頼む（頼むかどうかは AddRecordViewModel が決める）
///
/// ナビゲーションバー（タイトルと ✕）は AddRecordView の中にあるので、UINavigationController には入れずに開く
final class AddRecordViewController: UIHostingController<AddRecordView> {

    // MARK: - Init

    init(recordToEdit: Record? = nil) {
        let viewModel = AddRecordViewModel(recordToEdit: recordToEdit)
        super.init(rootView: AddRecordView(viewModel: viewModel, onCancel: {}, onSaved: { _ in }))
        // ボタンを押したときの処理は self を使うので、super.init のあとに入れ直す
        rootView = AddRecordView(
            viewModel: viewModel,
            onCancel: { [weak self] in self?.dismiss(animated: true) },
            onSaved: { [weak self] shouldRequestReview in self?.close(requestingReview: shouldRequestReview) }
        )
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Navigation

    /// 画面を閉じる。新規登録で記録の総数が節目になったときは、閉じたあとにストア評価を頼む（表示の頻度は iOS が決める）
    private func close(requestingReview shouldRequestReview: Bool) {
        // 閉じると画面がウインドウから外れるので、先にシーンを取っておく
        let scene = view.window?.windowScene
        dismiss(animated: true) {
            if shouldRequestReview, let scene {
                AppStore.requestReview(in: scene)
            }
        }
    }
}
