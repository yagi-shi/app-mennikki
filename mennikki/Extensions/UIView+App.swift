//
//  UIView+App.swift
//  mennikki
//
//  Created by Claude on 2026/02/11.
//

import UIKit

extension UIView {
    /// Duolingo風のカードシャドウを適用
    func applyCardShadow(radius: CGFloat = 10, opacity: Float = 0.12, offsetY: CGFloat = 4) {
        layer.shadowColor = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1).cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = CGSize(width: 0, height: offsetY)
        layer.masksToBounds = false
    }

    /// グラデーションレイヤーを追加（既存のグラデーションは除去してから追加）
    @discardableResult
    func applyGradient(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0), endPoint: CGPoint = CGPoint(x: 1, y: 1), cornerRadius: CGFloat = 0) -> CAGradientLayer {
        // 既存のグラデーションレイヤーを除去（蓄積防止）
        layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })

        let gradient = CAGradientLayer()
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        gradient.frame = bounds
        gradient.cornerRadius = cornerRadius
        layer.insertSublayer(gradient, at: 0)
        return gradient
    }

    /// バウンスアニメーション
    func bounceAnimation(scale: CGFloat = 1.15, duration: TimeInterval = 0.15) {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.8, options: .curveEaseOut) {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        } completion: { _ in
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.8) {
                self.transform = .identity
            }
        }
    }

    /// スタガードフェードイン
    func fadeInWithSlide(delay: TimeInterval = 0) {
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: 30)
        UIView.animate(withDuration: 0.4, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }
}

extension UIColor {
    /// RamenTypeに対応したカラー（Duolingo風の鮮やかな色）
    static func colorForRamenType(_ type: RamenType) -> UIColor {
        switch type {
        case .shoyu:    return UIColor(red: 212/255, green: 133/255, blue: 42/255,  alpha: 1) // amber
        case .shio:     return UIColor(red: 28/255,  green: 176/255, blue: 246/255, alpha: 1) // Duolingo blue
        case .miso:     return UIColor(red: 245/255, green: 166/255, blue: 35/255,  alpha: 1) // yellow-amber
        case .tonkotsu: return UIColor(red: 240/255, green: 128/255, blue: 128/255, alpha: 1) // light coral
        case .niboshi:  return UIColor(red: 70/255,  green: 100/255, blue: 150/255, alpha: 1) // dark navy
        case .paitan:   return UIColor(red: 247/255, green: 197/255, blue: 159/255, alpha: 1) // warm cream
        case .tsukemen: return UIColor(red: 232/255, green: 131/255, blue: 12/255,  alpha: 1) // orange
        case .mazemen:  return UIColor(red: 120/255, green: 80/255,  blue: 40/255,  alpha: 1) // dark brown
        case .jiro:     return UIColor(red: 139/255, green: 115/255, blue: 85/255,  alpha: 1) // tan brown
        case .iekei:    return UIColor(red: 192/255, green: 57/255,  blue: 43/255,  alpha: 1) // deep red
        case .other:    return UIColor(red: 175/255, green: 175/255, blue: 175/255, alpha: 1) // gray
        }
    }

    /// RamenTypeのタグ背景カラー（パステル）
    static func tagColorForRamenType(_ type: RamenType) -> UIColor {
        return colorForRamenType(type).withAlphaComponent(0.15)
    }
}
