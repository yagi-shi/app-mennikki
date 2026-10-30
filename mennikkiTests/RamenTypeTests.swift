//
//  RamenTypeTests.swift
//  mennikkiTests
//

import Testing
@testable import mennikki

/// RamenType のテスト。種類フィルターの選択肢の組み立てを確かめる
@MainActor
struct RamenTypeTests {

    @Test("選んでいる種類は、記録がなくても選択肢に含まれる")
    func filterOptionsIncludeSelectedTypesWithoutRecords() {
        let options = RamenType.filterOptions(registered: [.shoyu, .miso], selected: [.iekei])

        #expect(options == [.shoyu, .miso, .iekei])
    }

    @Test("登録済みで選んでいる種類は、選択肢に 1 回だけ含まれる")
    func filterOptionsHaveNoDuplicates() {
        let options = RamenType.filterOptions(registered: [.shoyu, .miso], selected: [.miso])

        #expect(options == [.shoyu, .miso])
    }

    @Test("選択肢は RamenType の定義順に並ぶ")
    func filterOptionsInDefinitionOrder() {
        let options = RamenType.filterOptions(registered: [.other, .shio], selected: [.jiro, .shoyu])

        #expect(options == [.shoyu, .shio, .jiro, .other])
    }

    @Test("登録済みの種類も選んでいる種類もなければ、選択肢は空になる")
    func filterOptionsEmpty() {
        #expect(RamenType.filterOptions(registered: [], selected: []).isEmpty)
    }
}
