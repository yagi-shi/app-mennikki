//
//  RamenType.swift
//  mennikki
//

import Foundation

/// ラーメンの種類を定義するEnum
enum RamenType: String, CaseIterable {
    case shoyu    = "醤油"
    case shio     = "塩"
    case miso     = "味噌"
    case tonkotsu = "豚骨"
    case niboshi  = "煮干し"
    case paitan   = "白湯"
    case tsukemen = "つけ麺"
    case mazemen  = "汁なし"
    case jiro     = "二郎系"
    case iekei    = "家系"
    case other    = "その他"
}
