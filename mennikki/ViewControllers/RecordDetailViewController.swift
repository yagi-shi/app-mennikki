//
//  RecordDetailViewController.swift
//  mennikki
//

import UIKit
import CoreData

/// 記録詳細画面
/// - 通常の白いナビバー（透明overlay廃止）
/// - 上部: 種類カラー or 写真（固定高さ220pt）
/// - 下部: 白背景の情報エリア
///
/// 記録の読み込みや、画面に出す値の組み立ては RecordDetailViewModel が受け持つ。この画面は、表示と画面の移動だけを行う
class RecordDetailViewController: UIViewController {

    // MARK: - Properties

    private static let defaultHeaderHeight: CGFloat = 220
    private static let maxHeaderHeight: CGFloat = 400
    /// 情報行（都道府県・訪問日・費用）の最低の高さ（文字が大きいときは、文字に合わせて高くする）
    private static let infoRowMinHeight: CGFloat = 60
    /// 情報行の、文字の上下の余白
    private static let infoRowVerticalPadding: CGFloat = 12

    private let viewModel: RecordDetailViewModel
    /// ヘッダーに出している写真。同じ写真を読み直さないために覚えておく
    private var renderedPhotoData: Data?
    private var headerHeightConstraint: NSLayoutConstraint!
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
        // 一覧のカードでは省略するため、詳細では全文を表示する
        l.numberOfLines = 0
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

    // 区切り線
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
        self.viewModel = RecordDetailViewModel(recordID: record.objectID)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.reload()
        guard !viewModel.shouldClose else {
            navigationController?.popViewController(animated: true)
            return
        }
        setupUI()
        setupConstraints()
        setupNavigationBar()

        // ViewModel の値が変わるたびに描き直す。お気に入りの切り替えで写真まで描き直さないように、分けて見る
        observeChanges { [weak self] in self?.renderRecord() }
        observeChanges { [weak self] in self?.renderFavoriteButton() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 編集画面から戻ったときに、変わった内容を出す
        viewModel.reload()
        if viewModel.shouldClose {
            navigationController?.popViewController(animated: true)
            return
        }
        // observeChanges の描き直しは次の順番になり、戻った直後に古い表示が一瞬見えることがあるので、ここですぐ描き直す
        renderRecord()
        renderFavoriteButton()
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
        editButton.accessibilityLabel = "記録を編集"

        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(deleteButtonTapped)
        )
        deleteButton.tintColor = .appPrimary
        deleteButton.accessibilityLabel = "記録を削除"

