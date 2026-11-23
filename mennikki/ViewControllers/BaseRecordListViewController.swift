//
//  BaseRecordListViewController.swift
//  mennikki
//

import UIKit

/// RecordListViewController と FavoriteListViewController の共通基底クラス
/// - 2列グリッドの CollectionView
/// - 空状態表示
/// - スタガーアニメーション
///
/// 記録の取り出しと絞り込みは RecordListViewModel が受け持つ。この画面は、表示と画面の移動だけを行う
class BaseRecordListViewController: UIViewController {

    // MARK: - Properties

    let viewModel: RecordListViewModel
    /// collectionView に出している記録。ViewModel の記録が先に変わっても、collectionView の件数とずれないように、
    /// 描き直したときの写しを使う
    private var displayedRecords: [Record] = []
    private var animatedCells = Set<IndexPath>()

    // MARK: - UI Components

    private(set) lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .appBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(RecordCell.self, forCellWithReuseIdentifier: RecordCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private let emptyStateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .appSecondaryText
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.font = .appEmptyStateTitle
        label.textColor = .appText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let emptyStateSubLabel: UILabel = {
        let label = UILabel()
        label.font = .appBody
        label.textColor = .appSecondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var emptyStateStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            emptyStateImageView,
            emptyStateLabel,
            emptyStateSubLabel
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: - Init

    init(scope: RecordListViewModel.Scope) {
        self.viewModel = RecordListViewModel(scope: scope)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Subclass Configuration (Override these)

    /// サブクラスで追加の制約やビューを設定するフック
    func setupAdditionalUI() {}

    /// サブクラスで追加の制約を設定するフック
    func setupAdditionalConstraints() {}

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBaseUI()
        setupBaseConstraints()
        setupAdditionalUI()
        setupAdditionalConstraints()

        viewModel.load()
        // 記録が変わるたびに描き直す（記録の追加や削除、絞り込みの変更）
        observeChanges { [weak self] in self?.renderRecords() }
    }

    // MARK: - Setup

    private func setupBaseUI() {
        view.backgroundColor = .appBackground
        view.addSubview(collectionView)
        view.addSubview(emptyStateStackView)
    }

    private func setupBaseConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            emptyStateStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    // MARK: - Rendering

    /// ViewModel の記録で、一覧と空の表示を描き直す
    func renderRecords() {
        displayedRecords = viewModel.records
        animatedCells.removeAll()
        collectionView.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        let isEmpty = displayedRecords.isEmpty
        emptyStateStackView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
        guard isEmpty else { return }

        // 絞り込みの有無で文言が変わるため、空になるたびに設定し直す
        let content = Self.emptyStateContent(for: viewModel.emptyState)
        let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
        emptyStateImageView.image = UIImage(systemName: content.iconName, withConfiguration: config)
        emptyStateLabel.text = content.title
        emptyStateSubLabel.text = content.subtitle
    }

    /// 空のときの表示の種類ごとの、アイコン（SF Symbols 名）と文言
    private static func emptyStateContent(
        for emptyState: RecordListViewModel.EmptyState
    ) -> (iconName: String, title: String, subtitle: String) {
        switch emptyState {
        case .noRecords:
            return ("bowl.fill", "まだラーメンの記録がありません", "＋ボタンから最初の記録を追加しましょう！")
        case .noMatchingRecords:
            return ("bowl.fill", "条件に合う記録がありません", "検索やフィルターを解除すると、すべての記録が表示されます")
        case .noFavorites:
            return ("heart.circle", "お気に入りがありません", "気に入ったラーメンを記録してみましょう！")
        }
    }
}

// MARK: - UICollectionViewDataSource

extension BaseRecordListViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedRecords.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: RecordCell.reuseIdentifier,
            for: indexPath
        ) as? RecordCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: displayedRecords[indexPath.item])

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension BaseRecordListViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard !animatedCells.contains(indexPath) else { return }
        animatedCells.insert(indexPath)
        let delay = Double(indexPath.item % 8) * 0.05
        cell.fadeInWithSlide(delay: delay)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let record = displayedRecords[indexPath.item]
        let detailVC = RecordDetailViewController(record: record)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension BaseRecordListViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 12
        let margins: CGFloat = 10 * 2
        let availableWidth = collectionView.bounds.width - margins - spacing
        let cellWidth = availableWidth / 2
        // 店名と種類タグ・星が切れない高さにする
        let cellHeight = RecordCell.height(forWidth: cellWidth)
        return CGSize(width: cellWidth, height: cellHeight)
    }
}
