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
    private let searchBarHeight: CGFloat = 52
    private var searchFieldTrailingToWrapper: NSLayoutConstraint!
    private var searchFieldTrailingToCancel: NSLayoutConstraint!
    private let searchBarWrapperView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let searchBarSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = .appBorder
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var searchTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "店名で検索"
        tf.tintColor = .appPrimary
        tf.backgroundColor = UIColor(white: 0.95, alpha: 1)
        tf.layer.cornerRadius = 10
        tf.font = .systemFont(ofSize: 16)
        tf.clearButtonMode = .whileEditing
        tf.returnKeyType = .search

        // 検索アイコン
        let iconView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iconView.tintColor = .appSecondaryText
        iconView.contentMode = .scaleAspectFit
        iconView.frame = CGRect(x: 0, y: 0, width: 28, height: 20)
        let leftContainer = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 20))
        iconView.frame.origin.x = 10
        leftContainer.addSubview(iconView)
        tf.leftView = leftContainer
        tf.leftViewMode = .always

        tf.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        tf.delegate = self
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.accessibilityLabel = "店名で検索"
        return tf
    }()
    private lazy var searchCancelButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .appSecondaryText
        button.addTarget(self, action: #selector(searchCancelTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.accessibilityLabel = "検索をクリア"
        return button
    }()

    // MARK: - UI Components

    // Floating Action Button（3D押し込みスタイル）
    private let fabButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .appPrimary
        button.layer.cornerRadius = 28
        // 3D ハードシャドウ（ぼかしなし、暗めの赤を底辺に）
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchTextField.resignFirstResponder()
    }

    // MARK: - Setup

    override func setupAdditionalUI() {
        setupNavigationBar()

        additionalSafeAreaInsets.top = searchBarHeight
        view.addSubview(searchBarWrapperView)
        searchBarWrapperView.addSubview(searchTextField)
        searchBarWrapperView.addSubview(searchCancelButton)
        searchBarWrapperView.addSubview(searchBarSeparator)

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
            searchBarWrapperView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -searchBarHeight),
            searchBarWrapperView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBarWrapperView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBarWrapperView.heightAnchor.constraint(equalToConstant: searchBarHeight),

            searchTextField.leadingAnchor.constraint(equalTo: searchBarWrapperView.leadingAnchor, constant: 16),
            searchTextField.centerYAnchor.constraint(equalTo: searchBarWrapperView.centerYAnchor),
            searchTextField.heightAnchor.constraint(equalToConstant: 36),

            searchCancelButton.trailingAnchor.constraint(equalTo: searchBarWrapperView.trailingAnchor, constant: -16),
            searchCancelButton.centerYAnchor.constraint(equalTo: searchBarWrapperView.centerYAnchor),

            searchBarSeparator.leadingAnchor.constraint(equalTo: searchBarWrapperView.leadingAnchor),
            searchBarSeparator.trailingAnchor.constraint(equalTo: searchBarWrapperView.trailingAnchor),
            searchBarSeparator.bottomAnchor.constraint(equalTo: searchBarWrapperView.bottomAnchor),
            searchBarSeparator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

            fabButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            fabButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            fabButton.widthAnchor.constraint(equalToConstant: 56),
            fabButton.heightAnchor.constraint(equalToConstant: 56)
        ])

        // デフォルト: テキストフィールドは右端まで広がる
        searchFieldTrailingToWrapper = searchTextField.trailingAnchor.constraint(equalTo: searchBarWrapperView.trailingAnchor, constant: -16)
        searchFieldTrailingToCancel = searchTextField.trailingAnchor.constraint(equalTo: searchCancelButton.leadingAnchor, constant: -8)
        searchFieldTrailingToWrapper.isActive = true
    }

    private func setupNavigationBar() {
        title = "記録"
        navigationItem.largeTitleDisplayMode = .never

        // 検索バーWrapperViewと一体化して見せるためナビバー下端のボーダーを消す
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [
            .font: UIFont.appNavigationTitle,
            .foregroundColor: UIColor.appText
        ]
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance

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

    // MARK: - Search Actions

    @objc private func searchTextChanged() {
        searchText = searchTextField.text ?? ""
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.refreshData()
        }
    }

    @objc private func searchCancelTapped() {
        searchTextField.text = ""
        searchTextField.resignFirstResponder()
        searchText = ""
        setCancelButtonVisible(false)
        refreshData()
    }

    private func setCancelButtonVisible(_ visible: Bool) {
        searchFieldTrailingToWrapper.isActive = !visible
        searchFieldTrailingToCancel.isActive = visible
        UIView.animate(withDuration: 0.25) {
            self.searchCancelButton.isHidden = !visible
            self.searchCancelButton.alpha = visible ? 1 : 0
            self.searchBarWrapperView.layoutIfNeeded()
        }
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

// MARK: - UITextFieldDelegate

extension RecordListViewController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        setCancelButtonVisible(true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.isEmpty ?? true {
            setCancelButtonVisible(false)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