        navigationItem.rightBarButtonItems = [editButton, favoriteBarButton, deleteButton]
    }

    private func renderFavoriteButton() {
        let isFav = viewModel.isFavorite
        let heartConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        favoriteButton.setImage(UIImage(systemName: isFav ? "heart.fill" : "heart", withConfiguration: heartConfig), for: .normal)
        favoriteButton.tintColor = isFav ? .appPrimary : .appSecondaryText
        favoriteButton.accessibilityLabel = isFav ? "お気に入り解除" : "お気に入り登録"
    }

    private func setupConstraints() {
        headerHeightConstraint = headerView.heightAnchor.constraint(equalToConstant: Self.defaultHeaderHeight)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
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
            headerHeightConstraint,

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

    private func renderRecord() {
        let typeColor = UIColor.colorForRamenType(viewModel.ramenType)

        renderHeader(typeColor: typeColor)

        // 店名
        storeNameLabel.text = viewModel.storeName

        // 種類タグ
        typeTagLabel.text = viewModel.ramenType.rawValue
        typeTagContainer.backgroundColor = typeColor

        // 星評価
        if let rating = viewModel.ratingToShow {
            starRatingView.rating = rating
            starRatingContainer.isHidden = false
        } else {
            starRatingContainer.isHidden = true
        }

        // 情報行（都道府県・訪問日・費用）。描き直すたびに、前の行を消してから並べる
        infoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, row) in viewModel.infoRows.enumerated() {
            if index > 0 { infoStack.addArrangedSubview(makeDivider()) }
            let style = Self.infoRowStyle(for: row.kind)
            infoStack.addArrangedSubview(makeInfoRow(icon: style.icon, title: row.title, value: row.value, color: style.color))
        }

        // コメント
        if let comment = viewModel.commentToShow {
            commentLabel.text = comment
            commentContainer.isHidden = false
        } else {
            commentContainer.isHidden = true
        }

        // アクセシビリティ
        isAccessibilityElement = false
        storeNameLabel.accessibilityTraits = .header
    }

    /// ヘッダーに、写真か、種類の色の背景を出す
    private func renderHeader(typeColor: UIColor) {
        guard let photoData = viewModel.photoData else {
            renderedPhotoData = nil
            headerImageView.isHidden = true
            headerPlaceholderIcon.isHidden = false
            headerView.backgroundColor = typeColor
            headerHeightConstraint.constant = Self.defaultHeaderHeight
            return
        }

        // 同じ写真を読み直すと、読み終わるまで一瞬カラー背景に戻るので、写真が変わったときだけ読み直す
        guard photoData != renderedPhotoData else { return }
        renderedPhotoData = photoData

        // まずカラー背景を表示しておく
        headerImageView.isHidden = true
        headerPlaceholderIcon.isHidden = false
        headerView.backgroundColor = typeColor

        // バックグラウンドで画像デコード（大きい写真でのUIフリーズ防止）
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let image = UIImage(data: photoData) else { return }
            DispatchQueue.main.async {
                guard let self else { return }
                self.headerImageView.image = image
                self.headerImageView.isHidden = false
                self.headerPlaceholderIcon.isHidden = true
                self.headerView.backgroundColor = .black
                self.updateHeaderHeight(for: image)
            }
        }
    }

    /// 情報行の種類ごとの、アイコンと色
    private static func infoRowStyle(for kind: RecordDetailViewModel.InfoRow.Kind) -> (icon: String, color: UIColor) {
        switch kind {
        case .prefecture: return (icon: "mappin.circle", color: .appPrimary)
        case .visitDate: return (icon: "calendar", color: .appSecondary)
        case .cost: return (icon: "yensign.circle", color: .appSuccess)
        }
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
        valueLabel.font = .appInfoValue
        valueLabel.textColor = .appText
        valueLabel.numberOfLines = 0
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        // アクセシビリティ
        container.isAccessibilityElement = true
        container.accessibilityLabel = "\(title)、\(value)"

        container.addSubview(iconIV)
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)

        // 文字が小さいときは最低の高さにし、大きいときは値の下に余白を残して高くする
        let valueBottom = valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Self.infoRowVerticalPadding)
        valueBottom.priority = .defaultHigh

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.infoRowMinHeight),

            iconIV.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            iconIV.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconIV.widthAnchor.constraint(equalToConstant: 22),
            iconIV.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.leadingAnchor.constraint(equalTo: iconIV.trailingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: Self.infoRowVerticalPadding),

            valueLabel.leadingAnchor.constraint(equalTo: iconIV.trailingAnchor, constant: 14),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            valueBottom
        ])

        return container
    }

    // MARK: - Actions

    @objc private func favoriteButtonTapped() {
        guard viewModel.toggleFavorite() else {
            showErrorAlert(message: "お気に入りの変更に失敗しました")
            return
        }
        // observeChanges の描き直しを待たずに、ハートの絵を切り替えてからバウンスさせる
        renderFavoriteButton()
        favoriteButton.bounceAnimation(scale: 1.4, duration: 0.12)
    }

    @objc private func editButtonTapped() {
        guard let record = viewModel.record else { return }
        let editVC = AddRecordViewController(recordToEdit: record)
        let nav = UINavigationController(rootViewController: editVC)
        nav.navigationBar.applyAppStyle()
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(
            title: "記録を削除しますか？",
            message: "この操作は取り消せません",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        alert.addAction(UIAlertAction(title: "削除", style: .destructive) { [weak self] _ in
            guard let self else { return }
            if self.viewModel.deleteRecord() {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.showErrorAlert(message: "記録の削除に失敗しました")
            }
        })
        present(alert, animated: true)
    }

    /// 画像のアスペクト比に応じてヘッダー高さを更新（220〜400pt）
    private func updateHeaderHeight(for image: UIImage) {
        let imageSize = image.size
        guard imageSize.width > 0 else { return }
        let screenWidth = view.bounds.width
        let fittingHeight = screenWidth * imageSize.height / imageSize.width
        let clampedHeight = min(max(fittingHeight, Self.defaultHeaderHeight), Self.maxHeaderHeight)
        headerHeightConstraint.constant = clampedHeight
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
