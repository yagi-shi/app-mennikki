//
//  RecordListViewController.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import UIKit

/// 記録一覧画面
class RecordListViewController: BaseRecordListViewController {

    // MARK: - Properties

    // フィルターボタン（適用中かどうかで見た目を切り替える）
    private var typeFilterButton: UIBarButtonItem?
    private var prefFilterButton: UIBarButtonItem?

    private var searchDebounceTimer: Timer?
    /// 検索欄の最低の高さ（文字が大きいときは、文字に合わせて高くする）
    private static let searchFieldMinHeight: CGFloat = 36
    /// 検索欄の、文字の上下の余白
    private static let searchFieldTextPadding: CGFloat = 8
    /// 検索バーの、検索欄の上下の余白
    private static let searchBarPadding: CGFloat = 8
    private lazy var searchFieldHeight: CGFloat = max(
        Self.searchFieldMinHeight,
        ceil(UIFont.appSearchField.lineHeight) + Self.searchFieldTextPadding * 2
    )
    private lazy var searchBarHeight: CGFloat = searchFieldHeight + Self.searchBarPadding * 2
    /// 検索欄の背景色（外のボタンの丸の背景にも使う）
    private static let searchFieldBackgroundColor = UIColor(white: 0.95, alpha: 1)
    /// 外のボタンの、丸の外側の余白。丸は検索欄と同じ高さにし、押せる範囲は丸より広くする（標準の文字サイズで 44pt）
    private static let searchCancelButtonHitPadding: CGFloat = 4
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
        tf.backgroundColor = Self.searchFieldBackgroundColor
        tf.layer.cornerRadius = 10
        tf.font = .appSearchField
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
        // 中の消去ボタン（塗りつぶしの丸に ×）と見分けられるよう、丸い背景に × の記号を、押せるものの色（フィルターのアイコンと同じ）で表示する
        let padding = Self.searchCancelButtonHitPadding
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "xmark")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(font: .appSearchField)
            .applying(UIImage.SymbolConfiguration(weight: .semibold))
        config.baseForegroundColor = .appPrimary
        config.background.backgroundColor = Self.searchFieldBackgroundColor
        config.background.backgroundInsets = NSDirectionalEdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding)
        config.background.cornerRadius = searchFieldHeight / 2
        config.cornerStyle = .fixed

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(searchCancelTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.accessibilityLabel = "検索を終了"
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

    // MARK: - Init

    init() {
        super.init(scope: .allRecords)
    }

    required init?(coder: NSCoder) { fatalError() }

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
            searchTextField.heightAnchor.constraint(equalToConstant: searchFieldHeight),

            // 丸の右端を、検索欄の左端と同じく画面端から 16pt の位置にそろえる
            searchCancelButton.trailingAnchor.constraint(equalTo: searchBarWrapperView.trailingAnchor, constant: -(16 - Self.searchCancelButtonHitPadding)),
            searchCancelButton.centerYAnchor.constraint(equalTo: searchBarWrapperView.centerYAnchor),
            searchCancelButton.widthAnchor.constraint(equalToConstant: searchFieldHeight + Self.searchCancelButtonHitPadding * 2),
            searchCancelButton.heightAnchor.constraint(equalToConstant: searchFieldHeight + Self.searchCancelButtonHitPadding * 2),

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
        // 検索欄と丸の間を 8pt あける
        searchFieldTrailingToCancel = searchTextField.trailingAnchor.constraint(equalTo: searchCancelButton.leadingAnchor, constant: -(8 - Self.searchCancelButtonHitPadding))
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
        typeFilterButton.accessibilityLabel = "種類でフィルター"
        // 都道府県フィルター
        let prefFilterButton = UIBarButtonItem(
            image: UIImage(systemName: "mappin.circle"),
            style: .plain,
            target: self,
            action: #selector(prefectureFilterButtonTapped)
        )
        prefFilterButton.accessibilityLabel = "都道府県でフィルター"
        navigationItem.rightBarButtonItems = [typeFilterButton, prefFilterButton]
        self.typeFilterButton = typeFilterButton
        self.prefFilterButton = prefFilterButton
        // 絞り込みの条件が変わるたびに、フィルターのボタンの見た目を描き直す
        observeChanges { [weak self] in self?.updateFilterButtons() }
    }

    /// 適用中のフィルターのアイコンを、塗りつぶしの赤色にする
    private func updateFilterButtons() {
        let filter = viewModel.filter
        applyFilterAppearance(to: typeFilterButton, symbolName: "line.3.horizontal.decrease.circle", isActive: filter.isRamenTypeFilterActive)
        applyFilterAppearance(to: prefFilterButton, symbolName: "mappin.circle", isActive: filter.isPrefectureFilterActive)
    }

    private func applyFilterAppearance(to button: UIBarButtonItem?, symbolName: String, isActive: Bool) {
        button?.image = UIImage(systemName: isActive ? "\(symbolName).fill" : symbolName)
        button?.tintColor = isActive ? .appPrimary : nil
        button?.accessibilityValue = isActive ? "適用中" : nil
    }

    // MARK: - Search Actions

    @objc private func searchTextChanged() {
        // 打ち終わるまで 0.3 秒待ってから絞り込む（1 文字ごとに取り出し直さないため）
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.viewModel.setSearchText(self.searchTextField.text ?? "")
        }
    }

    @objc private func searchCancelTapped() {
        searchTextField.text = ""
        searchTextField.resignFirstResponder()
        setCancelButtonVisible(false)
        viewModel.setSearchText("")
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
        // 記録に存在する種類と、選んでいる種類（記録がなくなったものを含む）だけを表示（軽量フェッチ）
        let options = viewModel.ramenTypeOptions()

        guard !options.isEmpty else {
            let alert = UIAlertController(
                title: "ラーメンの種類でフィルター",
                message: "記録がありません",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let alert = UIAlertController(title: "ラーメンの種類でフィルター", message: "選択してください", preferredStyle: .actionSheet)

        for type in options {
            let isSelected = viewModel.filter.selectedRamenTypes.contains(type)
            let title = isSelected ? "✓ \(type.rawValue)" : type.rawValue

            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.viewModel.toggleRamenType(type)
            }

            alert.addAction(action)
        }

        // クリアアクション
        if viewModel.filter.isRamenTypeFilterActive {
            let clearAction = UIAlertAction(title: "フィルターをクリア", style: .destructive) { [weak self] _ in
                self?.viewModel.clearRamenTypes()
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
        let uniquePrefectures = viewModel.prefectureOptions()

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
            let isSelected = viewModel.filter.selectedPrefecture == prefecture
            let title = isSelected ? "✓ \(prefecture.rawValue)" : prefecture.rawValue

            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.viewModel.togglePrefecture(prefecture)
            }
            alert.addAction(action)
        }

        if viewModel.filter.isPrefectureFilterActive {
            let clearAction = UIAlertAction(title: "フィルターをクリア", style: .destructive) { [weak self] _ in
                self?.viewModel.clearPrefecture()
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
