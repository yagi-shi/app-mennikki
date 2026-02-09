//
//  RecordDetailViewController.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import UIKit
import CoreData

/// 記録詳細画面
class RecordDetailViewController: UIViewController {

    // MARK: - Properties

    private let record: Record

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .appSecondaryText.withAlphaComponent(0.1)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let storeNameLabel: UILabel = {
        let label = UILabel()
        label.font = .appDetailTitle
        label.textColor = .appText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let ramenTypeTagLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .appText
        label.backgroundColor = .appTagBackground
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let visitDateLabel: UILabel = {
        let label = UILabel()
        label.font = .appBody
        label.textColor = .appText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let costLabel: UILabel = {
        let label = UILabel()
        label.font = .appBody
        label.textColor = .appText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let starRatingView: StarRatingView = {
        let view = StarRatingView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let commentContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let commentLabel: UILabel = {
        let label = UILabel()
        label.font = .appBody
        label.textColor = .appText
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    init(record: Record) {
        self.record = record
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupNavigationBar()
        setupConstraints()
        configureWithRecord()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .appBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        // スタックビューに要素を追加
        contentStackView.addArrangedSubview(photoImageView)
        contentStackView.addArrangedSubview(storeNameLabel)
        contentStackView.addArrangedSubview(ramenTypeTagLabel)
        contentStackView.addArrangedSubview(createInfoRow(icon: "calendar", label: visitDateLabel))
        contentStackView.addArrangedSubview(createInfoRow(icon: "yensign.circle", label: costLabel))
        contentStackView.addArrangedSubview(starRatingView)

        // コメントコンテナ
        commentContainerView.addSubview(commentLabel)
    }

    private func setupNavigationBar() {
        title = record.storeName

        // お気に入りボタン
        let favoriteButton = UIBarButtonItem(
            image: UIImage(systemName: record.isFavorite ? "heart.fill" : "heart"),
            style: .plain,
            target: self,
            action: #selector(favoriteButtonTapped)
        )
        favoriteButton.tintColor = .appPrimary

        // 編集ボタン
        let editButton = UIBarButtonItem(
            image: UIImage(systemName: "pencil.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )

        navigationItem.rightBarButtonItems = [editButton, favoriteButton]
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content Stack View
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

            // Photo ImageView
            photoImageView.widthAnchor.constraint(equalToConstant: 200),
            photoImageView.heightAnchor.constraint(equalToConstant: 200),

            // Ramen Type Tag
            ramenTypeTagLabel.heightAnchor.constraint(equalToConstant: 36),
            ramenTypeTagLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),

            // Star Rating View
            starRatingView.heightAnchor.constraint(equalToConstant: 50),

            // Comment Label
            commentLabel.topAnchor.constraint(equalTo: commentContainerView.topAnchor, constant: 16),
            commentLabel.leadingAnchor.constraint(equalTo: commentContainerView.leadingAnchor, constant: 16),
            commentLabel.trailingAnchor.constraint(equalTo: commentContainerView.trailingAnchor, constant: -16),
            commentLabel.bottomAnchor.constraint(equalTo: commentContainerView.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Configuration

    private func configureWithRecord() {
        // 店舗名
        storeNameLabel.text = record.storeName

        // ラーメンの種類
        if let ramenType = RamenType(rawValue: record.ramenType ?? "") {
            ramenTypeTagLabel.text = "  \(ramenType.rawValue)  "
        }

        // 訪問日
        if let visitDate = record.visitDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月dd日"
            visitDateLabel.text = formatter.string(from: visitDate)
        }

        // 費用
        if record.cost > 0 {
            costLabel.text = "¥\(record.cost)"
        } else {
            costLabel.text = "-"
        }

        // 評価
        starRatingView.rating = Int(record.rating)

        // 写真
        if let photoData = record.photo, let image = UIImage(data: photoData) {
            photoImageView.image = image
        } else {
            // プレースホルダー
            let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
            photoImageView.image = UIImage(systemName: "fork.knife", withConfiguration: config)
            photoImageView.tintColor = .appSecondaryText
            photoImageView.contentMode = .center
        }

        // コメント
        if let comment = record.comment, !comment.isEmpty {
            commentLabel.text = comment
            contentStackView.addArrangedSubview(commentContainerView)

            NSLayoutConstraint.activate([
                commentContainerView.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
                commentContainerView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor)
            ])
        }
    }

    // MARK: - Helper Methods

    private func createInfoRow(icon: String, label: UILabel) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let iconImageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        iconImageView.image = UIImage(systemName: icon, withConfiguration: config)
        iconImageView.tintColor = .appSecondary
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(iconImageView)
        containerView.addSubview(label)

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            label.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            label.topAnchor.constraint(equalTo: containerView.topAnchor),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        return containerView
    }

    // MARK: - Actions

    @objc private func favoriteButtonTapped() {
        CoreDataManager.shared.toggleFavorite(record)

        // ボタンの表示を更新
        let isFavorite = record.isFavorite
        let favoriteButton = navigationItem.rightBarButtonItems?.last
        favoriteButton?.image = UIImage(systemName: isFavorite ? "heart.fill" : "heart")

        // アニメーション
        if let button = navigationItem.rightBarButtonItem {
            // 簡易的なフィードバック
            print("Favorite toggled: \(isFavorite)")
        }
    }

    @objc private func editButtonTapped() {
        let editVC = AddRecordViewController(recordToEdit: record)
        let navController = UINavigationController(rootViewController: editVC)
        navController.navigationBar.applyAppStyle()
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
}
