//
//  RecordCell.swift
//  mennikki
//

import UIKit
import ImageIO

/// Duolingo風ラーメン記録カード
/// - 上半分: ラーメン種類カラーの背景（写真がある場合は写真）
/// - 下半分: 白背景、店名・種類タグ・評価・日付
/// - Duolingo の「押し込み」3Dシャドウ効果
class RecordCell: UICollectionViewCell {

    static let reuseIdentifier = "RecordCell"

    // MARK: - UI: 上エリア（カラー or 写真）

    private let topArea: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let topGradientView: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let topGradientLayer = CAGradientLayer()

    private let placeholderIcon: UIImageView = {
        let iv = UIImageView()
        let cfg = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
        iv.image = UIImage(systemName: "fork.knife", withConfiguration: cfg)
        iv.tintColor = UIColor.white.withAlphaComponent(0.6)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let favoriteIcon: UIImageView = {
        let iv = UIImageView()
        let cfg = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        iv.image = UIImage(systemName: "heart.fill", withConfiguration: cfg)
        iv.tintColor = .white
        iv.backgroundColor = UIColor(red: 255/255, green: 75/255, blue: 75/255, alpha: 1)
        iv.layer.cornerRadius = 12
        iv.contentMode = .center
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - UI: 下エリア（テキスト情報）

    private let storeNameLabel: UILabel = {
        let l = UILabel()
        l.font = .appStoreName
        l.textColor = .appText
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let typeTagContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 8
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

    private let starsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 1
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()


    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupUI() {
        // contentView: 角丸クリップ
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true

        // セル本体: Duolingo の「押し込み」ハードシャドウ
        layer.cornerRadius = 16
        layer.masksToBounds = false
        layer.shadowColor = UIColor.appBorder.cgColor
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 0          // ぼかしなし = ハードシャドウ
        layer.shadowOffset = CGSize(width: 0, height: 5)
        // カードのハードボーダー（Duolingo風の立体感）
        contentView.layer.borderWidth = 2
        contentView.layer.borderColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1).cgColor

        // 5個の星アイコンを追加
        for _ in 0..<5 {
            let iv = UIImageView()
            iv.widthAnchor.constraint(equalToConstant: 10).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 10).isActive = true
            starsStack.addArrangedSubview(iv)
        }

        contentView.addSubview(topArea)
        topArea.addSubview(photoImageView)
        topGradientView.layer.addSublayer(topGradientLayer)
        topArea.addSubview(topGradientView)
        topArea.addSubview(placeholderIcon)
        contentView.addSubview(favoriteIcon)
        contentView.addSubview(storeNameLabel)
        contentView.addSubview(typeTagContainer)
        typeTagContainer.addSubview(typeTagLabel)
        contentView.addSubview(starsStack)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 上エリア: セル高さの 48%
            topArea.topAnchor.constraint(equalTo: contentView.topAnchor),
            topArea.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topArea.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topArea.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.60),

            // 写真
            photoImageView.topAnchor.constraint(equalTo: topArea.topAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: topArea.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: topArea.trailingAnchor),
            photoImageView.bottomAnchor.constraint(equalTo: topArea.bottomAnchor),

            // グラデーションオーバーレイ
            topGradientView.topAnchor.constraint(equalTo: topArea.topAnchor),
            topGradientView.leadingAnchor.constraint(equalTo: topArea.leadingAnchor),
            topGradientView.trailingAnchor.constraint(equalTo: topArea.trailingAnchor),
            topGradientView.bottomAnchor.constraint(equalTo: topArea.bottomAnchor),

            // プレースホルダーアイコン
            placeholderIcon.centerXAnchor.constraint(equalTo: topArea.centerXAnchor),
            placeholderIcon.centerYAnchor.constraint(equalTo: topArea.centerYAnchor),
            placeholderIcon.widthAnchor.constraint(equalToConstant: 52),
            placeholderIcon.heightAnchor.constraint(equalToConstant: 52),

            // お気に入りバッジ
            favoriteIcon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            favoriteIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            favoriteIcon.widthAnchor.constraint(equalToConstant: 24),
            favoriteIcon.heightAnchor.constraint(equalToConstant: 24),

            // 店名
            storeNameLabel.topAnchor.constraint(equalTo: topArea.bottomAnchor, constant: 10),
            storeNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            storeNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),

