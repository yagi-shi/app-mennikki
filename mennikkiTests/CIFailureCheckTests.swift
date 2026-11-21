//
//  CIFailureCheckTests.swift
//  mennikkiTests
//

import Testing

/// Xcode Cloud で、テストが落ちたときに PR に失敗が表示されるかを確かめるための、わざと落ちるテスト。
/// このファイルはマージしない（#68）
struct CIFailureCheckTests {

    @Test("わざと落ちる（Xcode Cloud の失敗の表示の確認用）")
    func intentionalFailure() {
        #expect(Bool(false))
    }
}
