//
//  ViewController.swift
//  mennikki
//
//  Created by 八木佑樹 on 2026/02/06.
//

import UIKit

class ViewController: UIViewController {

    // MARK: - UI Components

    private let testLabel: UILabel = {
        let label = UILabel()
        label.text = "mennikki - ラーメン記録アプリ"
        label.font = .appNavigationTitle
        label.textColor = .appText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "プロジェクト初期設定完了"
        label.font = .appBody
        label.textColor = .appSecondaryText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let testButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Core Data テスト", for: .normal)
        button.backgroundColor = .appPrimary
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .appStoreName
        button.layer.cornerRadius = 24
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupConstraints()
        setupActions()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .appBackground

        view.addSubview(testLabel)
        view.addSubview(statusLabel)
        view.addSubview(testButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Test Label
            testLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            testLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            testLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            // Status Label
            statusLabel.topAnchor.constraint(equalTo: testLabel.bottomAnchor, constant: 16),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            // Test Button
            testButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 32),
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.widthAnchor.constraint(equalToConstant: 200),
            testButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupActions() {
        testButton.addTarget(self, action: #selector(testButtonTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func testButtonTapped() {
        // Core Dataのテスト
        let result = testCoreData()

        let alert = UIAlertController(
            title: result ? "成功" : "失敗",
            message: result ? "Core Dataが正常に動作しています" : "Core Dataでエラーが発生しました",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func testCoreData() -> Bool {
        // テストデータを作成
        let testRecord = CoreDataManager.shared.createRecord(
            storeName: "テスト店舗",
            ramenType: .shoyu,
            visitDate: Date(),
            cost: 1000,
            rating: 5,
            comment: "テストコメント"
        )

        if testRecord != nil {
            // 作成成功、削除
            _ = CoreDataManager.shared.deleteRecord(testRecord!)
            return true
        }

        return false
    }
}

