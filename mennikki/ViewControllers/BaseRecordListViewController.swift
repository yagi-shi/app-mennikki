//
//  BaseRecordListViewController.swift
//  mennikki
//

import UIKit
import CoreData
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.mennikki", category: "RecordList")

/// RecordListViewController と FavoriteListViewController の共通基底クラス
/// - 2列グリッドの CollectionView
/// - 空状態表示
/// - スタガーアニメーション
/// - NSFetchedResultsController デリゲート
class BaseRecordListViewController: UIViewController {

    // MARK: - Properties

    var fetchedResultsController: NSFetchedResultsController<Record>?
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
        label.font = .appSectionHeader
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

    // MARK: - Subclass Configuration (Override these)

    /// 空状態のアイコン（SF Symbols 名）
    var emptyStateIconName: String { "questionmark.circle" }

    /// 空状態のタイトル
    var emptyStateTitleText: String { "" }

    /// 空状態のサブタイトル
    var emptyStateSubTitleText: String { "" }

    /// FRC 用の NSPredicate（サブクラスでオーバーライド）
    func fetchPredicate() -> NSPredicate? { nil }

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
        setupFetchedResultsController()
        updateEmptyState()
    }

    // MARK: - Setup

    private func setupBaseUI() {
        view.backgroundColor = .appBackground
        view.addSubview(collectionView)
        view.addSubview(emptyStateStackView)

        let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
        emptyStateImageView.image = UIImage(systemName: emptyStateIconName, withConfiguration: config)
        emptyStateLabel.text = emptyStateTitleText
        emptyStateSubLabel.text = emptyStateSubTitleText
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

    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "visitDate", ascending: false)]
        fetchRequest.predicate = fetchPredicate()

        guard let context = CoreDataManager.shared.viewContext else { return }
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController?.delegate = self

        do {
            try fetchedResultsController?.performFetch()
        } catch {
            logger.error("Error fetching records: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Helper Methods

    func updateEmptyState() {
        let isEmpty = fetchedResultsController?.fetchedObjects?.isEmpty ?? true
        emptyStateStackView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }

    func resetAnimatedCells() {
        animatedCells.removeAll()
    }
}

// MARK: - UICollectionViewDataSource

extension BaseRecordListViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController?.fetchedObjects?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: RecordCell.reuseIdentifier,
            for: indexPath
        ) as? RecordCell else {
            return UICollectionViewCell()
        }

        if let record = fetchedResultsController?.object(at: indexPath) {
            cell.configure(with: record)
        }

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
        guard let record = fetchedResultsController?.object(at: indexPath) else { return }
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
        let cellHeight = cellWidth * 1.0
        return CGSize(width: cellWidth, height: cellHeight)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension BaseRecordListViewController: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        animatedCells.removeAll()
        collectionView.reloadData()
        updateEmptyState()
    }
}
