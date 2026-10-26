//
//  InfoPlistTests.swift
//  mennikkiTests
//

import Testing
import Foundation
@testable import mennikki

/// アプリに組み込まれる設定（Info.plist）のテスト
@MainActor
struct InfoPlistTests {

    @Test("iPhone が対応する向きが、縦向きだけになっている")
    func iPhoneSupportsPortraitOnly() throws {
        let orientations = try supportedOrientations(forKey: "UISupportedInterfaceOrientations~iphone")

        #expect(orientations == ["UIInterfaceOrientationPortrait"])
    }

    @Test("iPad が対応する向きが変わっていない（縦向き、上下逆の縦向き、横向き左右）")
    func iPadOrientationsAreUnchanged() throws {
        let orientations = try supportedOrientations(forKey: "UISupportedInterfaceOrientations~ipad")

        #expect(Set(orientations) == [
            "UIInterfaceOrientationPortrait",
            "UIInterfaceOrientationPortraitUpsideDown",
            "UIInterfaceOrientationLandscapeLeft",
            "UIInterfaceOrientationLandscapeRight",
        ])
    }

    // MARK: - Helper Methods

    /// アプリ本体の Info.plist を、端末の種類による読み替えをせずにそのまま読む
    private func supportedOrientations(forKey key: String) throws -> [String] {
        let url = try #require(Bundle.main.url(forResource: "Info", withExtension: "plist"))
        let data = try Data(contentsOf: url)
        let plist = try #require(try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        return try #require(plist[key] as? [String])
    }
}
