//
//  StarRatingView.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import UIKit

/// 星評価ビュー（タップ可能、アニメーション付き）
class StarRatingView: UIView {

    // MARK: - Properties

    var rating: Int = 0 {
        didSet {
            updateStars()
        }
    }

    var onRatingChanged: ((Int) -> Void)?

    private let maxRating = 5
    private var starButtons: [UIButton] = []

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStars()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStars()
    }

    // MARK: - Setup

    private func setupStars() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        for index in 0..<maxRating {
            let button = createStarButton(index: index)
            starButtons.append(button)
            stackView.addArrangedSubview(button)
        }

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func createStarButton(index: Int) -> UIButton {
        let button = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        button.setImage(UIImage(systemName: "star", withConfiguration: config), for: .normal)
        button.tintColor = .appBorder
        button.tag = index + 1
        button.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
        return button
    }

    // MARK: - Actions

    @objc private func starTapped(_ sender: UIButton) {
        let newRating = sender.tag

        // 同じ星をタップした場合は評価をクリア
        rating = (newRating == rating) ? 0 : newRating

        // アニメーション
        animateButton(sender)

        // コールバック
        onRatingChanged?(rating)
    }

    // MARK: - Helper Methods

    private func updateStars() {
        for (index, button) in starButtons.enumerated() {
            let isFilled = index < rating
            let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
            let imageName = isFilled ? "star.fill" : "star"
            button.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
            button.tintColor = isFilled ? .appSuccess : .appBorder
        }
    }

    private func animateButton(_ button: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = .identity
            }
        }
    }
}
