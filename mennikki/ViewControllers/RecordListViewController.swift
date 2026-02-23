//
//  RecordListViewController.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import UIKit
import CoreData
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.mennikki", category: "RecordList")

/// 記録一覧画面
class RecordListViewController: BaseRecordListViewController {

    // MARK: - Properties

    private var selectedRamenTypes: [RamenType] = []
    private var selectedPrefecture: Prefecture?
    private var searchText: String = ""
    private var searchDebounceTimer: Timer?
    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "店名で検索"
        sc.searchBar.tintColor = .appPrimary
        sc.searchBar.searchTextField.backgroundColor = .white
        return sc
    }()

    // MARK: - UI Components

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

    // MARK: - Base Class Configuration

    override var emptyStateIconName: String { "bowl.fill" }
    override var emptyStateTitleText: String { "まだラーメンの記録がありません" }
    override var emptyStateSubTitleText: String { "＋ボタンから最初の記録を追加しましょう！" }

    override func fetchPredicate() -> NSPredicate? {
        var predicates: [NSPredicate] = []

        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "storeName CONTAINS[cd] %@", searchText))
        }
        if !selectedRamenTypes.isEmpty {
            let typeStrings = selectedRamenTypes.map { $0.rawValue }
            predicates.append(NSPredicate(format: "ramenType IN %@", typeStrings))
        }
        if let prefecture = selectedPrefecture {
            predicates.append(NSPredicate(format: "prefecture == %@", prefecture.rawValue))
        }

        guard !predicates.isEmpty else { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    // MARK: - Setup

    override func setupAdditionalUI() {
        setupNavigationBar()

        view.addSubview(fabButton)
        fabButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        fabButton.addTarget(self, action: #selector(fabTouchDown), for: .touchDown)
        fabButton.addTarget(self, action: #selector(fabTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        fabButton.accessibilityLabel = "新しい記録を追加"
        fabButton.accessibilityTraits = .button
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 88, right: 0)
    }

    override func setupAdditionalConstraints() {
        NSLayoutConstraint.activate([
            fabButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            fabButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            fabButton.widthAnchor.constraint(equalToConstant: 56),
            fabButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func setupNavigationBar() {
        title = "記録"
        navigationItem.largeTitleDisplayMode = .never

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

    // MARK: - Refresh

    private func refreshData() {
        resetAnimatedCells()

        if let frc = fetchedResultsController {
            frc.fetchRequest.predicate = fetchPredicate()
            do {
                try frc.performFetch()
            } catch {
                logger.error("Error re-fetching records: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            setupFetchedResultsController()
        }

        collectionView.reloadData()
        updateEmptyState()
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

                self.refreshData()
            }

            alert.addAction(action)
        }

        // クリアアクション
        if !selectedRamenTypes.isEmpty {
            let clearAction = UIAlertAction(title: "フィルターをクリア", style: .destructive) { [weak self] _ in
                self?.selectedRamenTypes.removeAll()
                self?.refreshData()
            }
            alert.addAction(clearAction)
        }

        let cancelAction = UIAlertAction(title: "完了", style: .cancel)
        alert.addAction(cancelAction)

        // iPadでのクラッシュ対策（種類フィルターボタン = rightBarButtonItems[0]）
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?.first
        }

        present(alert, animated: true)
    }

    @objc private func prefectureFilterButtonTapped() {
        // 記録に存在する都道府県のみ抽出（軽量フェッチ）
        let prefStrings = CoreDataManager.shared.fetchDistinctPrefectures()
        let uniquePrefectures = prefStrings
            .compactMap { Prefecture(rawValue: $0) }
            .sorted { Prefecture.allCases.firstIndex(of: $0) ?? 0 < Prefecture.allCases.firstIndex(of: $1) ?? 0 }

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
                self.refreshData()
            }
            alert.addAction(action)
        }

        if selectedPrefecture != nil {
            let clearAction = UIAlertAction(title: "フィルターをクリア", style: .destructive) { [weak self] _ in
                self?.selectedPrefecture = nil
                self?.refreshData()
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

// MARK: - UISearchResultsUpdating

extension RecordListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.refreshData()
        }
    }
}
