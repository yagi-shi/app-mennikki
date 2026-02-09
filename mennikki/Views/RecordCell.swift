//
//  RecordCell.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import UIKit

/// 記録セル（2列グリッドで使用）
class RecordCell: UICollectionViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "RecordCell"

    // MARK: - UI Components

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .appSecondaryText.withAlphaComponent(0.1)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        // プレースホルダーアイコン
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        imageView.image = UIImage(systemName: "fork.knife", withConfiguration: config)
        imageView.tintColor = .appSecondaryText

        return imageView
    }()

    private let favoriteButton: UIButton = {
        let button = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        button.setImage(UIImage(systemName: "heart.fill", withConfiguration: config), for: .normal)
        button.tintColor = .appPrimary
        button.backgroundColor = .white.withAlphaComponent(0.9)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true // デフォルトは非表示
        return button
    }()

    private let storeNameLabel: UILabel = {
        let label = UILabel()
        label.font = .appStoreName
        label.textColor = .appText
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let ramenTypeTagLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .appText
        label.backgroundColor = .appTagBackground
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let visitDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .appSecondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        // セルの背景とシャドウ
        contentView.backgroundColor = .appCardBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true

        // シャドウ（contentViewの外側）
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.masksToBounds = false

        // サブビューを追加
        contentView.addSubview(photoImageView)
        contentView.addSubview(favoriteButton)
        contentView.addSubview(storeNameLabel)
        contentView.addSubview(ramenTypeTagLabel)
        contentView.addSubview(visitDateLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Photo ImageView（上部）
            photoImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            photoImageView.heightAnchor.constraint(equalToConstant: 120),

            // Favorite Button（右上に重なる）
            favoriteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            favoriteButton.widthAnchor.constraint(equalToConstant: 32),
            favoriteButton.heightAnchor.constraint(equalToConstant: 32),

            // Store Name Label
            storeNameLabel.topAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: 8),
            storeNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            storeNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            // Ramen Type Tag Label
            ramenTypeTagLabel.topAnchor.constraint(equalTo: storeNameLabel.bottomAnchor, constant: 6),
            ramenTypeTagLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            ramenTypeTagLabel.heightAnchor.constraint(equalToConstant: 24),

            // Visit Date Label
            visitDateLabel.topAnchor.constraint(equalTo: ramenTypeTagLabel.bottomAnchor, constant: 6),
            visitDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            visitDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            visitDateLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Configuration

    /// セルにデータを設定
    func configure(with record: Record) {
        // 店舗名
        storeNameLabel.text = record.storeName

        // ラーメンの種類
        if let ramenType = RamenType(rawValue: record.ramenType ?? "") {
            ramenTypeTagLabel.text = ramenType.rawValue
        } else {
            ramenTypeTagLabel.text = "不明"
        }

        // 訪問日
        if let visitDate = record.visitDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd"
            visitDateLabel.text = formatter.string(from: visitDate)
        } else {
            visitDateLabel.text = ""
        }

        // お気に入りバッジ
        favoriteButton.isHidden = !record.isFavorite

        // 写真
        if let photoData = record.photo, let image = UIImage(data: photoData) {
            photoImageView.image = image
            photoImageView.contentMode = .scaleAspectFill
        } else {
            // プレースホルダー
            let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
            photoImageView.image = UIImage(systemName: "fork.knife", withConfiguration: config)
            photoImageView.contentMode = .center
        }

        // アクセシビリティ
        isAccessibilityElement = true
        accessibilityTraits = .button

        let favoriteText = record.isFavorite ? "お気に入り" : ""
        accessibilityLabel = "\(record.storeName ?? "")、\(ramenTypeTagLabel.text ?? "")、\(visitDateLabel.text ?? "")、\(favoriteText)"
        accessibilityHint = "ダブルタップして記録の詳細を表示"
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        storeNameLabel.text = nil
        ramenTypeTagLabel.text = nil
        visitDateLabel.text = nil
        photoImageView.image = nil
        favoriteButton.isHidden = true
    }
}
