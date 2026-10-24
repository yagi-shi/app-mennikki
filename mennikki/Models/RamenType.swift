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

    /// 種類フィルターの選択肢。
    /// 登録済みの種類に、選んでいる種類（記録がなくなったものを含む）を加え、定義順に並べる
    static func filterOptions(registered: [RamenType], selected: [RamenType]) -> [RamenType] {
        let included = Set(registered).union(selected)
        return allCases.filter { included.contains($0) }
    }
}
