//
//  RecordCell.swift
//  mennikki
//

import UIKit
import ImageIO
import CoreData
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.mennikki", category: "RecordCell")

/// ラーメン記録カード
/// - 上半分: ラーメン種類カラーの背景（写真がある場合は写真）
/// - 下半分: 白背景、店名・種類タグ・評価・日付
/// - 「押し込み」3Dシャドウ効果
class RecordCell: UICollectionViewCell {

    static let reuseIdentifier = "RecordCell"

    // MARK: - Image Cache

    /// ダウンサンプリング済み画像のキャッシュ（全セルで共有）
    private static let imageCache = NSCache<NSString, UIImage>()

    /// 記録のサムネイルのキャッシュを破棄する。写真を差し替えたときに呼ぶ
    static func removeCachedImage(for record: Record) {
        let cacheKey = record.objectID.uriRepresentation().absoluteString as NSString
        imageCache.removeObject(forKey: cacheKey)
    }

    /// 現在表示中のレコード ID（セル再利用時の画像すり替え防止用）
    private var currentRecordID: String?

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
        iv.backgroundColor = .appPrimary
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
        l.numberOfLines = RecordCell.storeNameMaxLines
        // 高さが足りない場合は、種類タグではなく店名を縮めて省略する
        l.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
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


    // MARK: - Layout

    /// 上エリア（写真）の高さの、カード幅に対する比率
    private static let topAreaHeightRatio: CGFloat = 0.60
    /// 下エリア（店名・種類タグ・星）の上下左右の余白
    private static let bottomAreaPadding: CGFloat = 10
    /// 店名と種類タグの間隔
    private static let storeNameToTagSpacing: CGFloat = 6
    /// 種類タグの、文字の上下の余白
    private static let tagVerticalPadding: CGFloat = 3
    /// 店名の最大行数（入りきらない分は末尾を「…」で省略）
    private static let storeNameMaxLines = 1

    /// 下エリアの高さのキャッシュ（文字サイズの設定ごと）
    private static var cachedBottomAreaHeight: (category: UIContentSizeCategory, height: CGFloat)?

    /// 幅に対するカードの高さ。店名が最大行数まで入り、種類タグと星が切れない高さにする（店名の長さでは変えない）
    static func height(forWidth width: CGFloat) -> CGFloat {
        ceil(width * topAreaHeightRatio + bottomAreaHeight())
    }

    private static func bottomAreaHeight() -> CGFloat {
        let category = UIApplication.shared.preferredContentSizeCategory
        if let cached = cachedBottomAreaHeight, cached.category == category {
            return cached.height
        }
        // 日本語は代替フォントで描かれて行の高さが変わるため、実際の文字で測る
        let storeNameHeight = measuredHeight(of: "ラーメンAg", font: .appStoreName, lines: storeNameMaxLines)
        let tagHeight = measuredHeight(of: "醤油Ag", font: .appTag, lines: 1) + tagVerticalPadding * 2
        let height = bottomAreaPadding + storeNameHeight + storeNameToTagSpacing + tagHeight + bottomAreaPadding
        cachedBottomAreaHeight = (category, height)
        return height
    }

    private static func measuredHeight(of sample: String, font: UIFont, lines: Int) -> CGFloat {
        let label = UILabel()
        label.font = font
        label.numberOfLines = lines
        label.text = Array(repeating: sample, count: lines).joined(separator: "\n")
        let size = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
        return ceil(size.height)
    }

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

