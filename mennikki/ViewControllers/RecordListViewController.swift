//
//  RecordListViewController.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import UIKit
import CoreData

/// 記録一覧画面
class RecordListViewController: UIViewController {

    // MARK: - Properties

    private var fetchedResultsController: NSFetchedResultsController<Record>!
    private var searchController: UISearchController!
    private var selectedRamenTypes: [RamenType] = []
    private var searchText: String = ""

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
        imageView.image = UIImage(systemName: "bowl.fill", withConfiguration: config)
        imageView.tintColor = .appSecondaryText
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "まだラーメンの記録がありません"
        label.font = .appSectionHeader
        label.textColor = .appText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let emptyStateSubLabel: UILabel = {
        let label = UILabel()
        label.text = "＋ボタンから最初の記録を追加しましょう！"
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

        // 開発用: 初回起動時にテストデータを追加
        #if DEBUG
        if fetchedResultsController.fetchedObjects?.isEmpty == true {
            createMultipleTestRecords()
        }
        #endif
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .appBackground
        view.addSubview(collectionView)
        view.addSubview(emptyStateStackView)
    }

    private func setupNavigationBar() {
        title = "記録"

        // UISearchControllerの設定
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "店名やラーメンの種類で検索"
        searchController.searchBar.tintColor = .appPrimary
        searchController.searchBar.searchTextField.backgroundColor = .white

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        // フィルターボタンと＋ボタンを右上に配置
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain,
            target: self,
            action: #selector(filterButtonTapped)
        )

        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped)
        )

        navigationItem.rightBarButtonItems = [addButton, filterButton]
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

        // 検索条件を設定
        updateSearchPredicate(for: fetchRequest)

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
            print("Error fetching records: \(error)")
        }
    }

    private func updateSearchPredicate(for fetchRequest: NSFetchRequest<Record>) {
        var predicates: [NSPredicate] = []

        // 店名検索
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "storeName CONTAINS[cd] %@", searchText))
        }

        // ラーメン種類フィルター
        if !selectedRamenTypes.isEmpty {
            let typeStrings = selectedRamenTypes.map { $0.rawValue }
            predicates.append(NSPredicate(format: "ramenType IN %@", typeStrings))
        }

        // 複数の条件を結合
        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        } else {
            fetchRequest.predicate = nil
        }
    }

    private func refreshFetchedResultsController() {
        setupFetchedResultsController()
        collectionView.reloadData()
        updateEmptyState()
    }

    // MARK: - Helper Methods

    private func updateEmptyState() {
        let isEmpty = fetchedResultsController.fetchedObjects?.isEmpty ?? true
        emptyStateStackView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }

    // MARK: - Actions

    @objc private func addButtonTapped() {
        let addRecordVC = AddRecordViewController()
        let navController = UINavigationController(rootViewController: addRecordVC)
        navController.navigationBar.applyAppStyle()
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    @objc private func filterButtonTapped() {
        let alert = UIAlertController(title: "ラーメンの種類でフィルター", message: "選択してください", preferredStyle: .actionSheet)

        for type in RamenType.allCases {
            let isSelected = selectedRamenTypes.contains(type)
            let title = isSelected ? "✓ \(type.rawValue)" : type.rawValue

            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self = self else { return }

                if let index = self.selectedRamenTypes.firstIndex(of: type) {
                    self.selectedRamenTypes.remove(at: index)
                } else {
                    self.selectedRamenTypes.append(type)
                }

                self.refreshFetchedResultsController()
            }

            alert.addAction(action)
        }

        // クリアアクション
        if !selectedRamenTypes.isEmpty {
            let clearAction = UIAlertAction(title: "フィルターをクリア", style: .destructive) { [weak self] _ in
                self?.selectedRamenTypes.removeAll()
                self?.refreshFetchedResultsController()
            }
            alert.addAction(clearAction)
        }

        let cancelAction = UIAlertAction(title: "完了", style: .cancel)
        alert.addAction(cancelAction)

        // iPadでのクラッシュ対策
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?.last
        }

        present(alert, animated: true)
    }

    // MARK: - Test Helper

    private func createTestRecord() {
        let randomTypes: [RamenType] = [.shoyu, .miso, .shio, .tonkotsu, .tantan, .jiro]
        let randomType = randomTypes.randomElement() ?? .shoyu

        CoreDataManager.shared.createRecord(
            storeName: "テストラーメン店 \(Int.random(in: 1...100))",
            ramenType: randomType,
            visitDate: Date(),
            cost: Int16.random(in: 500...1500),
            rating: Int16.random(in: 1...5),
            comment: "美味しかったです！",
            isFavorite: Bool.random()
        )
    }

    private func createMultipleTestRecords() {
        let stores = [
            ("一風堂", RamenType.tonkotsu, true),
            ("天下一品", RamenType.shoyu, false),
            ("蒙古タンメン中本", RamenType.tantan, true),
            ("山岡家", RamenType.miso, false),
            ("二郎系ラーメン", RamenType.jiro, true),
            ("麺屋武蔵", RamenType.shio, false)
        ]

        for (index, store) in stores.enumerated() {
            let daysAgo = TimeInterval(-86400 * index) // 1日ずつ過去
            let visitDate = Date(timeIntervalSinceNow: daysAgo)

            CoreDataManager.shared.createRecord(
                storeName: store.0,
                ramenType: store.1,
                visitDate: visitDate,
                cost: Int16.random(in: 800...1500),
                rating: Int16.random(in: 3...5),
                comment: "とても美味しかったです！",
                isFavorite: store.2
            )
        }
    }
}

// MARK: - UICollectionViewDataSource

extension RecordListViewController: UICollectionViewDataSource {

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

extension RecordListViewController: UICollectionViewDelegate {

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

extension RecordListViewController: UICollectionViewDelegateFlowLayout {

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

extension RecordListViewController: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.reloadData()
        updateEmptyState()
    }
}

// MARK: - UISearchResultsUpdating

extension RecordListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
        refreshFetchedResultsController()
    }
}
