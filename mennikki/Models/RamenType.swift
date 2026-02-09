//
//  RamenType.swift
//  mennikki
//
//  Created by Claude on 2026/02/07.
//

import Foundation

/// ラーメンの種類を定義するEnum
enum RamenType: String, CaseIterable {
    case shoyu = "醤油ラーメン"
    case miso = "味噌ラーメン"
    case shio = "塩ラーメン"
    case tonkotsu = "豚骨ラーメン"
    case tantan = "担々ラーメン"
    case jiro = "二郎系ラーメン"
    case tsukemen = "つけ麺"
    case cold = "冷ラーメン"
    case taiwan = "台湾ラーメン"
    case other = "その他"
}
