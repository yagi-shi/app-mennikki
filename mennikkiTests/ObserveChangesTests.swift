//
//  ObserveChangesTests.swift
//  mennikkiTests
//

import Testing
import Observation
@testable import mennikki

/// テストで見る値。店名の代わりに文字列、件数の代わりに整数を持つ
@Observable
@MainActor
private final class ObservedModel {
    var count = 0
    var label = ""
}

/// observeChanges(_:) のテスト。iOS 17 の UIKit で、@Observable の値の変更を画面に伝えるための共通の部品
@MainActor
struct ObserveChangesTests {

    @Test("呼び出したときに、まず 1 回、すぐに呼ぶ")
    func callsOnceImmediately() {
        let model = ObservedModel()
        var receivedCounts: [Int] = []

        observeChanges { receivedCounts.append(model.count) }

        #expect(receivedCounts == [0])
    }

    @Test("読んだ値が変わると、変わったあとの値でもう一度呼ぶ")
    func callsAgainWithNewValueWhenReadValueChanges() async {
        let model = ObservedModel()
        var receivedCounts: [Int] = []
        observeChanges { receivedCounts.append(model.count) }

        model.count = 1
        await waitUntil { receivedCounts.count == 2 }

        #expect(receivedCounts == [0, 1])
    }

    @Test("読んだ値が 2 回続けて変わると、2 回とも呼ぶ")
    func callsEveryTimeReadValueChanges() async {
        let model = ObservedModel()
        var receivedCounts: [Int] = []
        observeChanges { receivedCounts.append(model.count) }

        model.count = 1
        await waitUntil { receivedCounts.count == 2 }
        model.count = 2
        await waitUntil { receivedCounts.count == 3 }

        #expect(receivedCounts == [0, 1, 2])
    }

    @Test("読んでいない値が変わっても、呼ばない")
    func doesNotCallWhenUnreadValueChanges() async {
        let model = ObservedModel()
        var receivedCounts: [Int] = []
        observeChanges { receivedCounts.append(model.count) }

        model.label = "変わった"
        await waitUntil { receivedCounts.count == 2 }

        #expect(receivedCounts == [0])
    }

    // MARK: - ヘルパー

    /// 再び呼ぶ処理はメインの処理の順番待ちに入るので、条件を満たすまで、順番を何度か譲って待つ
    private func waitUntil(_ condition: () -> Bool) async {
        let maxYieldCount = 50
        for _ in 0..<maxYieldCount {
            if condition() { return }
            await Task.yield()
        }
    }
}
