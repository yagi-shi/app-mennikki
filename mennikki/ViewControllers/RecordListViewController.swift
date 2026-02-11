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
    private var selectedPrefecture: Prefecture?
    private var searchText: String = ""
    private var animatedCells = Set<IndexPath>()

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

    // Floating Action Button（Duolingo 3D押し込みスタイル）
    private let fabButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .appPrimary
        button.layer.cornerRadius = 28
        // Duolingo 3D: ハードシャドウ（ぼかしなし、暗めの赤を底辺に）
        button.layer.shadowColor = UIColor(red: 180/255, green: 40/255, blue: 40/255, alpha: 1).cgColor
        button.layer.shadowOpacity = 1.0
        button.layer.shadowRadius = 0
        button.layer.shadowOffset = CGSize(width: 0, height: 5)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .appBackground
        view.addSubview(collectionView)
        view.addSubview(emptyStateStackView)
        view.addSubview(fabButton)
        fabButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        fabButton.addTarget(self, action: #selector(fabTouchDown), for: .touchDown)
        fabButton.addTarget(self, action: #selector(fabTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 88, right: 0)
    }

    private func setupNavigationBar() {
        title = "記録"
        navigationItem.largeTitleDisplayMode = .always

        // UISearchControllerの設定
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "店名で検索"
        searchController.searchBar.tintColor = .appPrimary
        searchController.searchBar.searchTextField.backgroundColor = .white

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true

        // 種類フィルター
        let typeFilterButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain,
            target: self,
            action: #selector(filterButtonTapped)
        )
        // 都道府県フィルター
        let prefFilterButton = UIBarButtonItem(
            image: UIImage(systemName: "mappin.circle"),
            style: .plain,
            target: self,
            action: #selector(prefectureFilterButtonTapped)
        )
        navigationItem.rightBarButtonItems = [typeFilterButton, prefFilterButton]
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
            emptyStateStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            // FAB
            fabButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            fabButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            fabButton.widthAnchor.constraint(equalToConstant: 56),
            fabButton.heightAnchor.constraint(equalToConstant: 56)
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

        // 都道府県フィルター
        if let prefecture = selectedPrefecture {
            predicates.append(NSPredicate(format: "prefecture == %@", prefecture.rawValue))
        }

        // 複数の条件を結合
        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        } else {
            fetchRequest.predicate = nil
        }
    }

    private func refreshFetchedResultsController() {
        animatedCells.removeAll()
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

    @objc private func fabTouchDown() {
        UIView.animate(withDuration: 0.08, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.fabButton.transform = CGAffineTransform(translationX: 0, y: 5)
            self.fabButton.layer.shadowOffset = .zero
        }
    }

    @objc private func fabTouchUp() {
        UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8) {
            self.fabButton.transform = .identity
            self.fabButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        }
    }

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

    @objc private func prefectureFilterButtonTapped() {
        // 記録に存在する都道府県のみ抽出
        let allRecords = CoreDataManager.shared.fetchAllRecords()
        let uniquePrefectures = Array(
            Set(allRecords.compactMap { $0.prefecture })
        )
        .compactMap { Prefecture(rawValue: $0) }
        .sorted { Prefecture.allCases.firstIndex(of: $0)! < Prefecture.allCases.firstIndex(of: $1)! }

        guard !uniquePrefectures.isEmpty else {
            let alert = UIAlertController(
                title: "都道府県フィルター",
                message: "都道府県が登録された記録がありません",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let alert = UIAlertController(title: "都道府県でフィルター", message: "選択してください", preferredStyle: .actionSheet)

        for prefecture in uniquePrefectures {
            let isSelected = selectedPrefecture == prefecture
            let title = isSelected ? "✓ \(prefecture.rawValue)" : prefecture.rawValue

            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self = self else { return }
                if self.selectedPrefecture == prefecture {
                    self.selectedPrefecture = nil
                } else {
                    self.selectedPrefecture = prefecture
                }
                self.refreshFetchedResultsController()
            }
            alert.addAction(action)
        }

        if selectedPrefecture != nil {
            let clearAction = UIAlertAction(title: "フィルターをクリア", style: .destructive) { [weak self] _ in
                self?.selectedPrefecture = nil
                self?.refreshFetchedResultsController()
            }
            alert.addAction(clearAction)
        }

        let cancelAction = UIAlertAction(title: "完了", style: .cancel)
        alert.addAction(cancelAction)

        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?.last
        }

        present(alert, animated: true)
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

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard !animatedCells.contains(indexPath) else { return }
        animatedCells.insert(indexPath)
        let delay = Double(indexPath.item % 8) * 0.05
        cell.fadeInWithSlide(delay: delay)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
        animatedCells.removeAll()
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
