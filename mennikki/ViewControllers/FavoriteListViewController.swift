//
//  FavoriteListViewController.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import UIKit
import CoreData

/// お気に入り一覧画面
class FavoriteListViewController: UIViewController {

    // MARK: - Properties

    private var fetchedResultsController: NSFetchedResultsController<Record>!

    // MARK: - UI Components

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

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
        let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
        imageView.image = UIImage(systemName: "heart.circle", withConfiguration: config)
        imageView.tintColor = .appSecondaryText
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "お気に入りがありません"
        label.font = .appSectionHeader
        label.textColor = .appText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let emptyStateSubLabel: UILabel = {
        let label = UILabel()
        label.text = "気に入ったラーメンを記録してみましょう！"
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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupNavigationBar()
        setupConstraints()
        setupFetchedResultsController()
        updateEmptyState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // お気に入りの変更を反映するため、表示時にデータを再取得
        try? fetchedResultsController.performFetch()
        collectionView.reloadData()
        updateEmptyState()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .appBackground
        view.addSubview(collectionView)
        view.addSubview(emptyStateStackView)
    }

    private func setupNavigationBar() {
        title = "お気に入り"
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Collection View
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Empty State Stack View
            emptyStateStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            emptyStateStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Record> = Record.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "visitDate", ascending: false)]

        // お気に入りのみをフィルタリング
        fetchRequest.predicate = NSPredicate(format: "isFavorite == true")

        let context = CoreDataManager.shared.viewContext
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error fetching favorite records: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func updateEmptyState() {
        let isEmpty = fetchedResultsController.fetchedObjects?.isEmpty ?? true
        emptyStateStackView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }
}

// MARK: - UICollectionViewDataSource

extension FavoriteListViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: RecordCell.reuseIdentifier,
            for: indexPath
        ) as? RecordCell else {
            return UICollectionViewCell()
        }

        let record = fetchedResultsController.object(at: indexPath)
        cell.configure(with: record)

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension FavoriteListViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // セルタップアニメーション
        if let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.1, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    cell.transform = .identity
                }
            }
        }

        // 詳細画面へ遷移
        let record = fetchedResultsController.object(at: indexPath)
        let detailVC = RecordDetailViewController(record: record)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension FavoriteListViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 12
        let margins: CGFloat = 16 * 2
        let availableWidth = collectionView.bounds.width - margins - spacing
        let cellWidth = availableWidth / 2

        // アスペクト比 1:1.3
        let cellHeight = cellWidth * 1.3

        return CGSize(width: cellWidth, height: cellHeight)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension FavoriteListViewController: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.reloadData()
        updateEmptyState()
    }
}
