//
//  RootScreenTests.swift
//  mennikkiTests
//

import Testing
@testable import mennikki

/// RootScreen のテスト。保存したデータを開けたかどうかで、アプリを開いたときに出す画面が決まることを確かめる
@MainActor
struct RootScreenTests {

    @Test("データを開けたときは、タブの画面を出す")
    func storeAvailableShowsRecordTabs() {
        #expect(RootScreen(isStoreAvailable: true) == .recordTabs)
    }

    @Test("データを開けなかったときは、知らせる画面を出す")
    func storeUnavailableShowsStoreLoadError() {
        #expect(RootScreen(isStoreAvailable: false) == .storeLoadError)
    }
}
