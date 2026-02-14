//
//  RecordDetailViewController.swift
//  mennikki
//

import UIKit
import CoreData
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.mennikki", category: "RecordDetail")

/// 記録詳細画面（Duolingo風クリーンレイアウト）
/// - 通常の白いナビバー（透明overlay廃止）
/// - 上部: 種類カラー or 写真（固定高さ220pt）
/// - 下部: 白背景の情報エリア
class RecordDetailViewController: UIViewController {

    // MARK: - Properties

    private static let visitDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy年M月d日（E）"
        fmt.locale = Locale(identifier: "ja_JP")
        return fmt
    }()

    private let recordID: NSManagedObjectID
    private var record: Record?
    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        let heartConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        button.setImage(UIImage(systemName: "heart", withConfiguration: heartConfig), for: .normal)
        button.tintColor = .appSecondaryText
        button.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - UI: スクロール全体

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - UI: ヘッダーエリア（写真 or カラー背景）

    private let headerView: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let headerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let headerPlaceholderIcon: UIImageView = {
        let iv = UIImageView()
        let cfg = UIImage.SymbolConfiguration(pointSize: 60, weight: .thin)
        iv.image = UIImage(systemName: "fork.knife", withConfiguration: cfg)
        iv.tintColor = UIColor.white.withAlphaComponent(0.6)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - UI: 情報エリア（白背景）

    private let infoView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // 店名
    private let storeNameLabel: UILabel = {
        let l = UILabel()
        l.font = .appDetailTitle
        l.textColor = .appText
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // 種類タグ
    private let typeTagContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 11
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let typeTagLabel: UILabel = {
        let l = UILabel()
        l.font = .appTag
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // 星評価エリア
    private let starRatingView: StarRatingView = {
        let v = StarRatingView()
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let starRatingContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Duolingo風区切り線
    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = .appBorder
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }

    // 情報カードスタック（訪問日・費用）
    private let infoStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // コメントエリア
    private let commentContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .appBackground
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let commentLabel: UILabel = {
        let l = UILabel()
        l.font = .appBody
        l.textColor = .appText
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init

    init(record: Record) {
        self.recordID = record.objectID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let fetched = CoreDataManager.shared.viewContext?.object(with: recordID) as? Record else {
            navigationController?.popViewController(animated: true)
            return
        }
        record = fetched
        setupUI()
        setupConstraints()
        setupNavigationBar()
        configureWithRecord()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 編集・削除後の再表示に対応
        guard let refreshed = try? CoreDataManager.shared.viewContext?.existingObject(with: recordID) as? Record else {
            navigationController?.popViewController(animated: true)
            return
        }
        record = refreshed
        // infoStack の既存行をクリアしてから再描画
        infoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        configureWithRecord()
        updateFavoriteButton()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerView)
        headerView.addSubview(headerImageView)
        headerView.addSubview(headerPlaceholderIcon)

        contentView.addSubview(infoView)
        infoView.addSubview(storeNameLabel)
        infoView.addSubview(typeTagContainer)
        typeTagContainer.addSubview(typeTagLabel)
        infoView.addSubview(starRatingContainer)
        starRatingContainer.addSubview(starRatingView)
        infoView.addSubview(infoStack)
        infoView.addSubview(commentContainer)
        commentContainer.addSubview(commentLabel)
    }

    private func setupNavigationBar() {
        navigationItem.title = ""
        navigationItem.largeTitleDisplayMode = .never

        let favoriteBarButton = UIBarButtonItem(customView: favoriteButton)

        let editButton = UIBarButtonItem(
            image: UIImage(systemName: "pencil"),
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )
        editButton.tintColor = .appSecondaryText

        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(deleteButtonTapped)
        )
        deleteButton.tintColor = .appPrimary
        deleteButton.accessibilityLabel = "記録を削除"

        navigationItem.rightBarButtonItems = [editButton, favoriteBarButton, deleteButton]

        updateFavoriteButton()
    }

    private func updateFavoriteButton() {
        guard let record else { return }
        let isFav = record.isFavorite
        let heartConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        favoriteButton.setImage(UIImage(systemName: isFav ? "heart.fill" : "heart", withConfiguration: heartConfig), for: .normal)
        favoriteButton.tintColor = isFav ? .appPrimary : .appSecondaryText
        favoriteButton.accessibilityLabel = isFav ? "お気に入り解除" : "お気に入り登録"
    }

    private func setupConstraints() {
        let headerHeight: CGFloat = 220

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // ヘッダー
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: headerHeight),

            headerImageView.topAnchor.constraint(equalTo: headerView.topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerImageView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),

            headerPlaceholderIcon.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            headerPlaceholderIcon.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            headerPlaceholderIcon.widthAnchor.constraint(equalToConstant: 72),
            headerPlaceholderIcon.heightAnchor.constraint(equalToConstant: 72),

            // 情報エリア（ヘッダー直下〜スクロール最下部）
            infoView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            infoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            infoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            infoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // 店名
            storeNameLabel.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 20),
            storeNameLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 20),
            storeNameLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -20),

            // 種類タグ（コンテナ）
            typeTagContainer.topAnchor.constraint(equalTo: storeNameLabel.bottomAnchor, constant: 10),
            typeTagContainer.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 20),

            // 種類タグ（ラベル：コンテナ内パディング）
            typeTagLabel.topAnchor.constraint(equalTo: typeTagContainer.topAnchor, constant: 4),
            typeTagLabel.bottomAnchor.constraint(equalTo: typeTagContainer.bottomAnchor, constant: -4),
            typeTagLabel.leadingAnchor.constraint(equalTo: typeTagContainer.leadingAnchor, constant: 10),
            typeTagLabel.trailingAnchor.constraint(equalTo: typeTagContainer.trailingAnchor, constant: -10),

            // 星評価
            starRatingContainer.topAnchor.constraint(equalTo: typeTagContainer.bottomAnchor, constant: 16),
            starRatingContainer.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 20),
            starRatingContainer.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -20),
            starRatingContainer.heightAnchor.constraint(equalToConstant: 44),

            starRatingView.leadingAnchor.constraint(equalTo: starRatingContainer.leadingAnchor),
            starRatingView.centerYAnchor.constraint(equalTo: starRatingContainer.centerYAnchor),

            // 情報スタック
            infoStack.topAnchor.constraint(equalTo: starRatingContainer.bottomAnchor, constant: 4),
            infoStack.leadingAnchor.constraint(equalTo: infoView.leadingAnchor),
            infoStack.trailingAnchor.constraint(equalTo: infoView.trailingAnchor),

            // コメント
            commentContainer.topAnchor.constraint(equalTo: infoStack.bottomAnchor, constant: 16),
            commentContainer.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 16),
            commentContainer.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -16),
            commentContainer.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -32),

            commentLabel.topAnchor.constraint(equalTo: commentContainer.topAnchor, constant: 16),
            commentLabel.leadingAnchor.constraint(equalTo: commentContainer.leadingAnchor, constant: 16),
            commentLabel.trailingAnchor.constraint(equalTo: commentContainer.trailingAnchor, constant: -16),
            commentLabel.bottomAnchor.constraint(equalTo: commentContainer.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Configuration

    private func configureWithRecord() {
        guard let record else { return }
        let rawType = record.ramenType ?? ""
        let ramenType: RamenType
        if let parsed = RamenType(rawValue: rawType) {
            ramenType = parsed
        } else {
            logger.warning("不明なラーメン種類: \"\(rawType, privacy: .public)\" → .other にフォールバック")
            ramenType = .other
        }
        let typeColor = UIColor.colorForRamenType(ramenType)

        // ヘッダー写真 or カラー背景
        if let data = record.photo {
            // まずカラー背景を表示しておく
            headerImageView.isHidden = true
            headerPlaceholderIcon.isHidden = false
            headerView.backgroundColor = typeColor

            // バックグラウンドで画像デコード（大きい写真でのUIフリーズ防止）
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.headerImageView.image = image
                    self?.headerImageView.isHidden = false
                    self?.headerPlaceholderIcon.isHidden = true
                    self?.headerView.backgroundColor = .black
                }
            }
        } else {
            headerImageView.isHidden = true
            headerPlaceholderIcon.isHidden = false
            headerView.backgroundColor = typeColor
        }

        // 店名
        storeNameLabel.text = record.storeName

        // 種類タグ
        typeTagLabel.text = ramenType.rawValue
        typeTagContainer.backgroundColor = typeColor

        // 星評価
        if record.rating > 0 {
            starRatingView.rating = Int(record.rating)
            starRatingContainer.isHidden = false
        } else {
            starRatingContainer.isHidden = true
        }

        // 情報行（訪問日・費用）
        var infoRows: [(icon: String, title: String, value: String, color: UIColor)] = []

        if let prefRaw = record.prefecture, let pref = Prefecture(rawValue: prefRaw) {
            infoRows.append((
                icon: "mappin.circle",
                title: "都道府県",
                value: pref.rawValue,
                color: .appPrimary
            ))
        }

        if let visitDate = record.visitDate {
            infoRows.append((
                icon: "calendar",
                title: "訪問日",
                value: Self.visitDateFormatter.string(from: visitDate),
                color: .appSecondary
            ))
        }

        if record.cost > 0 {
            infoRows.append((
                icon: "yensign.circle",
                title: "費用",
                value: "¥\(record.cost)",
                color: .appSuccess
            ))
        }

        for (i, row) in infoRows.enumerated() {
            if i > 0 { infoStack.addArrangedSubview(makeDivider()) }
            infoStack.addArrangedSubview(makeInfoRow(icon: row.icon, title: row.title, value: row.value, color: row.color))
        }

        // コメント
        if let comment = record.comment, !comment.isEmpty {
            commentLabel.text = comment
            commentContainer.isHidden = false
        } else {
            commentContainer.isHidden = true
        }

        // アクセシビリティ
        isAccessibilityElement = false
        storeNameLabel.accessibilityTraits = .header
    }

    /// 1行情報ビュー（アイコン + タイトル + 値）
    private func makeInfoRow(icon: String, title: String, value: String, color: UIColor) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconIV = UIImageView()
        let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        iconIV.image = UIImage(systemName: icon, withConfiguration: cfg)
        iconIV.tintColor = color
        iconIV.contentMode = .scaleAspectFit
        iconIV.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .appCaption
        titleLabel.textColor = .appSecondaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.rounded(ofSize: 15, weight: .bold)
        valueLabel.textColor = .appText
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        // アクセシビリティ
        container.isAccessibilityElement = true
        container.accessibilityLabel = "\(title)、\(value)"

        container.addSubview(iconIV)
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 60),

            iconIV.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            iconIV.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconIV.widthAnchor.constraint(equalToConstant: 22),
            iconIV.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.leadingAnchor.constraint(equalTo: iconIV.trailingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),

            valueLabel.leadingAnchor.constraint(equalTo: iconIV.trailingAnchor, constant: 14),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20)
        ])

        return container
    }

    // MARK: - Actions

    @objc private func favoriteButtonTapped() {
        guard let record else { return }
        let success = CoreDataManager.shared.toggleFavorite(record)
        if success {
            updateFavoriteButton()
            favoriteButton.bounceAnimation(scale: 1.4, duration: 0.12)
        } else {
            showErrorAlert(message: "お気に入りの変更に失敗しました")
        }
    }

    @objc private func editButtonTapped() {
        guard let record else { return }
        let editVC = AddRecordViewController(recordToEdit: record)
        let nav = UINavigationController(rootViewController: editVC)
        nav.navigationBar.applyAppStyle()
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func deleteButtonTapped() {
        guard let record else { return }
        let alert = UIAlertController(
            title: "記録を削除しますか？",
            message: "この操作は取り消せません",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        alert.addAction(UIAlertAction(title: "削除", style: .destructive) { [weak self] _ in
            guard let self else { return }
            let success = CoreDataManager.shared.deleteRecord(record)
            if success {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.showErrorAlert(message: "記録の削除に失敗しました")
            }
        })
        present(alert, animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