        // セル本体: 「押し込み」ハードシャドウ
        layer.cornerRadius = 16
        layer.masksToBounds = false
        layer.shadowColor = UIColor.appBorder.cgColor
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 0          // ぼかしなし = ハードシャドウ
        layer.shadowOffset = CGSize(width: 0, height: 5)
        // カードのハードボーダー（立体感）
        contentView.layer.borderWidth = 2
        contentView.layer.borderColor = UIColor.appCardBorder.cgColor

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
            // 上エリア: カード幅の 60%（カードの高さが変わっても写真の大きさは変えない）
            topArea.topAnchor.constraint(equalTo: contentView.topAnchor),
            topArea.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topArea.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topArea.heightAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: Self.topAreaHeightRatio),

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
            storeNameLabel.topAnchor.constraint(equalTo: topArea.bottomAnchor, constant: Self.bottomAreaPadding),
            storeNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.bottomAreaPadding),
            storeNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.bottomAreaPadding),

            // 種類タグ（コンテナ）: カードの下端にそろえる
            typeTagContainer.topAnchor.constraint(greaterThanOrEqualTo: storeNameLabel.bottomAnchor, constant: Self.storeNameToTagSpacing),
            typeTagContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.bottomAreaPadding),
            typeTagContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.bottomAreaPadding),

            // 種類タグ（ラベル：コンテナ内パディング）
            typeTagLabel.topAnchor.constraint(equalTo: typeTagContainer.topAnchor, constant: Self.tagVerticalPadding),
            typeTagLabel.bottomAnchor.constraint(equalTo: typeTagContainer.bottomAnchor, constant: -Self.tagVerticalPadding),
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
        let recordID = record.objectID.uriRepresentation().absoluteString
        currentRecordID = recordID

        storeNameLabel.text = record.storeName

        let rawType = record.ramenType ?? ""
        let ramenType: RamenType
        if let parsed = RamenType(rawValue: rawType) {
            ramenType = parsed
        } else {
            logger.warning("不明なラーメン種類: \"\(rawType, privacy: .public)\" → .other にフォールバック")
            ramenType = .other
        }
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
                ? UIColor(red: 88/255, green: 204/255, blue: 2/255, alpha: 1)   // green
                : UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1)
        }
        starsStack.isHidden = record.rating == 0

        // お気に入り
        favoriteIcon.isHidden = !record.isFavorite

        // 写真 or カラープレースホルダー
        if record.photo != nil {
            // まずプレースホルダー状態にしておく
            showColorPlaceholder(typeColor)

            let cacheKey = recordID as NSString
            // キャッシュにあれば即表示
            if let cached = Self.imageCache.object(forKey: cacheKey) {
                showPhoto(cached)
            } else {
                // バックグラウンドでダウンサンプリング
                let displayScale = traitCollection.displayScale > 0 ? traitCollection.displayScale : 2.0
                let photoData = record.photo
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let data = photoData,
                          let image = Self.downsampledImage(data: data, maxPixelSize: 300, scale: displayScale) else { return }
                    // キャッシュに保存
                    Self.imageCache.setObject(image, forKey: cacheKey)
                    DispatchQueue.main.async {
                        // セルが再利用されていないか確認
                        guard self?.currentRecordID == recordID else { return }
                        self?.showPhoto(image)
                    }
                }
            }
        } else {
            showColorPlaceholder(typeColor)
        }

        // アクセシビリティ
        isAccessibilityElement = true
        accessibilityLabel = "\(record.storeName ?? "")、\(ramenType.rawValue)"
        accessibilityHint = "ダブルタップして詳細を表示"
    }

    private func showPhoto(_ image: UIImage) {
        photoImageView.image = image
        photoImageView.isHidden = false
        placeholderIcon.isHidden = true
        topArea.backgroundColor = .black
        topGradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.18).cgColor
        ]
        topGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.4)
        topGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    }

    private func showColorPlaceholder(_ color: UIColor) {
        photoImageView.isHidden = true
        placeholderIcon.isHidden = false
        topArea.backgroundColor = color
        topGradientLayer.colors = [
            UIColor.white.withAlphaComponent(0.35).cgColor,
            UIColor.clear.cgColor
        ]
        topGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        topGradientLayer.endPoint = CGPoint(x: 1, y: 1)
    }

    // MARK: - Image Downsampling

    /// CGImageSource を使ってサムネイルサイズにダウンサンプリング（メモリ節約）
    private static func downsampledImage(data: Data, maxPixelSize: CGFloat, scale: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else { return nil }
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize * scale,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - 3D押し込みアニメーション

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.08, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                // 押すとカードが 5px 下にずれ、シャドウが消える
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
        currentRecordID = nil
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
