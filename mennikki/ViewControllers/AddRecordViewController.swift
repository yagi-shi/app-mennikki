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
    private var selectedPrefecture: Prefecture?
    private var selectedImage: UIImage?

    // ラーメン種類チップボタンを保持
    private var typeChipButtons: [UIButton] = []

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 20
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // 店名
    private let storeNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "店舗名を入力"
        tf.font = .appBody
        tf.borderStyle = .none
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 2
        tf.layer.borderColor = UIColor.appFieldBorder.cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.rightViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    // ラーメン種類チップスクロール
    private let ramenTypeScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let ramenTypeChipsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // 訪問日
    private let visitDatePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .inline
        dp.maximumDate = Date()
        dp.date = Date()
        dp.backgroundColor = .white
        dp.layer.cornerRadius = 12
        dp.tintColor = .appPrimary
        dp.translatesAutoresizingMaskIntoConstraints = false
        return dp
    }()

    // 費用
    private let costTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "費用（円）"
        tf.font = .appBody
        tf.keyboardType = .numberPad
        tf.borderStyle = .none
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 2
        tf.layer.borderColor = UIColor.appFieldBorder.cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.rightViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    // 都道府県選択ボタン
    private let prefectureButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "都道府県を選択"
        config.baseForegroundColor = .appSecondaryText
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var updated = attrs
            updated.font = UIFont.appBody
            return updated
        }
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        config.background.backgroundColor = .white
        config.background.cornerRadius = 12
        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.appFieldBorder.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // 評価
    private let starRatingView: StarRatingView = {
        let view = StarRatingView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // コメント
    private let commentTextView: UITextView = {
        let tv = UITextView()
        tv.font = .appBody
        tv.textColor = .appText
        tv.backgroundColor = .white
        tv.layer.cornerRadius = 12
        tv.layer.borderWidth = 2
        tv.layer.borderColor = UIColor.appFieldBorder.cgColor
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // 写真選択ボタン
    private let photoButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        button.setImage(UIImage(systemName: "camera.fill", withConfiguration: config), for: .normal)
        button.tintColor = UIColor.appFieldBorder.withAlphaComponent(1.0)
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.appFieldBorder.withAlphaComponent(0.3).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = UIColor.appFieldBorder.withAlphaComponent(0.1)
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Duolingo風 3D 保存ボタン（画面下部固定）
    private let saveActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("保存する", for: .normal)
        button.titleLabel?.font = .appButton
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .appSuccess
        button.layer.cornerRadius = 16
        // Duolingo 3D ハードシャドウ
        button.layer.shadowColor = UIColor(red: 50/255, green: 140/255, blue: 0/255, alpha: 1).cgColor
        button.layer.shadowOpacity = 1.0
        button.layer.shadowRadius = 0
        button.layer.shadowOffset = CGSize(width: 0, height: 5)
        button.translatesAutoresizingMaskIntoConstraints = false
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
        buildRamenTypeChips()

        if isEditMode {
            loadExistingData()
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .appBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        contentStackView.addArrangedSubview(makeSectionView(title: "店舗名", content: storeNameTextField))
        contentStackView.addArrangedSubview(makeSectionView(title: "ラーメンの種類", content: ramenTypeScrollView))
        contentStackView.addArrangedSubview(makeSectionView(title: "都道府県", content: prefectureButton))
        contentStackView.addArrangedSubview(makeSectionView(title: "訪問日", content: visitDatePicker))
        contentStackView.addArrangedSubview(makeSectionView(title: "費用", content: costTextField))
        contentStackView.addArrangedSubview(makeSectionView(title: "評価", content: starRatingView))
        contentStackView.addArrangedSubview(makeSectionView(title: "コメント", content: commentTextView))
        contentStackView.addArrangedSubview(makeSectionView(title: "写真", content: makePhotoSection()))

        view.addSubview(saveActionButton)

        storeNameTextField.delegate = self
        costTextField.delegate = self

        // アクセシビリティ
        storeNameTextField.accessibilityLabel = "店舗名"
        costTextField.accessibilityLabel = "費用"
        commentTextView.accessibilityLabel = "コメント"
        photoButton.accessibilityLabel = "写真を選択"
        saveActionButton.accessibilityLabel = "保存"
    }

    private func setupNavigationBar() {
        title = isEditMode ? "記録を編集" : "新規記録"
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )

    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

            storeNameTextField.heightAnchor.constraint(equalToConstant: 48),
            prefectureButton.heightAnchor.constraint(equalToConstant: 48),
            costTextField.heightAnchor.constraint(equalToConstant: 48),
            starRatingView.heightAnchor.constraint(equalToConstant: 50),
            commentTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            photoButton.heightAnchor.constraint(equalToConstant: 200),
            photoImageView.heightAnchor.constraint(equalToConstant: 200),

            // チップスクロールビュー高さ
            ramenTypeScrollView.heightAnchor.constraint(equalToConstant: 44),

            // Duolingo風 保存ボタン（画面下部固定）
            saveActionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveActionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveActionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            saveActionButton.heightAnchor.constraint(equalToConstant: 54)
        ])

        // スクロールビューの下部余白（ボタンと被らないように）
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
    }

    private func setupActions() {
        prefectureButton.addTarget(self, action: #selector(prefectureButtonTapped), for: .touchUpInside)
        photoButton.addTarget(self, action: #selector(photoButtonTapped), for: .touchUpInside)

        // 保存ボタン: Duolingo 3D 押し込みアニメーション
        saveActionButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveActionButton.addTarget(self, action: #selector(saveButtonDown), for: .touchDown)
        saveActionButton.addTarget(self, action: #selector(saveButtonUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        starRatingView.onRatingChanged = { _ in }
    }

    private func setupKeyboardHandling() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let bottomInset = frame.height - view.safeAreaInsets.bottom + 80 // 80 = 保存ボタン分
        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 80
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    // MARK: - Ramen Type Chips

    private func buildRamenTypeChips() {
        ramenTypeScrollView.addSubview(ramenTypeChipsStack)
        NSLayoutConstraint.activate([
            ramenTypeChipsStack.topAnchor.constraint(equalTo: ramenTypeScrollView.topAnchor),
            ramenTypeChipsStack.leadingAnchor.constraint(equalTo: ramenTypeScrollView.leadingAnchor),
            ramenTypeChipsStack.trailingAnchor.constraint(equalTo: ramenTypeScrollView.trailingAnchor),
            ramenTypeChipsStack.bottomAnchor.constraint(equalTo: ramenTypeScrollView.bottomAnchor),
            ramenTypeChipsStack.heightAnchor.constraint(equalTo: ramenTypeScrollView.heightAnchor)
        ])

        for type in RamenType.allCases {
            let chip = makeChipButton(for: type)
            ramenTypeChipsStack.addArrangedSubview(chip)
            typeChipButtons.append(chip)
        }
    }

    private func makeChipButton(for type: RamenType) -> UIButton {
        let color = UIColor.colorForRamenType(type)

        var config = UIButton.Configuration.plain()
        config.title = type.rawValue
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { _ in
            AttributeContainer([.font: UIFont.rounded(ofSize: 13, weight: .bold)])
        }
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)
        config.background.cornerRadius = 22

        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 22
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true

        button.configurationUpdateHandler = { btn in
            var updated = btn.configuration ?? UIButton.Configuration.plain()
            updated.baseForegroundColor = btn.isSelected ? .white : color
            updated.background.backgroundColor = btn.isSelected ? color : color.withAlphaComponent(0.12)
            btn.configuration = updated
            btn.layer.borderColor = btn.isSelected ? color.cgColor : UIColor.clear.cgColor
        }

        button.accessibilityLabel = type.rawValue
        button.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
        if let index = RamenType.allCases.firstIndex(of: type) {
            button.tag = index
        }
        return button
    }

    private func selectChip(for type: RamenType) {
        for (i, button) in typeChipButtons.enumerated() {
            let chipType = RamenType.allCases[i]
            let shouldSelect = chipType == type
            button.isSelected = shouldSelect
            if shouldSelect {
                button.accessibilityTraits.insert(.selected)
            } else {
                button.accessibilityTraits.remove(.selected)
            }
            UIView.animate(withDuration: 0.2) {
                button.transform = shouldSelect ? CGAffineTransform(scaleX: 1.05, y: 1.05) : .identity
            }
        }
    }

    // MARK: - Helper Methods

    private func makeSectionView(title: String, content: UIView) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        let attrString = NSAttributedString(
            string: title.uppercased(),
            attributes: [
                .font: UIFont.rounded(ofSize: 12, weight: .heavy),
                .foregroundColor: UIColor.appSecondaryText,
                .kern: 1.5
            ]
        )
        titleLabel.attributedText = attrString
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(content)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),

            content.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func makePhotoSection() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(photoButton)
        container.addSubview(photoImageView)

        NSLayoutConstraint.activate([
            photoButton.topAnchor.constraint(equalTo: container.topAnchor),
            photoButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            photoButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            photoButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            photoImageView.topAnchor.constraint(equalTo: container.topAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            photoImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            photoImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - Actions

    @objc private func prefectureButtonTapped() {
        let alert = UIAlertController(title: "都道府県を選択", message: nil, preferredStyle: .actionSheet)

        if selectedPrefecture != nil {
            alert.addAction(UIAlertAction(title: "選択を解除", style: .destructive) { [weak self] _ in
                self?.selectedPrefecture = nil
                self?.updatePrefectureButton(nil)
            })
        }

        for pref in Prefecture.allCases {
            alert.addAction(UIAlertAction(title: pref.rawValue, style: .default) { [weak self] _ in
                self?.selectedPrefecture = pref
                self?.updatePrefectureButton(pref)
            })
        }

        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = prefectureButton
            popover.sourceRect = prefectureButton.bounds
        }

        present(alert, animated: true)
    }

    private func updatePrefectureButton(_ prefecture: Prefecture?) {
        var config = prefectureButton.configuration ?? UIButton.Configuration.plain()
        if let prefecture {
            config.title = prefecture.rawValue
            config.baseForegroundColor = .appText
        } else {
            config.title = "都道府県を選択"
            config.baseForegroundColor = .appSecondaryText
        }
        prefectureButton.configuration = config
    }

    @objc private func saveButtonDown() {
        UIView.animate(withDuration: 0.08, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.saveActionButton.transform = CGAffineTransform(translationX: 0, y: 5)
            self.saveActionButton.layer.shadowOffset = .zero
        }
    }

    @objc private func saveButtonUp() {
        UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8) {
            self.saveActionButton.transform = .identity
            self.saveActionButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        }
    }

    @objc private func chipTapped(_ sender: UIButton) {
        let types = RamenType.allCases
        guard sender.tag < types.count else { return }
        let type = types[sender.tag]
        selectedRamenType = type
        selectChip(for: type)
        sender.bounceAnimation(scale: 1.1, duration: 0.12)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard let storeName = storeNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !storeName.isEmpty else {
            shakeView(storeNameTextField)
            showAlert(title: "エラー", message: "店舗名を入力してください")
            return
        }

        guard storeName.count <= 100 else {
            shakeView(storeNameTextField)
            showAlert(title: "エラー", message: "店舗名は100文字以内で入力してください")
            return
        }

        guard let ramenType = selectedRamenType else {
            showAlert(title: "エラー", message: "ラーメンの種類を選択してください")
            return
        }

        guard starRatingView.rating > 0 else {
            shakeView(starRatingView)
            showAlert(title: "エラー", message: "評価を選択してください")
            return
        }

        let commentText = commentTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if commentText.count > 500 {
            shakeView(commentTextView)
            showAlert(title: "エラー", message: "コメントは500文字以内で入力してください")
            return
        }

        let cost = Int16(costTextField.text ?? "0") ?? 0
        let rating = Int16(starRatingView.rating)
        let comment = commentText.isEmpty ? nil : commentText

        let image = selectedImage
        let existingPhoto: Data? = (isEditMode ? recordToEdit?.photo : nil)
        let visitDate = visitDatePicker.date
        let isFavorite = isEditMode ? (recordToEdit?.isFavorite ?? false) : false
        let record = recordToEdit
        let editMode = isEditMode

        view.isUserInteractionEnabled = false

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            var photoData: Data?
            if let image = image {
                let resized = self.resizeImage(image)
                photoData = resized.jpegData(compressionQuality: 0.75)
            } else if editMode, let existing = existingPhoto {
                photoData = existing
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.view.isUserInteractionEnabled = true

                var saveSuccess = false

                if editMode, let record = record {
                    saveSuccess = CoreDataManager.shared.updateRecord(
                        record,
                        storeName: storeName,
                        ramenType: ramenType,
                        visitDate: visitDate,
                        cost: cost,
                        rating: rating,
                        comment: comment,
                        photo: photoData,
                        isFavorite: isFavorite,
                        prefecture: selectedPrefecture
                    )
                } else {
                    saveSuccess = CoreDataManager.shared.createRecord(
                        storeName: storeName,
                        ramenType: ramenType,
                        visitDate: visitDate,
                        cost: cost,
                        rating: rating,
                        comment: comment,
                        photo: photoData,
                        prefecture: selectedPrefecture
                    ) != nil
                }

                guard saveSuccess else {
                    self.showAlert(title: "保存エラー", message: "データの保存に失敗しました。空き容量を確認してください。")
                    return
                }

                self.showSuccessAnimation()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.dismiss(animated: true)
                }
            }
        }
    }

    @objc private func photoButtonTapped() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
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

    private func shakeView(_ view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-8, 8, -6, 6, -4, 4, 0]
        view.layer.add(animation, forKey: "shake")
    }

    private func showSuccessAnimation() {
        let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmark.tintColor = .appSuccess
        checkmark.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        checkmark.center = view.center
        checkmark.alpha = 0
        checkmark.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        view.addSubview(checkmark)

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
            checkmark.alpha = 1
            checkmark.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0.2) {
                checkmark.alpha = 0
            }
        }
    }

    /// 長辺を maxDimension 以下にリサイズ（縦横比維持）
    /// UIGraphicsImageRenderer を使用（iOS 17+ 非推奨APIを回避）
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat = 800) -> UIImage {
        let size = image.size
        let longer = max(size.width, size.height)
        guard longer > maxDimension else { return image }

        let scale = maxDimension / longer
        let newSize = CGSize(width: (size.width * scale).rounded(),
                             height: (size.height * scale).rounded())

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func loadExistingData() {
        guard let record = recordToEdit else { return }

        storeNameTextField.text = record.storeName

        if let ramenType = RamenType(rawValue: record.ramenType ?? "") {
            selectedRamenType = ramenType
            selectChip(for: ramenType)
        }

        if let visitDate = record.visitDate {
            visitDatePicker.date = visitDate
        }

        if record.cost > 0 {
            costTextField.text = "\(record.cost)"
        }

        starRatingView.rating = Int(record.rating)
        commentTextView.text = record.comment

        if let prefRaw = record.prefecture, let pref = Prefecture(rawValue: prefRaw) {
            selectedPrefecture = pref
            updatePrefectureButton(pref)
        }

        if let photoData = record.photo {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let image = UIImage(data: photoData) else { return }
                DispatchQueue.main.async {
                    self?.selectedImage = image
                    self?.photoImageView.image = image
                    self?.photoImageView.isHidden = false
                    self?.photoButton.isHidden = true
                }
            }
        }
    }
}

// MARK: - UITextFieldDelegate (focus animation)

extension AddRecordViewController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.layer.borderColor = UIColor.appSecondary.cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.layer.borderColor = UIColor.appFieldBorder.cgColor
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == costTextField else { return true }
        let current = textField.text ?? ""
        guard let range = Range(range, in: current) else { return false }
        let newText = current.replacingCharacters(in: range, with: string)
        if newText.isEmpty { return true }
        guard let value = Int(newText) else { return false }
        return value <= 9999
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - PHPickerViewControllerDelegate

extension AddRecordViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider else { return }
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
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
