//
//  AddRecordViewController.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import UIKit
import PhotosUI

/// 新規記録・編集画面
class AddRecordViewController: UIViewController {

    // MARK: - Properties

    private var recordToEdit: Record?
    private var isEditMode: Bool { recordToEdit != nil }

    private var selectedRamenType: RamenType?
    private var selectedImage: UIImage?

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
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // 店名
    private let storeNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "店舗名を入力"
        textField.font = .appBody
        textField.borderStyle = .none
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 2
        textField.layer.borderColor = UIColor.appSecondaryText.withAlphaComponent(0.2).cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.rightViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    // ラーメンの種類
    private let ramenTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("ラーメンの種類を選択", for: .normal)
        button.titleLabel?.font = .appRamenType
        button.setTitleColor(.appText, for: .normal)
        button.backgroundColor = .appTagBackground
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // 訪問日
    private let visitDatePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        datePicker.maximumDate = Date()
        datePicker.date = Date()
        datePicker.backgroundColor = .white
        datePicker.layer.cornerRadius = 12
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        return datePicker
    }()

    // 費用
    private let costTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "費用（円）"
        textField.font = .appBody
        textField.keyboardType = .numberPad
        textField.borderStyle = .none
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 2
        textField.layer.borderColor = UIColor.appSecondaryText.withAlphaComponent(0.2).cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.rightViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    // 評価
    private let starRatingView: StarRatingView = {
        let view = StarRatingView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // コメント
    private let commentTextView: UITextView = {
        let textView = UITextView()
        textView.font = .appBody
        textView.textColor = .appText
        textView.backgroundColor = .white
        textView.layer.cornerRadius = 12
        textView.layer.borderWidth = 2
        textView.layer.borderColor = UIColor.appSecondaryText.withAlphaComponent(0.2).cgColor
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    // 写真選択ボタン
    private let photoButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        button.setImage(UIImage(systemName: "camera.fill", withConfiguration: config), for: .normal)
        button.tintColor = .appSecondaryText
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.appSecondaryText.withAlphaComponent(0.3).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .appSecondaryText.withAlphaComponent(0.1)
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("削除", for: .normal)
        button.titleLabel?.font = .appStoreName
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 24
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = !isEditMode
        return button
    }()

    // MARK: - Initialization

    init(recordToEdit: Record? = nil) {
        self.recordToEdit = recordToEdit
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
        setupActions()
        setupKeyboardHandling()

        // 編集モードの場合は既存データを読み込む
        if isEditMode {
            loadExistingData()
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .appBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        // セクションラベルとフォーム要素を追加
        contentStackView.addArrangedSubview(createSectionView(title: "店舗名", content: storeNameTextField))
        contentStackView.addArrangedSubview(createSectionView(title: "ラーメンの種類", content: ramenTypeButton))
        contentStackView.addArrangedSubview(createSectionView(title: "訪問日", content: visitDatePicker))
        contentStackView.addArrangedSubview(createSectionView(title: "費用", content: costTextField))
        contentStackView.addArrangedSubview(createSectionView(title: "評価", content: starRatingView))
        contentStackView.addArrangedSubview(createSectionView(title: "コメント", content: commentTextView))
        contentStackView.addArrangedSubview(createSectionView(title: "写真", content: createPhotoSection()))

        // 編集モードの場合は削除ボタンを追加
        if isEditMode {
            view.addSubview(deleteButton)
        }
    }

    private func setupNavigationBar() {
        title = isEditMode ? "記録を編集" : "新規記録"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "キャンセル",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "保存",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content Stack View
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

            // Store Name TextField
            storeNameTextField.heightAnchor.constraint(equalToConstant: 48),

            // Cost TextField
            costTextField.heightAnchor.constraint(equalToConstant: 48),

            // Star Rating View
            starRatingView.heightAnchor.constraint(equalToConstant: 50),

            // Comment TextView
            commentTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),

            // Photo Button
            photoButton.heightAnchor.constraint(equalToConstant: 200),

            // Photo ImageView
            photoImageView.heightAnchor.constraint(equalToConstant: 200)
        ])

        // 削除ボタンの制約（編集モード時のみ）
        if isEditMode {
            NSLayoutConstraint.activate([
                deleteButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                deleteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                deleteButton.heightAnchor.constraint(equalToConstant: 50)
            ])

            // スクロールビューの下部マージンを調整（削除ボタンの分）
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        }
    }

    private func setupActions() {
        ramenTypeButton.addTarget(self, action: #selector(ramenTypeButtonTapped), for: .touchUpInside)
        photoButton.addTarget(self, action: #selector(photoButtonTapped), for: .touchUpInside)

        if isEditMode {
            deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        }

        starRatingView.onRatingChanged = { [weak self] rating in
            print("Rating changed: \(rating)")
        }
    }

    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - Helper Methods

    private func createSectionView(title: String, content: UIView) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .appSectionHeader
        titleLabel.textColor = .appText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(titleLabel)
        containerView.addSubview(content)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            content.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            content.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        return containerView
    }

    private func createPhotoSection() -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(photoButton)
        containerView.addSubview(photoImageView)

        NSLayoutConstraint.activate([
            photoButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            photoButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            photoButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            photoButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            photoImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            photoImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        return containerView
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        // バリデーション
        guard let storeName = storeNameTextField.text, !storeName.isEmpty else {
            showAlert(title: "エラー", message: "店舗名を入力してください")
            return
        }

        guard let ramenType = selectedRamenType else {
            showAlert(title: "エラー", message: "ラーメンの種類を選択してください")
            return
        }

        // 費用の取得
        let cost = Int16(costTextField.text ?? "0") ?? 0

        // 評価の取得
        let rating = Int16(starRatingView.rating)

        // コメントの取得
        let comment = commentTextView.text.isEmpty ? nil : commentTextView.text

        // 写真データの取得
        var photoData: Data?
        if let image = selectedImage {
            // 画像をリサイズして保存
            if let resizedImage = resizeImage(image, maxWidth: 1024) {
                photoData = resizedImage.jpegData(compressionQuality: 0.8)
            }
        } else if isEditMode, let existingPhotoData = recordToEdit?.photo {
            // 編集モードで新しい写真が選択されていない場合は既存の写真を保持
            photoData = existingPhotoData
        }

        if isEditMode, let record = recordToEdit {
            // 編集モード: 既存レコードを更新
            CoreDataManager.shared.updateRecord(
                record,
                storeName: storeName,
                ramenType: ramenType,
                visitDate: visitDatePicker.date,
                cost: cost,
                rating: rating,
                comment: comment,
                photo: photoData,
                isFavorite: record.isFavorite
            )
        } else {
            // 新規作成モード
            CoreDataManager.shared.createRecord(
                storeName: storeName,
                ramenType: ramenType,
                visitDate: visitDatePicker.date,
                cost: cost,
                rating: rating,
                comment: comment,
                photo: photoData
            )
        }

        // 保存成功のフィードバック
        showSuccessAnimation()

        // 画面を閉じる
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.dismiss(animated: true)
        }
    }

    @objc private func ramenTypeButtonTapped() {
        let alertController = UIAlertController(title: "ラーメンの種類", message: "選択してください", preferredStyle: .actionSheet)

        for type in RamenType.allCases {
            let action = UIAlertAction(title: type.rawValue, style: .default) { [weak self] _ in
                self?.selectedRamenType = type
                self?.ramenTypeButton.setTitle(type.rawValue, for: .normal)
                self?.ramenTypeButton.backgroundColor = .appTagBackground
            }
            alertController.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
        alertController.addAction(cancelAction)

        // iPadでのクラッシュ対策
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = ramenTypeButton
            popoverController.sourceRect = ramenTypeButton.bounds
        }

        present(alertController, animated: true)
    }

    @objc private func photoButtonTapped() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Helper Methods

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showSuccessAnimation() {
        // 簡易的な成功フィードバック
        let checkmarkView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmarkView.tintColor = .appSuccess
        checkmarkView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        checkmarkView.center = view.center
        checkmarkView.alpha = 0

        view.addSubview(checkmarkView)

        UIView.animate(withDuration: 0.3, animations: {
            checkmarkView.alpha = 1
            checkmarkView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                checkmarkView.alpha = 0
                checkmarkView.transform = .identity
            }
        }
    }

    private func resizeImage(_ image: UIImage, maxWidth: CGFloat) -> UIImage? {
        let scale = maxWidth / image.size.width
        let newHeight = image.size.height * scale
        let newSize = CGSize(width: maxWidth, height: newHeight)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }

    private func loadExistingData() {
        guard let record = recordToEdit else { return }

        // 店舗名
        storeNameTextField.text = record.storeName

        // ラーメンの種類
        if let ramenType = RamenType(rawValue: record.ramenType ?? "") {
            selectedRamenType = ramenType
            ramenTypeButton.setTitle(ramenType.rawValue, for: .normal)
        }

        // 訪問日
        if let visitDate = record.visitDate {
            visitDatePicker.date = visitDate
        }

        // 費用
        if record.cost > 0 {
            costTextField.text = "\(record.cost)"
        }

        // 評価
        starRatingView.rating = Int(record.rating)

        // コメント
        commentTextView.text = record.comment

        // 写真
        if let photoData = record.photo, let image = UIImage(data: photoData) {
            selectedImage = image
            photoImageView.image = image
            photoImageView.isHidden = false
            photoButton.isHidden = true
        }
    }

    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(
            title: "記録を削除しますか？",
            message: "この操作は取り消せません",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))

        alert.addAction(UIAlertAction(title: "削除", style: .destructive) { [weak self] _ in
            guard let self = self, let record = self.recordToEdit else { return }

            // Core Dataから削除
            CoreDataManager.shared.deleteRecord(record)

            // アニメーション付きで画面を閉じる
            UIView.animate(withDuration: 0.3, animations: {
                self.view.alpha = 0
            }) { _ in
                self.dismiss(animated: true)
            }
        })

        present(alert, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension AddRecordViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider else { return }

        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                DispatchQueue.main.async {
                    if let image = image as? UIImage {
                        self?.selectedImage = image
                        self?.photoImageView.image = image
                        self?.photoImageView.isHidden = false
                        self?.photoButton.isHidden = true
                    }
                }
            }
        }
    }
}