            // 種類タグ（コンテナ）
            typeTagContainer.topAnchor.constraint(equalTo: storeNameLabel.bottomAnchor, constant: 6),
            typeTagContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),

            // 種類タグ（ラベル：コンテナ内パディング）
            typeTagLabel.topAnchor.constraint(equalTo: typeTagContainer.topAnchor, constant: 3),
            typeTagLabel.bottomAnchor.constraint(equalTo: typeTagContainer.bottomAnchor, constant: -3),
            typeTagLabel.leadingAnchor.constraint(equalTo: typeTagContainer.leadingAnchor, constant: 7),
            typeTagLabel.trailingAnchor.constraint(equalTo: typeTagContainer.trailingAnchor, constant: -7),

            // 星評価
            starsStack.centerYAnchor.constraint(equalTo: typeTagContainer.centerYAnchor),
            starsStack.leadingAnchor.constraint(equalTo: typeTagContainer.trailingAnchor, constant: 5),

        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 16).cgPath
        topGradientLayer.frame = topGradientView.bounds
    }

    // MARK: - Configure

    func configure(with record: Record) {
        storeNameLabel.text = record.storeName

        let ramenType = RamenType(rawValue: record.ramenType ?? "") ?? .other
        let typeColor = UIColor.colorForRamenType(ramenType)

        // 種類タグ
        typeTagLabel.text = ramenType.rawValue
        typeTagContainer.backgroundColor = typeColor

        // 星評価
        let stars = starsStack.arrangedSubviews.compactMap { $0 as? UIImageView }
        for (i, star) in stars.enumerated() {
            let cfg = UIImage.SymbolConfiguration(pointSize: 9, weight: .bold)
            let filled = i < Int(record.rating)
            star.image = UIImage(systemName: filled ? "star.fill" : "star", withConfiguration: cfg)
            star.tintColor = filled
                ? UIColor(red: 88/255, green: 204/255, blue: 2/255, alpha: 1)   // Duolingo green
                : UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1)
        }
        starsStack.isHidden = record.rating == 0

        // お気に入り
        favoriteIcon.isHidden = !record.isFavorite

        // 写真 or カラープレースホルダー
        if let data = record.photo, let image = Self.downsampledImage(data: data, maxPixelSize: 300) {
            photoImageView.image = image
            photoImageView.isHidden = false
            placeholderIcon.isHidden = true
            topArea.backgroundColor = .black
            // 写真下部に薄いグラデーション（白背景への自然な遷移）
            topGradientLayer.colors = [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.18).cgColor
            ]
            topGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.4)
            topGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        } else {
            photoImageView.isHidden = true
            placeholderIcon.isHidden = false
            topArea.backgroundColor = typeColor
            // カラー背景に左上ハイライト（立体感）
            topGradientLayer.colors = [
                UIColor.white.withAlphaComponent(0.35).cgColor,
                UIColor.clear.cgColor
            ]
            topGradientLayer.startPoint = CGPoint(x: 0, y: 0)
            topGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        }

        // アクセシビリティ
        isAccessibilityElement = true
        accessibilityLabel = "\(record.storeName ?? "")、\(ramenType.rawValue)"
        accessibilityHint = "ダブルタップして詳細を表示"
    }

    // MARK: - Image Downsampling

    /// CGImageSource を使ってサムネイルサイズにダウンサンプリング（メモリ節約）
    private static func downsampledImage(data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else { return nil }
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize * UIScreen.main.scale,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Duolingo 押し込みアニメーション

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.08, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                // Duolingo: 押すとカードが 5px 下にずれ、シャドウが消える
                self.transform = self.isHighlighted
                    ? CGAffineTransform(translationX: 0, y: 5)
                    : .identity
                self.layer.shadowOffset = self.isHighlighted
                    ? .zero
                    : CGSize(width: 0, height: 5)
            }
        }
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        storeNameLabel.text = nil
        typeTagLabel.text = nil
        typeTagContainer.backgroundColor = .clear
        photoImageView.image = nil
        photoImageView.isHidden = true
        placeholderIcon.isHidden = false
        favoriteIcon.isHidden = true
        starsStack.isHidden = false
        transform = .identity
        layer.shadowOffset = CGSize(width: 0, height: 5)
    }
}
